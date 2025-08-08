//
//  GroupMemberView.swift
//  HimaSoku
//
//  Created by Shuto Sawaki on 2025/08/08.
//

import SwiftUI

struct GroupMembersView: View {
    var groupMember: [User] = [User(name: "田中"), User(name: "佐藤"), User(name: "鈴木"), User(name: "山田"), User(name: "伊藤")]
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [.orange, .orange.opacity(0.3)]), startPoint: .top, endPoint: .bottom)
                .opacity(0.6)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            VStack {
                Text("グループメンバー一覧")
                    .fontWeight(.bold)
                    .font(.title2)
                    .padding(.bottom, 40)
                ScrollView {
                    ForEach(groupMember, id: \.id) { user in
                        Text(user.name)
                            .font(.headline)
                            .padding()
                            .frame(width: 300, height: 60)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(15)
                            .clipped()
                    }
                }
            }
            .offset(y: 10)
            .padding(.vertical, 30)
            .padding(.horizontal, 30)
            .background(Color.white)
            .cornerRadius(15)
            .frame(width: 350, height: 600)
            .shadow(radius: 10)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    GroupMembersView()
}
