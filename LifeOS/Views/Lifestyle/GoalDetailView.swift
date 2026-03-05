//
//  GoalDetailView.swift
//  LifeOS
//
//  Created by Lihong Gao on 2026-02-26.
//

import SwiftUI
import SwiftData
import Charts

private enum GoalTrackingRange: String, CaseIterable, Identifiable {
	case daily = "每日"
	case weekly = "每周"
	case monthly = "每月"
	case quarterly = "每季度"

	var id: String { rawValue }
}

private struct GoalTrackingPoint: Identifiable {
	let id = UUID()
	let label: String
	let progress: Double
	let checkIns: Int
	let endDate: Date
}

struct GoalDetailView: View {
	@Environment(\.modelContext) private var modelContext
	@Query(sort: \GoalMilestone.createdAt, order: .reverse) private var allMilestones: [GoalMilestone]
	@Query(sort: \GoalProgressEntry.recordedAt, order: .reverse) private var allProgressEntries: [GoalProgressEntry]

	@Binding var selectedGoal: Goal?
	@Bindable var goal: Goal

	@State private var newMilestoneTitle: String = ""
	@State private var progressNote: String = ""
	@State private var trackingRange: GoalTrackingRange = .weekly

	private let calendar = Calendar.current

	private var goalMilestones: [GoalMilestone] {
		allMilestones
			.filter { $0.goalID == goal.id }
			.sorted { $0.createdAt < $1.createdAt }
	}

	private var goalProgressEntries: [GoalProgressEntry] {
		allProgressEntries
			.filter { $0.goalID == goal.id }
			.sorted { $0.recordedAt < $1.recordedAt }
	}

	private var trackingPoints: [GoalTrackingPoint] {
		switch trackingRange {
		case .daily:
			return buildDailyPoints(days: 7)
		case .weekly:
			return buildWeeklyPoints(weeks: 8)
		case .monthly:
			return buildMonthlyPoints(months: 6)
		case .quarterly:
			return buildQuarterlyPoints(quarters: 4)
		}
	}

	private var milestoneCompletionRatio: String {
		guard !goalMilestones.isEmpty else { return "0/0" }
		let completed = goalMilestones.filter(\.isCompleted).count
		return "\(completed)/\(goalMilestones.count)"
	}

	private var milestoneCompletionRate: Double {
		guard !goalMilestones.isEmpty else { return 0 }
		return Double(goalMilestones.filter(\.isCompleted).count) / Double(goalMilestones.count)
	}

	private var displayedTrackingRange: ClosedRange<Date>? {
		guard
			let first = trackingPoints.first?.endDate,
			let last = trackingPoints.last?.endDate
		else {
			return nil
		}
		return first...last
	}

	private var checkInCountInCurrentRange: Int {
		guard let range = displayedTrackingRange else { return 0 }
		return goalProgressEntries.filter { range.contains($0.recordedAt) }.count
	}

	private var progressChangeInCurrentRange: Double {
		guard let range = displayedTrackingRange else { return 0 }
		let entries = goalProgressEntries.filter { range.contains($0.recordedAt) }
		guard let first = entries.first, let last = entries.last else { return 0 }
		return last.progress - first.progress
	}

	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 22) {
				TextField("目标标题", text: $goal.title)
					.font(.title.bold())
					.textFieldStyle(.plain)

				Divider()

				VStack(alignment: .leading, spacing: 14) {
					HStack(spacing: 12) {
						Label("状态", systemImage: "flag")
							.foregroundStyle(.secondary)
							.frame(width: 64, alignment: .leading)
						Toggle("已完成", isOn: $goal.isCompleted)
							.toggleStyle(.switch)
					}

					Toggle("设置截止日期", isOn: hasDueDateBinding)
						.font(.subheadline)
					if goal.dueDate != nil {
						DatePicker(
							"截止日期",
							selection: dueDateBinding,
							displayedComponents: .date
						)
						.datePickerStyle(.field)
					}

					DatePicker(
						"开始时间",
						selection: $goal.startDate,
						displayedComponents: [.date, .hourAndMinute]
					)
					.datePickerStyle(.field)

					VStack(alignment: .leading, spacing: 6) {
						Label("目标描述", systemImage: "text.alignleft")
							.font(.subheadline.weight(.semibold))
						TextEditor(text: $goal.targetDescription)
							.frame(height: 78)
							.padding(8)
							.background(Color(nsColor: .textBackgroundColor))
							.clipShape(RoundedRectangle(cornerRadius: 10))
							.overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.2)))
					}
				}

				Divider()

				VStack(alignment: .leading, spacing: 12) {
					HStack {
						Label("进度追踪", systemImage: "chart.line.uptrend.xyaxis")
							.font(.headline)
						Spacer()
						Text(String(format: "%.0f%%", goal.progress * 100))
							.font(.title2.bold())
							.foregroundStyle(.blue)
					}

					ProgressView(value: goal.progress, total: 1.0)
						.tint(goal.isCompleted ? .green : .blue)
						.scaleEffect(x: 1, y: 2)

					Slider(value: $goal.progress, in: 0...1, step: 0.05) {
						Text("进度")
					} minimumValueLabel: {
						Text("0%").font(.caption2)
					} maximumValueLabel: {
						Text("100%").font(.caption2)
					}

					HStack(spacing: 8) {
						ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { value in
							Button {
								withAnimation { goal.progress = value }
							} label: {
								Text(String(format: "%.0f%%", value * 100))
									.font(.caption)
									.frame(maxWidth: .infinity)
							}
							.buttonStyle(.bordered)
							.tint(goal.progress >= value ? .blue : .secondary)
						}
					}

					HStack(spacing: 8) {
						TextField("本次进展备注（可选）", text: $progressNote)
							.textFieldStyle(.roundedBorder)
						Button("记录当前进度") {
							recordProgressEntry()
						}
						.buttonStyle(.borderedProminent)
					}
				}

				Divider()

				VStack(alignment: .leading, spacing: 10) {
					HStack {
						Label("小目标拆分", systemImage: "checklist")
							.font(.headline)
						Spacer()
						Text("完成 \(milestoneCompletionRatio)")
							.font(.caption)
							.padding(.horizontal, 8)
							.padding(.vertical, 4)
							.background(Color.green.opacity(0.15))
							.clipShape(Capsule())
					}

					HStack(spacing: 8) {
						TextField("新增小目标", text: $newMilestoneTitle)
							.textFieldStyle(.roundedBorder)
						Button("添加") {
							addMilestone()
						}
						.buttonStyle(.bordered)
						.disabled(newMilestoneTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
					}

					if goalMilestones.isEmpty {
						Text("还没有小目标，建议拆分成可执行步骤。")
							.font(.caption)
							.foregroundStyle(.secondary)
					} else {
						VStack(spacing: 8) {
							ForEach(goalMilestones) { milestone in
								HStack(spacing: 10) {
									Toggle(
										"",
										isOn: Binding(
											get: { milestone.isCompleted },
											set: { milestone.isCompleted = $0 }
										)
									)
									.labelsHidden()
									TextField(
										"小目标内容",
										text: Binding(
											get: { milestone.title },
											set: { milestone.title = $0 }
										)
									)
									.textFieldStyle(.roundedBorder)
									if milestone.isCompleted {
										Image(systemName: "checkmark.circle.fill")
											.foregroundStyle(.green)
									}
									Button(role: .destructive) {
										modelContext.delete(milestone)
									} label: {
										Image(systemName: "trash")
									}
									.buttonStyle(.plain)
								}
							}
						}
					}
				}

				Divider()

				VStack(alignment: .leading, spacing: 12) {
					HStack {
						Label("周期 Tracking", systemImage: "chart.bar.xaxis")
							.font(.headline)
						Spacer()
						Picker("追踪粒度", selection: $trackingRange) {
							ForEach(GoalTrackingRange.allCases) { range in
								Text(range.rawValue).tag(range)
							}
						}
						.pickerStyle(.segmented)
						.frame(maxWidth: 360)
					}

					LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
						trackingMetricCard(
							title: "周期打卡",
							value: "\(checkInCountInCurrentRange)",
							subtitle: "当前 \(trackingRange.rawValue) 视角",
							color: .teal
						)
						trackingMetricCard(
							title: "进度变化",
							value: String(format: "%@%.0f%%", progressChangeInCurrentRange >= 0 ? "+" : "", progressChangeInCurrentRange * 100),
							subtitle: "区间首尾对比",
							color: progressChangeInCurrentRange >= 0 ? .blue : .orange
						)
						trackingMetricCard(
							title: "拆分完成率",
							value: String(format: "%.0f%%", milestoneCompletionRate * 100),
							subtitle: "小目标推进",
							color: .green
						)
					}

					if trackingPoints.allSatisfy({ $0.checkIns == 0 }) {
						RoundedRectangle(cornerRadius: 12)
							.fill(Color.gray.opacity(0.08))
							.frame(height: 180)
							.overlay(
								Label("暂无打卡记录，先点击“记录当前进度”", systemImage: "chart.xyaxis.line")
									.foregroundStyle(.secondary)
							)
					} else {
						Chart {
							ForEach(trackingPoints) { point in
								AreaMark(
									x: .value("周期", point.label),
									y: .value("进度", point.progress * 100)
								)
								.foregroundStyle(.blue.opacity(0.12))

								LineMark(
									x: .value("周期", point.label),
									y: .value("进度", point.progress * 100)
								)
								.foregroundStyle(.blue)
								.interpolationMethod(.catmullRom)

								PointMark(
									x: .value("周期", point.label),
									y: .value("进度", point.progress * 100)
								)
								.foregroundStyle(point.checkIns > 0 ? Color.blue : Color.secondary.opacity(0.4))
								.symbolSize(point.checkIns > 0 ? 60 : 30)
							}
						}
						.chartYScale(domain: 0...100)
						.chartYAxis {
							AxisMarks(position: .leading) { _ in
								AxisGridLine()
								AxisValueLabel()
							}
						}
						.frame(height: 200)
					}

					if !goalProgressEntries.isEmpty {
						VStack(alignment: .leading, spacing: 6) {
							Text("最近记录")
								.font(.caption)
								.foregroundStyle(.secondary)
							ForEach(goalProgressEntries.suffix(5).reversed()) { entry in
								HStack {
									Text(entry.recordedAt.formatted(date: .abbreviated, time: .shortened))
										.font(.caption2)
										.foregroundStyle(.secondary)
									Text(String(format: "%.0f%%", entry.progress * 100))
										.font(.caption)
									if !entry.note.isEmpty {
										Text(entry.note)
											.font(.caption2)
											.foregroundStyle(.secondary)
											.lineLimit(1)
									}
									Spacer()
								}
							}
						}
					}
				}

				Spacer()

				Button(role: .destructive) {
					deleteGoalAndRelatedData()
				} label: {
					Label("删除目标", systemImage: "trash")
						.frame(maxWidth: .infinity)
				}
				.buttonStyle(.bordered)
			}
			.padding(28)
		}
		.navigationTitle(goal.title.isEmpty ? "目标详情" : goal.title)
		.onChange(of: goal.progress) { _, newProgress in
			if newProgress >= 1 {
				goal.isCompleted = true
			} else if goal.isCompleted {
				goal.isCompleted = false
			}
		}
		.onChange(of: goal.isCompleted) { _, isCompleted in
			if isCompleted && goal.progress < 1 {
				goal.progress = 1
			}
		}
	}

	private var hasDueDateBinding: Binding<Bool> {
		Binding(
			get: { goal.dueDate != nil },
			set: { enabled in
				if enabled {
					goal.dueDate = goal.dueDate ?? Date()
				} else {
					goal.dueDate = nil
				}
			}
		)
	}

	private var dueDateBinding: Binding<Date> {
		Binding(
			get: { goal.dueDate ?? Date() },
			set: { goal.dueDate = $0 }
		)
	}

	private func trackingMetricCard(title: String, value: String, subtitle: String, color: Color) -> some View {
		VStack(alignment: .leading, spacing: 4) {
			Text(title)
				.font(.caption)
				.foregroundStyle(.secondary)
			Text(value)
				.font(.headline)
				.foregroundStyle(color)
			Text(subtitle)
				.font(.caption2)
				.foregroundStyle(.secondary)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(.horizontal, 10)
		.padding(.vertical, 8)
		.background(color.opacity(0.1))
		.clipShape(RoundedRectangle(cornerRadius: 10))
	}

	private func addMilestone() {
		let title = newMilestoneTitle.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !title.isEmpty else { return }
		modelContext.insert(GoalMilestone(goalID: goal.id, title: title))
		newMilestoneTitle = ""
	}

	private func recordProgressEntry() {
		let note = progressNote.trimmingCharacters(in: .whitespacesAndNewlines)
		modelContext.insert(
			GoalProgressEntry(
				goalID: goal.id,
				recordedAt: .now,
				progress: goal.progress,
				note: note
			)
		)
		progressNote = ""
	}

	private func deleteGoalAndRelatedData() {
		for milestone in goalMilestones {
			modelContext.delete(milestone)
		}
		for entry in goalProgressEntries {
			modelContext.delete(entry)
		}
		selectedGoal = nil
		modelContext.delete(goal)
	}

	private func progressBefore(_ date: Date) -> Double {
		goalProgressEntries.last(where: { $0.recordedAt < date })?.progress ?? 0
	}

	private func buildDailyPoints(days: Int) -> [GoalTrackingPoint] {
		let formatter = DateFormatter()
		formatter.dateFormat = "M/d"
		return (0..<days).reversed().compactMap { offset in
			guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { return nil }
			let start = calendar.startOfDay(for: date)
			guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return nil }
			let entries = goalProgressEntries.filter { $0.recordedAt >= start && $0.recordedAt < end }
			let progress = entries.last?.progress ?? progressBefore(end)
			return GoalTrackingPoint(
				label: formatter.string(from: start),
				progress: progress,
				checkIns: entries.count,
				endDate: end
			)
		}
	}

	private func buildWeeklyPoints(weeks: Int) -> [GoalTrackingPoint] {
		let formatter = DateFormatter()
		formatter.dateFormat = "M/d"
		return (0..<weeks).reversed().compactMap { offset in
			guard let anchor = calendar.date(byAdding: .weekOfYear, value: -offset, to: Date()),
				  let interval = calendar.dateInterval(of: .weekOfYear, for: anchor) else { return nil }
			let entries = goalProgressEntries.filter {
				$0.recordedAt >= interval.start && $0.recordedAt < interval.end
			}
			let progress = entries.last?.progress ?? progressBefore(interval.end)
			return GoalTrackingPoint(
				label: formatter.string(from: interval.start),
				progress: progress,
				checkIns: entries.count,
				endDate: interval.end
			)
		}
	}

	private func buildMonthlyPoints(months: Int) -> [GoalTrackingPoint] {
		let formatter = DateFormatter()
		formatter.dateFormat = "yy/MM"
		return (0..<months).reversed().compactMap { offset in
			guard let anchor = calendar.date(byAdding: .month, value: -offset, to: Date()),
				  let interval = calendar.dateInterval(of: .month, for: anchor) else { return nil }
			let entries = goalProgressEntries.filter {
				$0.recordedAt >= interval.start && $0.recordedAt < interval.end
			}
			let progress = entries.last?.progress ?? progressBefore(interval.end)
			return GoalTrackingPoint(
				label: formatter.string(from: interval.start),
				progress: progress,
				checkIns: entries.count,
				endDate: interval.end
			)
		}
	}

	private func buildQuarterlyPoints(quarters: Int) -> [GoalTrackingPoint] {
		return (0..<quarters).reversed().compactMap { offset in
			guard let anchor = calendar.date(byAdding: .month, value: -(offset * 3), to: Date()),
				  let quarterStart = startOfQuarter(for: anchor),
				  let quarterEnd = calendar.date(byAdding: .month, value: 3, to: quarterStart) else {
				return nil
			}
			let entries = goalProgressEntries.filter {
				$0.recordedAt >= quarterStart && $0.recordedAt < quarterEnd
			}
			let progress = entries.last?.progress ?? progressBefore(quarterEnd)
			let quarter = (calendar.component(.month, from: quarterStart) - 1) / 3 + 1
			let year = calendar.component(.year, from: quarterStart)
			return GoalTrackingPoint(
				label: "\(year)Q\(quarter)",
				progress: progress,
				checkIns: entries.count,
				endDate: quarterEnd
			)
		}
	}

	private func startOfQuarter(for date: Date) -> Date? {
		let components = calendar.dateComponents([.year, .month], from: date)
		guard let year = components.year, let month = components.month else { return nil }
		let startMonth = ((month - 1) / 3) * 3 + 1
		var normalized = DateComponents()
		normalized.year = year
		normalized.month = startMonth
		normalized.day = 1
		return calendar.date(from: normalized)
	}
}
