//
//  KnowledgeView.swift
//  LifeOS
//
//  Created by Lihong Gao on 2026-02-26.
//

import SwiftUI
import SwiftData

struct KnowledgeView: View {
	@Environment(\.modelContext) private var modelContext
	@Query(sort: \Note.updatedAt, order: .reverse) private var notes: [Note]

	@State private var selectedNote: Note?
	@State private var isAddingNote  = false
	@State private var searchText    = ""
	@State private var selectedTopic = "全部"

	// 所有 Topics
	var allTopics: [String] {
		let topics = Set(notes.map { $0.topic.isEmpty ? "未分类" : $0.topic })
		return ["全部"] + topics.sorted()
	}

	// 筛选后的笔记
	var filteredNotes: [Note] {
		notes.filter { note in
			let matchTopic = selectedTopic == "全部" ||
				(note.topic.isEmpty ? "未分类" : note.topic) == selectedTopic
			let matchSearch = searchText.isEmpty ||
				note.title.localizedCaseInsensitiveContains(searchText) ||
				note.content.localizedCaseInsensitiveContains(searchText) ||
				note.subtitle.localizedCaseInsensitiveContains(searchText)
			return matchTopic && matchSearch
		}
	}

	// 按 Topic 分组（仅"全部"模式下分组展示）
	var groupedNotes: [(String, [Note])] {
		let topics = Set(filteredNotes.map { $0.topic.isEmpty ? "未分类" : $0.topic })
		return topics.sorted().map { topic in
			(topic, filteredNotes.filter {
				($0.topic.isEmpty ? "未分类" : $0.topic) == topic
			})
		}
	}

	var body: some View {
		VStack(spacing: 0) {
			// 统计栏
			HStack(spacing: 16) {
				StatBadge(label: "笔记", count: notes.count, color: .blue)
				StatBadge(label: "主题", count: allTopics.count - 1, color: .indigo)
				Spacer()
				Button {
					isAddingNote = true
				} label: {
					Label("新建笔记", systemImage: "plus")
				}
				.buttonStyle(.borderedProminent)
				.controlSize(.small)
			}
			.padding(.horizontal, 16)
			.padding(.vertical, 10)
			.background(Color(nsColor: .windowBackgroundColor))

			Divider()

			// 搜索框
			HStack {
				Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
				TextField("搜索笔记…", text: $searchText)
					.textFieldStyle(.plain)
				if !searchText.isEmpty {
					Button { searchText = "" } label: {
						Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
					}
					.buttonStyle(.plain)
				}
			}
			.padding(8)
			.background(Color(nsColor: .controlBackgroundColor))
			.clipShape(RoundedRectangle(cornerRadius: 8))
			.padding(.horizontal, 12)
			.padding(.vertical, 8)

			// Topic 过滤器（横向滚动）
			ScrollView(.horizontal, showsIndicators: false) {
				HStack(spacing: 8) {
					ForEach(allTopics, id: \.self) { topic in
						TopicChip(
							label: topic,
							count: topic == "全部"
								? notes.count
								: notes.filter { ($0.topic.isEmpty ? "未分类" : $0.topic) == topic }.count,
							isSelected: selectedTopic == topic
						) {
							selectedTopic = topic
						}
					}
				}
				.padding(.horizontal, 12)
				.padding(.vertical, 6)
			}

			Divider()

			// 笔记列表
			List(selection: $selectedNote) {
				if filteredNotes.isEmpty {
					ContentUnavailableView(
						searchText.isEmpty ? "还没有笔记" : "没有匹配结果",
						systemImage: searchText.isEmpty ? "book.closed" : "magnifyingglass",
						description: Text(searchText.isEmpty ? "点击右上角新建第一条笔记" : "换个关键词试试")
					)
				} else if selectedTopic == "全部" {
					// 全部模式：按 Topic 分组
					ForEach(groupedNotes, id: \.0) { topic, items in
						Section(header: TopicSectionHeader(topic: topic, count: items.count)) {
							ForEach(items) { note in
								NoteRowView(note: note).tag(note)
							}
							.onDelete { offsets in
								for i in offsets { modelContext.delete(items[i]) }
							}
						}
					}
				} else {
					// 单 Topic 模式：平铺展示
					ForEach(filteredNotes) { note in
						NoteRowView(note: note).tag(note)
					}
					.onDelete { offsets in
						for i in offsets { modelContext.delete(filteredNotes[i]) }
					}
				}
			}
		}
		.navigationTitle("知识 Knowledge")
		.navigationSplitViewColumnWidth(min: ColumnWidth.min, ideal: ColumnWidth.ideal, max: ColumnWidth.max)
		.sheet(isPresented: $isAddingNote) {
			AddNoteSheet(isPresented: $isAddingNote)
		}
	}
}

// MARK: - Topic Chip
struct TopicChip: View {
	var label: String
	var count: Int
	var isSelected: Bool
	var action: () -> Void

	var body: some View {
		Button(action: action) {
			HStack(spacing: 4) {
				Text(label).font(.caption).fontWeight(isSelected ? .semibold : .regular)
				Text("\(count)")
					.font(.caption2)
					.padding(.horizontal, 5)
					.padding(.vertical, 1)
					.background(isSelected ? Color.white.opacity(0.3) : Color.secondary.opacity(0.15))
					.clipShape(Capsule())
			}
			.padding(.horizontal, 10)
			.padding(.vertical, 5)
			.background(isSelected ? Color.blue : Color(nsColor: .controlBackgroundColor))
			.foregroundStyle(isSelected ? .white : .primary)
			.clipShape(Capsule())
		}
		.buttonStyle(.plain)
	}
}

// MARK: - Topic Section Header
struct TopicSectionHeader: View {
	var topic: String
	var count: Int

	var body: some View {
		HStack {
			Label(topic, systemImage: "tag")
				.font(.subheadline.bold())
			Spacer()
			Text("\(count) 条").font(.caption).foregroundStyle(.secondary)
		}
	}
}

// MARK: - 笔记行
struct NoteRowView: View {
	var note: Note

	var body: some View {
		VStack(alignment: .leading, spacing: 4) {
			Text(note.title.isEmpty ? "无标题" : note.title)
				.font(.headline)
				.lineLimit(1)

			if !note.subtitle.isEmpty {
				Text(note.subtitle)
					.font(.subheadline)
					.foregroundStyle(.secondary)
					.lineLimit(1)
			}

			HStack(spacing: 6) {
				if !note.topic.isEmpty {
					Label(note.topic, systemImage: "tag")
						.font(.caption2)
						.foregroundStyle(.blue)
				}
				Spacer()
				Text(note.updatedAt, style: .relative)
					.font(.caption2)
					.foregroundStyle(.tertiary)
			}
		}
		.padding(.vertical, 4)
	}
}

// MARK: - 新建笔记 Sheet
struct AddNoteSheet: View {
	@Binding var isPresented: Bool
	@Environment(\.modelContext) private var modelContext

	@State private var title    = ""
	@State private var subtitle = ""
	@State private var topic    = ""
	@State private var content  = ""

	var body: some View {
		VStack(spacing: 20) {
			HStack {
				Text("新建笔记").font(.title3).bold()
				Spacer()
				Button("取消") { isPresented = false }
					.buttonStyle(.plain)
					.foregroundStyle(.secondary)
			}

			Form {
				TextField("标题 Title", text: $title)
				TextField("副标题 Sub-title（可选）", text: $subtitle)
				TextField("主题 Topic（可选）", text: $topic)
				TextEditor(text: $content)
					.frame(minHeight: 120)
					.overlay(
						Group {
							if content.isEmpty {
								Text("正文内容…")
									.foregroundStyle(.tertiary)
									.padding(4)
									.allowsHitTesting(false)
							}
						},
						alignment: .topLeading
					)
			}
			.formStyle(.grouped)

			HStack {
				Spacer()
				Button("创建笔记") { saveNote() }
					.buttonStyle(.borderedProminent)
					.disabled(title.isEmpty)
			}
		}
		.padding(24)
		.frame(width: 500, height: 460)
	}

	private func saveNote() {
		let note = Note(title: title, subtitle: subtitle, content: content, topic: topic)
		modelContext.insert(note)
		isPresented = false
	}
}
