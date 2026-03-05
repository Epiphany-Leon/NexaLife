//
//  RowTextStyle.swift
//  LifeOS
//
//  Created by Lihong Gao on 2026-02-26.
//
//  RowTextStyle.swift — 中栏文字尺寸规范

import SwiftUI

extension View {
	// 主标题
	func rowTitle() -> some View {
		self.font(.system(size: 16, weight: .semibold))
	}
	// 副标题
	func rowSubtitle() -> some View {
		self.font(.system(size: 13, weight: .regular))
	}
	// 时间戳等辅助信息
	func rowCaption() -> some View {
		self.font(.system(size: 12)).foregroundStyle(.secondary)
	}
}
