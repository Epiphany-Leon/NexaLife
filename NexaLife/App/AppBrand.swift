//
//  AppBrand.swift
//  NexaLife
//
//  Created by Codex on 2026-03-13.
//

import Foundation

enum AppBrand {
	static let englishName = "NexaLife"
	static let chineseName = "构筑人生"
	static let legacyEnglishName = "Life" + "OS"

	static let bundleIdentifier = "com.lihonggao.NexaLife"
	static let legacyBundleIdentifier = "com.lihonggao." + legacyEnglishName

	static let keychainService = englishName
	static let legacyKeychainService = legacyEnglishName

	static let syncArchiveFileName = "\(englishName)-sync.json"
	static let legacySyncArchiveFileName = "\(legacyEnglishName)-sync.json"

	static let autoBackupPrefix = "\(englishName)-auto-"
	static let legacyAutoBackupPrefix = "\(legacyEnglishName)-auto-"

	static let workspaceFolderName = englishName
	static let legacyWorkspaceFolderName = legacyEnglishName

	static let avatarFolderPath = "\(englishName)/Avatars"
	static let legacyAvatarFolderPath = "\(legacyEnglishName)/Avatars"

	static let emailVerificationEndpointEnv = "NEXALIFE_EMAIL_VERIFICATION_ENDPOINT"
	static let legacyEmailVerificationEndpointEnv = "LIFE" + "OS_EMAIL_VERIFICATION_ENDPOINT"
	static let emailVerificationKeyEnv = "NEXALIFE_EMAIL_VERIFICATION_KEY"
	static let legacyEmailVerificationKeyEnv = "LIFE" + "OS_EMAIL_VERIFICATION_KEY"

	static func displayName(for locale: Locale) -> String {
		locale.isChineseInterface ? chineseName : englishName
	}

	static func alternateName(for locale: Locale) -> String {
		locale.isChineseInterface ? englishName : chineseName
	}

	static func aboutTitle(for locale: Locale) -> String {
		locale.isChineseInterface ? "关于\(chineseName)" : "About \(englishName)"
	}

	static func localized(_ chinese: String, _ english: String, locale: Locale) -> String {
		locale.isChineseInterface ? chinese : english
	}

	static func migratedDirectory(in base: URL, preferredPath: String, legacyPath: String) -> URL {
		let fileManager = FileManager.default
		let preferredURL = base.appendingPathComponent(preferredPath, isDirectory: true)
		let legacyURL = base.appendingPathComponent(legacyPath, isDirectory: true)

		if !fileManager.fileExists(atPath: preferredURL.path),
		   fileManager.fileExists(atPath: legacyURL.path) {
			try? fileManager.createDirectory(
				at: preferredURL.deletingLastPathComponent(),
				withIntermediateDirectories: true
			)
			try? fileManager.moveItem(at: legacyURL, to: preferredURL)
		}

		return preferredURL
	}
}

extension Locale {
	var isChineseInterface: Bool {
		identifier.lowercased().hasPrefix("zh")
	}
}
