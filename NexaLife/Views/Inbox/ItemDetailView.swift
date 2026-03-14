//
//  ItemDetailView.swift
//  NexaLife
//
//  Created by Lihong Gao on 2026-02-26.
//

import SwiftUI
import SwiftData

struct ItemDetailView: View {
	@EnvironmentObject private var appState: AppState
	@Environment(\.modelContext) private var modelContext
	@Environment(\.locale) private var locale
	@Binding var selectedItem: InboxItem?
	@Bindable var item: InboxItem
	@StateObject private var aiService = AIService()
	@State private var isClassifying = false
	@State private var classifyTask: _Concurrency.Task<Void, Never>?
	@State private var classifyRequestID = 0
	@State private var handlingSuggestion: InboxHandlingSuggestion?

	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 24) {
				HStack(alignment: .center) {
					Text(item.timestamp.formatted(date: .long, time: .shortened))
						.font(.caption)
						.foregroundStyle(.secondary)
					Spacer()
					Button(role: .destructive) {
						deleteItem()
					} label: {
						Label(AppBrand.localized("删除闪念", "Delete Entry", locale: locale), systemImage: "trash")
					}
					.buttonStyle(.bordered)
				}

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

				if let suggestion = handlingSuggestion {
					VStack(alignment: .leading, spacing: 8) {
						Label(AppBrand.localized("AI 处理建议", "AI Handling Suggestion", locale: locale), systemImage: "sparkles")
							.font(.headline)
						Text(suggestion.headline)
							.font(.subheadline.bold())
						Text(suggestion.reason)
							.font(.subheadline)
							.foregroundStyle(.secondary)
						if suggestion.module != .inbox {
							Label(
								AppBrand.localized(
									"建议去往 \(suggestion.module.label(for: locale))",
									"Suggested destination: \(suggestion.module.label(for: locale))",
									locale: locale
								),
								systemImage: suggestion.module.icon
							)
								.font(.caption)
								.foregroundStyle(.purple)
						}
					}
					.padding(16)
					.frame(maxWidth: .infinity, alignment: .leading)
					.background(Color.purple.opacity(0.08))
					.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
				}

				Divider()

				VStack(alignment: .leading, spacing: 12) {
					Label(AppBrand.localized("归类到象限", "Move to Module", locale: locale), systemImage: "tray.and.arrow.down")
						.font(.headline)

					HStack {
						if let suggested = item.suggestedModule,
						   let suggestedModule = AppModule(rawValue: suggested) {
							Image(systemName: "sparkles").foregroundStyle(.purple)
							Text(
								AppBrand.localized(
									"AI 建议：\(suggestedModule.label(for: locale))",
									"AI suggestion: \(suggestedModule.label(for: locale))",
									locale: locale
								)
							)
								.font(.subheadline)
								.foregroundStyle(.purple)
						}
						if isClassifying {
							ProgressView().scaleEffect(0.7)
						}
						Spacer()
						Button(AppBrand.localized("重新分析", "Analyze Again", locale: locale)) {
							scheduleClassification(force: true)
						}
						.buttonStyle(.borderless)
					}

					LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
						ForEach([AppModule.execution, .lifestyle, .knowledge, .vitals], id: \.self) { module in
							Button {
								transferToModule(module)
							} label: {
								Label(module.label(for: locale), systemImage: module.icon)
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
		.navigationTitle(AppBrand.localized("闪念详情", "Captured Entry", locale: locale))
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
			handlingSuggestion = nil
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
		let suggestion = await aiService.suggestInboxHandling(text)
		guard requestID == classifyRequestID else { return }
		let currentText = item.content.trimmingCharacters(in: .whitespacesAndNewlines)
		if currentText == text {
			item.suggestedModule = result.rawValue
			handlingSuggestion = suggestion
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

	private func deleteItem() {
		selectedItem = nil
		modelContext.delete(item)
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
