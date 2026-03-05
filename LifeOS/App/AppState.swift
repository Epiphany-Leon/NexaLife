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
}

enum OnboardingStep {
	case selectAuth
	case createNickname
	case done
}

@MainActor
class AppState: ObservableObject {
	// MARK: - Onboarding
	@Published var hasCompletedOnboarding: Bool {
		didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding") }
	}

	// MARK: - User
	@Published var userName: String {
		didSet { UserDefaults.standard.set(userName, forKey: "userName") }
	}
	@Published var avatarImagePath: String {
		didSet { UserDefaults.standard.set(avatarImagePath, forKey: "avatarImagePath") }
	}
	@Published var apiTokenStorageMode: String {
		didSet { UserDefaults.standard.set(apiTokenStorageMode, forKey: "apiTokenStorageMode") }
	}
	@Published var globalCurrency: String {
		didSet { UserDefaults.standard.set(globalCurrency, forKey: "globalCurrency") }
	}
	@Published var monthlyBudget: Double {
		didSet { UserDefaults.standard.set(monthlyBudget, forKey: "monthlyBudget") }
	}

	// MARK: - Auth
	@Published var authToken: String?

	// MARK: - Navigation
	@Published var selectedModule: AppModule = .dashboard
	@Published var columnVisibility: NavigationSplitViewVisibility = .detailOnly

	// MARK: - Storage
	@Published var storageDirectory: URL? {
		didSet {
			if let url = storageDirectory {
				UserDefaults.standard.set(url.path, forKey: "storageDirectory")
			}
		}
	}

	init() {
		self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
		self.userName = UserDefaults.standard.string(forKey: "userName") ?? ""
		self.avatarImagePath = UserDefaults.standard.string(forKey: "avatarImagePath") ?? ""
		self.apiTokenStorageMode = UserDefaults.standard.string(forKey: "apiTokenStorageMode")
			?? APITokenStorageMode.keychain.rawValue
		self.globalCurrency = UserDefaults.standard.string(forKey: "globalCurrency")
			?? CurrencyCode.CNY.rawValue
		let defaultBudget = UserDefaults.standard.double(forKey: "monthlyBudget")
		self.monthlyBudget = defaultBudget > 0 ? defaultBudget : 0
		if let path = UserDefaults.standard.string(forKey: "storageDirectory") {
			self.storageDirectory = URL(fileURLWithPath: path)
		}
	}

	func completeOnboarding(name: String) {
		self.userName = name
		self.hasCompletedOnboarding = true
	}

	var selectedCurrencyCode: CurrencyCode {
		get { CurrencyCode(rawValue: globalCurrency) ?? .CNY }
		set { globalCurrency = newValue.rawValue }
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
}
