//
//  OnboardingView.swift
//  NexaLife
//
//  Created by Lihong Gao on 2026-02-26.
//

import SwiftUI
import SwiftData
import AppKit

struct OnboardingView: View {
	private enum EmailMode: String, CaseIterable, Identifiable {
		case create
		case signIn

		var id: String { rawValue }

		func title(for locale: Locale) -> String {
			switch self {
			case .create:
				return AppBrand.localized("创建 Profile", "Create Profile", locale: locale)
			case .signIn:
				return AppBrand.localized("登录已有 Profile", "Sign In to Existing Profile", locale: locale)
			}
		}

		var verificationPurpose: EmailVerificationPurpose {
			switch self {
			case .create:
				return .createAccount
			case .signIn:
				return .signIn
			}
		}
	}

	@EnvironmentObject private var appState: AppState
	@EnvironmentObject private var oauthService: OAuthService
	@Environment(\.modelContext) private var modelContext
	@Environment(\.locale) private var locale

	@State private var step: OnboardingStep = .selectAuth
	@State private var nickname: String = ""
	@State private var email: String = ""
	@State private var emailMode: EmailMode = .create
	@State private var verificationCode: String = ""
	@State private var emailAnnouncementOptIn = true
	@State private var verificationExpiresAt: Date?
	@State private var verificationPreviewCode: String?
	@State private var isSendingVerificationCode = false
	@State private var draftAccount: AuthenticatedAccount?
	@State private var statusMessage: String = ""
	@State private var statusIsError = false

	var body: some View {
		VStack(spacing: 0) {
			switch step {
			case .selectAuth:
				accountSelectionView
			case .createNickname:
				profileReviewView
			case .done:
				EmptyView()
			}
		}
		.frame(width: 760, height: 640)
		.background(
			LinearGradient(
				colors: [Color(nsColor: .windowBackgroundColor), Color.accentColor.opacity(0.08)],
				startPoint: .topLeading,
				endPoint: .bottomTrailing
			)
		)
	}

	private var accountSelectionView: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 22) {
				VStack(alignment: .leading, spacing: 8) {
					Text(AppBrand.localized("创建你的\(AppBrand.displayName(for: locale)) Profile", "Create Your \(AppBrand.displayName(for: locale)) Profile", locale: locale))
						.font(.system(size: 30, weight: .bold))
					Text(
						AppBrand.localized(
							"支持 Apple ID、任意邮箱和本地导入。你可以创建 Apple Profile、邮箱验证 Profile，或仅保留本机 Profile。",
							"Apple ID, any email address, and local import are all supported. You can create an Apple profile, an email-verified profile, or keep everything local.",
							locale: locale
						)
					)
						.foregroundStyle(.secondary)
						.fixedSize(horizontal: false, vertical: true)
				}

				HStack(alignment: .top, spacing: 16) {
					accountCard(
						title: "Apple ID",
						subtitle: AppBrand.localized(
							"Apple Profile / iCloud 同步开发中，当前版本暂不开放。",
							"Apple Profile and iCloud sync are still in development and are not available in this build.",
							locale: locale
						),
						systemImage: "applelogo"
					) {
						Button(AppBrand.localized("Apple ID（开发中）", "Apple ID (In Development)", locale: locale)) {}
						.buttonStyle(.borderedProminent)
						.disabled(true)
					}

					emailAccountCard
				}

				accountCard(
					title: AppBrand.localized("导入已有数据", "Import Existing Data", locale: locale),
					subtitle: AppBrand.localized(
						"支持导入之前导出的 \(AppBrand.displayName(for: locale)) JSON 数据包，适合迁移旧版本或切换设备。",
						"Import a previously exported \(AppBrand.displayName(for: locale)) JSON archive when migrating from an older build or switching devices.",
						locale: locale
					),
					systemImage: "square.and.arrow.down"
				) {
					HStack(spacing: 12) {
						Button(AppBrand.localized("导入本地数据", "Import Local Data", locale: locale)) {
							importLocalArchive()
						}
						.buttonStyle(.borderedProminent)

						Button(AppBrand.localized("创建本机 Profile", "Create Local Profile", locale: locale)) {
							startLocalAccount()
						}
						.buttonStyle(.bordered)
					}
				}

				if !statusMessage.isEmpty {
					Label(statusMessage, systemImage: statusIsError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
						.foregroundStyle(statusIsError ? .orange : .green)
						.font(.subheadline)
				}
			}
			.padding(32)
		}
	}

	private var emailAccountCard: some View {
		accountCard(
			title: AppBrand.localized("邮箱 Profile", "Email Profile", locale: locale),
			subtitle: AppBrand.localized(
				"不限 Gmail。先发送验证码到邮箱，再输入验证码完成创建或登录。",
				"Works with any mailbox. Send a verification code first, then enter it to create a profile or sign in.",
				locale: locale
			),
			systemImage: "envelope.fill"
		) {
			VStack(alignment: .leading, spacing: 12) {
				Picker("", selection: $emailMode) {
					ForEach(EmailMode.allCases) { mode in
						Text(mode.title(for: locale)).tag(mode)
					}
				}
				.pickerStyle(.segmented)
				.onChange(of: emailMode) { _, _ in
					resetEmailVerificationState()
				}

				if emailMode == .create {
					TextField(AppBrand.localized("昵称", "Profile Name", locale: locale), text: $nickname)
						.textFieldStyle(.roundedBorder)
				}

				TextField(AppBrand.localized("邮箱地址", "Email Address", locale: locale), text: $email)
					.textFieldStyle(.roundedBorder)
					.onChange(of: email) { _, _ in
						resetEmailVerificationState()
					}

				if emailMode == .create {
					Toggle(AppBrand.localized("接收版本更新与重要通知", "Receive release updates and important notices", locale: locale), isOn: $emailAnnouncementOptIn)
						.font(.subheadline)
				}

				if verificationExpiresAt == nil {
					Button(AppBrand.localized("发送验证码", "Send Verification Code", locale: locale)) {
						Task {
							await sendVerificationCode()
						}
					}
					.buttonStyle(.borderedProminent)
					.disabled(isSendingVerificationCode || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
				} else {
					TextField(AppBrand.localized("输入 6 位验证码", "Enter the 6-digit code", locale: locale), text: $verificationCode)
						.textFieldStyle(.roundedBorder)

					HStack(spacing: 10) {
						Button(AppBrand.localized("验证并继续", "Verify and Continue", locale: locale)) {
							completeEmailVerification()
						}
						.buttonStyle(.borderedProminent)
						.disabled(verificationCode.trimmingCharacters(in: .whitespacesAndNewlines).count < 6)

						Button(AppBrand.localized("重新发送", "Resend", locale: locale)) {
							Task {
								await sendVerificationCode()
							}
						}
						.buttonStyle(.bordered)
						.disabled(isSendingVerificationCode)
					}

					if let verificationExpiresAt {
						Text(
							AppBrand.localized(
								"验证码有效期至 \(verificationExpiresAt.formatted(date: .omitted, time: .shortened))",
								"Code expires at \(verificationExpiresAt.formatted(date: .omitted, time: .shortened))",
								locale: locale
							)
						)
							.font(.caption)
							.foregroundStyle(.secondary)
					}

					if let verificationPreviewCode {
						Text(
							AppBrand.localized(
								"当前未配置邮件发送服务，开发预览验证码：\(verificationPreviewCode)",
								"Email delivery is not configured yet. Preview code: \(verificationPreviewCode)",
								locale: locale
							)
						)
							.font(.caption)
							.foregroundStyle(.orange)
					}
				}
			}
		}
	}

	private var profileReviewView: some View {
			VStack(alignment: .leading, spacing: 24) {
			VStack(alignment: .leading, spacing: 8) {
				Text(AppBrand.localized("确认 Profile 资料", "Confirm Profile Details", locale: locale))
					.font(.system(size: 26, weight: .bold))
				Text(
					AppBrand.localized(
						"昵称会显示在 Dashboard 与侧边栏中，后续可在 Profile 中修改。",
						"Your profile name appears on the dashboard and in the sidebar. You can update it later in Profile settings.",
						locale: locale
					)
				)
					.foregroundStyle(.secondary)
			}

			GroupBox {
				VStack(alignment: .leading, spacing: 12) {
					HStack {
						Text(AppBrand.localized("Profile 类型", "Profile Type", locale: locale))
							.foregroundStyle(.secondary)
						Spacer()
						Text(draftAccount?.provider.label(for: locale) ?? AccountProviderOption.localOnly.label(for: locale))
					}
					if let email = draftAccount?.email, !email.isEmpty {
						HStack {
							Text(AppBrand.localized("邮箱", "Email", locale: locale))
								.foregroundStyle(.secondary)
							Spacer()
							Text(email)
						}
					}
					HStack {
						Text("Profile ID")
							.foregroundStyle(.secondary)
						Spacer()
						Text(draftAccount?.identifier ?? AppBrand.localized("未生成", "Not generated yet", locale: locale))
							.font(.system(.body, design: .monospaced))
							.lineLimit(1)
							.truncationMode(.middle)
					}
				}
				.padding(.top, 4)
			}

			VStack(alignment: .leading, spacing: 8) {
				Text(AppBrand.localized("昵称", "Profile Name", locale: locale))
					.font(.headline)
				TextField(AppBrand.localized("例如：Lihong", "For example: Lihong", locale: locale), text: $nickname)
					.textFieldStyle(.roundedBorder)
			}

			HStack(spacing: 12) {
				Button(AppBrand.localized("返回", "Back", locale: locale)) {
					step = .selectAuth
				}
				.buttonStyle(.bordered)

				Spacer()

				Button(AppBrand.localized("开始使用\(AppBrand.displayName(for: locale))", "Start Using \(AppBrand.displayName(for: locale))", locale: locale)) {
					completeAccountSetup()
				}
				.buttonStyle(.borderedProminent)
				.disabled(nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
			}

			if !statusMessage.isEmpty {
				Label(statusMessage, systemImage: statusIsError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
					.foregroundStyle(statusIsError ? .orange : .green)
					.font(.subheadline)
			}
		}
		.padding(32)
	}

	private func accountCard<Content: View>(
		title: String,
		subtitle: String,
		systemImage: String,
		@ViewBuilder content: () -> Content
	) -> some View {
		VStack(alignment: .leading, spacing: 16) {
			Label(title, systemImage: systemImage)
				.font(.headline)
			Text(subtitle)
				.foregroundStyle(.secondary)
				.fixedSize(horizontal: false, vertical: true)
			content()
		}
		.padding(20)
		.frame(maxWidth: .infinity, alignment: .leading)
		.background(Color(nsColor: .controlBackgroundColor))
		.clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
	}

	private func startAppleSignIn() {
		oauthService.startAppleSignIn { result in
			Task { @MainActor in
				switch result {
				case .success(let account):
					draftAccount = account
					nickname = account.displayName
					statusMessage = ""
					statusIsError = false
					step = .createNickname
				case .failure(let error):
					statusMessage = error.localizedDescription
					statusIsError = true
				}
			}
		}
	}

	private func sendVerificationCode() async {
		isSendingVerificationCode = true
		defer { isSendingVerificationCode = false }

		let result = await oauthService.sendEmailVerificationCode(
			name: emailMode == .create ? nickname : "",
			email: email,
			purpose: emailMode.verificationPurpose,
			announcementOptIn: emailAnnouncementOptIn
		)

		switch result {
		case .success(let dispatch):
			verificationExpiresAt = dispatch.expiresAt
			verificationPreviewCode = dispatch.previewCode
			verificationCode = ""
			if dispatch.sentViaEmailService {
				statusMessage = AppBrand.localized(
					"验证码已发送到 \(dispatch.destination)。",
					"Verification code sent to \(dispatch.destination).",
					locale: locale
				)
				statusIsError = false
			} else {
				statusMessage = AppBrand.localized(
					"已生成验证码，但当前仍处于开发预览模式。",
					"A verification code was generated, but the app is still in preview delivery mode.",
					locale: locale
				)
				statusIsError = false
			}
		case .failure(let error):
			statusMessage = error.localizedDescription
			statusIsError = true
		}
	}

	private func completeEmailVerification() {
		let result = oauthService.completeEmailVerification(
			email: email,
			code: verificationCode,
			purpose: emailMode.verificationPurpose
		)

		switch result {
		case .success(let account):
			draftAccount = account
			nickname = emailMode == .create ? nickname : account.displayName
			statusMessage = AppBrand.localized("邮箱验证完成。", "Email verification completed.", locale: locale)
			statusIsError = false
			step = .createNickname
		case .failure(let error):
			statusMessage = error.localizedDescription
			statusIsError = true
		}
	}

	private func startLocalAccount() {
		let displayName = nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
			? AppBrand.localized("本机 Profile", "Local Profile", locale: locale)
			: nickname
		draftAccount = AuthenticatedAccount(
			provider: .localOnly,
			identifier: UUID().uuidString,
			email: "",
			displayName: displayName
		)
		if nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
			nickname = displayName
		}
		statusMessage = ""
		statusIsError = false
		step = .createNickname
	}

	private func completeAccountSetup() {
		let finalName = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
		let account = draftAccount ?? AuthenticatedAccount(
			provider: .localOnly,
			identifier: UUID().uuidString,
			email: "",
			displayName: finalName
		)
		let finalizedAccount = AuthenticatedAccount(
			provider: account.provider,
			identifier: account.identifier,
			email: account.email,
			displayName: finalName
		)

		appState.applyAccount(
			provider: finalizedAccount.provider,
			email: finalizedAccount.email,
			identifier: finalizedAccount.identifier
		)
		oauthService.updateStoredProfile(finalizedAccount)
		appState.completeOnboarding(name: finalName)
		step = .done
	}

	private func importLocalArchive() {
		let panel = NSOpenPanel()
		panel.canChooseDirectories = true
		panel.canChooseFiles = true
		panel.allowsMultipleSelection = false
		panel.message = AppBrand.localized(
			"选择导出的 \(AppBrand.displayName(for: locale)) JSON 数据包或包含它的文件夹",
			"Choose an exported \(AppBrand.displayName(for: locale)) JSON archive or a folder that contains one",
			locale: locale
		)
		guard panel.runModal() == .OK, let source = panel.url else { return }

		do {
			let archive = try AppDataArchiveService.loadSnapshot(from: source)
			try AppDataArchiveService.replaceLocalData(
				with: archive,
				modelContext: modelContext,
				appState: appState
			)
			draftAccount = AuthenticatedAccount(
				provider: appState.selectedAccountProvider,
				identifier: appState.accountIdentifier,
				email: appState.accountEmail,
				displayName: appState.userName
			)
			nickname = appState.userName
			statusMessage = AppBrand.localized("已导入本地数据。", "Local data imported.", locale: locale)
			statusIsError = false
			if appState.hasCompletedOnboarding {
				step = .done
			} else {
				step = .createNickname
			}
		} catch {
			statusMessage = error.localizedDescription
			statusIsError = true
		}
	}

	private func resetEmailVerificationState() {
		verificationCode = ""
		verificationExpiresAt = nil
		verificationPreviewCode = nil
	}
}
