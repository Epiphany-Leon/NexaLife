//
//  AccountingView.swift
//  LifeOS
//
//  Created by Lihong Gao on 2026-02-26.
//

import SwiftUI
import SwiftData

private enum AccountingCategories {
	static let defaults: [String] = [
		"餐饮", "交通", "住房", "购物", "数码", "学习", "医疗", "旅行", "社交", "娱乐", "收入", "其他"
	]
}

struct AccountingView: View {
	@EnvironmentObject private var appState: AppState
	@Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]

	@Binding var selectedTransaction: Transaction?

	@State private var selectedCategory = "全部"
	@State private var searchText = ""
	@State private var isShowingFilterPicker = false

	private var globalCurrency: CurrencyCode {
		appState.selectedCurrencyCode
	}

	private var allCategories: [String] {
		let dynamic = transactions
			.map { $0.category.trimmingCharacters(in: .whitespacesAndNewlines) }
			.filter { !$0.isEmpty }
		let set = Set(AccountingCategories.defaults + dynamic)
		return ["全部"] + set.sorted()
	}

	private var categoryFilteredTransactions: [Transaction] {
		guard selectedCategory != "全部" else { return transactions }
		return transactions.filter { ($0.category.isEmpty ? "其他" : $0.category) == selectedCategory }
	}

	private var filteredTransactions: [Transaction] {
		let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !keyword.isEmpty else { return categoryFilteredTransactions }
		return categoryFilteredTransactions.filter { tx in
			let title = tx.title.trimmingCharacters(in: .whitespacesAndNewlines)
			let stream = tx.streamName.trimmingCharacters(in: .whitespacesAndNewlines)
			let category = tx.category.trimmingCharacters(in: .whitespacesAndNewlines)
			let note = tx.note.trimmingCharacters(in: .whitespacesAndNewlines)
			let amountText = String(format: "%.2f", abs(tx.amount))
			return title.localizedCaseInsensitiveContains(keyword)
				|| stream.localizedCaseInsensitiveContains(keyword)
				|| category.localizedCaseInsensitiveContains(keyword)
				|| note.localizedCaseInsensitiveContains(keyword)
				|| amountText.localizedCaseInsensitiveContains(keyword)
		}
	}

	private var monthlyTransactions: [Transaction] {
		let now = Date()
		return transactions.filter { Calendar.current.isDate($0.date, equalTo: now, toGranularity: .month) }
	}

	private var monthlyBudget: Double {
		max(0, appState.monthlyBudget)
	}

	private var monthlySpent: Double {
		abs(monthlyTransactions.map(convertedAmount).filter { $0 < 0 }.reduce(0, +))
	}

	private var monthlyIncome: Double {
		monthlyTransactions.map(convertedAmount).filter { $0 > 0 }.reduce(0, +)
	}

	private var monthlyBalance: Double {
		monthlyIncome - monthlySpent
	}

	var body: some View {
		VStack(spacing: 0) {
			header

			Divider()

			HStack(spacing: 10) {
				Text("分类筛选")
					.font(.caption)
					.foregroundStyle(.secondary)
				Button {
					isShowingFilterPicker = true
				} label: {
					HStack(spacing: 6) {
						Text(selectedCategory)
						Image(systemName: "chevron.down")
							.font(.caption)
					}
					.padding(.horizontal, 10)
					.padding(.vertical, 5)
					.background(Color(nsColor: .controlBackgroundColor))
					.clipShape(Capsule())
				}
				.buttonStyle(.plain)
				Spacer()
			}
			.padding(.horizontal, 12)
			.padding(.vertical, 8)

			HStack(spacing: 8) {
				Image(systemName: "magnifyingglass")
					.foregroundStyle(.secondary)
				TextField("搜索分类、标题、备注、金额…", text: $searchText)
					.textFieldStyle(.plain)
				if !searchText.isEmpty {
					Button {
						searchText = ""
					} label: {
						Image(systemName: "xmark.circle.fill")
							.foregroundStyle(.secondary)
					}
					.buttonStyle(.plain)
				}
			}
			.padding(.horizontal, 10)
			.padding(.vertical, 8)
			.background(Color(nsColor: .controlBackgroundColor))
			.clipShape(RoundedRectangle(cornerRadius: 8))
			.padding(.horizontal, 12)
			.padding(.bottom, 8)

			Divider()

			List(selection: $selectedTransaction) {
				if filteredTransactions.isEmpty {
					ContentUnavailableView(
						"还没有记录",
						systemImage: "yensign.circle",
						description: Text("点击右上角记一笔后，在右侧详情编辑")
					)
				} else {
					ForEach(filteredTransactions) { tx in
						TransactionRowView(
							transaction: tx,
							displayAmount: convertedAmount(tx),
							displayCurrency: globalCurrency
						)
						.tag(tx)
					}
				}
			}
		}
		.sheet(isPresented: $isShowingFilterPicker) {
			AccountingCategoryPickerSheet(
				isPresented: $isShowingFilterPicker,
				title: "选择筛选分类",
				categories: allCategories,
				selectedCategory: $selectedCategory
			)
		}
	}

	private var header: some View {
		VStack(spacing: 10) {
			LazyVGrid(
				columns: [GridItem(.flexible()), GridItem(.flexible())],
				spacing: 8
			) {
				AccountingMetricCard(
					title: "月度预算",
					value: CurrencyService.format(monthlyBudget, currency: globalCurrency, showSign: false),
					color: .blue
				)
				AccountingMetricCard(
					title: "实际支出",
					value: CurrencyService.format(monthlySpent, currency: globalCurrency, showSign: false),
					color: .red
				)
				AccountingMetricCard(
					title: "收入",
					value: CurrencyService.format(monthlyIncome, currency: globalCurrency, showSign: false),
					color: .green
				)
				AccountingMetricCard(
					title: "净收支",
					value: CurrencyService.format(monthlyBalance, currency: globalCurrency),
					color: monthlyBalance >= 0 ? .teal : .orange
				)
			}
		}
		.padding(.horizontal, 12)
		.padding(.vertical, 10)
		.background(Color(nsColor: .windowBackgroundColor))
	}

	private func convertedAmount(_ transaction: Transaction) -> Double {
		let source = CurrencyCode(rawValue: transaction.currencyCode) ?? .CNY
		return CurrencyService.convert(transaction.amount, from: source, to: globalCurrency)
	}

}

private struct AccountingMetricCard: View {
	var title: String
	var value: String
	var color: Color

	var body: some View {
		VStack(alignment: .leading, spacing: 4) {
			Text(title)
				.font(.caption)
				.foregroundStyle(.secondary)
				.lineLimit(1)
			Text(value)
				.font(.system(size: 20, weight: .bold))
				.foregroundStyle(color)
				.lineLimit(1)
				.minimumScaleFactor(0.75)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(.horizontal, 10)
		.padding(.vertical, 8)
		.background(color.opacity(0.08))
		.clipShape(RoundedRectangle(cornerRadius: 10))
	}
}

private struct TransactionRowView: View {
	var transaction: Transaction
	var displayAmount: Double
	var displayCurrency: CurrencyCode

	private var sourceCurrency: CurrencyCode {
		CurrencyCode(rawValue: transaction.currencyCode) ?? .CNY
	}

	private var displayTitle: String {
		let title = transaction.title.trimmingCharacters(in: .whitespacesAndNewlines)
		if !title.isEmpty { return title }
		if !transaction.streamName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
			return transaction.streamName
		}
		return transaction.category.isEmpty ? "未命名" : transaction.category
	}

	var body: some View {
		HStack(spacing: 12) {
			ZStack {
				Circle()
					.fill(transaction.amount >= 0 ? Color.green.opacity(0.12) : Color.red.opacity(0.12))
					.frame(width: 36, height: 36)
				Image(systemName: transaction.amount >= 0 ? "plus.circle" : "minus.circle")
					.foregroundStyle(transaction.amount >= 0 ? Color.green : Color.red)
			}

			VStack(alignment: .leading, spacing: 3) {
				Text(displayTitle)
					.font(.body)
					.lineLimit(1)
				if !transaction.category.isEmpty {
					Text(transaction.category)
						.font(.caption)
						.foregroundStyle(.secondary)
				}
				HStack(spacing: 6) {
					Text(transaction.date, style: .date)
						.font(.caption2)
						.foregroundStyle(.tertiary)
					Text("·")
						.font(.caption2)
						.foregroundStyle(.tertiary)
					Text(sourceCurrency.rawValue)
						.font(.caption2)
						.foregroundStyle(.tertiary)
				}
			}

			Spacer()

			Text(CurrencyService.format(displayAmount, currency: displayCurrency))
				.font(.system(size: 18, weight: .bold))
				.foregroundStyle(displayAmount >= 0 ? Color.green : Color.red)
		}
		.padding(.vertical, 4)
	}
}

struct AccountingTransactionDetailView: View {
	@Environment(\.modelContext) private var modelContext
	@Binding var selectedTransaction: Transaction?
	@Bindable var transaction: Transaction

	@State private var amountText: String = ""
	@State private var isExpense: Bool = true
	@State private var category: String = ""
	@State private var title: String = ""
	@State private var note: String = ""
	@State private var date: Date = .now
	@State private var currencyCode: String = CurrencyCode.CNY.rawValue
	@State private var isShowingCategoryPicker = false

	private var categories: [String] {
		AccountingCategories.defaults
	}

	private var transactionCurrency: CurrencyCode {
		CurrencyCode(rawValue: currencyCode) ?? .CNY
	}

	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 16) {
				HStack {
					Text("财务条目详情")
						.font(.title3.bold())
					Spacer()
					Button("保存") {
						saveChanges()
					}
					.buttonStyle(.borderedProminent)
					.controlSize(.small)
				}

				Picker("类型", selection: $isExpense) {
					Text("支出").tag(true)
					Text("收入").tag(false)
				}
				.pickerStyle(.segmented)

				HStack(spacing: 10) {
					Text(isExpense ? "-" : "+")
						.font(.system(size: 26, weight: .black))
						.foregroundStyle(isExpense ? .red : .green)
					Text(transactionCurrency.symbol)
						.font(.system(size: 26, weight: .black))
					TextField("金额", text: $amountText)
						.font(.system(size: 24, weight: .bold))
						.textFieldStyle(.roundedBorder)
						.frame(width: 180)

					Picker("币种", selection: $currencyCode) {
						ForEach(CurrencyCode.allCases) { code in
							Text(code.displayName).tag(code.rawValue)
						}
					}
					.pickerStyle(.menu)
				}

				LabeledContent("分类") {
					Button {
						isShowingCategoryPicker = true
					} label: {
						HStack {
							Text(category.isEmpty ? "选择分类" : category)
							Spacer()
							Image(systemName: "chevron.down")
						}
						.padding(.horizontal, 10)
						.padding(.vertical, 6)
						.background(Color(nsColor: .controlBackgroundColor))
						.clipShape(RoundedRectangle(cornerRadius: 8))
					}
					.buttonStyle(.plain)
				}

				TextField("标题", text: $title)
					.textFieldStyle(.roundedBorder)

				TextField("备注", text: $note, axis: .vertical)
					.lineLimit(3...5)
					.textFieldStyle(.roundedBorder)

				DatePicker("日期", selection: $date, displayedComponents: .date)

				Button(role: .destructive) {
					selectedTransaction = nil
					modelContext.delete(transaction)
				} label: {
					Label("删除条目", systemImage: "trash")
						.frame(maxWidth: .infinity)
				}
				.buttonStyle(.bordered)
			}
			.padding(24)
		}
		.sheet(isPresented: $isShowingCategoryPicker) {
			AccountingCategoryPickerSheet(
				isPresented: $isShowingCategoryPicker,
				title: "选择分类",
				categories: categories,
				selectedCategory: $category
			)
		}
		.onAppear {
			loadFromTransaction()
		}
		.onChange(of: transaction.id) { _, _ in
			loadFromTransaction()
		}
	}

	private func loadFromTransaction() {
		amountText = String(format: "%.2f", abs(transaction.amount))
		isExpense = transaction.amount < 0
		category = transaction.category.isEmpty ? "其他" : transaction.category
		title = transaction.title.isEmpty ? transaction.streamName : transaction.title
		note = transaction.note
		date = transaction.date
		currencyCode = transaction.currencyCode
	}

	private func saveChanges() {
		let parsed = Double(amountText) ?? 0
		transaction.amount = isExpense ? -abs(parsed) : abs(parsed)
		transaction.category = category.trimmingCharacters(in: .whitespacesAndNewlines)
		transaction.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
		transaction.note = note
		transaction.date = date
		transaction.currencyCode = currencyCode
	}
}

struct AccountingCategoryPickerSheet: View {
	@Binding var isPresented: Bool
	let title: String
	let categories: [String]
	@Binding var selectedCategory: String

	@State private var searchText = ""

	private var filteredCategories: [String] {
		let source = categories.isEmpty ? ["其他"] : categories
		guard !searchText.isEmpty else { return source }
		return source.filter { $0.localizedCaseInsensitiveContains(searchText) }
	}

	var body: some View {
		VStack(spacing: 12) {
			HStack {
				Text(title)
					.font(.headline)
				Spacer()
				Button("关闭") { isPresented = false }
					.buttonStyle(.plain)
			}

			TextField("搜索分类…", text: $searchText)
				.textFieldStyle(.roundedBorder)

				List(filteredCategories, id: \.self) { (category: String) in
					Button {
						selectedCategory = category
						isPresented = false
					} label: {
						HStack {
							Text(category)
							Spacer()
							if selectedCategory == category {
								Image(systemName: "checkmark")
									.foregroundColor(.accentColor)
							}
						}
					}
					.buttonStyle(.plain)
				}
		}
		.padding(16)
		.frame(width: 320, height: 360)
	}
}
