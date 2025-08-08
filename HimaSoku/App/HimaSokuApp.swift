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
    var body: some Scene {
        WindowGroup {
            LoginView()
        }
    }
}
extension EnvironmentValues {
    @Entry var user: User  = User(id: "0", name: "john Doe")
}
