import Foundation
import AppIntents
import SwiftUI

struct ContentView: View {
    // UserDefaultsに保存された値を監視するためのState
    @Environment(\.user) var user
    @State var names: [String] = []
    @State var empacyMembers: [User] = [User(id: UUID().uuidString, name: "みんな忙しいみたい！")]

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [.orange, .orange.opacity(0.3)]), startPoint: .top, endPoint: .bottom)
                .opacity(0.6)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            .offset(y: 10)
            .padding(.vertical, 30)
            .padding(.horizontal, 30)
            .background(Color.white)
            .cornerRadius(15)
            .frame(width: 350, height: 600)
            .frame(maxHeight:600)
            .shadow(radius: 10)
            .ignoresSafeArea()
            .onAppear {
                // 画面が最初に表示された時にも値を読み込む
            }
        }
        .onAppear {
            self.names = UserDefaults.standard.stringArray(forKey: "Empathies") ?? []
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
            let params = ["name": "友達", "group_id": "1"]
            Task {
                do {
                    let result = try await APIClient.shared.postData(path: "/groups", params: params)
                    switch result {
                    case .success:
                        UserDefaults.standard.set("1", forKey: "group_id")
                        return
                    case .failure:
                        return
                    }

                } catch {
                    
                }
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
