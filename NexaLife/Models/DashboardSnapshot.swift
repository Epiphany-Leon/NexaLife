//
//  DashboardSnapshot.swift
//  NexaLife
//
//  Created by Lihong Gao on 2026-02-26.
//
//  DashboardSnapshot.swift — 月度 Dashboard 存档

import Foundation
import SwiftData

@Model
final class DashboardSnapshot: Identifiable {
	var id:            UUID   = UUID()
	var monthKey:      String = ""   // 格式 "2026-01"
	var createdAt:     Date   = Date()

	// 存档数据
	var pendingTasks:   Int    = 0
	var doneTasks:      Int    = 0
	var totalNotes:     Int    = 0
	var monthlyIncome:  Double = 0.0
	var monthlyExpense: Double = 0.0
	var activeGoals:    Int    = 0
	var vitalsCount:    Int    = 0
	var summary:        String = ""  // 可选的月度总结文字

	init(
		monthKey:      String,
		pendingTasks:  Int,
		doneTasks:     Int,
		totalNotes:    Int,
		monthlyIncome: Double,
		monthlyExpense:Double,
		activeGoals:   Int,
		vitalsCount:   Int
	) {
		self.monthKey       = monthKey
		self.pendingTasks   = pendingTasks
		self.doneTasks      = doneTasks
		self.totalNotes     = totalNotes
		self.monthlyIncome  = monthlyIncome
		self.monthlyExpense = monthlyExpense
		self.activeGoals    = activeGoals
		self.vitalsCount    = vitalsCount
	}
}
