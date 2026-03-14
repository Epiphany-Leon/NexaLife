//
//  Note.swift
//  NexaLife
//
//  Created by Lihong Gao on 2026-02-26.
//
//  Note.swift — Knowledge 模块

import Foundation
import SwiftData

@Model
final class Note: Identifiable {
    var id: UUID = UUID()
    var title: String = ""
    var subtitle: String = ""
    var content: String = ""
    var topic: String = ""              // Topics 分组
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(title: String, subtitle: String = "", content: String = "", topic: String = "") {
        self.title = title
        self.subtitle = subtitle
        self.content = content
        self.topic = topic
    }
}
