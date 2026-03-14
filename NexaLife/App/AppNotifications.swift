//
//  AppNotifications.swift
//  NexaLife
//

import Foundation

extension Notification.Name {
	static let nexaLifeShowQuickInput = Notification.Name("nexaLife.showQuickInput")
	static let nexaLifeShowGlobalSearch = Notification.Name("nexaLife.showGlobalSearch")
	static let nexaLifeExecutionCreateTask = Notification.Name("nexaLife.execution.createTask")
	static let nexaLifeExecutionManageProjects = Notification.Name("nexaLife.execution.manageProjects")
	static let nexaLifePerformAutoBackup = Notification.Name("nexaLife.performAutoBackup")
	static let nexaLifeResetSelections = Notification.Name("nexaLife.resetSelections")
}
