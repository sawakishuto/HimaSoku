import UIKit
import UserNotifications
import os.log

class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // UNUserNotificationCenterのデリゲートを自身に設定します。
        // これにより、通知に関するイベント（フォアグラウンドでの受信など）をこのクラスで一元管理できます。
        UNUserNotificationCenter.current().delegate = self
        
        // ユーザーに通知の許可を要求します。
        requestNotificationAuthorization()
        
        return true // 起動処理が成功したことを示します。
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
        // ここで、取得したデバイストークンを自社のサーバーに送信する処理を実装します。
    }

    /// APNsへのデバイス登録が失敗した場合に呼び出されます。
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        os_log("リモート通知の登録に失敗しました: %@", log: .default, type: .error, error.localizedDescription)
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {

    /// アプリがフォアグラウンドで動作中に通知を受信したときに呼び出されます。
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        // フォアグラウンドで通知をどのように表示するかを指定します。
        // iOS 14以降では、複数のオプションを組み合わせることができます。
        // .banner: 画面上部にバナーとして表示
        // .list: 通知センターにリストとして表示
        // .sound: 通知音を再生
        // .badge: アプリアイコンにバッジを表示
        completionHandler([.banner, .list, .sound, .badge])
    }

    /// ユーザーが通知（バナーや通知センターの項目）を操作したときに呼び出されます。
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {

        // 通知に含まれる情報（userInfo）を使って、特定の処理を実行できます。
        // 例：通知をタップしたら特定の画面を開くなど。
        let userInfo = response.notification.request.content.userInfo
        os_log("ユーザーが通知に応答しました。UserInfo: %@", log: .default, type: .info, userInfo)
        
        // 処理が完了したら必ずcompletionHandlerを呼び出します。
        completionHandler()
    }
}
