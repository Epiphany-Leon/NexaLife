//
//  LifeOSApp.swift
//  LifeOS
//
//  Created by Lihong Gao on 2026-02-24.
//

import SwiftUI
import SwiftData

@main
struct LifeOSApp: App {
	@StateObject private var appState     = AppState()
	@StateObject private var oauthService = OAuthService.mock   // 开发期间用 mock

	var sharedModelContainer: ModelContainer = {
		let schema = Schema([
			InboxItem.self,
				TaskItem.self,
				ExecutionProject.self,
				Note.self,
				Transaction.self,
				Goal.self,
				GoalMilestone.self,
				GoalProgressEntry.self,
				VitalsEntry.self,
				Connection.self,
				DashboardSnapshot.self   // ✅ 新增
			])
		let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
		let config    = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isPreview)
		do    { return try ModelContainer(for: schema, configurations: [config]) }
		catch {
			let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
			return try! ModelContainer(for: schema, configurations: [fallback])
		}
	}()

	var body: some Scene {
		WindowGroup {
			Group {
				if !appState.hasCompletedOnboarding {
					OnboardingView()
				} else {
					ContentView()
				}
			}
			.environmentObject(appState)
			.environmentObject(oauthService)
		}
		// ✅ 任务6：默认窗口尺寸加大
		.defaultSize(width: 1280, height: 800)
		.modelContainer(sharedModelContainer)
		.commands {
			CommandGroup(after: .appInfo) {
				Button("偏好设置…") {
					NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
				}
				.keyboardShortcut(",", modifiers: .command)
			}
		}

		Settings {
			PreferencesView()
				.environmentObject(appState)
		}
	}
}
