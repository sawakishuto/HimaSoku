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

    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Image(systemName: "1.circle.fill")
                }
                .environment(\.user, user)
            
            GroupMembersView()
                .tabItem {
                    Image(systemName: "2.circle.fill")
                }
                .environment(\.user, user)
        }
    }
}
#Preview {
    HimaTabView()
}
