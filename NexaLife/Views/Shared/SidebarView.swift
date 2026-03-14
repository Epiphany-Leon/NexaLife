//
//  SidebarView.swift
//  NexaLife
//
//  Created by Lihong Gao on 2026-02-26.
//
//  SidebarView.swift — 补充 Dashboard 入口点击后收起侧边栏

import SwiftUI
import AppKit

struct SidebarView: View {
	@EnvironmentObject private var appState: AppState
	@Environment(\.locale) private var locale
	@State private var isShowingAccountDetail = false

	var body: some View {
		List(selection: Binding(
			get: { appState.selectedModule },
			set: { if let m = $0 { appState.updateModule(m) } }
		)) {
			// 用户头像 + 昵称
			Button {
				isShowingAccountDetail = true
			} label: {
				HStack(spacing: 10) {
					AvatarThumbnail(path: appState.avatarImagePath)
					Text(appState.userName)
						.font(.headline)
					Spacer()
					Image(systemName: "chevron.right")
						.font(.caption)
						.foregroundStyle(.tertiary)
				}
				.frame(maxWidth: .infinity, alignment: .leading)
				.contentShape(Rectangle())
			}
			.buttonStyle(.plain)
			.padding(.vertical, 6)
			.contentShape(Rectangle())
			.listRowSeparator(.hidden)

			NavigationLink(value: AppModule.dashboard) {
				Label(AppModule.dashboard.label(for: locale), systemImage: AppModule.dashboard.icon)
			}

			Section(AppBrand.localized("主控室", "Core", locale: locale)) {
				NavigationLink(value: AppModule.inbox) {
					Label(AppModule.inbox.label(for: locale), systemImage: AppModule.inbox.icon)
				}
			}

			Section(AppBrand.localized("四大象限", "Four Quadrants", locale: locale)) {
				ForEach([AppModule.execution, AppModule.lifestyle, AppModule.knowledge, AppModule.vitals]) { module in
					NavigationLink(value: module) {
						Label(module.label(for: locale), systemImage: module.icon)
					}
				}
			}
		}
		.navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 260)
		.sheet(isPresented: $isShowingAccountDetail) {
			AccountDetailView()
				.environmentObject(appState)
				.environment(\.locale, appState.currentLocale)
				.preferredColorScheme(appState.selectedAppearanceMode.colorScheme)
		}
	}
}

private struct AvatarThumbnail: View {
	var path: String

	var body: some View {
		if let image = NSImage(contentsOfFile: path), !path.isEmpty {
			Image(nsImage: image)
				.resizable()
				.scaledToFill()
				.frame(width: 32, height: 32)
				.clipShape(Circle())
		} else {
			Image(systemName: "person.circle.fill")
				.resizable()
				.frame(width: 32, height: 32)
				.foregroundStyle(.secondary)
		}
	}
}
