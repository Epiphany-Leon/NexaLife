//
//  KeychainHelper.swift
//  NexaLife
//
//  Created by Lihong Gao on 2026-02-26.
//
//  KeychainHelper.swift — 独立 Keychain 工具，全局可用

import Foundation
import Security

class KeychainHelper {
	static let shared = KeychainHelper()
	private init() {}

	@discardableResult
	func save(service: String, account: String, value: String) -> Bool {
		let data = Data(value.utf8)
		let query: [String: Any] = [
			kSecClass as String:       kSecClassGenericPassword,
			kSecAttrService as String: service,
			kSecAttrAccount as String: account,
			kSecValueData as String:   data
		]
		let deleteStatus = SecItemDelete(query as CFDictionary)
		if deleteStatus != errSecSuccess && deleteStatus != errSecItemNotFound {
			AppLogger.warning(
				"Keychain delete-before-save failed (\(statusDescription(deleteStatus))) service=\(service) account=\(account)",
				category: "security"
			)
		}
		let addStatus = SecItemAdd(query as CFDictionary, nil)
		guard addStatus == errSecSuccess else {
			AppLogger.error(
				"Keychain save failed (\(statusDescription(addStatus))) service=\(service) account=\(account)",
				category: "security"
			)
			return false
		}
		return true
	}

	func read(service: String, account: String) -> String? {
		let query: [String: Any] = [
			kSecClass as String:       kSecClassGenericPassword,
			kSecAttrService as String: service,
			kSecAttrAccount as String: account,
				kSecReturnData as String:  true,
				kSecMatchLimit as String:  kSecMatchLimitOne
			]
		var result: AnyObject?
		let status = SecItemCopyMatching(query as CFDictionary, &result)
		if status == errSecItemNotFound { return nil }
		guard status == errSecSuccess else {
			AppLogger.warning(
				"Keychain read failed (\(statusDescription(status))) service=\(service) account=\(account)",
				category: "security"
			)
			return nil
		}
		guard let data = result as? Data else { return nil }
		return String(data: data, encoding: .utf8)
	}

	@discardableResult
	func delete(service: String, account: String) -> Bool {
		let query: [String: Any] = [
			kSecClass as String:       kSecClassGenericPassword,
			kSecAttrService as String: service,
			kSecAttrAccount as String: account
		]
		let status = SecItemDelete(query as CFDictionary)
		guard status == errSecSuccess || status == errSecItemNotFound else {
			AppLogger.warning(
				"Keychain delete failed (\(statusDescription(status))) service=\(service) account=\(account)",
				category: "security"
			)
			return false
		}
		return true
	}

	private func statusDescription(_ status: OSStatus) -> String {
		if let message = SecCopyErrorMessageString(status, nil) as String? {
			return message
		}
		return "OSStatus=\(status)"
	}
}
