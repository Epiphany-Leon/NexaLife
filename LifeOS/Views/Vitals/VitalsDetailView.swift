//
//  VitalsDetailView.swift
//  LifeOS
//
//  Created by Lihong Gao on 2026-02-26.
//

import SwiftUI
import SwiftData

struct VitalsDetailView: View {
	@Environment(\.modelContext) private var modelContext
	@Bindable var entry: VitalsEntry
	@StateObject private var aiService = AIService()

	@State private var aiGuidance: String = ""
	@State private var isLoadingAI = false

	var typeColor: Color {
		switch entry.type {
		case .coreCode:   return .purple
		case .treehol:    return .green
		case .motivation: return .orange
		}
	}

	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 24) {

				// 类型 + 时间
				HStack {
					Label(entry.type.rawValue, systemImage: typeIcon)
						.font(.subheadline)
						.padding(.horizontal, 10)
						.padding(.vertical, 4)
						.background(typeColor.opacity(0.1))
						.foregroundStyle(typeColor)
						.clipShape(Capsule())

					if entry.isProtected {
						Label("受保护", systemImage: "lock.fill")
							.font(.caption)
							.foregroundStyle(.secondary)
					}

					Spacer()

					Text(entry.timestamp.formatted(date: .long, time: .shortened))
						.font(.caption)
						.foregroundStyle(.tertiary)
				}

				Divider()

				// 动力评分（仅 motivation 显示）
				if entry.type == .motivation {
					HStack(spacing: 6) {
						Text("能量评分").font(.subheadline).foregroundStyle(.secondary)
						HStack(spacing: 3) {
							ForEach(1...5, id: \.self) { i in
								Button {
									entry.moodScore = i
								} label: {
									Image(systemName: i <= entry.moodScore ? "star.fill" : "star")
										.foregroundStyle(i <= entry.moodScore ? Color.orange : Color.secondary)
								}
								.buttonStyle(.plain)
							}
						}
					}
				}

				// 内容（核心守则可编辑，树洞只读）
				if entry.type == .treehol {
					Text(entry.content)
						.font(.body)
						.frame(maxWidth: .infinity, alignment: .leading)
						.padding(14)
						.background(Color.green.opacity(0.05))
						.clipShape(RoundedRectangle(cornerRadius: 10))
				} else {
					TextEditor(text: $entry.content)
						.font(.body)
						.frame(minHeight: 160)
						.scrollContentBackground(.hidden)
						.padding(10)
						.background(typeColor.opacity(0.04))
						.clipShape(RoundedRectangle(cornerRadius: 10))
				}

				// AI 辅助区（核心守则专属）
				if entry.type == .coreCode {
					Divider()
					VStack(alignment: .leading, spacing: 12) {
						HStack {
							Label("AI 辅助指导", systemImage: "sparkles")
								.font(.headline)
							Spacer()
							Button {
								loadAIGuidance()
							} label: {
								if isLoadingAI {
									ProgressView().scaleEffect(0.7)
								} else {
									Label("获取建议", systemImage: "wand.and.stars")
								}
							}
							.buttonStyle(.bordered)
							.disabled(isLoadingAI)
						}

						if !aiGuidance.isEmpty {
							Text(aiGuidance)
								.font(.body)
								.padding(14)
								.background(Color.purple.opacity(0.06))
								.clipShape(RoundedRectangle(cornerRadius: 10))
						}
					}
				}

				// 存档区（动力/灵感 & 树洞）
				if entry.type != .coreCode {
					Divider()
					HStack(spacing: 12) {
						Button {
							archiveEntry(to: "Knowledge")
						} label: {
							Label(entry.isArchived ? "已存档" : "存入 Knowledge", systemImage: "book")
								.frame(maxWidth: .infinity)
						}
						.buttonStyle(.bordered)
						.tint(.blue)
						.disabled(entry.isArchived)

						Button {
							archiveEntry(to: "Vitals")
						} label: {
							Label("存入 Vitals Review", systemImage: "sparkles")
								.frame(maxWidth: .infinity)
						}
						.buttonStyle(.bordered)
						.tint(.purple)
						.disabled(entry.isArchived)
					}
				}

				Spacer()
			}
			.padding(28)
		}
		.navigationTitle(entry.type.rawValue)
	}

	private var typeIcon: String {
		switch entry.type {
		case .coreCode:   return "shield.lefthalf.filled"
		case .treehol:    return "tree"
		case .motivation: return "bolt.heart"
		}
	}

	// MARK: - AI 辅助
	private func loadAIGuidance() {
		isLoadingAI = true
		Task {
			let guidance = await aiService.generateReport(
				entries: [entry.content],
				type: "核心守则指导"
			)
			await MainActor.run {
				aiGuidance = guidance
				isLoadingAI = false
			}
		}
	}

	// MARK: - 存档
	private func archiveEntry(to destination: String) {
		let note = Note(
			title: "【Vitals 存档】\(entry.type.rawValue)",
			subtitle: entry.timestamp.formatted(date: .abbreviated, time: .omitted),
			content: entry.content,
			topic: destination == "Vitals" ? "Vitals Review" : "Vitals"
		)
		modelContext.insert(note)
		entry.isArchived = true
	}
}
