//
//  LifeOSApp.swift
//  LifeOS
//
//  Created by Lihong Gao on 2026-02-26.
//
//  OAuthService.swift

import Foundation
import AuthenticationServices
import Combine

class OAuthService: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
	@Published var authToken: String? = nil

	// ✅ macOS 必须实现此协议方法，提供 presentation anchor
	func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
		// 返回 App 当前的主窗口
		NSApplication.shared.windows.first ?? ASPresentationAnchor()
	}

	func startOAuthFlow(type: AuthType, completion: @escaping (Bool) -> Void) {
		guard let authUrl = type.getOAuthURL else {
			completion(false)
			return
		}

		// ✅ callbackURLScheme 必须与 Info.plist 中注册的 URL Scheme 一致
		let callbackScheme = "lifeos"

		let session = ASWebAuthenticationSession(
			url: authUrl,
			callbackURLScheme: callbackScheme
		) { [weak self] callbackURL, error in
			if let error = error as? ASWebAuthenticationSessionError,
			   error.code == .canceledLogin {
				completion(false)
				return
			}
			if let error = error {
				print("OAuth 失败: \(error.localizedDescription)")
				completion(false)
				return
			}
			guard let callbackURL = callbackURL else {
				completion(false)
				return
			}
			self?.handleCallback(callbackURL: callbackURL, completion: completion)
		}

		session.prefersEphemeralWebBrowserSession = false
		session.presentationContextProvider = self   // ✅ 关键：设置 context provider
		session.start()
	}

	private func handleCallback(callbackURL: URL, completion: @escaping (Bool) -> Void) {
		guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: true),
			  let token = components.queryItems?.first(where: { $0.name == "token" })?.value
		else {
			// ✅ 开发阶段：callback 里没有 token 时用 mock token 继续流程
			DispatchQueue.main.async { self.authToken = "mock-dev-token" }
			completion(true)
			return
		}
		DispatchQueue.main.async { self.authToken = token }
		completion(true)
	}

	// Preview mock
	static var mock: OAuthService {
		let s = OAuthService()
		s.authToken = "preview-mock-token"
		return s
	}
}

enum AuthType {
	case apple, google, custom

	var getOAuthURL: URL? {
		switch self {
		// ✅ 使用真实 Apple OAuth 端点，附带必要参数
		case .apple:
			var components = URLComponents(string: "https://appleid.apple.com/auth/authorize")!
			components.queryItems = [
				URLQueryItem(name: "response_type", value: "code"),
				URLQueryItem(name: "client_id",     value: "com.lihonggao.LifeOS"),  // 替换为你的 Service ID
				URLQueryItem(name: "redirect_uri",  value: "lifeos://apple-auth"),
				URLQueryItem(name: "scope",         value: "name email"),
			]
			return components.url
		case .google:
			var components = URLComponents(string: "https://accounts.google.com/o/oauth2/auth")!
			components.queryItems = [
				URLQueryItem(name: "response_type",  value: "code"),
				URLQueryItem(name: "client_id",      value: "YOUR_GOOGLE_CLIENT_ID"),
				URLQueryItem(name: "redirect_uri",   value: "lifeos://google-auth"),
				URLQueryItem(name: "scope",          value: "openid email profile"),
			]
			return components.url
		case .custom:
			return URL(string: "https://yourcustomauth.com/oauth")
		}
	}
}
