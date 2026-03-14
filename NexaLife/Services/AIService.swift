//
//  AIService.swift
//  NexaLife
//
//  Created by Lihong Gao on 2026-02-26.
//
//  AIService.swift

import Foundation
import Combine

struct TaskMetadataSuggestion: Equatable {
	var category: String
	var tags: [String]
	var projectName: String
}

struct ConnectionInsight: Equatable {
	var importance: Int           // 1~5
	var attitude: String
	var reason: String
	var nextAction: String
	var keySignals: [String]
}

struct InboxHandlingSuggestion: Equatable {
	var module: AppModule
	var headline: String
	var reason: String
}

private struct TaskMetadataAIResponse: Decodable {
	var category: String?
	var tags: [String]?
	var projectName: String?
}

private struct ConnectionInsightAIResponse: Decodable {
	var importance: Int?
	var attitude: String?
	var reason: String?
	var nextAction: String?
	var keySignals: [String]?
}

private struct InboxHandlingAIResponse: Decodable {
	var module: String?
	var headline: String?
	var reason: String?
}

private enum TaskSuggestionEngine {
	private struct Rule {
		let category: String
		let keywords: [String]
		let tags: [String]
	}

	private static let rules: [Rule] = [
		Rule(
			category: "工作",
			keywords: ["meeting", "会议", "汇报", "复盘", "交付", "客户", "需求", "roadmap", "milestone", "kpi"],
			tags: ["工作", "协作"]
		),
		Rule(
			category: "学习",
			keywords: ["学习", "读书", "课程", "整理", "总结", "note", "notes", "study", "research"],
			tags: ["学习", "沉淀"]
		),
		Rule(
			category: "产品",
			keywords: ["产品", "设计", "原型", "迭代", "版本", "体验", "需求池", "feature", "ux", "ui"],
			tags: ["产品", "迭代"]
		),
		Rule(
			category: "开发",
			keywords: ["开发", "编码", "调试", "上线", "修复", "重构", "api", "bug", "test", "release", "deploy"],
			tags: ["开发", "交付"]
		),
		Rule(
			category: "运营",
			keywords: ["运营", "增长", "活动", "推广", "转化", "留存", "内容", "campaign"],
			tags: ["运营", "增长"]
		),
		Rule(
			category: "个人",
			keywords: ["生活", "家务", "健康", "运动", "体检", "旅行", "家庭", "personal", "fitness"],
			tags: ["个人", "生活"]
		)
	]

	private static let moduleRules: [(AppModule, [String])] = [
		(.execution, ["待办", "任务", "项目", "截止", "计划", "执行", "安排", "todo", "deadline", "deliver"]),
		(.knowledge, ["学习", "笔记", "复盘", "总结", "读书", "知识", "note", "learn", "study"]),
		(.lifestyle, ["消费", "支出", "预算", "收入", "工资", "报销", "转账", "付款", "收款", "账单", "记账", "花了", "买了", "餐饮", "交通", "房租", "旅行", "社交", "理财", "money", "budget", "expense", "income", "finance", "payment"]),
		(.vitals, ["情绪", "反思", "焦虑", "动力", "灵感", "价值观", "心理", "mood", "reflect"])
	]

	static func moduleSuggestion(for text: String) -> AppModule {
		let normalized = text.lowercased()
		var bestModule: AppModule = .inbox
		var bestScore = 0
		for (module, keywords) in moduleRules {
			let score = keywords.reduce(into: 0) { partial, word in
				if normalized.contains(word) { partial += 1 }
			}
			if score > bestScore {
				bestScore = score
				bestModule = module
			}
		}
		return bestScore == 0 ? .inbox : bestModule
	}

	static func suggestTaskMetadata(
		title: String,
		notes: String,
		existingProjects: [String],
		currentProject: String = "",
		locale: Locale
	) -> TaskMetadataSuggestion {
		let trimmedProject = currentProject.trimmingCharacters(in: .whitespacesAndNewlines)
		let content = "\(title) \(notes)".lowercased()

		let inferredCategory = inferCategory(from: content)
		let inferredTags = inferTags(from: content, category: inferredCategory)
		let inferredProject = inferProject(
			title: title,
			content: content,
			existingProjects: existingProjects,
			currentProject: trimmedProject
		)

		return TaskMetadataSuggestion(
			category: localizedCategory(inferredCategory, locale: locale),
			tags: localizedTags(inferredTags, locale: locale),
			projectName: inferredProject
		)
	}

	private static func inferCategory(from content: String) -> String {
		var bestCategory = "通用"
		var bestScore = 0

		for rule in rules {
			let score = rule.keywords.reduce(into: 0) { partial, word in
				if content.contains(word.lowercased()) { partial += 1 }
			}
			if score > bestScore {
				bestScore = score
				bestCategory = rule.category
			}
		}

		return bestCategory
	}

	private static func inferTags(from content: String, category: String) -> [String] {
		var tags: [String] = []
		if let matchedRule = rules.first(where: { $0.category == category }) {
			tags.append(contentsOf: matchedRule.tags)
		}

		let extraTagRules: [(String, String)] = [
			("紧急", "紧急"),
			("urgent", "紧急"),
			("本周", "本周"),
			("today", "今日"),
			("今天", "今日"),
			("review", "复盘"),
			("复盘", "复盘"),
			("计划", "规划"),
			("写作", "写作"),
			("沟通", "沟通"),
			("会议", "会议"),
			("文档", "文档")
		]

		for (keyword, tag) in extraTagRules where content.contains(keyword) {
			tags.append(tag)
		}

		return normalizeTags(tags)
	}

	private static func inferProject(
		title: String,
		content: String,
		existingProjects: [String],
		currentProject: String
	) -> String {
		if !currentProject.isEmpty { return currentProject }

		var bestProject = ""
		var bestScore = 0

		for original in existingProjects {
			let project = original.trimmingCharacters(in: .whitespacesAndNewlines)
			guard !project.isEmpty, project != "收件箱" else { continue }

			let lowered = project.lowercased()
			var score = 0
			if content.contains(lowered) { score += 4 }

			let words = lowered
				.components(separatedBy: CharacterSet.alphanumerics.inverted)
				.filter { $0.count >= 2 }
			for word in words where content.contains(word) {
				score += 1
			}

			if score > bestScore {
				bestScore = score
				bestProject = project
			}
		}

		if bestScore > 0 { return bestProject }

		let separators = ["：", ":", "-", "｜", "|"]
		for separator in separators {
			let parts = title.components(separatedBy: separator)
			if let first = parts.first?.trimmingCharacters(in: .whitespacesAndNewlines),
			   !first.isEmpty, first.count <= 20 {
				return first
			}
		}

		return "收件箱"
	}

	static func normalizeTags(_ tags: [String]) -> [String] {
		var seen: Set<String> = []
		var normalized: [String] = []
		for raw in tags {
			let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
			guard !value.isEmpty, !seen.contains(value) else { continue }
			seen.insert(value)
			normalized.append(value)
		}
		return Array(normalized.prefix(5))
	}

	private static func localizedCategory(_ category: String, locale: Locale) -> String {
		guard !locale.isChineseInterface else { return category }
		switch category {
		case "工作": return "Work"
		case "学习": return "Learning"
		case "产品": return "Product"
		case "开发": return "Engineering"
		case "运营": return "Operations"
		case "个人": return "Personal"
		default: return "General"
		}
	}

	private static func localizedTags(_ tags: [String], locale: Locale) -> [String] {
		guard !locale.isChineseInterface else { return tags }
		let map: [String: String] = [
			"工作": "Work",
			"协作": "Collaboration",
			"学习": "Learning",
			"沉淀": "Synthesis",
			"产品": "Product",
			"迭代": "Iteration",
			"开发": "Engineering",
			"交付": "Delivery",
			"运营": "Operations",
			"增长": "Growth",
			"个人": "Personal",
			"生活": "Life",
			"紧急": "Urgent",
			"本周": "This Week",
			"今日": "Today",
			"复盘": "Review",
			"规划": "Planning",
			"写作": "Writing",
			"沟通": "Communication",
			"会议": "Meeting",
			"文档": "Docs"
		]
		return tags.map { map[$0] ?? $0 }
	}
}

private enum ConnectionInsightEngine {
	static func fallback(
		name: String,
		relationship: String,
		notes: String,
		lastContactDate: Date?,
		question: String,
		locale: Locale
	) -> ConnectionInsight {
		let content = "\(name) \(relationship) \(notes) \(question)".lowercased()
		let isCore =
			["合伙", "核心", "投资", "家人", "partner", "mentor", "导师", "老板", "客户"].contains { content.contains($0) }
		let isWeak =
			["泛泛", "普通", "弱", "一般", "一般认识", "社群", "群友"].contains { content.contains($0) }

		var importance = isCore ? 4 : 3
		if isWeak { importance = 2 }
		if let date = lastContactDate {
			let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
			if days > 90 { importance = max(2, importance - 1) }
		}
		importance = min(5, max(1, importance))

		let attitude: String
		switch importance {
		case 5:
			attitude = AppBrand.localized("高信任 + 高频沟通，优先维护", "High trust and frequent communication. Maintain this relationship first.", locale: locale)
		case 4:
			attitude = AppBrand.localized("稳定投入，围绕互惠价值保持联系", "Invest consistently and keep contact around mutual value.", locale: locale)
		case 3:
			attitude = AppBrand.localized("保持温和连接，按周期跟进", "Keep a warm connection and follow up on a steady cadence.", locale: locale)
		default:
			attitude = AppBrand.localized("轻量维护，避免过度投入", "Maintain lightly and avoid over-investing.", locale: locale)
		}

		let reason = AppBrand.localized(
			"关系标签「\(relationship.isEmpty ? "未填写" : relationship)」与近况信息有限，已基于当前文本进行保守评估。",
			"The relationship label \"\(relationship.isEmpty ? "Not provided" : relationship)\" and recent context are limited, so this is a conservative assessment based on the current text.",
			locale: locale
		)

		let nextAction: String
		if let date = lastContactDate {
			let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
			nextAction = days > 30
				? AppBrand.localized("在 48 小时内发送一次近况问候并提出一个具体可帮忙点。", "Send a quick check-in within 48 hours and offer one concrete way to help.", locale: locale)
				: AppBrand.localized("维持当前沟通节奏，下一次沟通聚焦双方共同目标。", "Keep the current cadence and focus the next conversation on shared goals.", locale: locale)
		} else {
			nextAction = AppBrand.localized("先建立最近联系记录，再决定跟进频率。建议先发一条简短近况问候。", "Record a recent touchpoint first, then decide the cadence. Start with a short check-in.", locale: locale)
		}

		return ConnectionInsight(
			importance: importance,
			attitude: attitude,
			reason: reason,
			nextAction: nextAction,
			keySignals: locale.isChineseInterface
				? ["关系角色", "最近联系间隔", "备注关键词"]
				: ["Role", "Days Since Contact", "Note Keywords"]
		)
	}
}

private enum InboxSuggestionEngine {
	static func fallback(for text: String, locale: Locale) -> InboxHandlingSuggestion {
		let module = TaskSuggestionEngine.moduleSuggestion(for: text)
		switch module {
		case .execution:
			return InboxHandlingSuggestion(
				module: .execution,
				headline: AppBrand.localized("建议转成执行任务", "Turn this into an execution task", locale: locale),
				reason: AppBrand.localized("文本更像待办、计划或提醒，适合进入 Execution 继续拆解。", "This reads like a task, plan, or reminder, so Execution is the best next stop.", locale: locale)
			)
		case .knowledge:
			return InboxHandlingSuggestion(
				module: .knowledge,
				headline: AppBrand.localized("建议沉淀为知识笔记", "Capture this as a knowledge note", locale: locale),
				reason: AppBrand.localized("文本带有学习、总结或记录属性，进入 Knowledge 更容易继续补充。", "This looks like learning, synthesis, or documentation, so Knowledge will be easier to extend.", locale: locale)
			)
		case .lifestyle:
			return InboxHandlingSuggestion(
				module: .lifestyle,
				headline: AppBrand.localized("建议归入生活模块", "Move this into Lifestyle", locale: locale),
				reason: AppBrand.localized("内容偏向消费、目标、人脉或生活事务，适合在 Lifestyle 继续处理。", "This points to spending, goals, relationships, or life operations, so Lifestyle is a better fit.", locale: locale)
			)
		case .vitals:
			return InboxHandlingSuggestion(
				module: .vitals,
				headline: AppBrand.localized("建议沉淀到 Vitals", "Capture this in Vitals", locale: locale),
				reason: AppBrand.localized("文本更像情绪、反思或核心守则记录，留在 Vitals 更自然。", "This reads more like emotion, reflection, or a principle, so Vitals is the most natural place.", locale: locale)
			)
		case .dashboard, .inbox:
			return InboxHandlingSuggestion(
				module: .inbox,
				headline: AppBrand.localized("先留在收件箱", "Keep it in the inbox for now", locale: locale),
				reason: AppBrand.localized("当前信息还不够明确，建议补全上下文后再决定转移方向。", "The context is still too thin. Add more detail before moving it elsewhere.", locale: locale)
			)
		}
	}
}

@MainActor
class AIService: ObservableObject {

	enum AIProvider: String {
		case deepseek = "https://api.deepseek.com/v1/chat/completions"
		case qwen     = "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions"
	}

	var provider: AIProvider {
		let raw = UserDefaults.standard.string(forKey: "aiProvider") ?? "deepseek"
		return raw == "qwen" ? .qwen : .deepseek
	}

	var apiKey: String {
		AICredentialStore.readAPIKey()
	}

	var isConfigured: Bool { !apiKey.isEmpty }

	private var interfaceLocale: Locale {
		let stored = UserDefaults.standard.string(forKey: "appLanguagePreference") ?? AppLanguagePreference.system.rawValue
		switch stored {
		case AppLanguagePreference.simplifiedChinese.rawValue:
			return Locale(identifier: AppLanguagePreference.simplifiedChinese.rawValue)
		case AppLanguagePreference.english.rawValue:
			return Locale(identifier: AppLanguagePreference.english.rawValue)
		default:
			return .autoupdatingCurrent
		}
	}

	// MARK: - 自动归类
	func classifyText(_ text: String) async -> AppModule {
		let locale = interfaceLocale
		let fallback = TaskSuggestionEngine.moduleSuggestion(for: text)
		guard isConfigured else {
			return fallback
		}
		let prompt = locale.isChineseInterface
			? """
			你是 NexaLife 的智能助手。根据以下文本，判断最适合归入哪个象限。
			- Execution：任务、待办、计划、项目、提醒
			- Knowledge：笔记、学习、想法、文章、读书
			- Lifestyle：消费、金钱、社交、目标、生活事务
			- Vitals：情绪、反思、心理、价值观、核心守则
			- Inbox：无法判断

			文本："\(text)"
			只回答一个英文单词：Execution / Knowledge / Lifestyle / Vitals / Inbox
			"""
			: """
			You are the intelligent assistant for NexaLife. Classify the following text into the most suitable module.
			- Execution: tasks, plans, projects, reminders
			- Knowledge: notes, learning, ideas, articles, reading
			- Lifestyle: spending, money, relationships, goals, life operations
			- Vitals: emotions, reflection, psychology, values, principles
			- Inbox: cannot determine yet

			Text: "\(text)"
			Reply with one word only: Execution / Knowledge / Lifestyle / Vitals / Inbox
			"""
		guard let response = await callAPI(prompt: prompt, maxTokens: 20) else { return fallback }
		return AppModule(rawValue: response.trimmingCharacters(in: .whitespacesAndNewlines)) ?? fallback
	}

	func suggestTaskMetadata(
		title: String,
		notes: String,
		existingProjects: [String],
		currentProject: String = ""
	) async -> TaskMetadataSuggestion {
		let locale = interfaceLocale
		let fallback = TaskSuggestionEngine.suggestTaskMetadata(
			title: title,
			notes: notes,
			existingProjects: existingProjects,
			currentProject: currentProject,
			locale: locale
		)

		guard isConfigured else { return fallback }

		let projectList = existingProjects
			.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
			.filter { !$0.isEmpty && $0 != "收件箱" }

		let prompt = locale.isChineseInterface
			? """
			你是任务管理助手，请基于输入内容生成执行任务元数据。
			输出 JSON 对象，禁止输出其他文本，结构如下：
			{"category":"分类名","tags":["tag1","tag2"],"projectName":"项目名或收件箱"}

			要求：
			1) category 要简短，中文 2-6 字
			2) tags 返回 2-5 个短标签
			3) projectName 如果无法判断，返回“收件箱”
			4) 可选项目池：\(projectList.joined(separator: "、"))

			任务标题：\(title)
			任务备注：\(notes)
			"""
			: """
			You are a task-management assistant. Generate metadata for this execution task.
			Return JSON only with this structure:
			{"category":"Category","tags":["tag1","tag2"],"projectName":"Project name or 收件箱"}

			Rules:
			1) category should be short and clear
			2) return 2-5 short tags
			3) if no project is clear, return "收件箱"
			4) available project pool: \(projectList.joined(separator: ", "))

			Title: \(title)
			Notes: \(notes)
			"""

		guard
			let response = await callAPI(prompt: prompt, maxTokens: 180),
			let jsonString = extractJSONObject(from: response),
			let data = jsonString.data(using: .utf8),
			let parsed = try? JSONDecoder().decode(TaskMetadataAIResponse.self, from: data)
		else {
			return fallback
		}

		let category = parsed.category?
			.trimmingCharacters(in: .whitespacesAndNewlines)
			.nonEmpty ?? fallback.category

		let tags = TaskSuggestionEngine.normalizeTags(parsed.tags ?? [])
		let finalTags = tags.isEmpty ? fallback.tags : tags

		let project = parsed.projectName?
			.trimmingCharacters(in: .whitespacesAndNewlines)
			.nonEmpty ?? fallback.projectName

		return TaskMetadataSuggestion(
			category: category,
			tags: finalTags,
			projectName: project
		)
	}

	func analyzeConnection(
		name: String,
		relationship: String,
		notes: String,
		lastContactDate: Date?,
		question: String
	) async -> ConnectionInsight {
		let locale = interfaceLocale
		let fallback = ConnectionInsightEngine.fallback(
			name: name,
			relationship: relationship,
			notes: notes,
			lastContactDate: lastContactDate,
			question: question,
			locale: locale
		)

		guard isConfigured else { return fallback }

		let dateText = lastContactDate?.formatted(date: .abbreviated, time: .omitted)
			?? AppBrand.localized("未记录", "Not recorded", locale: locale)
		let prompt = locale.isChineseInterface
			? """
			你是人脉策略顾问，请基于输入判断关系重要性与互动策略。
			仅输出 JSON，不要输出其他文本：
			{"importance":1-5,"attitude":"一句话策略","reason":"40字内依据","nextAction":"下一步动作","keySignals":["信号1","信号2"]}

			要求：
			1) importance 必须是 1 到 5 的整数
			2) attitude 强调“我该如何对待此人”
			3) nextAction 必须可执行并具体
			4) keySignals 返回 2-4 个关键词

			姓名：\(name)
			关系：\(relationship)
			最近联系：\(dateText)
			备注：\(notes)
			我的问题：\(question)
			"""
			: """
			You are a relationship strategy advisor. Judge the importance of this relationship and suggest how to handle it.
			Return JSON only:
			{"importance":1-5,"attitude":"one-line strategy","reason":"reason in under 40 words","nextAction":"next step","keySignals":["signal1","signal2"]}

			Rules:
			1) importance must be an integer from 1 to 5
			2) attitude should answer how I should approach this person
			3) nextAction must be concrete and executable
			4) keySignals should include 2-4 short keywords

			Name: \(name)
			Relationship: \(relationship)
			Last Contact: \(dateText)
			Notes: \(notes)
			My Question: \(question)
			"""

		guard
			let response = await callAPI(prompt: prompt, maxTokens: 260),
			let jsonString = extractJSONObject(from: response),
			let data = jsonString.data(using: .utf8),
			let parsed = try? JSONDecoder().decode(ConnectionInsightAIResponse.self, from: data)
		else {
			return fallback
		}

		let importance = min(5, max(1, parsed.importance ?? fallback.importance))
		let attitude = parsed.attitude?
			.trimmingCharacters(in: .whitespacesAndNewlines)
			.nonEmpty ?? fallback.attitude
		let reason = parsed.reason?
			.trimmingCharacters(in: .whitespacesAndNewlines)
			.nonEmpty ?? fallback.reason
		let nextAction = parsed.nextAction?
			.trimmingCharacters(in: .whitespacesAndNewlines)
			.nonEmpty ?? fallback.nextAction
		let signals = TaskSuggestionEngine.normalizeTags(parsed.keySignals ?? fallback.keySignals)

		return ConnectionInsight(
			importance: importance,
			attitude: attitude,
			reason: reason,
			nextAction: nextAction,
			keySignals: signals.isEmpty ? fallback.keySignals : signals
		)
	}

	func suggestInboxHandling(_ text: String) async -> InboxHandlingSuggestion {
		let locale = interfaceLocale
		let fallback = InboxSuggestionEngine.fallback(for: text, locale: locale)
		guard isConfigured else { return fallback }

		let prompt = locale.isChineseInterface
			? """
			你是 NexaLife 的收件箱分流助手，请基于输入给出一个处理建议。
			仅输出 JSON，不要输出其他文本：
			{"module":"Execution|Knowledge|Lifestyle|Vitals|Inbox","headline":"一句话建议","reason":"40字内原因"}

			输入：\(text)
			"""
			: """
			You are the inbox triage assistant for NexaLife. Based on the text below, suggest how it should be handled.
			Return JSON only:
			{"module":"Execution|Knowledge|Lifestyle|Vitals|Inbox","headline":"one-line suggestion","reason":"reason in under 40 words"}

			Input: \(text)
			"""

		guard
			let response = await callAPI(prompt: prompt, maxTokens: 180),
			let jsonString = extractJSONObject(from: response),
			let data = jsonString.data(using: .utf8),
			let parsed = try? JSONDecoder().decode(InboxHandlingAIResponse.self, from: data)
		else {
			return fallback
		}

		let module = parsed.module?
			.trimmingCharacters(in: .whitespacesAndNewlines)
			.nonEmpty
			.flatMap(AppModule.init(rawValue:))
			?? fallback.module
		let headline = parsed.headline?
			.trimmingCharacters(in: .whitespacesAndNewlines)
			.nonEmpty ?? fallback.headline
		let reason = parsed.reason?
			.trimmingCharacters(in: .whitespacesAndNewlines)
			.nonEmpty ?? fallback.reason

		return InboxHandlingSuggestion(module: module, headline: headline, reason: reason)
	}

	// MARK: - 生成报告
	func generateReport(entries: [String], type: String) async -> String {
		let locale = interfaceLocale
		guard isConfigured else {
			return AppBrand.localized(
				"⚠️ 请先在「偏好设置 → AI 设置」中配置 API Key",
				"⚠️ Configure an API key in Preferences -> AI first.",
				locale: locale
			)
		}
		let prompt = locale.isChineseInterface
			? """
			基于以下「\(type)」记录，生成一份简洁的个人总结报告（中文，300字以内，分段落）：
			\(entries.joined(separator: "\n---\n"))
			"""
			: """
			Based on the following "\(type)" records, write a concise personal summary report in English (under 300 words, split into paragraphs):
			\(entries.joined(separator: "\n---\n"))
			"""
		return await callAPI(prompt: prompt, maxTokens: 500)
			?? AppBrand.localized("报告生成失败，请检查网络与 API Key。", "Report generation failed. Check the network connection and API key.", locale: locale)
	}

	// MARK: - 通用 API 调用
	// ✅ 去掉 nonisolated，统一在 @MainActor 上下文，URLSession 本身是线程安全的
	func callAPI(prompt: String, maxTokens: Int = 300) async -> String? {
		let rawProvider = UserDefaults.standard.string(forKey: "aiProvider") ?? AIProviderOption.deepseek.rawValue
		let providerURL = rawProvider == AIProviderOption.qwen.rawValue ? AIProvider.qwen.rawValue : AIProvider.deepseek.rawValue
		let modelName: String = {
			if rawProvider == AIProviderOption.qwen.rawValue {
				return UserDefaults.standard.string(forKey: "aiModelQwen") ?? "qwen-turbo"
			}
			return UserDefaults.standard.string(forKey: "aiModelDeepSeek") ?? "deepseek-chat"
		}()
		let configuredTimeout = UserDefaults.standard.double(forKey: "aiTimeoutSeconds")
		let timeout = configuredTimeout > 0 ? configuredTimeout : 30
		let key = AICredentialStore.readAPIKey()

		guard !key.isEmpty, let url = URL(string: providerURL) else { return nil }

		let body: [String: Any] = [
			"model":      modelName,
			"messages":   [["role": "user", "content": prompt]],
			"max_tokens": maxTokens
		]

		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.timeoutInterval = timeout
		request.httpBody = try? JSONSerialization.data(withJSONObject: body)

		do {
			// ✅ URLSession.data(for:) 是 async，会自动挂起并在后台线程执行网络请求
			//    返回后自动回到 @MainActor，无需手动切换线程
			let (data, response) = try await URLSession.shared.data(for: request)
			guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
				let status = (response as? HTTPURLResponse)?.statusCode ?? -1
				AppLogger.warning(
					"AI API HTTP error status=\(status) provider=\(rawProvider) model=\(modelName)",
					category: "ai"
				)
				return nil
			}
			let json    = try JSONSerialization.jsonObject(with: data) as? [String: Any]
			let choices = json?["choices"] as? [[String: Any]]
			let message = choices?.first?["message"] as? [String: Any]
			return message?["content"] as? String
		} catch {
			AppLogger.warning(
				"AI API request failed provider=\(rawProvider) model=\(modelName): \(error.localizedDescription)",
				category: "ai"
			)
			return nil
		}
	}

	private func extractJSONObject(from text: String) -> String? {
		let pattern = #"\{[\s\S]*\}"#
		guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
		let range = NSRange(text.startIndex..<text.endIndex, in: text)
		guard let match = regex.firstMatch(in: text, range: range),
			  let matchedRange = Range(match.range, in: text) else {
			return nil
		}
		return String(text[matchedRange])
	}
}

private extension String {
	var nonEmpty: String? { isEmpty ? nil : self }
}
