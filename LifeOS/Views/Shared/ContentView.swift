//
//  ContentView.swift
//  LifeOS
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
					Label("捕捉闪念", systemImage: "plus.circle.fill")
				}
				.keyboardShortcut("n", modifiers: [.command, .shift])
			}
		}
		.sheet(isPresented: $isShowingQuickInput) {
			QuickInputSheet(isPresented: $isShowingQuickInput)
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
			KnowledgeView()
		case .lifestyle:
			LifestyleView(
				selectedTab: $selectedLifestyleTab,
				selectedTransaction: $selectedTransaction,
				selectedGoal: $selectedGoal,
				selectedConnection: $selectedConnection
			)
		case .vitals:
			VitalsView()
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
				placeholderView(icon: "tray", message: "选择条目查看详情")
			}
		case .execution:
			if let task = selectedTask {
				TaskDetailView(selectedTask: $selectedTask, task: task)
			} else {
				placeholderView(icon: "target", message: "选择任务查看详情")
			}
		case .knowledge:
			if let note = selectedNote {
				NoteDetailView(note: note)
			} else {
				placeholderView(icon: "book", message: "选择笔记开始阅读")
			}
		case .vitals:
			if let entry = selectedVitalsEntry {
				VitalsDetailView(entry: entry)
			} else {
				placeholderView(icon: "sparkles", message: "选择记录查看详情")
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
}
