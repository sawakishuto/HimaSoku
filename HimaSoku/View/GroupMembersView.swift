//
//  GroupMemberView.swift
//  HimaSoku
//
//  Created by Shuto Sawaki on 2025/08/08.
//

import SwiftUI

struct GroupMembersView: View {
    @State var groupMember: GroupMember? = nil
    @State var isAlertPresented: Bool = false
    @Environment(\.user) var user
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [.orange, .orange.opacity(0.3)]), startPoint: .top, endPoint: .bottom)
                .opacity(0.6)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack {
                Text((groupMember?.group.name ?? "") + " のメンバー")
                    .fontWeight(.bold)
                    .font(.title2)
                    .padding(.bottom, 40)

                ScrollView {

                    ForEach(groupMember?.users ?? [], id: \.id) { user in
                        Text(user.name ?? "名前の取得に失敗しました")
                            .font(.headline)
                            .padding()
                            .frame(width: 300, height: 60)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(15)
                            .clipped()
                    }
                }
                .frame(width: 300, height: 500)
                
            }
            .offset(y: 10)
            .padding(.vertical, 30)
            .padding(.horizontal, 30)
            .background(Color.white)
            .cornerRadius(15)
            .frame(width: 350, height: 600)
            .shadow(radius: 10)
            Button {
                let params = [
                    "uuid":UUID().uuidString ,
                    "group_id": "1",
                    "firebase_uid": user.id
                ]
                Task {
                    do {
                        let result = try await APIClient.shared.postData(path: "/users_groups", params: params)
                        switch result {
                        case .success:
                            return
                        case .failure:
                            return
                        }

                    } catch {
                        print("参加エラー")
                    }
                }
            } label: {
                VStack(spacing: 0) {
                    Image("hima-man")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 50)
                    Text("参加")
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
                .frame(width: 90, height: 90)
                .background(.orange)
                .cornerRadius(90)
                .shadow(radius: 5)
            }
            .position(x: 310, y:690)
            
        }
        .ignoresSafeArea()
        .alert("参加に成功しました！", isPresented: $isAlertPresented, actions: {
        }, message: {
            Text("暇なときにサクッと伝えましょう！")
        })
        .onAppear {
            Task {
                do {
                    let groupMember: GroupMember = try await APIClient.shared.fetchData(path: "/groups/1/users")
                    self.groupMember = groupMember
                } catch {
                    
                }
            }
        }
    }
}

#Preview {
    GroupMembersView()
}
