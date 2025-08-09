import Foundation
import AppIntents
import UserNotifications
import SwiftUI

struct HimaSokuIntent: AppIntent {
    @State var isSuccessed: Bool = false
    // ショートカットアプリの一覧に表示される機能のタイトル
    static var title: LocalizedStringResource = "HimaSoku"
    
    // 機能の詳細な説明
    static var description: IntentDescription = IntentDescription("あなたの暇を速攻で共有しましょう！")
    @Parameter(title: "何時まで暇？？🥱")
    var durationTime: String
    
    // 実際に処理を実行するメソッド
    // このメソッドの中に、テキストを受け取った後の処理を記述します
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // タイトル、本文、サウンド設定の保持
        
        // ユーザが暇な時間を入力したらその情報をもとに自分のグループに所属している人全員に通知を送るAPIを叩く
        guard let user = KeychainManager.shared.getUser() else {
               return .result(dialog: "ユーザー情報の取得に失敗しました。")
           }
           
        let params = ["firebase_uid": user.id, "name": user.name, "durationTime": durationTime]
        
           do {
               // 関数自体がasyncなので、ここでTaskを起動する必要はありません。
               // 直接API呼び出しを 'await' (待機) します。
               let result = try await APIClient.shared.postData(path: "/notifications/group/1", params: params)
               
               // awaitが終わった後、APIの結果を使って分岐します。
               switch result {
               case .success:
                   // 成功したので、成功ダイアログの結果を返す
                   return .result(dialog: "HimaSokuを実行しました。")
                   
               case .failure(let error): // エラーも具体的に扱うとデバッグしやすくなります
                   // APIが失敗を返したので、失敗ダイアログの結果を返す
                   print("API Error: \(error)") // 念のためエラー内容をログに出力
                   return .result(dialog: "HimaSokuが失敗しました、もう一度お試しください")
               }
           } catch {
               // `await`中にネットワークエラーなどで例外が発生した場合の処理
               print("Request Error: \(error)") // エラー内容をログに出力
               return .result(dialog: "HimaSokuが失敗しました、もう一度お試しください")
           }
        
        
//        
//        let likeActionIcon = UNNotificationActionIcon(systemImageName: "lasso")
//        let likeAction = UNNotificationAction(identifier: "like-action",
//                                                   title: "わかる😀",
//                                                 options: [],
//                                                    icon: likeActionIcon)
//                
//        let commentActionIcon = UNNotificationActionIcon(templateImageName: "text.bubble")
//        let commentAction = UNTextInputNotificationAction(identifier: "comment-action",
//                                                               title: "スルーで！🙇‍♂️",
//                                                             options: [],
//                                                                icon: commentActionIcon,
//                                                textInputButtonTitle: "Post",
//                                                textInputPlaceholder: "Type here…")
//
//        let category = UNNotificationCategory(identifier: "update-actions",
//                                                 actions: [likeAction, commentAction],
//                                       intentIdentifiers: [], options: [])
//
//        
//        let content = UNMutableNotificationContent()
//        content.title = "HimaSoku"
//        content.subtitle = "\(durationTime)"
//        content.body = "〇〇さんが暇みたいです"
//        content.sound = UNNotificationSound.default
//        content.categoryIdentifier = "update-actions"
//
//        // seconds後に起動するトリガーを保持
//        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3,
//                                                        repeats: false)
//        // 識別子とともに通知の表示内容とトリガーをrequestに内包する
//        let request = UNNotificationRequest(identifier: "Timer",
//                                            content: content,
//                                            trigger: trigger)
//
//        // UNUserNotificationCenterにrequest
//        UNUserNotificationCenter.current().setNotificationCategories([category])
//        UNUserNotificationCenter.current().add(request) { (error) in
//            if let error = error {
//                print(error.localizedDescription)
//            }
//        }
    }
}
