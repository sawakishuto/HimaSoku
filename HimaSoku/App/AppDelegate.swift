import UIKit
import FirebaseCore
import UserNotifications
import os.log
import GoogleSignIn

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        setupNotificationCategories()

        // UNUserNotificationCenterのデリゲートを自身に設定します。
        // これにより、通知に関するイベント（フォアグラウンドでの受信など）をこのクラスで一元管理できます。
        UNUserNotificationCenter.current().delegate = self

        // ユーザーに通知の許可を要求します。
        requestNotificationAuthorization()
        return true // 起動処理が成功したことを示します。
    }
    
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }

    /// ユーザーに通知の許可を要求します。
    private func requestNotificationAuthorization() {
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        
        UNUserNotificationCenter.current().requestAuthorization(options: options) { granted, error in
            // エラーハンドリング：エラーオブジェクトが存在すれば、その内容をログに出力します。
            if let error = error {
                os_log("通知許可の要求でエラーが発生しました: %@", log: .default, type: .error, error.localizedDescription)
                return
            }
            
            if granted {
                os_log("ユーザーは通知を許可しました。", log: .default, type: .info)
                // 許可された場合、APNsにデバイスを登録します。
                // この処理はメインスレッドで実行する必要があります。
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                os_log("ユーザーは通知を許可しませんでした。", log: .default, type: .info)
                // 許可されなかった場合のフォールバック処理（例：設定画面へ誘導するなど）をここに記述できます。
            }
        }
    }

    // MARK: - APNs Registration

    /// APNsへのデバイス登録が成功した場合に呼び出されます。
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Data型のデバイストークンを16進数の文字列に変換します。
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        os_log("Device Token: %@", log: .default, type: .info, token)
        UserDefaults.standard.set(token, forKey: "device_token")

        // ここで、取得したデバイストークンを自社のサーバーに送信する処理を実装します。
    }

    /// APNsへのデバイス登録が失敗した場合に呼び出されます。
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        os_log("リモート通知の登録に失敗しました: %@", log: .default, type: .error, error.localizedDescription)
    }
    
    func setupNotificationCategories() {
        // アクションボタンの定義
        let joinAction = UNNotificationAction(
            identifier: "JOIN_ACTION",
            title: "わかる~😮",
            options: [.foreground] // アプリを前面に表示
        )
        
        let declineAction = UNNotificationAction(
            identifier: "DECLINE_ACTION",
            title: "一旦スルーで！",
            options: []
        )
        
        // カテゴリの定義
        let himasokuCategory = UNNotificationCategory(
            identifier: "HIMASOKU_INVITE",
            actions: [joinAction, declineAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // 通知センターに登録
        UNUserNotificationCenter.current().setNotificationCategories([himasokuCategory])
    }
    
    /// アプリがフォアグラウンドで動作中に通知を受信したときに呼び出されます。
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound, .badge])
    }
    func application(_ application: UIApplication,
                       didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("サイレントプッシュ通知をバックグラウンドで受信しました。")
        print("受信データ (userInfo): \(userInfo)")
        
        // userInfoからuser_nameを取得し、UserDefaultsに保存する処理を呼び出す
        if let userName = userInfo["user_name"] as? String {
            saveUserName(userName)
            
            // 新しいデータがあったので、.newData を返す
            completionHandler(.newData)
        } else {
            // user_nameがペイロードに含まれていなかった場合
            completionHandler(.noData)
        }
        
    }
    private func saveUserName(_ newName: String) {
            let defaults = UserDefaults.standard
            
            // 1. 現在保存されているユーザー名の配列を読み込む
            // まだ何も保存されていなければ、空の配列として扱う
            var currentNames = defaults.stringArray(forKey: "Empathies") ?? []
            
            // 2. 新しいユーザー名を配列の先頭に追加する (最新のものが上に来るように)
            currentNames.insert(newName, at: 0)
            
            // 3. 更新した配列をUserDefaultsに保存し直す
            defaults.set(currentNames, forKey: "Empathies")
        }
    
    
    

    /// ユーザーが通知（バナーや通知センターの項目）を操作したときに呼び出されます。
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void)  {

        // 通知に含まれる情報（userInfo）を使って、特定の処理を実行できます。
        // 例：通知をタップしたら特定の画面を開くなど。
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier
        
        // --- ▼▼▼ デバッグコードを追加 ▼▼▼ ---
         print("✅ Action Identifier: \(actionIdentifier)")
         print("✅ User Info: \(userInfo)")
         // --- ▲▲▲ デバッグコードを追加 ▲▲▲ ---
               
               // カスタムデータを取得
               let senderFirebaseUID = userInfo["sender_firebase_uid"] as? String
               let senderName = userInfo["sender_name"] as? String
               let groupId = userInfo["group_id"] as? String
               let durationTime = userInfo["durationTime"] as? String
               
               switch actionIdentifier {
               case "JOIN_ACTION":
                   // 参加アクションの処理
                    handleJoinAction(
                       senderFirebaseUID: senderFirebaseUID!,
                       senderName: senderName!,
                       groupId: groupId!,
                       durationTime: durationTime!
                   )
                   
               case "DECLINE_ACTION":
                   // 断るアクションの処理
                   print("断った。")
               default:
                   break
               }
               
               completionHandler()
           }
    
    
    func handleJoinAction(
        senderFirebaseUID: String,
        senderName: String,
        groupId: String,
        durationTime: String
    ) -> Void {
        let user = KeychainManager.shared.getUser()
        if let user = user {
            do {
                try  APIClient.shared.sendJoinAction(firebaseUID: user.id, actionIdentifier:  "JOIN_ACTION", groupId: groupId, senderName: senderName, senderFirebaseUID: senderFirebaseUID, durationTime: "0")
            } catch {
                print("参加失敗")
            }
        }

    
}

    }

