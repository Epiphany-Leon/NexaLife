//
//  DashboardCard.swift
//  NexaLife
//
//  Created by Lihong Gao on 2026-02-26.
//
//  DashboardCard.swift

import SwiftUI

struct DashboardCard: View {
	var title:    String
	var value:    String      // ✅ 主数据（原 primary）
	var subtitle: String      // ✅ 次要数据（原 secondary）
	var icon:     String
	var color:    Color

	var body: some View {
		VStack(alignment: .leading, spacing: 14) {
			Label(title, systemImage: icon)
				.font(.subheadline.bold())
				.foregroundStyle(color)
			Text(value)
				.font(.system(size: 26, weight: .bold))
				.foregroundStyle(.primary)
			Text(subtitle)
				.font(.caption)
				.foregroundStyle(.secondary)
				.lineLimit(1)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(22)
		.background(
			RoundedRectangle(cornerRadius: 16)
				.fill(Color(nsColor: .windowBackgroundColor))
				.shadow(color: color.opacity(0.08), radius: 10, x: 0, y: 4)
		)
		.overlay(
			RoundedRectangle(cornerRadius: 16)
				.stroke(color.opacity(0.12), lineWidth: 1)
		)
	}
}
