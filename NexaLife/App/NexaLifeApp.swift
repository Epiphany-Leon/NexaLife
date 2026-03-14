//
//  NexaLifeApp.swift
//  NexaLife
//
//  Created by Lihong Gao on 2026-02-24.
//

import SwiftUI
import SwiftData

@main
struct NexaLifeApp: App {
	@StateObject private var appState     = AppState()
	@StateObject private var oauthService = OAuthService()

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
			.environment(\.locale, appState.currentLocale)
			.preferredColorScheme(appState.selectedAppearanceMode.colorScheme)
		}
		// ✅ 任务6：默认窗口尺寸加大
			.defaultSize(width: 1280, height: 800)
			.modelContainer(sharedModelContainer)
			.commands {
				AboutCommands(locale: appState.currentLocale)

				CommandMenu("settings.commands.quick_actions") {
					Button("settings.commands.quick_capture") {
						NotificationCenter.default.post(name: .nexaLifeShowQuickInput, object: nil)
					}
				.keyboardShortcut(
					appState.selectedQuickCaptureShortcut.keyEquivalent,
					modifiers: appState.selectedQuickCaptureShortcut.modifiers
				)

				Button("settings.commands.global_search") {
					NotificationCenter.default.post(name: .nexaLifeShowGlobalSearch, object: nil)
				}
				.keyboardShortcut(
					appState.selectedGlobalSearchShortcut.keyEquivalent,
					modifiers: appState.selectedGlobalSearchShortcut.modifiers
				)
			}
		}

		Settings {
			PreferencesView()
				.environmentObject(appState)
				.environmentObject(oauthService)
				.environment(\.locale, appState.currentLocale)
				.preferredColorScheme(appState.selectedAppearanceMode.colorScheme)
				.modelContainer(sharedModelContainer)
		}

		Window(AppBrand.aboutTitle(for: appState.currentLocale), id: "about-nexalife") {
			AboutNexaLifeView()
				.padding(24)
				.frame(width: 520)
				.environment(\.locale, appState.currentLocale)
				.preferredColorScheme(appState.selectedAppearanceMode.colorScheme)
		}
		.windowResizability(.contentSize)
	}
}

private struct AboutCommands: Commands {
	@Environment(\.openWindow) private var openWindow
	let locale: Locale

	var body: some Commands {
		CommandGroup(replacing: .appInfo) {
			Button(AppBrand.aboutTitle(for: locale)) {
				openWindow(id: "about-nexalife")
			}
		}
	}
}
