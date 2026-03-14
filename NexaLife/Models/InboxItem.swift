//
//  InboxItem.swift
//  NexaLife
//
//  Created by Lihong Gao on 2026-02-24.
//

import Foundation
import SwiftData

@Model
final class InboxItem: Identifiable {
	var id: UUID = UUID()
	var timestamp: Date = Date()
	var content: String = ""
	var isProcessed: Bool = false
	var suggestedModule: String?        // AI 建议的象限

	init(
		content: String,
		timestamp: Date = .now,
		isProcessed: Bool = false,
		suggestedModule: String? = nil  // ✅ 确保此参数存在
	) {
		self.content = content
		self.timestamp = timestamp
		self.isProcessed = isProcessed
		self.suggestedModule = suggestedModule
	}
}
