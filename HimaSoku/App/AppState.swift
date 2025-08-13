//
//  AppState.swift
//  HimaSoku
//
//  Created by Shuto Sawaki on 2025/08/13.
//

import Foundation

class AppState: ObservableObject {
    // @Publishedを付けることで、このプロパティの変更がUIに自動的に通知される
    @Published var currentGroup: Group = Group(id: "1", name: "未設定")
}
