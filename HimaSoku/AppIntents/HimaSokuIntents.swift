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
        let groupId = UserDefaults.standard.string(forKey: "group_id")
        
           do {
               // 関数自体がasyncなので、ここでTaskを起動する必要はありません。
               // 直接API呼び出しを 'await' (待機) します。
               let result = try await APIClient.shared.postData(path: "/notifications/group/1", params: params)
               
               // awaitが終わった後、APIの結果を使って分岐します。
               switch result {
               case .success:
                   // 成功したので、成功ダイアログの結果を返す
                   UserDefaults.standard.removeObject(forKey: "Empathies")
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
    }
}
