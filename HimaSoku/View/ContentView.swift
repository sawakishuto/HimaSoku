import AppIntents
import Foundation
import SwiftUI

struct ContentView: View {
    // UserDefaultsに保存された値を監視するためのState
    @Environment(\.user) var user
    @State var names: [String] = []
    @State var empacyMembers: [User] = [
        User(id: UUID().uuidString, name: "みんな忙しいみたい！")
    ]
    @State var isPresented: Bool = false
    @State var groupName: String = ""
    @State var isPresentedId: Bool = false
    @State var groupId: String = ""

    var body: some View {
        ZStack {
            
            LinearGradient(
                gradient: Gradient(colors: [.orange, .orange.opacity(0.3)]),
                startPoint: .top, endPoint: .bottom
            )
            .opacity(0.6)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            VStack {
                Spacer()
                
                VStack(spacing: 40) {
                    Text("暇な友達")
                        .fontWeight(.bold)
                        .font(.title2)
                    
                    ScrollView {
                        ForEach(empacyMembers, id: \.id) { user in
                            Text(user.name)
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
            }
                .offset(y: 10)
                .padding(.vertical, 30)
                .padding(.horizontal, 30)
                .background(Color.white)
                .cornerRadius(15)
                .frame(width: 350, height: 600)
                .frame(maxHeight: 600)
                .shadow(radius: 10)
                .ignoresSafeArea()
            
            
                Button {
                    self.isPresented = true
                } label: {
                    VStack(spacing: 0) {
                        Text("＋")
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .font(.system(size: 40))
                    }
                    .frame(width: 90, height: 90)
                    .background(.orange)
                    .cornerRadius(90)
                    .shadow(radius: 5)
                    .scaleEffect(0.8)
                    .position(x: 310, y: 690)
                }
                .sheet(isPresented: $isPresented) {
                    VStack(spacing: 20) {
                        Text("グループ名")
                            .fontWeight(.bold)
                        TextField("いつも暇な友達😻", text: $groupName)
                            .frame(width: 300, height: 30)
                            .padding()
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.black, lineWidth: 1)
                            )

                        Button {
                            Task {
                                let groupId = UUID().uuidString.prefix(8)
                                do {
                                    let result = try await APIClient.shared
                                        .postData(
                                            path: "/groups",
                                            params: [
                                                "group_id": groupId,
                                                "name": groupName
                                            ])
                                    switch result {
                                    case .success:
                                        UserDefaults.standard.set(groupId, forKey: "groupId")
                                        self.groupId = String(groupId)
                                        
                                        let params = ["uuid": UUID().uuidString,
                                                      "group_id": self.groupId,
                                                      "firebase_uid": user.id
                                        ]
                                        
                                        Task {
                                            do {
                                                let result = try await APIClient.shared.postData(path: "/users_groups", params: params)
                                                switch result {
                                                case .success:
                                                    self.isPresentedId = true
                                                case .failure: break
                                                }
                                            } catch {
                                                
                                            }
                                        }
                                        
                                    case .failure:
                                        break
                                    }
                                } catch {

                                }
                            }

                        } label: {
                            Text("作成!!")
                                .frame(width: 150, height: 60)
                                .background(.orange)
                                .cornerRadius(90)
                                .shadow(radius: 5)
                                .foregroundStyle(.white)
                                .fontWeight(.bold)
                        }
                        .alert("コピーして仲間を増やそう！", isPresented: $isPresentedId) {
                            Button("OK") {
                                UIPasteboard.general.string = self.groupId
                                self.isPresentedId = false
                                self.isPresented = false
                            }
                        } message: {
                            Text("タップでコピー: \(self.groupId)")
                        }
                    }
                }
        }
        .onAppear {
            self.names =
                UserDefaults.standard.stringArray(forKey: "Empathies") ?? []
            if !names.isEmpty {
                let empathiesUsers = names.map { name in
                    User(id: UUID().uuidString, name: name)
                }
                self.empacyMembers = empathiesUsers
            }

            let groupId = UserDefaults.standard.string(forKey: "group_id")
            if groupId != nil {
                return
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
