//
//  GoalMilestone.swift
//  LifeOS
//
//  Created by Codex on 2026-03-04.
//

import Foundation
import SwiftData

@Model
final class GoalMilestone: Identifiable {
	var id: UUID = UUID()
	var goalID: UUID = UUID()
	var title: String = ""
	var isCompleted: Bool = false
	var createdAt: Date = Date()
	var dueDate: Date?

	init(
		goalID: UUID,
		title: String,
		isCompleted: Bool = false,
		dueDate: Date? = nil,
		createdAt: Date = .now
	) {
		self.goalID = goalID
		self.title = title
		self.isCompleted = isCompleted
		self.dueDate = dueDate
		self.createdAt = createdAt
	}
}
