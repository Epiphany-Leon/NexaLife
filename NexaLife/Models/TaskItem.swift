//
//  Task.swift
//  NexaLife
//
//  Created by Lihong Gao on 2026-02-26.
//
//  TaskItem.swift — Execution 模块（避免与 Swift.Task 冲突）

import Foundation
import SwiftData

enum TaskStatus: String, Codable, CaseIterable {
	case todo       = "待办"
	case inProgress = "进行中"
	case done       = "已完成"
}

@Model
final class TaskItem: Identifiable {
	var id: UUID = UUID()
	var title: String = ""
	var notes: String = ""
	var category: String = ""
	var tagsText: String = ""
	var status: TaskStatus = TaskStatus.todo
	var projectName: String = ""
	var dueDate: Date?
	var createdAt: Date = Date()
	var completedAt: Date?
	var archivedMonthKey: String?

	var isDone: Bool { status == .done }
	var tagList: [String] {
		tagsText
			.split(separator: ",")
			.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
			.filter { !$0.isEmpty }
	}

	init(
		title: String,
		notes: String = "",
		category: String = "",
		tagsText: String = "",
		status: TaskStatus = .todo,
		projectName: String = "",
		dueDate: Date? = nil,
		completedAt: Date? = nil,
		archivedMonthKey: String? = nil
	) {
		self.title = title
		self.notes = notes
		self.category = category
		self.tagsText = tagsText
		self.status = status
		self.projectName = projectName
		self.dueDate = dueDate
		self.completedAt = completedAt
		self.archivedMonthKey = archivedMonthKey
	}
}
