//
//  KeyChainManager.swift
//  HimaSoku
//
//  Created by Shuto Sawaki on 2025/08/08.
//

import Foundation
import KeychainAccess


enum KeychainKey: String {
    case userAuthToken
    case refreshToken
    case user_name
    case user_id
    case group_ids
}

final class KeychainManager {
    // アプリ内で常に同じインスタンスにアクセスできるようにシングルトンにする
    static let shared = KeychainManager()

    // キーチェーンのインスタンスを生成
    // service名は、他のアプリと衝突しないように、アプリのBundle IDを使うのが一般的
    private let keychain = Keychain(service: "com.sawaki.HimaSoku")
    
    // プライベートな初期化子で、外部からのインスタンス生成を防ぐ
    private init() {}
    
    // キーをenumで管理すると、タイプミスを防げて安全


    // MARK: - Public Methods
    
    // ここに、追加・取得・削除のメソッドを定義していく
    
    // KeychainManager.swift の中にメソッドを追加

    func save(key: KeychainKey.RawValue, stringData: String) {
        do {
            // "userAuthToken" というキーで、渡されたtoken文字列を保存
            try keychain.set(stringData, key: key)
            print("✅ キーチェーンへのトークン保存が成功しました。")
        } catch let error {
            print("❌ キーチェーンへの保存に失敗しました: \(error)")
        }
    }
    
    // KeychainManager.swift の中にメソッドを追加

    func getToken(key: KeychainKey.RawValue) -> String? {
        do {
            // "userAuthToken" というキーに対応する文字列を取得
            let token = try keychain.getString(key)
            return token
        } catch let error {
            print("❌ キーチェーンからの取得に失敗しました: \(error)")
            return nil
        }
    }
    
    // KeychainManager.swift の中にメソッドを追加

    func deleteToken(key: KeychainKey.RawValue) {
        do {
            // "userAuthToken" というキーのデータを削除
            try keychain.remove(key)
            print("🗑️ キーチェーンからトークンを削除しました。")
        } catch let error {
            print("❌ キーチェーンからの削除に失敗しました: \(error)")
        }
    }
    
    func getUser()  -> User? {
        do {
            // "userAuthToken" というキーのデータを削除
            guard let userName = try keychain.getString(KeychainKey.user_name.rawValue) else { return nil }
            guard let userId = try keychain.getString(KeychainKey.user_id.rawValue) else {return nil}
            print("取得できた")
            return User(id: userId, name: userName)
        } catch let error {
            print("❌ キーチェーンからの削除に失敗しました: \(error)")
            return nil
        }
    }
    
    /// 趣味の配列をJSONデータに変換してキーチェーンに保存する
    func save(group_ids: [String]) {
        // 1. 配列をJSON Dataにエンコード（変換）する
        guard let data = try? JSONEncoder().encode(group_ids) else {
            print("❌ 配列のJSONエンコードに失敗しました。")
            return
        }
        
        // 2. Data型としてキーチェーンに保存する
        do {
            try keychain.set(data, key: KeychainKey.group_ids.rawValue)
            print("✅ キーチェーンへの趣味配列の保存が成功しました。")
        } catch let error {
            print("❌ キーチェーンへの保存に失敗しました: \(error)")
        }
    }
    
    func getgroups() -> [String]? {
        do {
            // 1. Data型としてキーチェーンから取得する
            guard let data = try keychain.getData(KeychainKey.group_ids.rawValue) else {
                return nil // データが存在しない場合はnilを返す
            }
            
            // 2. JSON Dataを配列にデコード（復元）する
            let group_ids = try JSONDecoder().decode([String].self, from: data)
            return group_ids
            
        } catch let error {
            print("❌ キーチェーンからの取得またはデコードに失敗しました: \(error)")
            return nil
        }
    }
    
    
    
    
}
