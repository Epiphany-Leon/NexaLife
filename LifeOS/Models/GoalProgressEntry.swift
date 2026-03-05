//
//  GoalProgressEntry.swift
//  LifeOS
//
//  Created by Codex on 2026-03-04.
//

import Foundation
import SwiftData

@Model
final class GoalProgressEntry: Identifiable {
	var id: UUID = UUID()
	var goalID: UUID = UUID()
	var recordedAt: Date = Date()
	var progress: Double = 0.0
	var note: String = ""

	init(
		goalID: UUID,
		recordedAt: Date = .now,
		progress: Double,
		note: String = ""
	) {
		self.goalID = goalID
		self.recordedAt = recordedAt
		self.progress = min(1, max(0, progress))
		self.note = note
	}
}
