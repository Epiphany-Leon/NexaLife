//
//  ItemDetailView.swift
//  LifeOS
//
//  Created by Lihong Gao on 2026-02-26.
//

import SwiftUI
import SwiftData

struct ItemDetailView: View {
	@EnvironmentObject private var appState: AppState
	@Environment(\.modelContext) private var modelContext
	@Binding var selectedItem: InboxItem?
	@Bindable var item: InboxItem
	@StateObject private var aiService = AIService()
	@State private var isClassifying = false
	@State private var classifyTask: _Concurrency.Task<Void, Never>?
	@State private var classifyRequestID = 0

	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 24) {

				Text(item.timestamp.formatted(date: .long, time: .shortened))
					.font(.caption)
					.foregroundStyle(.secondary)

				TextEditor(text: $item.content)
					.font(.body)
					.frame(minHeight: 160)
					.padding(10)
					.background(Color(nsColor: .textBackgroundColor))
					.clipShape(RoundedRectangle(cornerRadius: 10))
					.overlay(
						RoundedRectangle(cornerRadius: 10)
							.stroke(Color.gray.opacity(0.2))
					)

				Divider()

				VStack(alignment: .leading, spacing: 12) {
					Label("归类到象限", systemImage: "tray.and.arrow.down")
						.font(.headline)

					HStack {
						if let suggested = item.suggestedModule {
							Image(systemName: "sparkles").foregroundStyle(.purple)
							Text("AI 建议：\(suggested)")
								.font(.subheadline)
								.foregroundStyle(.purple)
						}
						if isClassifying {
							ProgressView().scaleEffect(0.7)
						}
						Spacer()
						Button("重新分析") {
							scheduleClassification(force: true)
						}
						.buttonStyle(.borderless)
					}

					LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
						ForEach([AppModule.execution, .lifestyle, .knowledge, .vitals], id: \.self) { module in
							Button {
								transferToModule(module)
							} label: {
								Label(module.label, systemImage: module.icon)
									.frame(maxWidth: .infinity)
							}
							.buttonStyle(.bordered)
							.tint(item.suggestedModule == module.rawValue ? .accentColor : .secondary)
						}
					}
				}
			}
			.padding(24)
		}
		.navigationTitle("闪念详情")
		.onAppear {
			scheduleClassification(force: true)
		}
		.onChange(of: item.content) { _, _ in
			scheduleClassification(force: false)
		}
		.onDisappear {
			classifyTask?.cancel()
		}
	}

	private func scheduleClassification(force: Bool) {
		classifyTask?.cancel()
		let text = item.content.trimmingCharacters(in: .whitespacesAndNewlines)
		if text.count <= 3 {
			if force {
				item.suggestedModule = nil
			}
			isClassifying = false
			return
		}

		classifyRequestID += 1
		let requestID = classifyRequestID
		classifyTask = _Concurrency.Task {
			try? await _Concurrency.Task.sleep(nanoseconds: 600_000_000)
			guard !_Concurrency.Task.isCancelled else { return }
			await runClassification(text: text, requestID: requestID)
		}
	}

	@MainActor
	private func runClassification(text: String, requestID: Int) async {
		isClassifying = true
		defer { isClassifying = false }
		let result = await aiService.classifyText(text)
		guard requestID == classifyRequestID else { return }
		let currentText = item.content.trimmingCharacters(in: .whitespacesAndNewlines)
		if currentText == text {
			item.suggestedModule = result.rawValue
		}
	}

	private func transferToModule(_ module: AppModule) {
		guard module != .inbox else { return }
		let content = item.content.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !content.isEmpty else { return }

		let transferred = InboxRoutingService.transfer(
			content: content,
			to: module,
			modelContext: modelContext
		)
		guard transferred else { return }

		item.suggestedModule = module.rawValue
		selectedItem = nil
		modelContext.delete(item)
		appState.updateModule(module)
	}
}

#Preview {
	let config = ModelConfiguration(isStoredInMemoryOnly: true)
	let container = try! ModelContainer(for: InboxItem.self, configurations: config)
	let sample = InboxItem(content: "读完《原则》第三章，整理关于原则驱动决策的笔记", suggestedModule: "Knowledge")
	container.mainContext.insert(sample)

	return ItemDetailView(selectedItem: .constant(sample), item: sample)
		.environmentObject(AppState())
		.modelContainer(container)
		.frame(width: 600, height: 500)
}
