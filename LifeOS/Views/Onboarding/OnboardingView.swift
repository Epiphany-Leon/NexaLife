//
//  OnboardingView.swift
//  LifeOS
//
//  Created by Lihong Gao on 2026-02-26.
//
//  OnboardingView.swift — 初次启动流程

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var oauthService: OAuthService

    @State private var step: OnboardingStep = .selectAuth
    @State private var nickname: String = ""
    @State private var useLocalStorage: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            switch step {
            case .selectAuth:
                authSelectionView
            case .createNickname:
                nicknameView
            case .done:
                EmptyView()
            }
        }
        .frame(width: 480, height: 360)
        .background(.ultraThinMaterial)
    }

    // MARK: Step A — 选择登录方式 or 本地文件夹
    private var authSelectionView: some View {
        VStack(spacing: 28) {
            Text("欢迎使用 LifeOS").font(.largeTitle).bold()
            Text("选择你的数据存储方式").foregroundStyle(.secondary)

            Divider()

            // 方式一：登录
            VStack(spacing: 12) {
                Button {
                    oauthService.startOAuthFlow(type: .apple) { success in
                        if success { step = .createNickname }
                    }
                } label: {
                    Label("使用 Apple ID 登录", systemImage: "applelogo")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    oauthService.startOAuthFlow(type: .google) { success in
                        if success { step = .createNickname }
                    }
                } label: {
                    Label("使用邮箱登录", systemImage: "envelope.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }

            Divider().overlay(Text("或").padding(.horizontal, 8))

            // 方式二：本地文件夹
            Button {
                selectLocalFolder()
            } label: {
                Label("选择本地文件夹（离线模式）", systemImage: "folder.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .padding(40)
    }

    // MARK: Step B — 创建昵称
    private var nicknameView: some View {
        VStack(spacing: 24) {
            Text("创建你的昵称").font(.title).bold()
            Text("昵称将在 Dashboard 中显示，可随时在偏好设置中修改")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            TextField("例如：Lihong", text: $nickname)
                .textFieldStyle(.roundedBorder)
                .frame(width: 260)

            Button("开始使用 LifeOS") {
                guard !nickname.isEmpty else { return }
                appState.completeOnboarding(name: nickname)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(nickname.isEmpty)
        }
        .padding(40)
    }

    private func selectLocalFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "选择 LifeOS 数据存储文件夹"
        panel.prompt = "选择此文件夹"
        if panel.runModal() == .OK, let url = panel.url {
            appState.storageDirectory = url
            step = .createNickname
        }
    }
}
