//
//  KeychainHelper.swift
//  LifeOS
//
//  Created by Lihong Gao on 2026-02-26.
//
//  KeychainHelper.swift — 独立 Keychain 工具，全局可用

import Foundation
import Security

class KeychainHelper {
	static let shared = KeychainHelper()
	private init() {}

	func save(service: String, account: String, value: String) {
		let data = Data(value.utf8)
		let query: [String: Any] = [
			kSecClass as String:       kSecClassGenericPassword,
			kSecAttrService as String: service,
			kSecAttrAccount as String: account,
			kSecValueData as String:   data
		]
		SecItemDelete(query as CFDictionary)
		SecItemAdd(query as CFDictionary, nil)
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
		SecItemCopyMatching(query as CFDictionary, &result)
		guard let data = result as? Data else { return nil }
		return String(data: data, encoding: .utf8)
	}

	func delete(service: String, account: String) {
		let query: [String: Any] = [
			kSecClass as String:       kSecClassGenericPassword,
			kSecAttrService as String: service,
			kSecAttrAccount as String: account
		]
		SecItemDelete(query as CFDictionary)
	}
}
