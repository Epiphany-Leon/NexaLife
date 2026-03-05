//
//  QuickInputSheet.swift
//  LifeOS
//
//  Created by Lihong Gao on 2026-02-26.
//
//  QuickInputSheet.swift

import SwiftUI
import SwiftData

struct QuickInputSheet: View {
	@Binding var isPresented: Bool
	@EnvironmentObject private var appState: AppState
	@Environment(\.modelContext) private var modelContext
	@StateObject private var aiService = AIService()

	@State private var inputText:       String     = ""
	@State private var suggestedModule: AppModule? = nil
	@State private var isAnalyzing:     Bool       = false
	@State private var debounceTask:    _Concurrency.Task<Void, Never>? = nil
	@State private var aiRequestID:     Int        = 0

	var body: some View {
		VStack(spacing: 20) {

			// 标题
			HStack {
				Label("捕捉闪念", systemImage: "bolt.fill")
					.font(.title3.bold())
				Spacer()
				Button("取消") {
					inputText = ""
					suggestedModule = nil
					isPresented = false
				}
				.buttonStyle(.plain)
				.foregroundStyle(.secondary)
			}

			// 文本输入框
			ZStack(alignment: .topLeading) {
				if inputText.isEmpty {
					Text("写下你的闪念…")
						.font(.system(size: 14))
						.foregroundStyle(.tertiary)
						.padding(.horizontal, 10)
						.padding(.vertical, 10)
						.allowsHitTesting(false)
				}
				TextEditor(text: $inputText)
					.font(.system(size: 14))
					.padding(6)
					.frame(minHeight: 120)
					.scrollContentBackground(.hidden)
					// ✅ 防抖：停止输入 0.8 秒后自动触发 AI 分析
					.onChange(of: inputText) { _, newValue in
						debounceTask?.cancel()
						aiRequestID += 1
						let currentRequestID = aiRequestID
						guard newValue.count > 3 else {
							suggestedModule = nil
							isAnalyzing = false
							return
						}
						debounceTask = _Concurrency.Task {
							try? await _Concurrency.Task.sleep(nanoseconds: 800_000_000)
							guard !_Concurrency.Task.isCancelled else { return }
							await triggerAI(text: newValue, requestID: currentRequestID)
						}
					}
			}
			.background(Color(nsColor: .textBackgroundColor))
			.clipShape(RoundedRectangle(cornerRadius: 8))
			.overlay(
				RoundedRectangle(cornerRadius: 8)
					.stroke(Color.gray.opacity(0.2))
			)

			// ✅ AI 分析结果区 — 输入停顿后立即显示，不需要等到选择后
			HStack(spacing: 10) {
				if isAnalyzing {
					ProgressView().scaleEffect(0.7)
					Text("AI 分析中…")
						.font(.system(size: 13))
						.foregroundStyle(.secondary)
				} else if let module = suggestedModule {
					Image(systemName: "sparkles").foregroundStyle(.purple)
					Text("建议归入：")
						.font(.system(size: 13))
						.foregroundStyle(.secondary)
					Text(module.label)
						.font(.system(size: 13, weight: .semibold))
						.foregroundStyle(.purple)
				} else if inputText.count > 3 && !aiService.isConfigured {
					Image(systemName: "exclamationmark.circle").foregroundStyle(.orange)
					Text("未配置 API Key，将存入收件箱")
						.font(.system(size: 13))
						.foregroundStyle(.secondary)
				} else {
					// 占位，保持布局稳定
					Text(" ").font(.system(size: 13))
				}
				Spacer()
			}
			.frame(height: 24)

			// 操作按钮
			HStack(spacing: 12) {
				// 手动选择归属
				Menu {
					ForEach(AppModule.allCases.filter { $0 != .dashboard }, id: \.self) { m in
						Button {
							applyManualSelection(m)
						} label: {
							Label(m.label, systemImage: m.icon)
						}
					}
				} label: {
					Label(
						suggestedModule != nil ? suggestedModule!.label : "选择象限",
						systemImage: suggestedModule?.icon ?? "tray"
					)
				}
				.buttonStyle(.bordered)
				.frame(maxWidth: .infinity)

				Spacer()

				Button("存入 LifeOS") { saveItem() }
					.buttonStyle(.borderedProminent)
					.disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
					.keyboardShortcut(.return, modifiers: .command)
			}
		}
		.padding(24)
		.frame(width: 500)
		.onDisappear {
			debounceTask?.cancel()
		}
	}

	// MARK: - AI 触发（防抖后调用）
	@MainActor
	private func triggerAI(text: String, requestID: Int) async {
		isAnalyzing = true
		defer { isAnalyzing = false }
		let module = await aiService.classifyText(text)
		guard requestID == aiRequestID, text == inputText else { return }
		suggestedModule = module
	}

	// MARK: - 保存
	private func saveItem() {
		let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !trimmed.isEmpty else { return }

		if let module = suggestedModule, module != .inbox {
			let transferred = InboxRoutingService.transfer(
				content: trimmed,
				to: module,
				modelContext: modelContext
			)
			if transferred {
				appState.updateModule(module)
			}
		} else {
			let newItem = InboxItem(
				content: trimmed,
				isProcessed: false,
				suggestedModule: suggestedModule?.rawValue
			)
			modelContext.insert(newItem)
		}

		inputText = ""
		suggestedModule = nil
		debounceTask?.cancel()
		isPresented = false
	}

	private func applyManualSelection(_ module: AppModule) {
		debounceTask?.cancel()
		aiRequestID += 1
		isAnalyzing = false
		suggestedModule = module
	}
}
