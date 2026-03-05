//
//  LifeOSApp.swift
//  LifeOS
//
//  Created by Lihong Gao on 2026-02-26.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var oauthService: OAuthService  // 获取 OAuthService 的共享实例
    
    var body: some View {
        VStack(spacing: 20) {
            Text("欢迎使用 LifeOS").font(.title).bold()
            Button("使用 Apple 登录") {
                oauthService.startOAuthFlow(type: .apple) { success in
                    if success {
                        print("Apple 登录成功")
                    } else {
                        print("Apple 登录失败")
                    }
                }
            }
            Button("使用 Google 登录") {
                oauthService.startOAuthFlow(type: .google) { success in
                    if success {
                        print("Google 登录成功")
                    } else {
                        print("Google 登录失败")
                    }
                }
            }
            Button("使用自定义登录") {
                oauthService.startOAuthFlow(type: .custom) { success in
                    if success {
                        print("自定义登录成功")
                    } else {
                        print("自定义登录失败")
                    }
                }
            }
        }
        .padding()
    }
}
