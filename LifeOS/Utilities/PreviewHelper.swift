//
//  PreviewHelper.swift
//  LifeOS
//
//  Created by Lihong Gao on 2026-02-26.
//
//  PreviewHelper.swift — Preview 专用容器，全局复用

import SwiftData
import Foundation

// ✅ 移除 @MainActor，改用同步方式，Preview 宏不在 MainActor 上下文
func previewContainer() -> ModelContainer {
	let schema = Schema([
		InboxItem.self,
		TaskItem.self,
		ExecutionProject.self,
		Note.self,
		Transaction.self,
		Goal.self,
		GoalMilestone.self,
		GoalProgressEntry.self,
		VitalsEntry.self,
		Connection.self,
		DashboardSnapshot.self   // ✅ 新增
	])
	let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
	return try! ModelContainer(for: schema, configurations: config)
}
