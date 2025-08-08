//
//  TabView.swift
//  HimaSoku
//
//  Created by Shuto Sawaki on 2025/08/08.
//

import SwiftUI

struct TabView: View {
    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Image(systemName: "1.circle.fill")
                }
            
            GroupMembersView()
                .tabItem {
                    Image(systemName: "2.circle.fill")
                }
        }
    }
}
#Preview {
    TabView()
}
