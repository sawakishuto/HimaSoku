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
    @State var isPresented: Bool = false
    @State var groupId: String = ""
    @State var groups: [Group] = []
    @State var currentGroup: Group = Group(id: "1", name: "未設定")
    @EnvironmentObject var appState: AppState
    @Environment(\.user) var user
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [.orange, .orange.opacity(0.3)]), startPoint: .top, endPoint: .bottom)
                .opacity(0.6)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack {
                
                Picker("グループを選択", selection: $groupId) {
                    ForEach(groups, id: \.id) { group in
                        Text("\(group.name)" + "のメンバー")
                            .tag(group.id) // tag修飾子でgroupIdと紐づける
                            .fontWeight(.bold)
                            .font(.title2)
                            .padding(.bottom, 40)
                    }
                }
                .pickerStyle(.menu) // ドロップダウン形式のスタイル
                .onChange(of: groupId) { oldValue, newValue in
                    Task {
                        // ここに非同期処理を書く
                        do {
                            UserDefaults.standard.set(newValue, forKey: "groupId")
                            let groupMember = try await fetchGroupMember(groupId: newValue)
                            self.groupMember = groupMember
                            self.appState.currentGroup = groupMember.group
                        } catch {
                            print("Failed to fetch group members for new group ID \(newValue): \(error)")
                        }
                    }
                }

                ScrollView {

                    ForEach(groupMember?.users ?? [], id: \.id) { user in
                        Text(user.name)
                            .font(.headline)
                            .padding()
                            .frame(width: 300, height: 60)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(15)
                            .clipped()
                            .shadow(radius: 10)
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
            .environment(\.group, currentGroup)
            
            Button {
                self.isPresented = true
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
                .scaleEffect(0.8)
            }
            .position(x: 310, y:690)
            .sheet(isPresented: $isPresented) {
                VStack(spacing: 20) {
                    Text("グループIDを入力")
                        .fontWeight(.bold)
                    TextField("1111-1111-1111", text: $groupId)
                        .frame(width: 300, height: 30)
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.black, lineWidth: 1)
                        )

                    Button {
                        let params = ["uuid": UUID().uuidString,
                                      "group_id": self.groupId,
                                      "firebase_uid": user.id
                        ]
                        Task {
                            do {
                                let result = try await APIClient.shared.postData(path: "/users_groups", params: params)
                                switch result {
                                case .success:
                                    Task{
                                       let groupMember = try await  fetchGroupMember(groupId: self.groupId)
                                        self.groupMember = groupMember
                                        self.isAlertPresented.toggle()
                                   }
                                case .failure: break
                                }
                            } catch {
                                
                            }
                        }

                    } label: {
                        Text("参加!!")
                            .frame(width: 150, height: 60)
                            .background(.orange)
                            .cornerRadius(90)
                            .shadow(radius: 5)
                            .foregroundStyle(.white)
                            .fontWeight(.bold)
                    }
                }
            }
        }
        .ignoresSafeArea()
        .alert("参加完了！！", isPresented: $isAlertPresented) {
            Button("OK") {
                UIPasteboard.general.string = self.groupId
                self.isPresented = false
                self.isAlertPresented = false
            }
        } message: {
            Text("さくっと暇を共有しよう！！")
        }
        .onAppear {
            Task {
                if appState.currentGroup.id == "1" {
                    self.groupId = UserDefaults.standard.string(forKey: "groupId") ?? "1"
                } else {
                    print("\(appState.currentGroup)")
                    self.groupId = appState.currentGroup.id
                }
                do {
                    let groups: Groups = try await APIClient.shared.fetchData(path: "/users/\(user.id)/groups")
                    self.groups = groups.groups
                    if groups.groups == [] {
                        return
                        
                    } else {
                        let groupMember: GroupMember = try await APIClient.shared.fetchData(path: "/groups/\(groupId)/users")
                        self.groupMember = groupMember
                    }

                } catch {
                    
                }
            }
        }
    }
    
    func fetchGroupMember(groupId: String) async throws -> GroupMember {
        let groupMember: GroupMember = try await APIClient.shared.fetchData(path: "/groups/\(groupId)/users")
        return groupMember
    }
}

#Preview {
    GroupMembersView()
}
