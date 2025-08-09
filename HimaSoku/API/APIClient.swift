import Foundation
import Alamofire
import FirebaseAuth

// MARK: - APIError
// API関連のエラーを統括するカスタムエラー型
enum APIError: Error, LocalizedError {
    case authenticationError
    case forbidden
    case invalidURL
    case decodingError
    case unknown(statusCode: Int?)

    var errorDescription: String? {
        switch self {
        case .authenticationError: "認証に失敗しました。再度ログインしてください。"
        case .forbidden: "アクセス権がありません。"
        case .invalidURL: "無効なURLです。"
        case .decodingError: "レスポンスデータの解析に失敗しました。"
        case .unknown(let code): "不明なエラーが発生しました。\(code.map { "(\($0))" } ?? "")"
        }
    }
}

// MARK: - APIClient
final class APIClient {

    static let shared = APIClient()
    private let baseURL = "https://himasoku-234324210193.asia-northeast1.run.app" // baseURLのほうが一般的

    private init() {}

    // MARK: - Public Methods
    // 各HTTPメソッドに対応する公開メソッド。内部で共通の`request`メソッドを呼ぶだけ。

    func fetchData<T: Decodable>(path: String, params: Parameters? = nil) async throws -> T {
        return try await baseRequest(path: path, method: .get, parameters: params)
    }

    func postData(path: String, params: Parameters) async throws -> Result<Int, Error> {
        return try await postRequest(path: path, method: .post, parameters: params, encoding: JSONEncoding.default)
    }

    func putData(path: String, params: Parameters) async throws -> Result<Int, Error> {
        return try await postRequest(path: path, method: .put, parameters: params, encoding: JSONEncoding.default)
    }
    
    func patchData(path: String, params: Parameters) async throws -> Result<Int, Error> {
        return try await postRequest(path: path, method: .patch, parameters: params, encoding: JSONEncoding.default)
    }

    func postDeviceToken(path: String, uid: String, deviceId: String) async throws -> Result<Int, Error>  {
        let params = ["device_id": deviceId, "firebase_uid": uid]
        
        return try await postRequest(path: path, method: .post, parameters: params, encoding: JSONEncoding.default)
    }
    
    // MARK: - Core Logic (Private)
    /// レスポンスボディを必要としないPOSTリクエストを送信するメソッド
    private func postRequest(
        path: String,
        method: HTTPMethod,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = JSONEncoding.default
    ) async throws -> Result<Int, Error> { // 戻り値を Void にする (書かなくても同じ)
        // 1. FirebaseからIDトークンを非同期で取得
        let token = try await getUserToken()
        
        let url = baseURL + path
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json"
        ]

        // 2. Alamofireでリクエストを実行し、レスポンスを待つ
        do {
            // .serializingData() を使い、レスポンスボディは無視する
            // .validate() がステータスコードの検証をしてくれる
            // 成功すれば何もせず、失敗すればエラーがthrowされる
            let response = try await AF.request(url,
                                     method: .post,
                                     parameters: parameters,
                                     encoding: encoding,
                                     headers: headers)
                .validate(statusCode: 200..<300)
                .serializingData() // または .serializingEmpty()
                .value
            
            print("✅ POST Request Succeeded (No Response Body): to \(url)")
            return .success(200)
            // 成功時は何も返さない
            
        } catch {
            // 発生したエラーをカスタムエラーに変換してthrowする
            print("❌ POST Request Failed: \(error.localizedDescription)")
            throw mapToAPIError(from: error)
        }
    }

    
    /// 全てのAPIリクエストのコアとなる、汎用的なプライベートメソッド
    private func baseRequest<T: Decodable>(
        path: String,
        method: HTTPMethod,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = URLEncoding.default
    ) async throws -> T {
        // 1. FirebaseからIDトークンを非同期で取得
        let token = try await getUserToken()
        
        let url = baseURL + path
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)", // "Bearer "プリフィックスが一般的
            "Accept": "application/json"
        ]

        // 2. Alamofireでリクエストを実行し、レスポンスを待つ
        do {
            let value = try await AF.request(url,
                                             method: method,
                                             parameters: parameters,
                                             encoding: encoding,
                                             headers: headers)
                .validate(statusCode: 200..<300) // 200番台でなければエラーをthrowする
                .serializingDecodable(T.self)   // レスポンスを自動でデコード
                .value                          // 結果を非同期で待つ
            
            print("✅ Request Succeeded: \(method.rawValue) to \(url)")
            return value
        } catch {
            // 発生したエラーをカスタムエラーに変換してthrowする
            print("❌ Request Failed: \(error)")
            throw mapToAPIError(from: error)
        }
    }

    /// Firebase AuthからIDトークンを非同期で取得する
    private func getUserToken() async throws -> String {
        guard let user = Auth.auth().currentUser else {
            throw APIError.authenticationError
        }
        
        let token = try await user.getIDToken()
        // user.getIDToken()は元々async throwsに対応している
        // tokenを入れ直している
        KeychainManager.shared.deleteToken(key: KeychainKey.userAuthToken.rawValue)
        KeychainManager.shared.save(key: KeychainKey.userAuthToken.rawValue, stringData: token)
        return token
    }

    /// Alamofireのエラーを独自のAPIErrorにマッピングする
    private func mapToAPIError(from error: Error) -> APIError {
        if let afError = error as? AFError {
            switch afError {
            case .responseValidationFailed(let reason):
                if case .unacceptableStatusCode(let code) = reason {
                    switch code {
                    case 401: return .authenticationError
                    case 403: return .forbidden
                    case 404: return .invalidURL
                    default: return .unknown(statusCode: code)
                    }
                }
            case .responseSerializationFailed:
                return .decodingError
            default:
                break // その他のAFErrorは下のunknownにフォールスルー
            }
        }
        return .unknown(statusCode: nil)
    }
    
    func sendJoinAction(
            firebaseUID: String,
            actionIdentifier: String,
            groupId: String,
            senderName: String,
            senderFirebaseUID: String,
            durationTime: String?
        ) {
            guard let url = URL(string: "\(baseURL)/notifications/response") else { return }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // Firebase IDトークンを取得してAuthorizationヘッダーに設定
            Auth.auth().currentUser?.getIDToken { [weak self] token, error in
                guard let token = token else { return }
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                
                let parameters: [String: Any] = [
                    "firebase_uid": firebaseUID,
                    "action_identifier": actionIdentifier,
                    "group_id": groupId,
                    "sender_name": senderName,
                    "sender_firebase_uid": senderFirebaseUID,
                    "duration_time": durationTime ?? ""
                ]
                
                do {
                    request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
                    
                    URLSession.shared.dataTask(with: request) { data, response, error in
                        // レスポンス処理
                        if let error = error {
                            print("Error: \(error)")
                            return
                        }
                        
                        print("Join action sent successfully")
                    }.resume()
                    
                } catch {
                    print("JSON serialization error: \(error)")
                }
            }
        }
}
