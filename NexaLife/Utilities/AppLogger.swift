//
//  AppLogger.swift
//  NexaLife
//
//  Created by Codex on 2026-03-07.
//

import Foundation
import OSLog

private enum AppLogLevel: Int {
	case error = 0
	case warning = 1
	case info = 2
	case debug = 3
}

enum AppLogger {
	private static let subsystem = Bundle.main.bundleIdentifier ?? AppBrand.bundleIdentifier

	static func error(_ message: String, category: String = "app") {
		log(level: .error, message: message, category: category)
	}

	static func warning(_ message: String, category: String = "app") {
		log(level: .warning, message: message, category: category)
	}

	static func info(_ message: String, category: String = "app") {
		log(level: .info, message: message, category: category)
	}

	static func debug(_ message: String, category: String = "app") {
		log(level: .debug, message: message, category: category)
	}

	static func redactSecret(_ value: String, prefixCount: Int = 4, suffixCount: Int = 2) -> String {
		let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !trimmed.isEmpty else { return "<empty>" }
		if trimmed.count <= prefixCount + suffixCount {
			return String(repeating: "*", count: max(4, trimmed.count))
		}
		let prefix = trimmed.prefix(prefixCount)
		let suffix = trimmed.suffix(suffixCount)
		return "\(prefix)…\(suffix)"
	}

	private static func log(level: AppLogLevel, message: String, category: String) {
		guard isEnabled(level) else { return }
		let logger = Logger(subsystem: subsystem, category: category)
		switch level {
		case .error:
			logger.error("\(message, privacy: .public)")
		case .warning:
			logger.warning("\(message, privacy: .public)")
		case .info:
			logger.info("\(message, privacy: .public)")
		case .debug:
			logger.debug("\(message, privacy: .public)")
		}
	}

	private static func isEnabled(_ level: AppLogLevel) -> Bool {
		level.rawValue <= configuredLevel().rawValue
	}

	private static func configuredLevel() -> AppLogLevel {
		let raw = UserDefaults.standard.string(forKey: "logLevel") ?? "info"
		switch raw {
		case "error":
			return .error
		case "warning":
			return .warning
		case "debug":
			return .debug
		default:
			return .info
		}
	}
}
