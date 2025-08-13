//
//  HimaSokuApp.swift
//  HimaSoku
//
//  Created by Shuto Sawaki on 2025/08/08.
//

import SwiftUI
@main
struct HimaSokuApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            LoginView()
                .environmentObject(appState)
        }
    }
}
extension EnvironmentValues {
    @Entry var user: User  = User(id: "0", name: "john Doe")
}
extension EnvironmentValues {
    @Entry var group: Group = Group(id: "1", name: "未設定")
}
