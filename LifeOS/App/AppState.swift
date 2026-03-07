//
//  AppState.swift
//  LifeOS
//
//  Created by Lihong Gao on 2026-02-26.
//
//  AppState.swift — LifeOS 全局状态中枢

import SwiftUI
import Combine

enum AppModule: String, CaseIterable, Identifiable {
	case dashboard  = "Dashboard"
	case inbox      = "Inbox"
	case execution  = "Execution"
	case lifestyle  = "Lifestyle"
	case knowledge  = "Knowledge"
	case vitals     = "Vitals"

	var id: String { rawValue }

	var icon: String {
		switch self {
		case .dashboard:  return "gauge.with.needle"
		case .inbox:      return "tray.and.arrow.down"
		case .execution:  return "target"
		case .lifestyle:  return "cup.and.saucer"
		case .knowledge:  return "book"
		case .vitals:     return "sparkles"
		}
	}

	var label: String {
		switch self {
		case .dashboard:  return "仪表盘 Dashboard"
		case .inbox:      return "收件箱 Inbox"
		case .execution:  return "执行 Execution"
		case .lifestyle:  return "生活 Lifestyle"
		case .knowledge:  return "知识 Knowledge"
		case .vitals:     return "觉知 Vitals"
		}
	}

	var preferenceLabel: String {
		switch self {
		case .dashboard:
			return String(localized: "preferences.module.dashboard")
		case .inbox:
			return String(localized: "preferences.module.inbox")
		case .execution:
			return String(localized: "preferences.module.execution")
		case .lifestyle:
			return String(localized: "preferences.module.lifestyle")
		case .knowledge:
			return String(localized: "preferences.module.knowledge")
		case .vitals:
			return String(localized: "preferences.module.vitals")
		}
	}
}

enum OnboardingStep {
	case selectAuth
	case createNickname
	case done
}

enum AppLanguagePreference: String, CaseIterable, Identifiable {
	case system
	case simplifiedChinese = "zh-Hans"
	case english = "en"

	var id: String { rawValue }

	var locale: Locale {
		switch self {
		case .system:
			return .autoupdatingCurrent
		case .simplifiedChinese:
			return Locale(identifier: "zh-Hans")
		case .english:
			return Locale(identifier: "en")
		}
	}
}

enum AppAppearanceMode: String, CaseIterable, Identifiable {
	case system
	case light
	case dark

	var id: String { rawValue }

	var colorScheme: ColorScheme? {
		switch self {
		case .system:
			return nil
		case .light:
			return .light
		case .dark:
			return .dark
		}
	}
}

enum AIProviderOption: String, CaseIterable, Identifiable {
	case deepseek
	case qwen

	var id: String { rawValue }
}

enum BackupFrequency: String, CaseIterable, Identifiable {
	case off
	case daily
	case weekly

	var id: String { rawValue }
}

enum LogLevel: String, CaseIterable, Identifiable {
	case error
	case warning
	case info
	case debug

	var id: String { rawValue }
}

enum ShortcutPreset: String, CaseIterable, Identifiable {
	case commandShiftN
	case commandN
	case commandK
	case commandShiftSpace
	case commandF

	var id: String { rawValue }

	var keyEquivalent: KeyEquivalent {
		switch self {
		case .commandShiftN:
			return "n"
		case .commandN:
			return "n"
		case .commandK:
			return "k"
		case .commandShiftSpace:
			return " "
		case .commandF:
			return "f"
		}
	}

	var modifiers: EventModifiers {
		switch self {
		case .commandShiftN:
			return [.command, .shift]
		case .commandN, .commandK, .commandF:
			return .command
		case .commandShiftSpace:
			return [.command, .shift]
		}
	}
}

@MainActor
class AppState: ObservableObject {
	private enum Keys {
		static let hasCompletedOnboarding = "hasCompletedOnboarding"
		static let userName = "userName"
		static let avatarImagePath = "avatarImagePath"
		static let apiTokenStorageMode = "apiTokenStorageMode"
		static let globalCurrency = "globalCurrency"
		static let monthlyBudget = "monthlyBudget"
		static let storageDirectory = "storageDirectory"
		static let appLanguage = "appLanguagePreference"
		static let appearanceMode = "appAppearanceMode"
		static let startupModule = "startupModule"
		static let aiProvider = "aiProvider"
		static let aiModelDeepSeek = "aiModelDeepSeek"
		static let aiModelQwen = "aiModelQwen"
		static let aiTimeoutSeconds = "aiTimeoutSeconds"
		static let backupFrequency = "backupFrequency"
		static let lastAutoBackupAt = "lastAutoBackupAt"
		static let quickCaptureShortcut = "quickCaptureShortcut"
		static let globalSearchShortcut = "globalSearchShortcut"
		static let logLevel = "logLevel"
		static let crashReportEnabled = "crashReportEnabled"
	}

	// MARK: - Onboarding
	@Published var hasCompletedOnboarding: Bool {
		didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding) }
	}

	// MARK: - User
	@Published var userName: String {
		didSet { UserDefaults.standard.set(userName, forKey: Keys.userName) }
	}
	@Published var avatarImagePath: String {
		didSet { UserDefaults.standard.set(avatarImagePath, forKey: Keys.avatarImagePath) }
	}
	@Published var apiTokenStorageMode: String {
		didSet { UserDefaults.standard.set(apiTokenStorageMode, forKey: Keys.apiTokenStorageMode) }
	}
	@Published var globalCurrency: String {
		didSet { UserDefaults.standard.set(globalCurrency, forKey: Keys.globalCurrency) }
	}
	@Published var monthlyBudget: Double {
		didSet { UserDefaults.standard.set(monthlyBudget, forKey: Keys.monthlyBudget) }
	}

	// MARK: - Preferences
	@Published var appLanguagePreference: String {
		didSet { UserDefaults.standard.set(appLanguagePreference, forKey: Keys.appLanguage) }
	}
	@Published var appAppearanceMode: String {
		didSet { UserDefaults.standard.set(appAppearanceMode, forKey: Keys.appearanceMode) }
	}
	@Published var startupModule: String {
		didSet { UserDefaults.standard.set(startupModule, forKey: Keys.startupModule) }
	}
	@Published var aiProvider: String {
		didSet { UserDefaults.standard.set(aiProvider, forKey: Keys.aiProvider) }
	}
	@Published var aiModelDeepSeek: String {
		didSet { UserDefaults.standard.set(aiModelDeepSeek, forKey: Keys.aiModelDeepSeek) }
	}
	@Published var aiModelQwen: String {
		didSet { UserDefaults.standard.set(aiModelQwen, forKey: Keys.aiModelQwen) }
	}
	@Published var aiTimeoutSeconds: Double {
		didSet { UserDefaults.standard.set(aiTimeoutSeconds, forKey: Keys.aiTimeoutSeconds) }
	}
	@Published var backupFrequency: String {
		didSet { UserDefaults.standard.set(backupFrequency, forKey: Keys.backupFrequency) }
	}
	@Published var quickCaptureShortcut: String {
		didSet { UserDefaults.standard.set(quickCaptureShortcut, forKey: Keys.quickCaptureShortcut) }
	}
	@Published var globalSearchShortcut: String {
		didSet { UserDefaults.standard.set(globalSearchShortcut, forKey: Keys.globalSearchShortcut) }
	}
	@Published var logLevel: String {
		didSet { UserDefaults.standard.set(logLevel, forKey: Keys.logLevel) }
	}
	@Published var crashReportEnabled: Bool {
		didSet { UserDefaults.standard.set(crashReportEnabled, forKey: Keys.crashReportEnabled) }
	}

	// MARK: - Auth
	@Published var authToken: String?

	// MARK: - Navigation
	@Published var selectedModule: AppModule
	@Published var columnVisibility: NavigationSplitViewVisibility

	// MARK: - Storage
	@Published var storageDirectory: URL? {
		didSet {
			if let url = storageDirectory {
				UserDefaults.standard.set(url.path, forKey: Keys.storageDirectory)
			}
		}
	}

	init() {
		AICredentialStore.bootstrapSecurityDefaults()

		self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Keys.hasCompletedOnboarding)
		self.userName = UserDefaults.standard.string(forKey: Keys.userName) ?? ""
		self.avatarImagePath = UserDefaults.standard.string(forKey: Keys.avatarImagePath) ?? ""
		self.apiTokenStorageMode = UserDefaults.standard.string(forKey: Keys.apiTokenStorageMode)
			?? APITokenStorageMode.keychain.rawValue
		self.globalCurrency = UserDefaults.standard.string(forKey: Keys.globalCurrency)
			?? CurrencyCode.CNY.rawValue
		let defaultBudget = UserDefaults.standard.double(forKey: Keys.monthlyBudget)
		self.monthlyBudget = defaultBudget > 0 ? defaultBudget : 0
		self.appLanguagePreference = UserDefaults.standard.string(forKey: Keys.appLanguage)
			?? AppLanguagePreference.system.rawValue
		self.appAppearanceMode = UserDefaults.standard.string(forKey: Keys.appearanceMode)
			?? AppAppearanceMode.system.rawValue
			let startupModuleRaw = UserDefaults.standard.string(forKey: Keys.startupModule)
				?? AppModule.dashboard.rawValue
			self.startupModule = startupModuleRaw
		self.aiProvider = UserDefaults.standard.string(forKey: Keys.aiProvider)
			?? AIProviderOption.deepseek.rawValue
		self.aiModelDeepSeek = UserDefaults.standard.string(forKey: Keys.aiModelDeepSeek)
			?? "deepseek-chat"
		self.aiModelQwen = UserDefaults.standard.string(forKey: Keys.aiModelQwen)
			?? "qwen-turbo"
		let timeout = UserDefaults.standard.double(forKey: Keys.aiTimeoutSeconds)
		self.aiTimeoutSeconds = timeout > 0 ? timeout : 30
		self.backupFrequency = UserDefaults.standard.string(forKey: Keys.backupFrequency)
			?? BackupFrequency.off.rawValue
		self.quickCaptureShortcut = UserDefaults.standard.string(forKey: Keys.quickCaptureShortcut)
			?? ShortcutPreset.commandShiftN.rawValue
		self.globalSearchShortcut = UserDefaults.standard.string(forKey: Keys.globalSearchShortcut)
			?? ShortcutPreset.commandK.rawValue
		self.logLevel = UserDefaults.standard.string(forKey: Keys.logLevel)
			?? LogLevel.info.rawValue
		if UserDefaults.standard.object(forKey: Keys.crashReportEnabled) == nil {
			self.crashReportEnabled = true
		} else {
			self.crashReportEnabled = UserDefaults.standard.bool(forKey: Keys.crashReportEnabled)
		}

			let bootModule = AppModule(rawValue: startupModuleRaw) ?? .dashboard
		self.selectedModule = bootModule
		self.columnVisibility = bootModule == .dashboard ? .detailOnly : .all
		self.storageDirectory = nil

		if let path = UserDefaults.standard.string(forKey: Keys.storageDirectory) {
			self.storageDirectory = URL(fileURLWithPath: path)
		}
	}

	func completeOnboarding(name: String) {
		self.userName = name
		self.hasCompletedOnboarding = true
	}

	func resetAccountForFreshStart() {
		hasCompletedOnboarding = false
		userName = ""
		avatarImagePath = ""
		authToken = nil

		apiTokenStorageMode = APITokenStorageMode.keychain.rawValue
		globalCurrency = CurrencyCode.CNY.rawValue
		monthlyBudget = 0

		appLanguagePreference = AppLanguagePreference.system.rawValue
		appAppearanceMode = AppAppearanceMode.system.rawValue
		startupModule = AppModule.dashboard.rawValue
		aiProvider = AIProviderOption.deepseek.rawValue
		aiModelDeepSeek = "deepseek-chat"
		aiModelQwen = "qwen-turbo"
		aiTimeoutSeconds = 30
		backupFrequency = BackupFrequency.off.rawValue
		quickCaptureShortcut = ShortcutPreset.commandShiftN.rawValue
		globalSearchShortcut = ShortcutPreset.commandK.rawValue
		logLevel = LogLevel.info.rawValue
		crashReportEnabled = true

		selectedModule = .dashboard
		columnVisibility = .detailOnly

		storageDirectory = nil
		UserDefaults.standard.removeObject(forKey: Keys.storageDirectory)
		UserDefaults.standard.removeObject(forKey: Keys.lastAutoBackupAt)
	}

	var selectedCurrencyCode: CurrencyCode {
		get { CurrencyCode(rawValue: globalCurrency) ?? .CNY }
		set { globalCurrency = newValue.rawValue }
	}

	var selectedLanguagePreference: AppLanguagePreference {
		get { AppLanguagePreference(rawValue: appLanguagePreference) ?? .system }
		set { appLanguagePreference = newValue.rawValue }
	}

	var currentLocale: Locale {
		selectedLanguagePreference.locale
	}

	var selectedAppearanceMode: AppAppearanceMode {
		get { AppAppearanceMode(rawValue: appAppearanceMode) ?? .system }
		set { appAppearanceMode = newValue.rawValue }
	}

	var selectedStartupModule: AppModule {
		get { AppModule(rawValue: startupModule) ?? .dashboard }
		set { startupModule = newValue.rawValue }
	}

	var selectedAIProvider: AIProviderOption {
		get { AIProviderOption(rawValue: aiProvider) ?? .deepseek }
		set { aiProvider = newValue.rawValue }
	}

	var selectedBackupFrequency: BackupFrequency {
		get { BackupFrequency(rawValue: backupFrequency) ?? .off }
		set { backupFrequency = newValue.rawValue }
	}

	var selectedQuickCaptureShortcut: ShortcutPreset {
		get { ShortcutPreset(rawValue: quickCaptureShortcut) ?? .commandShiftN }
		set { quickCaptureShortcut = newValue.rawValue }
	}

	var selectedGlobalSearchShortcut: ShortcutPreset {
		get { ShortcutPreset(rawValue: globalSearchShortcut) ?? .commandK }
		set { globalSearchShortcut = newValue.rawValue }
	}

	var selectedLogLevel: LogLevel {
		get { LogLevel(rawValue: logLevel) ?? .info }
		set { logLevel = newValue.rawValue }
	}

	var selectedAPITokenStorageMode: APITokenStorageMode {
		get { APITokenStorageMode(rawValue: apiTokenStorageMode) ?? .keychain }
		set { apiTokenStorageMode = newValue.rawValue }
	}

	func updateModule(_ module: AppModule) {
		// ✅ 用 Task 替代 DispatchQueue.main.async，避免在视图更新中发布变更
		Task { @MainActor in
			self.selectedModule = module
			withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
				self.columnVisibility = module == .dashboard ? .detailOnly : .all
			}
		}
	}

	func runAutoBackupIfNeeded() {
		let frequency = selectedBackupFrequency
		guard frequency != .off else { return }

		let now = Date()
		let last = UserDefaults.standard.object(forKey: Keys.lastAutoBackupAt) as? Date
		guard shouldRunAutoBackup(last: last, now: now, frequency: frequency) else { return }

		let source = resolvedDataDirectory()
		let backupRoot = source.deletingLastPathComponent().appendingPathComponent("LifeOSBackups", isDirectory: true)
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyyMMdd-HHmmss"
		let destination = backupRoot.appendingPathComponent("LifeOS-auto-\(formatter.string(from: now))", isDirectory: true)

		do {
			try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
			try FileManager.default.createDirectory(at: backupRoot, withIntermediateDirectories: true)
			try FileManager.default.copyItem(at: source, to: destination)
			UserDefaults.standard.set(now, forKey: Keys.lastAutoBackupAt)
		} catch {
			AppLogger.warning("Auto backup failed: \(error.localizedDescription)", category: "data")
		}
	}

	private func resolvedDataDirectory() -> URL {
		if let storageDirectory {
			return storageDirectory
		}
		let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
			?? URL(fileURLWithPath: NSTemporaryDirectory())
		return documents.appendingPathComponent("LifeOS", isDirectory: true)
	}

	private func shouldRunAutoBackup(last: Date?, now: Date, frequency: BackupFrequency) -> Bool {
		guard let last else { return true }
		switch frequency {
		case .off:
			return false
		case .daily:
			return !Calendar.current.isDate(last, inSameDayAs: now)
		case .weekly:
			let days = Calendar.current.dateComponents([.day], from: last, to: now).day ?? 0
			return days >= 7
		}
	}
}
