//
//  Goal.swift
//  NexaLife
//
//  Created by Lihong Gao on 2026-02-26.
//
//  Goal.swift — Lifestyle/Goal

import Foundation
import SwiftData

@Model
final class Goal: Identifiable {
    var id: UUID = UUID()
    var title: String = ""
    var targetDescription: String = ""
    var progress: Double = 0.0          // 0.0 ~ 1.0
    var startDate: Date = Date()
    var dueDate: Date?
    var isCompleted: Bool = false

    init(title: String, targetDescription: String = "", dueDate: Date? = nil) {
        self.title = title
        self.targetDescription = targetDescription
        self.dueDate = dueDate
    }
}
