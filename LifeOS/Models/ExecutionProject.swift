//
//  ExecutionProject.swift
//  LifeOS
//
//  Created by Lihong Gao on 2026-03-02.
//

import Foundation
import SwiftData

enum ProjectHorizon: String, Codable, CaseIterable {
	case shortTerm = "短期"
	case midTerm = "中期"
	case longTerm = "长期"
}

@Model
final class ExecutionProject: Identifiable {
	var id: UUID = UUID()
	var name: String = ""
	var detail: String = ""
	var horizon: ProjectHorizon = ProjectHorizon.shortTerm
	var createdAt: Date = Date()
	var updatedAt: Date = Date()

	init(name: String, detail: String = "", horizon: ProjectHorizon = ProjectHorizon.shortTerm) {
		self.name = name
		self.detail = detail
		self.horizon = horizon
	}
}
