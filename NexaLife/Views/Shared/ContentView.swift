//
//  ContentView.swift
//  NexaLife
//
//  Created by Lihong Gao on 2026-02-24.
//
//  ContentView.swift

import SwiftUI
import SwiftData

struct ContentView: View {
	@EnvironmentObject private var appState: AppState
	@Environment(\.modelContext) private var modelContext
	@State private var isShowingQuickInput = false
	@State private var isShowingGlobalSearch = false

	@State private var selectedDashboardSnapshot: DashboardSnapshot? = nil
	@State private var selectedInboxItem:          InboxItem?          // ✅ 由这里统一持有
	@State private var selectedTask:               TaskItem?
	@State private var selectedNote:               Note?
	@State private var selectedVitalsEntry:        VitalsEntry?
	@State private var selectedLifestyleTab:       LifestyleTab = .accounting
	@State private var selectedTransaction:        Transaction?
	@State private var selectedGoal:               Goal?
	@State private var selectedConnection:         Connection?

	var body: some View {
		NavigationSplitView(columnVisibility: $appState.columnVisibility) {
			SidebarView()
		} content: {
			contentColumnView
		} detail: {
			detailView
		}
		.toolbar {
			ToolbarItem(placement: .primaryAction) {
				Button { isShowingQuickInput = true } label: {
					Label("settings.commands.quick_capture", systemImage: "plus.circle.fill")
				}
				.keyboardShortcut(
					appState.selectedQuickCaptureShortcut.keyEquivalent,
					modifiers: appState.selectedQuickCaptureShortcut.modifiers
				)
			}
		}
		.sheet(isPresented: $isShowingQuickInput) {
			QuickInputSheet(isPresented: $isShowingQuickInput)
		}
		.sheet(isPresented: $isShowingGlobalSearch) {
			GlobalSearchSheet()
				.environmentObject(appState)
		}
			.onReceive(NotificationCenter.default.publisher(for: .nexaLifeShowQuickInput)) { _ in
				isShowingQuickInput = true
			}
			.onReceive(NotificationCenter.default.publisher(for: .nexaLifeShowGlobalSearch)) { _ in
				isShowingGlobalSearch = true
			}
			.onReceive(NotificationCenter.default.publisher(for: .nexaLifePerformAutoBackup)) { note in
				performAutoBackup(at: note.object as? Date ?? .now)
			}
			.onReceive(NotificationCenter.default.publisher(for: .nexaLifeResetSelections)) { _ in
				resetSelections()
			}
			.task {
				appState.runAutoBackupIfNeeded()
			}
	}

	// MARK: - 中间列
	@ViewBuilder
	private var contentColumnView: some View {
		switch appState.selectedModule {
		case .dashboard:
			DashboardArchiveListView(selectedSnapshot: $selectedDashboardSnapshot)
		case .inbox:
			// ✅ 传入 binding，选中后 detail 列同步更新
			InboxView(selectedItem: $selectedInboxItem)
		case .execution:
			ExecutionView(selectedTask: $selectedTask)
		case .knowledge:
			KnowledgeView(selectedNote: $selectedNote)
		case .lifestyle:
			LifestyleView(
				selectedTab: $selectedLifestyleTab,
				selectedTransaction: $selectedTransaction,
				selectedGoal: $selectedGoal,
				selectedConnection: $selectedConnection
			)
		case .vitals:
			VitalsView(selectedEntry: $selectedVitalsEntry)
		}
	}

	// MARK: - 详情列
	@ViewBuilder
	private var detailView: some View {
		switch appState.selectedModule {
		case .dashboard:
			DashboardView(externalSnapshot: $selectedDashboardSnapshot)
		case .inbox:
			if let item = selectedInboxItem {
				ItemDetailView(selectedItem: $selectedInboxItem, item: item)
			} else {
				lifestyleCreatePlaceholder(
					icon: "tray",
					message: "选择条目查看详情，或直接新建一条闪念",
					buttonTitle: "新建闪念"
				) {
					NotificationCenter.default.post(name: .nexaLifeShowQuickInput, object: nil)
				}
			}
		case .execution:
			if let task = selectedTask {
				TaskDetailView(selectedTask: $selectedTask, task: task)
			} else {
				ExecutionEmptyDetailView()
			}
		case .knowledge:
			if let note = selectedNote {
				NoteDetailView(selectedNote: $selectedNote, note: note)
			} else {
				lifestyleCreatePlaceholder(
					icon: "book",
					message: "选择笔记开始阅读",
					buttonTitle: "新建笔记"
				) {
					let note = Note(title: "新笔记")
					modelContext.insert(note)
					selectedNote = note
				}
			}
		case .vitals:
			if let entry = selectedVitalsEntry {
				VitalsDetailView(selectedEntry: $selectedVitalsEntry, entry: entry)
			} else {
				vitalsCreatePlaceholder()
			}
		case .lifestyle:
			lifestyleDetailView
		}
	}

	@ViewBuilder
	private var lifestyleDetailView: some View {
		switch selectedLifestyleTab {
		case .accounting:
			if let transaction = selectedTransaction {
					AccountingTransactionDetailView(
						selectedTransaction: $selectedTransaction,
						transaction: transaction
					)
			} else {
				lifestyleCreatePlaceholder(
					icon: "yensign.circle",
					message: "选择财务条目查看详情",
					buttonTitle: "新建财务条目"
				) {
					let tx = Transaction(
						amount: 0,
						category: "其他",
						title: "新条目",
						note: "",
						date: .now,
						currencyCode: appState.selectedCurrencyCode.rawValue
					)
					modelContext.insert(tx)
					selectedTransaction = tx
				}
			}
		case .goals:
				if let goal = selectedGoal {
					GoalDetailView(selectedGoal: $selectedGoal, goal: goal)
				} else {
				lifestyleCreatePlaceholder(
					icon: "flag.checkered",
					message: "选择目标查看详情",
					buttonTitle: "新建目标"
				) {
					let goal = Goal(title: "新目标")
					modelContext.insert(goal)
					selectedGoal = goal
				}
			}
		case .connections:
				if let connection = selectedConnection {
					ConnectionDetailView(selectedConnection: $selectedConnection, connection: connection)
				} else {
				lifestyleCreatePlaceholder(
					icon: "person.2",
					message: "选择联系人查看详情",
					buttonTitle: "新建联系人"
				) {
					let connection = Connection(name: "新联系人")
					modelContext.insert(connection)
					selectedConnection = connection
				}
			}
		}
	}

	// MARK: - 占位视图
	private func vitalsCreatePlaceholder() -> some View {
		VStack(spacing: 14) {
			Image(systemName: "sparkles")
				.font(.system(size: 40))
				.foregroundStyle(.tertiary)
			Text("选择记录查看详情")
				.foregroundStyle(.secondary)
				.font(.title3)

			HStack(spacing: 8) {
				ForEach(VitalsEntryType.allCases, id: \.self) { type in
					Button(type.rawValue) {
						createVitalsEntry(type)
					}
					.buttonStyle(.borderedProminent)
					.controlSize(.small)
				}
			}
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
	}

	private func createVitalsEntry(_ type: VitalsEntryType) {
		let isProtected = type == .coreCode || type == .treehol
		let entry = VitalsEntry(
			content: "",
			type: type,
			category: type == .coreCode ? "未分类" : "",
			isProtected: isProtected,
			moodScore: type == .motivation ? 3 : 0
		)
		modelContext.insert(entry)
		selectedVitalsEntry = entry
	}

	private func placeholderView(icon: String, message: String) -> some View {
		VStack(spacing: 12) {
			Image(systemName: icon)
				.font(.system(size: 40))
				.foregroundStyle(.tertiary)
			Text(message)
				.foregroundStyle(.secondary)
				.font(.title3)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
	}

	private func lifestyleCreatePlaceholder(
		icon: String,
		message: String,
		buttonTitle: String,
		action: @escaping () -> Void
	) -> some View {
		VStack(spacing: 14) {
			Image(systemName: icon)
				.font(.system(size: 40))
				.foregroundStyle(.tertiary)
			Text(message)
				.foregroundStyle(.secondary)
				.font(.title3)
			Button(buttonTitle, action: action)
				.buttonStyle(.borderedProminent)
		}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
	}

	private func performAutoBackup(at date: Date) {
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyyMMdd-HHmmss"
		let fileName = "\(AppBrand.autoBackupPrefix)\(formatter.string(from: date)).json"
		let backupRoot = resolvedWorkspaceDirectory().appendingPathComponent("Backups", isDirectory: true)

		do {
			let archive = try AppDataArchiveService.captureSnapshot(
				modelContext: modelContext,
				appState: appState
			)
			_ = try AppDataArchiveService.writeSnapshot(
				archive,
				toDirectory: backupRoot,
				fileName: fileName
			)
			appState.markAutoBackupCompleted(at: date)
		} catch {
			AppLogger.warning("Auto backup failed: \(error.localizedDescription)", category: "data")
		}
	}

	private func resolvedWorkspaceDirectory() -> URL {
		let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
			?? URL(fileURLWithPath: NSTemporaryDirectory())
		return AppBrand.migratedDirectory(
			in: documents,
			preferredPath: AppBrand.workspaceFolderName,
			legacyPath: AppBrand.legacyWorkspaceFolderName
		)
	}

	private func resetSelections() {
		selectedDashboardSnapshot = nil
		selectedInboxItem = nil
		selectedTask = nil
		selectedNote = nil
		selectedVitalsEntry = nil
		selectedLifestyleTab = .accounting
		selectedTransaction = nil
		selectedGoal = nil
		selectedConnection = nil
	}
}

private struct ExecutionEmptyDetailView: View {
	@Query private var tasks: [TaskItem]
	@Query private var projects: [ExecutionProject]

	private var activeTasks: [TaskItem] {
		tasks.filter { $0.archivedMonthKey == nil }
	}

	private var todoCount: Int {
		activeTasks.filter { $0.status == .todo }.count
	}

	private var inProgressCount: Int {
		activeTasks.filter { $0.status == .inProgress }.count
	}

	private var doneCount: Int {
		activeTasks.filter { $0.status == .done }.count
	}

	var body: some View {
		VStack(spacing: 18) {
			Image(systemName: "target")
				.font(.system(size: 42))
				.foregroundStyle(.tertiary)

			Text("选择任务查看详情")
				.font(.title3)
				.foregroundStyle(.secondary)

			Text("也可以从这里直接开始执行")
				.font(.subheadline)
				.foregroundStyle(.tertiary)

			HStack(spacing: 8) {
				ExecutionQuickChip(title: "待办", value: todoCount, color: .orange)
				ExecutionQuickChip(title: "进行中", value: inProgressCount, color: .blue)
				ExecutionQuickChip(title: "已完成", value: doneCount, color: .green)
				ExecutionQuickChip(title: "项目", value: projects.count, color: .teal)
			}

			HStack(spacing: 10) {
				Button {
					NotificationCenter.default.post(name: .nexaLifeExecutionCreateTask, object: nil)
				} label: {
					Label("新建任务", systemImage: "plus")
				}
				.buttonStyle(.borderedProminent)

				Button {
					NotificationCenter.default.post(name: .nexaLifeExecutionManageProjects, object: nil)
				} label: {
					Label("项目管理", systemImage: "folder.badge.gearshape")
				}
				.buttonStyle(.bordered)
			}
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.padding(20)
	}
}

private struct ExecutionQuickChip: View {
	let title: String
	let value: Int
	let color: Color

	var body: some View {
		HStack(spacing: 6) {
			Text(title)
			Text("\(value)")
				.bold()
		}
		.font(.caption)
		.padding(.horizontal, 10)
		.padding(.vertical, 4)
		.background(color.opacity(0.12))
		.foregroundStyle(color)
		.clipShape(Capsule())
	}
}

private struct GlobalSearchSheet: View {
	@EnvironmentObject private var appState: AppState
	@Environment(\.dismiss) private var dismiss
	@Environment(\.locale) private var locale
	@State private var query: String = ""

	private var filteredModules: [AppModule] {
		let keyword = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
		guard !keyword.isEmpty else { return AppModule.allCases }
		return AppModule.allCases.filter { module in
			module.preferenceLabel(for: locale).lowercased().contains(keyword)
				|| module.rawValue.lowercased().contains(keyword)
		}
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			Text("settings.global_search.title")
				.font(.title3.bold())

			TextField("settings.global_search.placeholder", text: $query)
				.textFieldStyle(.roundedBorder)

			Divider()

			ScrollView {
				VStack(alignment: .leading, spacing: 8) {
					ForEach(filteredModules) { module in
						Button {
							appState.updateModule(module)
							dismiss()
						} label: {
							HStack {
								Image(systemName: module.icon)
								Text(module.preferenceLabel(for: locale))
								Spacer()
							}
						}
						.buttonStyle(.plain)
						.padding(.horizontal, 10)
						.padding(.vertical, 8)
						.background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
					}
				}
			}

			HStack {
				Spacer()
				Button("settings.global_search.close") { dismiss() }
					.buttonStyle(.bordered)
			}
		}
		.padding(18)
		.frame(width: 420, height: 380)
	}
}
