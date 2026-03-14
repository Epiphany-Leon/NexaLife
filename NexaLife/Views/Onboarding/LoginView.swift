//
//  NexaLifeApp.swift
//  NexaLife
//
//  Created by Lihong Gao on 2026-02-26.
//

import SwiftUI

struct LoginView: View {
	@EnvironmentObject private var oauthService: OAuthService  // 获取 OAuthService 的共享实例
	@Environment(\.locale) private var locale
	@State private var message: String = ""

	var body: some View {
		VStack(spacing: 20) {
			Text(AppBrand.localized("欢迎使用\(AppBrand.displayName(for: locale))", "Welcome to \(AppBrand.displayName(for: locale))", locale: locale)).font(.title).bold()
			Button(AppBrand.localized("Apple ID（开发中）", "Apple ID (In Development)", locale: locale)) {}
				.disabled(true)
			Text(AppBrand.localized("邮箱 Profile 请在新的引导页中通过验证码创建或登录。", "Use the new onboarding flow to create or sign in to an email profile with a verification code.", locale: locale))
				.font(.subheadline)
				.foregroundStyle(.secondary)
			if !message.isEmpty {
				Text(message)
					.font(.footnote)
					.foregroundStyle(.secondary)
			}
		}
		.padding()
	}
}
