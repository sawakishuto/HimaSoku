import UIKit
import FirebaseCore
import UserNotifications
import os.log // os_logを使うためにimport
import GoogleSignIn

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

// Loggerの定義（推奨）
private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "AppDelegate")

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    logger.info("🚀 [didFinishLaunchingWithOptions] アプリケーションの起動処理を開始します。")
    
    logger.info("🔥 [didFinishLaunchingWithOptions] Firebaseを初期化します。")
    FirebaseApp.configure()
    
    logger.info("🔔 [didFinishLaunchingWithOptions] 通知カテゴリを設定します。")
    setupNotificationCategories()

    logger.info("👤 [didFinishLaunchingWithOptions] UNUserNotificationCenterのデリゲートを自身に設定します。")
    UNUserNotificationCenter.current().delegate = self

    logger.info("🙋 [didFinishLaunchingWithOptions] ユーザーに通知の許可を要求します。")
    requestNotificationAuthorization()
    
    logger.info("✅ [didFinishLaunchingWithOptions] 起動処理が正常に完了しました。")
    return true
}

// ... (open url, requestNotificationAuthorization, APNs Registration, setupNotificationCategories, saveUserName は変更なし) ...
func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
    logger.info("➡️ [open url] URLスキーム経由でアプリが開かれました。URL: \(url.absoluteString)")
    return GIDSignIn.sharedInstance.handle(url)
}

private func requestNotificationAuthorization() {
    logger.info("➡️ [requestNotificationAuthorization] 通知許可ダイアログの表示を要求します。")
    let options: UNAuthorizationOptions = [.alert, .badge, .sound]
    
    UNUserNotificationCenter.current().requestAuthorization(options: options) { granted, error in
        if let error = error {
            self.logger.error("🚨 [requestNotificationAuthorization] 通知許可の要求でエラーが発生しました: \(error.localizedDescription)")
            return
        }
        
        if granted {
            self.logger.info("👍 [requestNotificationAuthorization] ユーザーは通知を許可しました。")
            DispatchQueue.main.async {
                self.logger.info("📡 [requestNotificationAuthorization] APNsへのデバイス登録を開始します。")
                UIApplication.shared.registerForRemoteNotifications()
            }
        } else {
            self.logger.warning("🙅 [requestNotificationAuthorization] ユーザーは通知を許可しませんでした。")
        }
    }
}

func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    logger.info("✅ [didRegisterForRemoteNotificationsWithDeviceToken] APNsへの登録が成功しました。")
    logger.debug("🔑 Device Token: \(token)")
    UserDefaults.standard.set(token, forKey: "device_token")
}

func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    logger.error("🚨 [didFailToRegisterForRemoteNotificationsWithError] APNsへの登録に失敗しました: \(error.localizedDescription)")
}

func setupNotificationCategories() {
    logger.info("➡️ [setupNotificationCategories] 通知アクションとカテゴリの定義を開始します。")
    let joinAction = UNNotificationAction(identifier: "JOIN_ACTION", title: "わかる😮", options: [])
    let declineAction = UNNotificationAction(identifier: "DECLINE_ACTION", title: "今は暇じゃない😢", options: [.destructive])

    let himasokuCategory = UNNotificationCategory(
        identifier: "HIMASOKU_INVITE",
        actions: [joinAction, declineAction],
        intentIdentifiers: [],
        options: [.customDismissAction]
    )
    
    UNUserNotificationCenter.current().setNotificationCategories([himasokuCategory])
    logger.info("✅ [setupNotificationCategories] 通知カテゴリ'HIMASOKU_INVITE'を登録しました。")
}

// MARK: - Notification Handlers

/// 【修正】アプリがフォアグラウンドで動作中に通知を受信したときに呼び出されます。
func userNotificationCenter(_ center: UNUserNotificationCenter,
                            willPresent notification: UNNotification,
                            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    
    logger.info("➡️ [willPresent] アプリがフォアグラウンド中に通知を受信しました。")
    let userInfo = notification.request.content.userInfo
    let application = UIApplication.shared
    
    // --- ▼▼▼ ここからバックグラウンド処理を複製 ▼▼▼ ---
    logger.info("⬇️ [willPresent内の処理] バックグラウンド互換処理を開始します。")
    logger.debug("  [willPresent内の処理] 受信データ (userInfo): \(userInfo)")
    
    if let action = userInfo["action"] as? String {
        logger.info("  [willPresent内の処理] 'action'キーが見つかりました: '\(action)'。即時処理を実行します。")
        switch action {
        case "JOIN":
            logger.info("    [willPresent内の処理] case 'JOIN' に入りました。")
            if let userName = userInfo["user_name"] as? String {
                saveUserName(userName)
            } else {
                saveUserName("名無しさんだよお")
            }
        case "DECLINE":
            logger.info("    [willPresent内の処理] case 'DECLINE' に入りました。")
        default:
            logger.info("    [willPresent内の処理] case 'default' に入りました。")
        }
    } else {
        logger.info("  [willPresent内の処理] 'action'キーが見つかりませんでした。待機処理の可能性があります。")
        
        // クラッシュ回避のため、必要な情報が揃っているか確認
        guard let notificationId = userInfo["notification_id"] as? String,
              let senderFirebaseUID = userInfo["sender_firebase_uid"] as? String,
              let senderName = userInfo["sender_name"] as? String,
              let groupId = userInfo["group_id"] as? String,
              let durationTime = userInfo["durationTime"] as? String else {
            
            logger.error("  🚨 [willPresent内の処理] 'notification_id'など待機処理に必要な情報が見つからないため、処理を中断します。")
            // フォアグラウンドでは、データ処理が失敗しても通知自体は表示させる
            completionHandler([.banner, .list, .sound, .badge])
            return
        }
        logger.info("  [willPresent内の処理] Notification ID: '\(notificationId)' を確認しました。")
        
        var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
        logger.info("  [willPresent内の処理] バックグラウンドタスクを開始します (TaskName: JoinActionCheck-\(notificationId))。")
        backgroundTaskID = application.beginBackgroundTask(withName: "JoinActionCheck-\(notificationId)") {
            self.logger.warning("  ⌛️ [willPresent内の処理] バックグラウンドタスクの時間が切れそうです。タスクを終了します。")
            application.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }

        logger.info("  [willPresent内の処理] 30秒後に非同期処理をスケジュールします。")
        DispatchQueue.global().asyncAfter(deadline: .now() + 30) {
            self.logger.info("  [willPresent内のasyncAfter] 非同期処理が開始されました (ID: \(notificationId))。")
            
            let userActioned = UserDefaults.standard.bool(forKey: notificationId)
            self.logger.info("    [willPresent内のasyncAfter] ユーザーのアクション済みフラグを確認しました: \(userActioned ? "はい" : "いいえ")。")

            if !userActioned {
                self.logger.info("    [willPresent内のasyncAfter] アクションがなかったので、handleDeclineActionを呼び出します。")
                self.handleDeclineAction(
                    senderFirebaseUID: senderFirebaseUID,
                    senderName: senderName,
                    groupId: groupId,
                    durationTime: durationTime
                )
            } else {
                self.logger.info("    [willPresent内のasyncAfter] アクション済みだったので、何もしません。")
            }
            
            self.logger.info("    [willPresent内のasyncAfter] 使用済みフラグ（\(notificationId)）を削除します。")
            UserDefaults.standard.removeObject(forKey: notificationId)
            
            // フォアグラウンドではバックグラウンドタスクを終了させるだけで良い
            application.endBackgroundTask(backgroundTaskID)
        }
    }
    // --- ▲▲▲ ここまでバックグラウンド処理の複製 ▲▲▲ ---

    // データ処理とは非同期で、通知の表示設定はすぐに返す
    logger.info("  [willPresent] 通知の表示オプション（バナー、リスト等）を設定します。")
    completionHandler([.banner, .list, .sound, .badge])
}

/// 【修正】バックグラウンドで通知を受信したときに呼び出されます。
func application(_ application: UIApplication,
                 didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                 fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    
    logger.info("⬇️ [didReceiveRemoteNotification] バックグラウンド通知を受信しました。")
    logger.debug("  [didReceiveRemoteNotification] 受信データ (userInfo): \(userInfo)")
    
    if let action = userInfo["action"] as? String {
        logger.info("  [didReceiveRemoteNotification] 'action'キーが見つかりました: '\(action)'。即時処理を実行します。")
        switch action {
        case "JOIN":
            logger.info("    [didReceiveRemoteNotification] case 'JOIN' に入りました。")
            if let userName = userInfo["user_name"] as? String {
                saveUserName(userName)
                completionHandler(.newData)
            } else {
                saveUserName("名無しさんだよお")
                completionHandler(.noData)
            }
        case "DECLINE":
            logger.info("    [didReceiveRemoteNotification] case 'DECLINE' に入りました。")
            completionHandler(.noData)
        default:
            logger.info("    [didReceiveRemoteNotification] case 'default' に入りました。")
            completionHandler(.noData)
        }
    } else {
        logger.info("  [didReceiveRemoteNotification] 'action'キーが見つかりませんでした。待機処理の可能性があります。")
        
        // クラッシュ回避のため、必要な情報が揃っているか確認
        guard let notificationId = userInfo["notification_id"] as? String,
              let senderFirebaseUID = userInfo["sender_firebase_uid"] as? String,
              let senderName = userInfo["sender_name"] as? String,
              let groupId = userInfo["group_id"] as? String,
              let durationTime = userInfo["durationTime"] as? String else {
            
            logger.error("  🚨 [didReceiveRemoteNotification] 'notification_id'など待機処理に必要な情報が見つからないため、処理を中断します。")
            completionHandler(.failed)
            return
        }
        logger.info("  [didReceiveRemoteNotification] Notification ID: '\(notificationId)' を確認しました。")
        
        var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
        logger.info("  [didReceiveRemoteNotification] バックグラウンドタスクを開始します (TaskName: JoinActionCheck-\(notificationId))。")
        backgroundTaskID = application.beginBackgroundTask(withName: "JoinActionCheck-\(notificationId)") {
            self.logger.warning("  ⌛️ [didReceiveRemoteNotification] バックグラウンドタスクの時間が切れそうです。タスクを終了します。")
            application.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }

        logger.info("  [didReceiveRemoteNotification] 30秒後に非同期処理をスケジュールします。")
        DispatchQueue.global().asyncAfter(deadline: .now() + 30) {
            self.logger.info("  [asyncAfter] 非同期処理が開始されました (ID: \(notificationId))。")
            
            let userActioned = UserDefaults.standard.bool(forKey: notificationId)
            self.logger.info("    [asyncAfter] ユーザーのアクション済みフラグを確認しました: \(userActioned ? "はい" : "いいえ")。")

            if !userActioned {
                self.logger.info("    [asyncAfter] アクションがなかったので、handleDeclineActionを呼び出します。")
                self.handleDeclineAction(
                    senderFirebaseUID: senderFirebaseUID,
                    senderName: senderName,
                    groupId: groupId,
                    durationTime: durationTime
                )
            } else {
                self.logger.info("    [asyncAfter] アクション済みだったので、何もしません。")
            }
            
            self.logger.info("    [asyncAfter] 使用済みフラグ（\(notificationId)）を削除します。")
            UserDefaults.standard.removeObject(forKey: notificationId)
            
            // 【重要】必ず完了ハンドラを呼ぶ
            completionHandler(.newData)
            // 【重要】バックグラウンドタスクを終了
            application.endBackgroundTask(backgroundTaskID)
        }
    }
}

private func saveUserName(_ newName: String) {
    logger.info("➡️ [saveUserName] ユーザー名 '\(newName)' を保存します。")
    let defaults = UserDefaults.standard
    var currentNames = defaults.stringArray(forKey: "Empathies") ?? []
    currentNames.insert(newName, at: 0)
    defaults.set(currentNames, forKey: "Empathies")
    logger.info("✅ [saveUserName] 保存が完了しました。")
}

     

        /// ユーザーが通知（バナーや通知センターの項目）を操作したときに呼び出されます。

        func userNotificationCenter(_ center: UNUserNotificationCenter,

                                    didReceive response: UNNotificationResponse,

                                    withCompletionHandler completionHandler: @escaping () -> Void) {



            logger.info("➡️ [didReceive response] ユーザーが通知を操作しました。")

            let userInfo = response.notification.request.content.userInfo

            let actionIdentifier = response.actionIdentifier

            

            logger.info("  [didReceive response] Action Identifier: \(actionIdentifier)")

            logger.debug("  [didReceive response] User Info: \(userInfo)")

            

            // カスタムデータを取得

            let senderFirebaseUID = userInfo["sender_firebase_uid"] as? String

            let senderName = userInfo["sender_name"] as? String

            let groupId = userInfo["group_id"] as? String

            let durationTime = userInfo["durationTime"] as? String

            

            switch actionIdentifier {

            case "JOIN_ACTION":

                logger.info("    [didReceive response] 'JOIN_ACTION' が選択されました。")

                handleJoinAction(

                    senderFirebaseUID: senderFirebaseUID!,

                    senderName: senderName!,

                    groupId: groupId!,

                    durationTime: durationTime!

                )

            case "DECLINE_ACTION":

                logger.info("    [didReceive response] 'DECLINE_ACTION' が選択されました。")

                handleDeclineAction(

                    senderFirebaseUID: senderFirebaseUID!,

                    senderName: senderName!,

                    groupId: groupId!,

                    durationTime: durationTime!

                )

            default:

                logger.info("    [didReceive response] デフォルトのアクション（通知タップ）が選択されました。")

                break

            }



            if let notificationId = userInfo["notification_id"] as? String {

                logger.info("  [didReceive response] アクション済みフラグを立てます (ID: \(notificationId))。")

                UserDefaults.standard.set(true, forKey: notificationId)

            } else {

                logger.warning("  [didReceive response] アクション済みフラグを立てようとしましたが、'notification_id'が見つかりませんでした。")

            }

            

            completionHandler()

            logger.info("✅ [didReceive response] 通知操作のハンドリングを完了しました。")

        }
  func handleJoinAction(senderFirebaseUID: String, senderName: String, groupId: String, durationTime: String) {

        logger.info("➡️ [handleJoinAction] 参加APIの送信処理を開始します。")

        let user = KeychainManager.shared.getUser()

        if let user = user {

            do {

                try APIClient.shared.sendAction(firebaseUID: user.id, actionIdentifier: "JOIN_ACTION", groupId: groupId, senderName: senderName, senderFirebaseUID: senderFirebaseUID, durationTime: "0")

                logger.info("✅ [handleJoinAction] 参加APIの送信に成功しました。")

            } catch {

                logger.error("🚨 [handleJoinAction] 参加APIの送信に失敗しました: \(error.localizedDescription)")

            }

        } else {

            logger.warning("🚨 [handleJoinAction] ユーザー情報が取得できなかったため、APIを送信できませんでした。")

        }

    }

    

    func handleDeclineAction(senderFirebaseUID: String, senderName: String, groupId: String, durationTime: String) {

        logger.info("➡️ [handleDeclineAction] 辞退APIの送信処理を開始します。")

        let user = KeychainManager.shared.getUser()

        if let user = user {

            do {

                try APIClient.shared.sendAction(firebaseUID: user.id, actionIdentifier: "DECLINE_ACTION", groupId: groupId, senderName: senderName, senderFirebaseUID: senderFirebaseUID, durationTime: "0")

                logger.info("✅ [handleDeclineAction] 辞退APIの送信に成功しました。")

            } catch {

                logger.error("🚨 [handleDeclineAction] 辞退APIの送信に失敗しました: \(error.localizedDescription)")

            }

        } else {

            logger.warning("🚨 [handleDeclineAction] ユーザー情報が取得できなかったため、APIを送信できませんでした。")

        }

    }
}
