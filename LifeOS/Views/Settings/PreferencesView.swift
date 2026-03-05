//
//  PreferencesView.swift
//  LifeOS
//
//  Created by Lihong Gao on 2026-02-26.
//
//  PreferencesView.swift

import SwiftUI

struct PreferencesView: View {
	@EnvironmentObject private var appState: AppState

	@State private var apiKey:           String = ""
	@State private var selectedProvider: String = "deepseek"
	@State private var isSaved:          Bool   = false

	var body: some View {
		TabView {
			// 通用
			Form {
				Section("用户") {
					LabeledContent("昵称") {
						TextField("昵称", text: $appState.userName)
							.frame(width: 200)
					}
				}
				Section("数据存储") {
					LabeledContent("存储路径") {
						Text(appState.storageDirectory?.path ?? "默认路径")
							.foregroundStyle(.secondary)
							.truncationMode(.middle)
							.frame(width: 200)
					}
					Button("更改存储文件夹…") { selectFolder() }
				}
			}
			.tabItem { Label("通用", systemImage: "gearshape") }

			// AI 设置
			Form {
				Section("服务商") {
					Picker("AI 服务商", selection: $selectedProvider) {
						Text("DeepSeek").tag("deepseek")
						Text("Qwen（阿里云）").tag("qwen")
					}
					.pickerStyle(.radioGroup)
					.onChange(of: selectedProvider) { _, newValue in
						UserDefaults.standard.set(newValue, forKey: "aiProvider")
					}
				}
				Section("API Key") {
					LabeledContent(selectedProvider == "deepseek" ? "DeepSeek Key" : "DashScope Key") {
						SecureField("sk-...", text: $apiKey)
							.frame(width: 260)
					}
					HStack {
						Button("保存 API Key") {
							AICredentialStore.saveAPIKey(apiKey)
							withAnimation { isSaved = true }
							DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
								isSaved = false
							}
						}
						.buttonStyle(.borderedProminent)
						.disabled(apiKey.isEmpty)

						if isSaved {
							Label("已保存", systemImage: "checkmark.circle.fill")
								.foregroundStyle(.green)
								.font(.subheadline)
								.transition(.opacity)
						}
					}
				}
				Section("说明") {
					Text("DeepSeek：https://platform.deepseek.com\nQwen：https://dashscope.aliyun.com")
						.font(.caption)
						.foregroundStyle(.secondary)
				}
			}
			.tabItem { Label("AI 设置", systemImage: "sparkles") }
		}
		.padding()
		.frame(width: 500, height: 360)
		.onAppear {
			apiKey           = AICredentialStore.readAPIKey()
			selectedProvider = UserDefaults.standard.string(forKey: "aiProvider") ?? "deepseek"
		}
	}

	private func selectFolder() {
		let panel = NSOpenPanel()
		panel.canChooseDirectories  = true
		panel.canChooseFiles        = false
		panel.allowsMultipleSelection = false
		if panel.runModal() == .OK { appState.storageDirectory = panel.url }
	}
}
