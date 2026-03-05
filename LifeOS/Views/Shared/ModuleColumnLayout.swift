//
//  ModuleColumnLayout.swift
//  LifeOS
//
//  Created by Lihong Gao on 2026-02-26.
//
//  ModuleColumnLayout.swift
//  各象限中栏通用布局配置

import SwiftUI

// ✅ 任务7：统一的中栏宽度设置
enum ColumnWidth {
	static let min:   CGFloat = 320
	static let ideal: CGFloat = 380
	static let max:   CGFloat = 480
}

// 多段文字均匀分布组件（动态适配中栏宽度）
struct EvenlySpacedLabels: View {
	var items: [(icon: String, text: String, color: Color)]

	var body: some View {
		GeometryReader { geo in
			HStack(spacing: 0) {
				ForEach(Array(items.enumerated()), id: \.offset) { index, item in
					HStack(spacing: 6) {
						Image(systemName: item.icon)
							.foregroundStyle(item.color)
						Text(item.text)
							.font(.system(size: 15, weight: .medium))
					}
					.frame(width: geo.size.width / CGFloat(items.count))
				}
			}
		}
		.frame(height: 28)
	}
}
