//
//  AccountDetailView.swift
//  LifeOS
//
//  Created by Codex on 2026-03-01.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct AccountDetailView: View {
	@EnvironmentObject private var appState: AppState
	@Environment(\.dismiss) private var dismiss

	@State private var draftUserName: String = ""
	@State private var draftBudgetText: String = ""
	@State private var savedProfile = false
	@State private var savedBudget = false
	@State private var isShowingAvatarCropper = false
	@State private var pendingAvatarImage: NSImage?
	private let formLabelWidth: CGFloat = 72
	private let trailingContentWidth: CGFloat = 360
	private let trailingEdgePadding: CGFloat = 12

	private var avatarImage: NSImage? {
		guard !appState.avatarImagePath.isEmpty else { return nil }
		return NSImage(contentsOfFile: appState.avatarImagePath)
	}

	var body: some View {
		VStack(spacing: 0) {
			HStack {
				Text("账户")
					.font(.title3.bold())
				Spacer()
				Button("关闭") {
					dismiss()
				}
				.buttonStyle(.bordered)
			}
			.padding(.horizontal, 20)
			.padding(.vertical, 14)

			Divider()

			Form {
				Section("账户") {
					HStack(spacing: 14) {
						Group {
							if let image = avatarImage {
								Image(nsImage: image)
									.resizable()
									.scaledToFill()
							} else {
								Image(systemName: "person.circle.fill")
									.resizable()
									.scaledToFit()
									.foregroundStyle(.secondary)
							}
						}
						.frame(width: 72, height: 72)
						.clipShape(Circle())

						Spacer(minLength: 12)

						VStack(alignment: .trailing, spacing: 8) {
							Button("修改头像并裁剪…") {
								selectAvatarForManualCrop()
							}
							.buttonStyle(.bordered)
							if !appState.avatarImagePath.isEmpty {
								Button("移除头像", role: .destructive) {
									appState.avatarImagePath = ""
								}
								.buttonStyle(.plain)
							}
						}
					}
					.padding(.trailing, trailingEdgePadding)

					rightAlignedRow(label: "昵称") {
						HStack(spacing: 8) {
							TextField("", text: $draftUserName)
								.textFieldStyle(.roundedBorder)
								.frame(width: 180)
							Button("保存") {
								appState.userName = draftUserName.trimmingCharacters(in: .whitespacesAndNewlines)
								showSavedFlag($savedProfile)
							}
							.buttonStyle(.borderedProminent)
							.controlSize(.small)
							if savedProfile {
								Image(systemName: "checkmark.circle.fill")
									.foregroundStyle(.green)
							}
						}
					}
				}

				Section("偏好") {
					rightAlignedRow(label: "全局货币") {
						HStack {
							Spacer(minLength: 0)
							Picker("全局货币", selection: $appState.globalCurrency) {
								ForEach(CurrencyCode.allCases) { code in
									Text(code.displayName).tag(code.rawValue)
								}
							}
							.labelsHidden()
							.frame(width: 220, alignment: .trailing)
						}
					}

					rightAlignedRow(label: "月度预算") {
						HStack(spacing: 8) {
							TextField("", text: $draftBudgetText)
								.textFieldStyle(.roundedBorder)
								.frame(width: 140)
							Button("保存") {
								let parsed = Double(draftBudgetText) ?? 0
								appState.monthlyBudget = max(0, parsed)
								draftBudgetText = String(format: "%.2f", appState.monthlyBudget)
								showSavedFlag($savedBudget)
							}
							.buttonStyle(.borderedProminent)
							.controlSize(.small)
							if savedBudget {
								Image(systemName: "checkmark.circle.fill")
									.foregroundStyle(.green)
							}
						}
					}

						rightAlignedRow(label: "高级设置") {
							Button("在设置中管理 API Token 与数据存储…") {
								NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
							}
							.buttonStyle(.bordered)
						}
					}
			}
			.formStyle(.grouped)
		}
		.frame(width: 640, height: 420)
		.sheet(isPresented: $isShowingAvatarCropper, onDismiss: {
			pendingAvatarImage = nil
		}) {
			if let source = pendingAvatarImage {
				AvatarCropperSheet(sourceImage: source) { cropped in
					saveAvatarImage(cropped)
				}
			}
		}
		.onAppear {
			draftUserName = appState.userName
			draftBudgetText = String(format: "%.2f", appState.monthlyBudget)
		}
	}

	private func rightAlignedRow<Content: View>(
		label: String,
		@ViewBuilder content: () -> Content
	) -> some View {
		HStack(alignment: .center, spacing: 12) {
			Text(label)
				.frame(width: formLabelWidth, alignment: .leading)
			Spacer(minLength: 12)
			content()
				.frame(maxWidth: trailingContentWidth, alignment: .trailing)
		}
		.padding(.trailing, trailingEdgePadding)
	}

	private func showSavedFlag(_ flag: Binding<Bool>) {
		withAnimation { flag.wrappedValue = true }
		DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
			withAnimation { flag.wrappedValue = false }
		}
	}

	private func selectAvatarForManualCrop() {
		let panel = NSOpenPanel()
		panel.canChooseDirectories = false
		panel.canChooseFiles = true
		panel.allowsMultipleSelection = false
		panel.allowedContentTypes = [.image]
		guard panel.runModal() == .OK,
			  let sourceURL = panel.url,
			  let sourceImage = NSImage(contentsOf: sourceURL) else {
			return
		}
		pendingAvatarImage = sourceImage
		isShowingAvatarCropper = true
	}

	private func saveAvatarImage(_ image: NSImage) {
		guard let pngData = image.pngData() else { return }
		let folder = avatarStoreFolderURL()
		do {
			try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
			let targetURL = folder.appendingPathComponent("avatar.png")
			try pngData.write(to: targetURL, options: .atomic)
			appState.avatarImagePath = targetURL.path
		} catch {
			AppLogger.warning("Avatar save failed: \(error.localizedDescription)", category: "profile")
		}
	}

	private func avatarStoreFolderURL() -> URL {
		let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
			?? URL(fileURLWithPath: NSTemporaryDirectory())
		return base.appendingPathComponent("LifeOS/Avatars", isDirectory: true)
	}
}

private struct AvatarCropperSheet: View {
	@Environment(\.dismiss) private var dismiss

	let sourceImage: NSImage
	let onSave: (NSImage) -> Void

	@State private var zoom: CGFloat = 1
	@State private var offset: CGSize = .zero
	@State private var dragStartOffset: CGSize = .zero

	private let previewSide: CGFloat = 340
	private let cropDiameter: CGFloat = 260
	private let outputSide: CGFloat = 512

	private var sourceSize: CGSize {
		guard let cg = sourceImage.cgImageFromImage else { return .zero }
		return CGSize(width: cg.width, height: cg.height)
	}

	private var baseScale: CGFloat {
		guard sourceSize.width > 0, sourceSize.height > 0 else { return 1 }
		return max(cropDiameter / sourceSize.width, cropDiameter / sourceSize.height)
	}

	private var renderedWidth: CGFloat { sourceSize.width * baseScale * zoom }
	private var renderedHeight: CGFloat { sourceSize.height * baseScale * zoom }

	var body: some View {
		VStack(alignment: .leading, spacing: 14) {
			Text("手动裁剪头像")
				.font(.title3.bold())

			ZStack {
				Color.black.opacity(0.06)

				Image(nsImage: sourceImage)
					.resizable()
					.interpolation(.high)
					.frame(width: renderedWidth, height: renderedHeight)
					.offset(offset)
					.gesture(dragGesture)

				Color.black.opacity(0.44)
					.compositingGroup()
					.mask {
						Rectangle()
							.overlay {
								Circle()
									.frame(width: cropDiameter, height: cropDiameter)
									.blendMode(.destinationOut)
							}
					}
					.allowsHitTesting(false)

				Circle()
					.strokeBorder(.white.opacity(0.95), lineWidth: 2)
					.frame(width: cropDiameter, height: cropDiameter)
					.shadow(color: .black.opacity(0.25), radius: 3, y: 1)
			}
			.frame(width: previewSide, height: previewSide)
			.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

			HStack(spacing: 10) {
				Text("缩放")
					.foregroundStyle(.secondary)
				Slider(value: $zoom, in: 1...4, step: 0.01)
					.onChange(of: zoom) { _, newValue in
						offset = clampedOffset(offset, zoom: newValue)
						dragStartOffset = offset
					}
				Button("重置") {
					zoom = 1
					offset = .zero
					dragStartOffset = .zero
				}
				.buttonStyle(.bordered)
			}

			HStack {
				Spacer()
				Button("取消") {
					dismiss()
				}
				.buttonStyle(.bordered)
				Button("保存头像") {
					guard let image = renderCroppedAvatar() else { return }
					onSave(image)
					dismiss()
				}
				.buttonStyle(.borderedProminent)
			}
		}
		.padding(18)
		.frame(width: 380)
	}

	private var dragGesture: some Gesture {
		DragGesture(minimumDistance: 0)
			.onChanged { value in
				let next = CGSize(
					width: dragStartOffset.width + value.translation.width,
					height: dragStartOffset.height + value.translation.height
				)
				offset = clampedOffset(next)
			}
			.onEnded { _ in
				dragStartOffset = offset
			}
	}

	private func clampedOffset(_ candidate: CGSize, zoom: CGFloat? = nil) -> CGSize {
		let resolvedZoom = zoom ?? self.zoom
		let width = sourceSize.width * baseScale * resolvedZoom
		let height = sourceSize.height * baseScale * resolvedZoom

		let maxX = max(0, (width - cropDiameter) / 2)
		let maxY = max(0, (height - cropDiameter) / 2)

		return CGSize(
			width: min(max(candidate.width, -maxX), maxX),
			height: min(max(candidate.height, -maxY), maxY)
		)
	}

	private func renderCroppedAvatar() -> NSImage? {
		guard let cg = sourceImage.cgImageFromImage else { return nil }

		let mappedScale = baseScale * zoom
		guard mappedScale > 0 else { return nil }

		let side = max(1, cropDiameter / mappedScale)
		let centerX = CGFloat(cg.width) / 2 - offset.width / mappedScale
		let centerYTopDown = CGFloat(cg.height) / 2 - offset.height / mappedScale

		var topDownX = centerX - side / 2
		var topDownY = centerYTopDown - side / 2
		topDownX = min(max(0, topDownX), CGFloat(cg.width) - side)
		topDownY = min(max(0, topDownY), CGFloat(cg.height) - side)

		let yFromBottom = CGFloat(cg.height) - topDownY - side
		let primaryRect = CGRect(x: topDownX, y: yFromBottom, width: side, height: side).integral
		let fallbackRect = CGRect(x: topDownX, y: topDownY, width: side, height: side).integral
		let square = cg.cropping(to: primaryRect) ?? cg.cropping(to: fallbackRect)
		guard let square else { return nil }

		let outputSize = NSSize(width: outputSide, height: outputSide)
		let output = NSImage(size: outputSize)
		output.lockFocus()
		let path = NSBezierPath(ovalIn: NSRect(origin: .zero, size: outputSize))
		path.addClip()
		NSGraphicsContext.current?.imageInterpolation = .high
		NSImage(cgImage: square, size: outputSize).draw(in: NSRect(origin: .zero, size: outputSize))
		output.unlockFocus()
		return output
	}
}

private extension NSImage {
	var cgImageFromImage: CGImage? {
		if let cgImage = cgImage(forProposedRect: nil, context: nil, hints: nil) {
			return cgImage
		}
		guard let data = tiffRepresentation,
			  let rep = NSBitmapImageRep(data: data) else {
			return nil
		}
		return rep.cgImage
	}

	func pngData() -> Data? {
		guard let tiffData = tiffRepresentation,
			  let bitmap = NSBitmapImageRep(data: tiffData) else {
			return nil
		}
		return bitmap.representation(using: .png, properties: [:])
	}
}
