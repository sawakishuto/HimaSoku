//
//  TabView.swift
//  HimaSoku
//
//  Created by Shuto Sawaki on 2025/08/08.
//

import SwiftUI

struct HimaTabView: View {
    @State var user: User = User(id: "", name: "")
    @Environment(\.user) var currentUser
    @Environment(\.group) var group

    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Image(systemName: "flag.circle") // SFSymbolsのアイコン
                    Text("暇の集い")
                }
                .environment(\.user, user)
            
            GroupMembersView()
                .tabItem {
                    Image(systemName: "person.2.circle") // SFSymbolsのアイコン
                    Text("グループ")
                }
                .environment(\.user, user)
        }
        .ignoresSafeArea()

    }
}
#Preview {
    HimaTabView()
}
