//
//  PreferencesView.swift
//  LifeOS
//
//  Created by Lihong Gao on 2026-02-26.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct PreferencesView: View {
	@EnvironmentObject private var appState: AppState

	@State private var apiKeyInput: String = ""
	@State private var savedApiKey: String = ""
	@State private var showTokenValue = false
	@State private var copiedToken = false
	@State private var savedToken = false
	@State private var aiTestInProgress = false
	@State private var aiTestMessage: String = ""
	@State private var aiTestSucceeded = false
	@State private var dataStatusMessage: String = ""
	@State private var dataStatusSuccess = true
	@State private var rebirthStatusMessage: String = ""
	@State private var rebirthStatusSuccess = true
	@State private var showClearContentConfirmation = false
	@State private var showDeleteAccountConfirmation = false
	@State private var privacyStatusMessage: String = ""
	@State private var privacyStatusSuccess = true

	private let deepSeekModels = ["deepseek-chat", "deepseek-reasoner"]
	private let qwenModels = ["qwen-turbo", "qwen-plus", "qwen-max"]

	private var tokenDisplayText: String {
		guard !savedApiKey.isEmpty else { return String(localized: "preferences.token.not_saved") }
		if showTokenValue { return savedApiKey }
		return String(repeating: "*", count: max(8, min(savedApiKey.count, 24)))
	}

	var body: some View {
		TabView {
			generalTab
				.tabItem { Label("preferences.tab.general", systemImage: "gearshape") }

			aiTab
				.tabItem { Label("preferences.tab.ai", systemImage: "sparkles") }

			dataTab
				.tabItem { Label("preferences.tab.data", systemImage: "externaldrive") }

			shortcutsTab
				.tabItem { Label("preferences.tab.shortcuts", systemImage: "keyboard") }

			privacyTab
				.tabItem { Label("preferences.tab.privacy", systemImage: "lock.shield") }
		}
		.frame(width: 860, height: 620)
		.onAppear {
			appState.apiTokenStorageMode = AICredentialStore.mode.rawValue
			let key = AICredentialStore.readAPIKey()
			savedApiKey = key
			apiKeyInput = key
		}
	}

	private var generalTab: some View {
		preferencePane {
			PreferenceSectionCard(title: "preferences.section.profile") {
				PreferenceRow(title: "preferences.profile.nickname") {
					TextField(String(localized: "preferences.profile.nickname.placeholder"), text: $appState.userName)
						.textFieldStyle(.roundedBorder)
						.frame(width: 280)
				}
			}

			PreferenceSectionCard(title: "preferences.section.localization") {
				PreferenceRow(title: "preferences.localization.language") {
					Picker("", selection: $appState.appLanguagePreference) {
						ForEach(AppLanguagePreference.allCases) { item in
							Text(item.preferenceLabel).tag(item.rawValue)
						}
					}
					.labelsHidden()
					.frame(width: 280)
				}

				PreferenceRow(title: "preferences.localization.appearance") {
					Picker("", selection: $appState.appAppearanceMode) {
						ForEach(AppAppearanceMode.allCases) { item in
							Text(item.preferenceLabel).tag(item.rawValue)
						}
					}
					.labelsHidden()
					.frame(width: 280)
				}
			}

			PreferenceSectionCard(title: "preferences.section.startup") {
				PreferenceRow(title: "preferences.startup.module") {
					Picker("", selection: $appState.startupModule) {
						ForEach(AppModule.allCases) { module in
							Text(module.preferenceLabel).tag(module.rawValue)
						}
					}
					.labelsHidden()
					.frame(width: 280)
				}
			}
		}
	}

	private var aiTab: some View {
		preferencePane {
			PreferenceSectionCard(title: "preferences.ai.section.provider") {
				PreferenceRow(title: "preferences.ai.provider") {
					Picker("", selection: $appState.aiProvider) {
						ForEach(AIProviderOption.allCases) { option in
							Text(option.preferenceLabel).tag(option.rawValue)
						}
					}
					.labelsHidden()
					.frame(width: 280)
				}

				PreferenceRow(title: "preferences.ai.model") {
					Picker("", selection: aiModelBinding) {
						ForEach(activeModelOptions, id: \.self) { model in
							Text(model).tag(model)
						}
					}
					.labelsHidden()
					.frame(width: 280)
				}

				PreferenceRow(title: "preferences.ai.timeout") {
					HStack(spacing: 10) {
						Slider(value: $appState.aiTimeoutSeconds, in: 5...120, step: 1)
							.frame(width: 220)
						Text("\(Int(appState.aiTimeoutSeconds))s")
							.monospacedDigit()
							.frame(width: 44, alignment: .trailing)
					}
				}

				PreferenceActionRow {
					HStack(spacing: 10) {
						Button("preferences.ai.test") {
							Task {
								await runAITest()
							}
						}
						.buttonStyle(.bordered)
						.disabled(aiTestInProgress)

						if aiTestInProgress {
							ProgressView()
								.controlSize(.small)
						}

						if !aiTestMessage.isEmpty {
							Text(aiTestMessage)
								.font(.subheadline)
								.foregroundStyle(aiTestSucceeded ? .green : .secondary)
						}
					}
				}
			}

			PreferenceSectionCard(title: "preferences.token.section") {
					PreferenceRow(title: "preferences.token.storage_mode") {
						Picker("", selection: $appState.apiTokenStorageMode) {
							ForEach(APITokenStorageMode.allCases) { mode in
								Text(mode.preferenceLabel).tag(mode.rawValue)
							}
						}
						.labelsHidden()
						.frame(width: 280)
						.onChange(of: appState.apiTokenStorageMode) { _, newValue in
							let newMode = APITokenStorageMode(rawValue: newValue) ?? .keychain
							AICredentialStore.updateStorageMode(newMode)
							let key = AICredentialStore.readAPIKey()
							savedApiKey = key
							apiKeyInput = key
						}
					}

				if appState.selectedAPITokenStorageMode == .localFile {
					PreferenceRow(title: "preferences.token.local_file") {
						HStack(spacing: 8) {
							Text(AICredentialStore.localFileURL().path)
								.foregroundStyle(.secondary)
								.truncationMode(.middle)
								.frame(width: 260, alignment: .trailing)
							Button("preferences.token.pick_file") {
								selectTokenFile()
							}
							.buttonStyle(.bordered)
							.controlSize(.small)
						}
					}
				}

				PreferenceRow(title: "preferences.token.saved") {
					HStack(spacing: 8) {
						if showTokenValue && !savedApiKey.isEmpty {
							Button(savedApiKey) {
								copyTokenToPasteboard()
							}
							.buttonStyle(.plain)
							.help(String(localized: "preferences.token.copy_hint"))
							.textSelection(.enabled)
							.lineLimit(1)
							.truncationMode(.middle)
						} else {
							Text(tokenDisplayText)
								.foregroundStyle(savedApiKey.isEmpty ? .secondary : .primary)
						}
						Button {
							showTokenValue.toggle()
						} label: {
							Image(systemName: showTokenValue ? "eye.slash" : "eye")
						}
						.buttonStyle(.plain)
						if copiedToken {
							Text("preferences.token.copied")
								.font(.caption)
								.foregroundStyle(.green)
						}
					}
				}

				PreferenceRow(title: "preferences.token.update") {
					SecureField("sk-...", text: $apiKeyInput)
						.textFieldStyle(.roundedBorder)
						.frame(width: 280)
				}

				PreferenceRow(title: "preferences.token.storage_location") {
					Text(AICredentialStore.storageLocationDescription())
						.foregroundStyle(.secondary)
						.truncationMode(.middle)
						.frame(width: 360, alignment: .leading)
				}

				PreferenceActionRow {
					HStack(spacing: 10) {
						Button("preferences.token.save") {
							saveAPIKey()
						}
						.buttonStyle(.borderedProminent)
						.disabled(apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

						if savedToken {
							Label("preferences.common.saved", systemImage: "checkmark.circle.fill")
								.font(.subheadline)
								.foregroundStyle(.green)
						}
					}
				}
			}
		}
	}

	private var dataTab: some View {
		preferencePane {
			PreferenceSectionCard(title: "preferences.data.section.storage") {
				PreferenceRow(title: "preferences.data.directory") {
					Text(resolvedDataDirectory().path)
						.foregroundStyle(.secondary)
						.truncationMode(.middle)
						.frame(width: 360, alignment: .leading)
				}

				PreferenceActionRow {
					Button("preferences.data.change_directory") {
						selectDataFolder()
					}
					.buttonStyle(.bordered)
				}
			}

			PreferenceSectionCard(title: "preferences.data.section.backup") {
				PreferenceRow(title: "preferences.data.backup_frequency") {
					Picker("", selection: $appState.backupFrequency) {
						ForEach(BackupFrequency.allCases) { item in
							Text(item.preferenceLabel).tag(item.rawValue)
						}
					}
					.labelsHidden()
					.frame(width: 280)
				}

				PreferenceActionRow {
					HStack(spacing: 10) {
						Button("preferences.data.export") {
							exportDataFolder()
						}
						.buttonStyle(.bordered)

						Button("preferences.data.import") {
							importDataFolder()
						}
						.buttonStyle(.bordered)
					}
				}
			}

			PreferenceSectionCard(title: "preferences.data.section.integrity") {
				PreferenceActionRow {
					HStack(spacing: 10) {
						Button("preferences.data.validate") {
							validateDataDirectory()
						}
						.buttonStyle(.bordered)

						Button("preferences.data.repair") {
							repairDataDirectory()
						}
						.buttonStyle(.bordered)
					}
				}

				if !dataStatusMessage.isEmpty {
					PreferenceActionRow {
						Text(dataStatusMessage)
							.font(.subheadline)
							.foregroundStyle(dataStatusSuccess ? .green : .orange)
							.fixedSize(horizontal: false, vertical: true)
					}
				}
			}

			PreferenceSectionCard(title: "preferences.data.section.fresh_start") {
				PreferenceActionRow {
					Text("preferences.data.fresh_start.tagline")
						.font(.subheadline)
						.foregroundStyle(.secondary)
						.fixedSize(horizontal: false, vertical: true)
				}

				PreferenceActionRow {
					HStack(spacing: 10) {
						Button("preferences.data.fresh_start.clear_content", role: .destructive) {
							showClearContentConfirmation = true
						}
						.buttonStyle(.bordered)

						Button("preferences.data.fresh_start.delete_account", role: .destructive) {
							showDeleteAccountConfirmation = true
						}
						.buttonStyle(.borderedProminent)
						.tint(.red)
					}
				}

				if !rebirthStatusMessage.isEmpty {
					PreferenceActionRow {
						Text(rebirthStatusMessage)
							.font(.subheadline)
							.foregroundStyle(rebirthStatusSuccess ? .green : .orange)
							.fixedSize(horizontal: false, vertical: true)
					}
				}
			}
		}
		.confirmationDialog(
			String(localized: "preferences.data.fresh_start.clear_content.confirm.title"),
			isPresented: $showClearContentConfirmation,
			titleVisibility: .visible
		) {
			Button("preferences.data.fresh_start.clear_content", role: .destructive) {
				clearContentForFreshStart()
			}
			Button(role: .cancel) {}
		} message: {
			Text("preferences.data.fresh_start.clear_content.confirm.message")
		}
		.confirmationDialog(
			String(localized: "preferences.data.fresh_start.delete_account.confirm.title"),
			isPresented: $showDeleteAccountConfirmation,
			titleVisibility: .visible
		) {
			Button("preferences.data.fresh_start.delete_account", role: .destructive) {
				deleteAccountForFreshStart()
			}
			Button(role: .cancel) {}
		} message: {
			Text("preferences.data.fresh_start.delete_account.confirm.message")
		}
	}

	private var shortcutsTab: some View {
		preferencePane {
			PreferenceSectionCard(title: "preferences.shortcuts.section") {
				PreferenceRow(title: "preferences.shortcuts.quick_capture") {
					Picker("", selection: $appState.quickCaptureShortcut) {
						ForEach(ShortcutPreset.allCases) { preset in
							Text(preset.preferenceLabel).tag(preset.rawValue)
						}
					}
					.labelsHidden()
					.frame(width: 280)
				}

				PreferenceRow(title: "preferences.shortcuts.global_search") {
					Picker("", selection: $appState.globalSearchShortcut) {
						ForEach(ShortcutPreset.allCases) { preset in
							Text(preset.preferenceLabel).tag(preset.rawValue)
						}
					}
					.labelsHidden()
					.frame(width: 280)
				}

				PreferenceActionRow {
					Text("preferences.shortcuts.hint")
						.font(.caption)
						.foregroundStyle(.secondary)
				}
			}
		}
	}

	private var privacyTab: some View {
		preferencePane {
			PreferenceSectionCard(title: "preferences.privacy.section") {
				PreferenceRow(title: "preferences.privacy.log_level") {
					Picker("", selection: $appState.logLevel) {
						ForEach(LogLevel.allCases) { item in
							Text(item.preferenceLabel).tag(item.rawValue)
						}
					}
					.labelsHidden()
					.frame(width: 280)
				}

				PreferenceActionRow {
					Toggle("preferences.privacy.crash_reports", isOn: $appState.crashReportEnabled)
				}

				PreferenceActionRow {
					Button("preferences.privacy.clear_cache") {
						clearCaches()
					}
					.buttonStyle(.bordered)
				}

				if !privacyStatusMessage.isEmpty {
					PreferenceActionRow {
						Text(privacyStatusMessage)
							.font(.subheadline)
							.foregroundStyle(privacyStatusSuccess ? .green : .orange)
					}
				}
			}
		}
	}

	private func preferencePane<Content: View>(@ViewBuilder content: () -> Content) -> some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 16) {
				content()
			}
			.padding(.horizontal, 24)
			.padding(.vertical, 20)
			.frame(maxWidth: 760, alignment: .leading)
			.frame(maxWidth: .infinity, alignment: .leading)
		}
		.background(Color(nsColor: .windowBackgroundColor))
	}

	private var aiModelBinding: Binding<String> {
		Binding(
			get: {
				appState.selectedAIProvider == .qwen ? appState.aiModelQwen : appState.aiModelDeepSeek
			},
			set: { newValue in
				if appState.selectedAIProvider == .qwen {
					appState.aiModelQwen = newValue
				} else {
					appState.aiModelDeepSeek = newValue
				}
			}
		)
	}

	private var activeModelOptions: [String] {
		appState.selectedAIProvider == .qwen ? qwenModels : deepSeekModels
	}

	private func saveAPIKey() {
		let trimmed = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !trimmed.isEmpty else { return }
		AICredentialStore.saveAPIKey(trimmed)
		savedApiKey = AICredentialStore.readAPIKey()
		withAnimation { savedToken = true }
		DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
			withAnimation { savedToken = false }
		}
	}

	@MainActor
	private func runAITest() async {
		aiTestInProgress = true
		aiTestMessage = ""
		let service = AIService()
		let response = await service.callAPI(
			prompt: "请回复：连接成功",
			maxTokens: 20
		)
		aiTestInProgress = false
		if let response, !response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
			aiTestMessage = String(localized: "preferences.ai.test.success")
			aiTestSucceeded = true
		} else {
			aiTestMessage = String(localized: "preferences.ai.test.failure")
			aiTestSucceeded = false
		}
	}

	private func selectTokenFile() {
		let panel = NSSavePanel()
		panel.nameFieldStringValue = "ai_api_token.txt"
		panel.allowedContentTypes = [.plainText]
		panel.canCreateDirectories = true
		guard panel.runModal() == .OK, let url = panel.url else { return }
		AICredentialStore.setLocalFileURL(url)
		if !apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
			AICredentialStore.saveAPIKey(apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines))
			savedApiKey = AICredentialStore.readAPIKey()
		}
	}

	private func copyTokenToPasteboard() {
		guard !savedApiKey.isEmpty else { return }
		let board = NSPasteboard.general
		board.clearContents()
		board.setString(savedApiKey, forType: .string)
		withAnimation { copiedToken = true }
		DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
			withAnimation { copiedToken = false }
		}
	}

	private func selectDataFolder() {
		let panel = NSOpenPanel()
		panel.canChooseDirectories = true
		panel.canChooseFiles = false
		panel.allowsMultipleSelection = false
		if panel.runModal() == .OK {
			appState.storageDirectory = panel.url
		}
	}

	private func resolvedDataDirectory() -> URL {
		if let userPicked = appState.storageDirectory {
			return userPicked
		}
		let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
			?? URL(fileURLWithPath: NSTemporaryDirectory())
		return documents.appendingPathComponent("LifeOS", isDirectory: true)
	}

	private func exportDataFolder() {
		let source = resolvedDataDirectory()
		let panel = NSOpenPanel()
		panel.canChooseDirectories = true
		panel.canChooseFiles = false
		panel.allowsMultipleSelection = false
		guard panel.runModal() == .OK, let destinationRoot = panel.url else { return }

		let formatter = DateFormatter()
		formatter.dateFormat = "yyyyMMdd-HHmmss"
		let stamp = formatter.string(from: .now)
		let destination = destinationRoot.appendingPathComponent("LifeOS-backup-\(stamp)", isDirectory: true)

		do {
			try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
			try FileManager.default.copyItem(at: source, to: destination)
			dataStatusMessage = String(localized: "preferences.data.export.success") + destination.path
			dataStatusSuccess = true
		} catch {
			dataStatusMessage = String(localized: "preferences.data.export.failure") + error.localizedDescription
			dataStatusSuccess = false
		}
	}

	private enum DataImportError: LocalizedError {
		case emptySource

		var errorDescription: String? {
			switch self {
			case .emptySource:
				return String(localized: "preferences.data.import.error.empty_source")
			}
		}
	}

	private func importDataFolder() {
		let panel = NSOpenPanel()
		panel.canChooseDirectories = true
		panel.canChooseFiles = false
		panel.allowsMultipleSelection = false
		guard panel.runModal() == .OK, let source = panel.url else { return }

		let target = resolvedDataDirectory()
		let fm = FileManager.default

		do {
			let sourceItems = try fm.contentsOfDirectory(
				at: source,
				includingPropertiesForKeys: nil,
				options: [.skipsHiddenFiles]
			)
			guard !sourceItems.isEmpty else { throw DataImportError.emptySource }

			let snapshot = try createImportSnapshot(for: target)
			do {
				try replaceDirectoryContents(at: target, with: sourceItems)
				try? fm.removeItem(at: snapshot)
			} catch {
				let rollbackSucceeded = restoreImportSnapshot(snapshot, to: target)
				if rollbackSucceeded {
					try? fm.removeItem(at: snapshot)
					dataStatusMessage = String(localized: "preferences.data.import.failure.rolled_back") + error.localizedDescription
				} else {
					dataStatusMessage = String(localized: "preferences.data.import.failure.rollback") + error.localizedDescription
				}
				dataStatusSuccess = false
				return
			}

			dataStatusMessage = String(localized: "preferences.data.import.success")
			dataStatusSuccess = true
		} catch {
			dataStatusMessage = String(localized: "preferences.data.import.failure") + error.localizedDescription
			dataStatusSuccess = false
		}
	}

	private func createImportSnapshot(for target: URL) throws -> URL {
		let fm = FileManager.default
		try fm.createDirectory(at: target, withIntermediateDirectories: true)

		let snapshotRoot = target
			.deletingLastPathComponent()
			.appendingPathComponent("LifeOSImportSnapshots", isDirectory: true)
		try fm.createDirectory(at: snapshotRoot, withIntermediateDirectories: true)

		let formatter = DateFormatter()
		formatter.dateFormat = "yyyyMMdd-HHmmss"
		let snapshot = snapshotRoot
			.appendingPathComponent("LifeOS-import-snapshot-\(formatter.string(from: .now))", isDirectory: true)
		try fm.copyItem(at: target, to: snapshot)
		return snapshot
	}

	private func replaceDirectoryContents(at target: URL, with items: [URL]) throws {
		let fm = FileManager.default
		try fm.createDirectory(at: target, withIntermediateDirectories: true)

		let existingItems = try fm.contentsOfDirectory(
			at: target,
			includingPropertiesForKeys: nil,
			options: [.skipsHiddenFiles]
		)
		for existing in existingItems {
			try fm.removeItem(at: existing)
		}

		for item in items {
			let destination = target.appendingPathComponent(item.lastPathComponent)
			try fm.copyItem(at: item, to: destination)
		}
	}

	private func restoreImportSnapshot(_ snapshot: URL, to target: URL) -> Bool {
		let fm = FileManager.default
		do {
			if fm.fileExists(atPath: target.path) {
				try fm.removeItem(at: target)
			}
			try fm.copyItem(at: snapshot, to: target)
			return true
		} catch {
			AppLogger.error("Data import rollback failed: \(error.localizedDescription)", category: "data")
			return false
		}
	}

	private func validateDataDirectory() {
		let directory = resolvedDataDirectory()
		let fm = FileManager.default
		var warnings: [String] = []

		var isDirectory: ObjCBool = false
		if !fm.fileExists(atPath: directory.path, isDirectory: &isDirectory) || !isDirectory.boolValue {
			warnings.append(String(localized: "preferences.data.validation.missing_directory"))
		}
		if !fm.isReadableFile(atPath: directory.path) {
			warnings.append(String(localized: "preferences.data.validation.not_readable"))
		}
		if !fm.isWritableFile(atPath: directory.path) {
			warnings.append(String(localized: "preferences.data.validation.not_writable"))
		}
		if !appState.avatarImagePath.isEmpty && !fm.fileExists(atPath: appState.avatarImagePath) {
			warnings.append(String(localized: "preferences.data.validation.avatar_missing"))
		}

		if warnings.isEmpty {
			dataStatusMessage = String(localized: "preferences.data.validation.ok")
			dataStatusSuccess = true
		} else {
			dataStatusMessage = warnings.joined(separator: "\n")
			dataStatusSuccess = false
		}
	}

	private func repairDataDirectory() {
		let directory = resolvedDataDirectory()
		let fm = FileManager.default
		var actions: [String] = []

		do {
			try fm.createDirectory(at: directory, withIntermediateDirectories: true)
			actions.append(String(localized: "preferences.data.repair.directory_created"))
		} catch {
			dataStatusMessage = String(localized: "preferences.data.repair.failure") + error.localizedDescription
			dataStatusSuccess = false
			return
		}

		if !appState.avatarImagePath.isEmpty && !fm.fileExists(atPath: appState.avatarImagePath) {
			appState.avatarImagePath = ""
			actions.append(String(localized: "preferences.data.repair.avatar_reset"))
		}

		if appState.aiTimeoutSeconds < 5 || appState.aiTimeoutSeconds > 120 {
			appState.aiTimeoutSeconds = 30
			actions.append(String(localized: "preferences.data.repair.timeout_reset"))
		}

		if actions.isEmpty {
			dataStatusMessage = String(localized: "preferences.data.repair.noop")
		} else {
			dataStatusMessage = actions.joined(separator: "\n")
		}
		dataStatusSuccess = true
	}

	private func clearCaches() {
		URLCache.shared.removeAllCachedResponses()
		let fm = FileManager.default
		let temp = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
		do {
			let tempItems = try fm.contentsOfDirectory(at: temp, includingPropertiesForKeys: nil)
			for item in tempItems where item.lastPathComponent.hasPrefix("LifeOS") {
				try? fm.removeItem(at: item)
			}
			privacyStatusMessage = String(localized: "preferences.privacy.clear_cache.success")
			privacyStatusSuccess = true
		} catch {
			privacyStatusMessage = String(localized: "preferences.privacy.clear_cache.failure") + error.localizedDescription
			privacyStatusSuccess = false
		}
	}

	private func clearContentForFreshStart() {
		rebirthStatusMessage = ""
		let issues = cleanupLocalContentForFreshStart()
		if issues.isEmpty {
			rebirthStatusMessage = String(localized: "preferences.data.fresh_start.clear_success")
				+ "\n"
				+ String(localized: "preferences.data.fresh_start.restart_hint")
			rebirthStatusSuccess = true
		} else {
			rebirthStatusMessage = String(localized: "preferences.data.fresh_start.partial_failure")
				+ issues.joined(separator: "\n")
			rebirthStatusSuccess = false
		}
	}

	private func deleteAccountForFreshStart() {
		rebirthStatusMessage = ""
		var issues = cleanupLocalContentForFreshStart()
		AICredentialStore.clearAPIKey()
		appState.resetAccountForFreshStart()

		savedApiKey = ""
		apiKeyInput = ""
		showTokenValue = false
		copiedToken = false

		if issues.isEmpty {
			rebirthStatusMessage = String(localized: "preferences.data.fresh_start.delete_success")
				+ "\n"
				+ String(localized: "preferences.data.fresh_start.restart_hint")
			rebirthStatusSuccess = true
		} else {
			issues.insert(String(localized: "preferences.data.fresh_start.delete_success"), at: 0)
			rebirthStatusMessage = String(localized: "preferences.data.fresh_start.partial_failure")
				+ issues.joined(separator: "\n")
			rebirthStatusSuccess = false
		}
	}

	private func cleanupLocalContentForFreshStart() -> [String] {
		var issues: [String] = []
		let dataDirectory = resolvedDataDirectory()
		let parentDirectory = dataDirectory.deletingLastPathComponent()
		let backupRoot = parentDirectory.appendingPathComponent("LifeOSBackups", isDirectory: true)
		let snapshotRoot = parentDirectory.appendingPathComponent("LifeOSImportSnapshots", isDirectory: true)

		do {
			try clearDirectoryContentsIfExists(at: dataDirectory)
		} catch {
			issues.append(error.localizedDescription)
		}

		do {
			try clearDirectoryContentsIfExists(at: backupRoot)
		} catch {
			issues.append(error.localizedDescription)
		}

		do {
			try clearDirectoryContentsIfExists(at: snapshotRoot)
		} catch {
			issues.append(error.localizedDescription)
		}

		do {
			try removeSwiftDataStoreFiles()
		} catch {
			issues.append(error.localizedDescription)
		}

		if !appState.avatarImagePath.isEmpty {
			appState.avatarImagePath = ""
		}

		return issues
	}

	private func clearDirectoryContentsIfExists(at directory: URL) throws {
		let fm = FileManager.default
		var isDirectory: ObjCBool = false
		guard fm.fileExists(atPath: directory.path, isDirectory: &isDirectory), isDirectory.boolValue else { return }
		let items = try fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
		for item in items {
			try fm.removeItem(at: item)
		}
	}

	private func removeSwiftDataStoreFiles() throws {
		let fm = FileManager.default
		let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
			?? URL(fileURLWithPath: NSTemporaryDirectory())
		let bundleDirectory = appSupport.appendingPathComponent(Bundle.main.bundleIdentifier ?? "LifeOS", isDirectory: true)

		for directory in [appSupport, bundleDirectory] {
			var isDirectory: ObjCBool = false
			guard fm.fileExists(atPath: directory.path, isDirectory: &isDirectory), isDirectory.boolValue else { continue }
			let items = try fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
			for item in items where item.lastPathComponent.hasPrefix("default.store") {
				try fm.removeItem(at: item)
			}
		}
	}
}

private struct PreferenceSectionCard<Content: View>: View {
	let title: LocalizedStringKey
	@ViewBuilder var content: () -> Content

	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			Text(title)
				.font(.headline)

			VStack(alignment: .leading, spacing: 10) {
				content()
			}
		}
		.padding(16)
		.frame(maxWidth: .infinity, alignment: .leading)
		.background(Color(nsColor: .controlBackgroundColor))
		.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
	}
}

private struct PreferenceRow<Control: View>: View {
	let title: LocalizedStringKey
	@ViewBuilder var control: () -> Control

	var body: some View {
		HStack(alignment: .center, spacing: 16) {
			Text(title)
				.foregroundStyle(.secondary)
				.frame(width: 200, alignment: .trailing)
			control()
				.frame(maxWidth: .infinity, alignment: .leading)
		}
	}
}

private struct PreferenceActionRow<Content: View>: View {
	@ViewBuilder var content: () -> Content

	var body: some View {
		HStack(alignment: .center, spacing: 16) {
			Color.clear
				.frame(width: 200, height: 1)
			content()
				.frame(maxWidth: .infinity, alignment: .leading)
		}
	}
}

private extension AppLanguagePreference {
	var preferenceLabel: String {
		switch self {
		case .system:
			return String(localized: "preferences.language.system")
		case .simplifiedChinese:
			return String(localized: "preferences.language.zh")
		case .english:
			return String(localized: "preferences.language.en")
		}
	}
}

private extension AppAppearanceMode {
	var preferenceLabel: String {
		switch self {
		case .system:
			return String(localized: "preferences.appearance.system")
		case .light:
			return String(localized: "preferences.appearance.light")
		case .dark:
			return String(localized: "preferences.appearance.dark")
		}
	}
}

private extension AIProviderOption {
	var preferenceLabel: String {
		switch self {
		case .deepseek:
			return String(localized: "preferences.ai.provider.deepseek")
		case .qwen:
			return String(localized: "preferences.ai.provider.qwen")
		}
	}
}

private extension APITokenStorageMode {
	var preferenceLabel: String {
		switch self {
		case .keychain:
			return String(localized: "preferences.token.mode.keychain")
		case .localFile:
			return String(localized: "preferences.token.mode.local")
		}
	}
}

private extension BackupFrequency {
	var preferenceLabel: String {
		switch self {
		case .off:
			return String(localized: "preferences.backup.off")
		case .daily:
			return String(localized: "preferences.backup.daily")
		case .weekly:
			return String(localized: "preferences.backup.weekly")
		}
	}
}

private extension LogLevel {
	var preferenceLabel: String {
		switch self {
		case .error:
			return String(localized: "preferences.log.error")
		case .warning:
			return String(localized: "preferences.log.warning")
		case .info:
			return String(localized: "preferences.log.info")
		case .debug:
			return String(localized: "preferences.log.debug")
		}
	}
}

private extension ShortcutPreset {
	var preferenceLabel: String {
		switch self {
		case .commandShiftN:
			return String(localized: "preferences.shortcut.command_shift_n")
		case .commandN:
			return String(localized: "preferences.shortcut.command_n")
		case .commandK:
			return String(localized: "preferences.shortcut.command_k")
		case .commandShiftSpace:
			return String(localized: "preferences.shortcut.command_shift_space")
		case .commandF:
			return String(localized: "preferences.shortcut.command_f")
		}
	}
}
