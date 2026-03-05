//
//  LifestyleView.swift
//  LifeOS
//
//  Created by Lihong Gao on 2026-02-26.
//

import SwiftUI
import SwiftData

enum LifestyleTab: String, CaseIterable {
	case accounting  = "账务"
	case goals       = "目标"
	case connections = "人脉"

	var icon: String {
		switch self {
		case .accounting:  return "yensign.circle"
		case .goals:       return "flag.checkered"
		case .connections: return "person.2"
		}
	}
}

struct LifestyleView: View {
	@Binding var selectedTab: LifestyleTab
	@Binding var selectedTransaction: Transaction?
	@Binding var selectedGoal: Goal?
	@Binding var selectedConnection: Connection?

	var body: some View {
		VStack(spacing: 0) {
			HStack {
				Picker("子模块", selection: $selectedTab) {
					ForEach(LifestyleTab.allCases, id: \.self) { tab in
						Label(tab.rawValue, systemImage: tab.icon).tag(tab)
					}
				}
				.pickerStyle(.menu)
				.labelsHidden()
				.frame(width: 180, alignment: .leading)

				Label(selectedTab.rawValue, systemImage: selectedTab.icon)
					.font(.subheadline)
					.foregroundStyle(.secondary)

				Spacer()
			}
			.padding(.horizontal, 16)
			.padding(.vertical, 10)
			.background(Color(nsColor: .windowBackgroundColor))

			Divider()

			switch selectedTab {
			case .accounting:
				AccountingView(selectedTransaction: $selectedTransaction)
			case .goals:
				GoalView(selectedGoal: $selectedGoal)
			case .connections:
				ConnectionView(selectedConnection: $selectedConnection)
			}
		}
		.navigationTitle("生活 Lifestyle")
		.navigationSplitViewColumnWidth(min: 360, ideal: 480, max: 620)
		.onChange(of: selectedTab) { _, tab in
			switch tab {
			case .accounting:
				selectedGoal = nil
				selectedConnection = nil
			case .goals:
				selectedTransaction = nil
				selectedConnection = nil
			case .connections:
				selectedTransaction = nil
				selectedGoal = nil
			}
		}
	}
}
