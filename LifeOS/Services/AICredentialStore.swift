//
//  AICredentialStore.swift
//  LifeOS
//
//  Created by Codex on 2026-03-01.
//

import Foundation

enum APITokenStorageMode: String, CaseIterable, Identifiable {
	case keychain
	case localFile

	var id: String { rawValue }

	var label: String {
		switch self {
		case .keychain: return "系统钥匙串 Keychain"
		case .localFile: return "本地文件 Local File"
		}
	}
}

enum AICredentialStore {
	private static let service = "LifeOS"
	private static let account = "aiApiKey"
	private static let storageModeKey = "apiTokenStorageMode"
	private static let localFilePathKey = "apiTokenLocalFilePath"
	private static let storageDirectoryKey = "storageDirectory"
	private static let fallbackFolderName = "LifeOS"
	private static let tokenFileName = "ai_api_token.txt"

	static var mode: APITokenStorageMode {
		let raw = UserDefaults.standard.string(forKey: storageModeKey) ?? APITokenStorageMode.keychain.rawValue
		return APITokenStorageMode(rawValue: raw) ?? .keychain
	}

	static func saveAPIKey(_ key: String) {
		switch mode {
		case .keychain:
			KeychainHelper.shared.save(service: service, account: account, value: key)
		case .localFile:
			saveToLocalFile(key)
			KeychainHelper.shared.delete(service: service, account: account)
		}
	}

	static func readAPIKey() -> String {
		switch mode {
		case .keychain:
			return KeychainHelper.shared.read(service: service, account: account) ?? ""
		case .localFile:
			return readFromLocalFile() ?? ""
		}
	}

	static func storageLocationDescription() -> String {
		switch mode {
		case .keychain:
			return "系统钥匙串 (Service: \(service), Account: \(account))"
		case .localFile:
			return localTokenFileURL().path
		}
	}

	static func localFileURL() -> URL {
		localTokenFileURL()
	}

	static func setLocalFileURL(_ url: URL) {
		UserDefaults.standard.set(url.path, forKey: localFilePathKey)
	}

	private static func saveToLocalFile(_ key: String) {
		let url = localTokenFileURL()
		do {
			try FileManager.default.createDirectory(
				at: url.deletingLastPathComponent(),
				withIntermediateDirectories: true,
				attributes: nil
			)
			try key.data(using: .utf8)?.write(to: url, options: [.atomic])
		} catch {
			NSLog("AICredentialStore save file error: \(error.localizedDescription)")
		}
	}

	private static func readFromLocalFile() -> String? {
		let url = localTokenFileURL()
		guard let data = try? Data(contentsOf: url) else { return nil }
		return String(data: data, encoding: .utf8)
	}

	private static func localTokenFileURL() -> URL {
		if let customPath = UserDefaults.standard.string(forKey: localFilePathKey),
		   !customPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
			return URL(fileURLWithPath: customPath)
		}

		if let userPath = UserDefaults.standard.string(forKey: storageDirectoryKey),
		   !userPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
			return URL(fileURLWithPath: userPath).appendingPathComponent(tokenFileName)
		}

		let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
			?? URL(fileURLWithPath: NSTemporaryDirectory())
		return base
			.appendingPathComponent(fallbackFolderName, isDirectory: true)
			.appendingPathComponent(tokenFileName)
	}
}
