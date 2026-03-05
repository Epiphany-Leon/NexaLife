//
//  NoteDetailView.swift
//  LifeOS
//
//  Created by Lihong Gao on 2026-02-26.
//

import SwiftUI
import SwiftData

struct NoteDetailView: View {
	@Environment(\.modelContext) private var modelContext
	@Bindable var note: Note
	@StateObject private var aiService = AIService()

	@State private var isGeneratingReport = false
	@State private var generatedReport: String = ""
	@State private var showReportSheet = false

	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 24) {

				// 标题
				TextField("标题", text: $note.title)
					.font(.title.bold())
					.textFieldStyle(.plain)
					.onChange(of: note.title) { _, _ in note.updatedAt = Date() }

				// 副标题
				TextField("副标题 Sub-title（可选）", text: $note.subtitle)
					.font(.title3)
					.textFieldStyle(.plain)
					.foregroundStyle(.secondary)
					.onChange(of: note.subtitle) { _, _ in note.updatedAt = Date() }

				// 元信息行
				HStack(spacing: 12) {
					// Topic 编辑
					HStack(spacing: 4) {
						Image(systemName: "tag").foregroundStyle(.blue)
						TextField("主题 Topic", text: $note.topic)
							.textFieldStyle(.plain)
							.font(.subheadline)
							.foregroundStyle(.blue)
							.frame(maxWidth: 120)
					}
					.padding(.horizontal, 8)
					.padding(.vertical, 4)
					.background(Color.blue.opacity(0.08))
					.clipShape(Capsule())

					Spacer()

					VStack(alignment: .trailing, spacing: 2) {
						Text("创建 " + note.createdAt.formatted(date: .abbreviated, time: .omitted))
						Text("更新 " + note.updatedAt.formatted(date: .abbreviated, time: .shortened))
					}
					.font(.caption2)
					.foregroundStyle(.tertiary)
				}

				Divider()

				// 正文
				TextEditor(text: $note.content)
					.font(.body)
					.frame(minHeight: 300)
					.scrollContentBackground(.hidden)
					.onChange(of: note.content) { _, _ in note.updatedAt = Date() }

				Divider()

				// AI 报告生成区
				VStack(alignment: .leading, spacing: 12) {
					HStack {
						Label("AI 专题报告", systemImage: "sparkles")
							.font(.headline)
						Spacer()
						Button {
							generateAIReport()
						} label: {
							if isGeneratingReport {
								ProgressView().scaleEffect(0.7)
								Text("生成中…")
							} else {
								Label("生成报告", systemImage: "wand.and.stars")
							}
						}
						.buttonStyle(.bordered)
						.disabled(isGeneratingReport || note.content.isEmpty)
					}

					if !generatedReport.isEmpty {
						VStack(alignment: .leading, spacing: 10) {
							Text(generatedReport)
								.font(.body)
								.padding(14)
								.background(Color.purple.opacity(0.06))
								.clipShape(RoundedRectangle(cornerRadius: 10))

							HStack(spacing: 10) {
								// 存入 Knowledge
								Button {
									archiveReport(to: "Knowledge")
								} label: {
									Label("存入 Knowledge", systemImage: "book")
								}
								.buttonStyle(.bordered)
								.tint(.blue)

								// 存入 Vitals Review
								Button {
									archiveReport(to: "Vitals")
								} label: {
									Label("存入 Vitals", systemImage: "sparkles")
								}
								.buttonStyle(.bordered)
								.tint(.purple)

								Spacer()

								Button {
									generatedReport = ""
								} label: {
									Image(systemName: "xmark")
								}
								.buttonStyle(.plain)
								.foregroundStyle(.secondary)
							}
						}
					}
				}

				Spacer()

				// 删除按钮
				Button(role: .destructive) {
					modelContext.delete(note)
				} label: {
					Label("删除笔记", systemImage: "trash")
						.frame(maxWidth: .infinity)
				}
				.buttonStyle(.bordered)
			}
			.padding(28)
		}
		.navigationTitle(note.title.isEmpty ? "笔记详情" : note.title)
	}

	// MARK: - AI 生成报告
	private func generateAIReport() {
		isGeneratingReport = true
		Task {
			let report = await aiService.generateReport(
				entries: [note.title, note.subtitle, note.content],
				type: "Knowledge"
			)
			await MainActor.run {
				generatedReport = report
				isGeneratingReport = false
			}
		}
	}

	// MARK: - 存档报告
	private func archiveReport(to destination: String) {
		let archiveNote = Note(
			title: "【AI报告】\(note.title)",
			subtitle: "由 AI 生成 · \(Date().formatted(date: .abbreviated, time: .omitted))",
			content: generatedReport,
			topic: destination == "Vitals" ? "Vitals Review" : note.topic
		)
		modelContext.insert(archiveNote)
		generatedReport = ""
	}
}
