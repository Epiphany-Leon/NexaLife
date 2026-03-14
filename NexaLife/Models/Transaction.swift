//
//  Transaction.swift
//  NexaLife
//
//  Created by Lihong Gao on 2026-02-26.
//
//  Transaction.swift — Lifestyle/Accounting

import Foundation
import SwiftData

@Model
final class Transaction: Identifiable {
    var id: UUID = UUID()
    var amount: Double = 0.0            // 负数为支出，正数为收入
    var category: String = ""
    var title: String = ""              // 原 Stream 概念，改为标题
    var note: String = ""
    var date: Date = Date()
    var currencyCode: String = CurrencyCode.CNY.rawValue
    var streamName: String = ""         // 兼容旧数据

    init(
        amount: Double,
        category: String = "",
        title: String = "",
        note: String = "",
        date: Date = .now,
        currencyCode: String = CurrencyCode.CNY.rawValue,
        streamName: String = ""
    ) {
        self.amount = amount
        self.category = category
        self.title = title
        self.note = note
        self.date = date
        self.currencyCode = currencyCode
        self.streamName = streamName
    }
}
