//
//  Connection.swift
//  NexaLife
//
//  Created by Lihong Gao on 2026-02-26.
//
//  Connection.swift — Lifestyle/CRM

import Foundation
import SwiftData

@Model
final class Connection: Identifiable {
    var id: UUID = UUID()
    var name: String = ""
    var relationship: String = ""
    var notes: String = ""
    var lastContactDate: Date?
    var importanceLevel: Int = 3          // 1~5
    var attitudeStrategy: String = ""
    var followUpPlan: String = ""

    init(
        name: String,
        relationship: String = "",
        notes: String = "",
        importanceLevel: Int = 3,
        attitudeStrategy: String = "",
        followUpPlan: String = ""
    ) {
        self.name = name
        self.relationship = relationship
        self.notes = notes
        self.importanceLevel = min(5, max(1, importanceLevel))
        self.attitudeStrategy = attitudeStrategy
        self.followUpPlan = followUpPlan
    }
}
