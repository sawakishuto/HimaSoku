import Foundation
import AppIntents
import SwiftUI

struct ContentView: View {
    // UserDefaultsに保存された値を監視するためのState
    @State private var lastMemo: String = ""
    var goSignMembers: [User] = [
        User(name: "井上"),
        User(name: "佐藤"),
        User(name: "鈴木"),
        User(name: "田中")
    ]

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
                    ForEach(goSignMembers, id: \.id) { user in
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
            .ignoresSafeArea()
            .onAppear {
                // 画面が最初に表示された時にも値を読み込む
            }
        }.ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}




struct AddMemoIntent: AppIntent {
    
    // ショートカットアプリの一覧に表示される機能のタイトル
    static var title: LocalizedStringResource = "メモを追加"
    
    // 機能の詳細な説明
    static var description: IntentDescription = IntentDescription("指定されたテキストをアプリに保存します。")
    
    // ショートカットから受け取るパラメータ（引数）を定義します
    // ここでは「メモの内容」という名前で、テキスト(String)を受け取ります
    @Parameter(title: "何時まで暇？？🥱")
    var memoContent: String
    
    // 実際に処理を実行するメソッド
    // このメソッドの中に、テキストを受け取った後の処理を記述します
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // タイトル、本文、サウンド設定の保持
        
        let likeActionIcon = UNNotificationActionIcon(systemImageName: "hand.thumbsup")
        let likeAction = UNNotificationAction(identifier: "like-action",
                                                   title: "Like",
                                                 options: [],
                                                    icon: likeActionIcon)
                
        let commentActionIcon = UNNotificationActionIcon(templateImageName: "text.bubble")
        let commentAction = UNTextInputNotificationAction(identifier: "comment-action",
                                                               title: "Comment",
                                                             options: [],
                                                                icon: commentActionIcon,
                                                textInputButtonTitle: "Post",
                                                textInputPlaceholder: "Type here…")

        let category = UNNotificationCategory(identifier: "update-actions",
                                                 actions: [likeAction, commentAction],
                                       intentIdentifiers: [], options: [])

        
        let content = UNMutableNotificationContent()
        content.title = "HimaSoku"
        content.subtitle = "\(memoContent)"
        content.body = "〇〇さんが暇みたいです"
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "update-actions"

        // seconds後に起動するトリガーを保持
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3,
                                                        repeats: false)
        // 識別子とともに通知の表示内容とトリガーをrequestに内包する
        let request = UNNotificationRequest(identifier: "Timer",
                                            content: content,
                                            trigger: trigger)

        // UNUserNotificationCenterにrequest
        UNUserNotificationCenter.current().setNotificationCategories([category])
        UNUserNotificationCenter.current().add(request) { (error) in
            if let error = error {
                print(error.localizedDescription)
            }
        }
        // --- ここからがアプリの処理部分 ---
        
        // デバッグ用に、受け取ったテキストをコンソールに出力します
        print("ショートカットからテキストを受け取りました: \(memoContent)")
        
        // UserDefaultsに保存する例
        UserDefaults.standard.set(memoContent, forKey: "lastMemo")
        
        // --- ここまでがアプリの処理部分 ---
        
        // 処理が終わったら、ショートカットに成功したことを返します
        // このメッセージは、ショートカット実行後に画面に表示されます
        return .result(dialog: "暇メッセージを送信した。")
    }
}
