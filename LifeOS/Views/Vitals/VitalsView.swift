//
//  VitalsView.swift
//  LifeOS
//
//  Created by Lihong Gao on 2026-02-26.
//

import SwiftUI
import SwiftData
import LocalAuthentication

struct VitalsView: View {
	@Environment(\.modelContext) private var modelContext
	@Query(sort: \VitalsEntry.timestamp, order: .reverse) private var entries: [VitalsEntry]

	@State private var selectedEntry: VitalsEntry?
	@State private var selectedType: VitalsEntryType? = nil   // nil = 全部
	@State private var isAddingEntry = false
	@State private var addingType: VitalsEntryType = .motivation

	// 按类型筛选
	var filteredEntries: [VitalsEntry] {
		guard let type = selectedType else { return entries }
		return entries.filter { $0.type == type }
	}

	var body: some View {
		VStack(spacing: 0) {

			// 统计栏
			HStack(spacing: 16) {
				VitalsStatBadge(
					type: .coreCode,
					count: entries.filter { $0.type == .coreCode }.count
				)
				VitalsStatBadge(
					type: .treehol,
					count: entries.filter { $0.type == .treehol }.count
				)
				VitalsStatBadge(
					type: .motivation,
					count: entries.filter { $0.type == .motivation }.count
				)
				Spacer()
			}
			.padding(.horizontal, 16)
			.padding(.vertical, 10)
			.background(Color(nsColor: .windowBackgroundColor))

			Divider()

			// 类型筛选器
			HStack(spacing: 0) {
				TypeFilterButton(label: "全部", isSelected: selectedType == nil) {
					selectedType = nil
				}
				ForEach(VitalsEntryType.allCases, id: \.self) { type in
					TypeFilterButton(label: type.rawValue, isSelected: selectedType == type) {
						selectedType = type
					}
				}
				Spacer()

				// 新增按钮
				Menu {
					ForEach(VitalsEntryType.allCases, id: \.self) { type in
						Button {
							addingType = type
							isAddingEntry = true
						} label: {
							Label(type.rawValue, systemImage: typeIcon(type))
						}
					}
				} label: {
					Label("新增", systemImage: "plus")
						.font(.subheadline)
				}
				.buttonStyle(.borderedProminent)
				.controlSize(.small)
				.padding(.trailing, 12)
			}
			.padding(.vertical, 6)

			Divider()

			// 列表
			List(selection: $selectedEntry) {
				if filteredEntries.isEmpty {
					ContentUnavailableView(
						"还没有记录",
						systemImage: "sparkles",
						description: Text("点击右上角开始记录")
					)
				} else {
					ForEach(filteredEntries) { entry in
						VitalsRowView(entry: entry) {
							attemptDelete(entry: entry)
						}
						.tag(entry)
					}
				}
			}
		}
		.navigationTitle("觉知 Vitals")
		.navigationSplitViewColumnWidth(min: ColumnWidth.min, ideal: ColumnWidth.ideal, max: ColumnWidth.max)
		.sheet(isPresented: $isAddingEntry) {
			AddVitalsEntrySheet(isPresented: $isAddingEntry, defaultType: addingType)
		}
	}

	// MARK: - 删除保护
	private func attemptDelete(entry: VitalsEntry) {
		if entry.isProtected {
			authenticateToDelete(entry: entry)
		} else {
			modelContext.delete(entry)
		}
	}

	private func authenticateToDelete(entry: VitalsEntry) {
		let context = LAContext()
		var error: NSError?

		if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
			context.evaluatePolicy(
				.deviceOwnerAuthentication,
				localizedReason: "需要验证身份才能删除「\(entry.type.rawValue)」记录"
			) { success, _ in
				DispatchQueue.main.async {
					if success { modelContext.delete(entry) }
				}
			}
		}
	}

	private func typeIcon(_ type: VitalsEntryType) -> String {
		switch type {
		case .coreCode:   return "shield.lefthalf.filled"
		case .treehol:    return "tree"
		case .motivation: return "bolt.heart"
		}
	}
}

// MARK: - 统计徽章
struct VitalsStatBadge: View {
	var type: VitalsEntryType
	var count: Int

	var color: Color {
		switch type {
		case .coreCode:   return .purple
		case .treehol:    return .green
		case .motivation: return .orange
		}
	}

	var icon: String {
		switch type {
		case .coreCode:   return "shield.lefthalf.filled"
		case .treehol:    return "tree"
		case .motivation: return "bolt.heart"
		}
	}

	var body: some View {
		HStack(spacing: 4) {
			Image(systemName: icon).font(.caption).foregroundStyle(color)
			VStack(alignment: .leading, spacing: 1) {
				Text("\(count)").font(.system(size: 15, weight: .bold)).foregroundStyle(color)
				Text(type.rawValue).font(.caption2).foregroundStyle(.secondary)
			}
		}
	}
}

// MARK: - 类型筛选按钮
struct TypeFilterButton: View {
	var label: String
	var isSelected: Bool
	var action: () -> Void

	var body: some View {
		Button(action: action) {
			Text(label)
				.font(.subheadline)
				.padding(.horizontal, 12)
				.padding(.vertical, 5)
				.background(isSelected ? Color.accentColor : Color.clear)
				.foregroundStyle(isSelected ? .white : .primary)
				.clipShape(Capsule())
		}
		.buttonStyle(.plain)
		.padding(.leading, 8)
	}
}

// MARK: - 条目行
struct VitalsRowView: View {
	var entry: VitalsEntry
	var onDelete: () -> Void

	var typeColor: Color {
		switch entry.type {
		case .coreCode:   return .purple
		case .treehol:    return .green
		case .motivation: return .orange
		}
	}

	var typeIcon: String {
		switch entry.type {
		case .coreCode:   return "shield.lefthalf.filled"
		case .treehol:    return "tree"
		case .motivation: return "bolt.heart"
		}
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 6) {
			HStack(spacing: 6) {
				// 类型标签
				Label(entry.type.rawValue, systemImage: typeIcon)
					.font(.caption2)
					.padding(.horizontal, 6)
					.padding(.vertical, 2)
					.background(typeColor.opacity(0.12))
					.foregroundStyle(typeColor)
					.clipShape(Capsule())

				if entry.isProtected {
					Image(systemName: "lock.fill")
						.font(.caption2)
						.foregroundStyle(.secondary)
				}

				if entry.isArchived {
					Image(systemName: "archivebox.fill")
						.font(.caption2)
						.foregroundStyle(.blue)
				}

				Spacer()

				// 动力打分星级
				if entry.type == .motivation && entry.moodScore > 0 {
					HStack(spacing: 1) {
						ForEach(1...5, id: \.self) { i in
							Image(systemName: i <= entry.moodScore ? "star.fill" : "star")
								.font(.caption2)
								.foregroundStyle(i <= entry.moodScore ? Color.orange : Color.secondary)
						}
					}
				}
			}

			Text(entry.content)
				.font(.body)
				.lineLimit(3)

			Text(entry.timestamp, style: .relative)
				.font(.caption2)
				.foregroundStyle(.tertiary)
		}
		.padding(.vertical, 4)
		.contextMenu {
			if !entry.isProtected {
				Button(role: .destructive, action: onDelete) {
					Label("删除", systemImage: "trash")
				}
			} else {
				Button(action: onDelete) {
					Label("删除（需要验证）", systemImage: "lock.fill")
				}
			}
		}
	}
}
