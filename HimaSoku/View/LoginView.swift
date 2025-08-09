//
//  LoginVIew.swift
//  HimaSoku
//
//  Created by Shuto Sawaki on 2025/08/08.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import Alamofire
import KeychainAccess


struct LoginView: View {
    @State var name: String = ""
    @State var password: String = ""
    @State var isLogined: Bool = false
    @State var user: User? = nil
    var body: some View {
        if isLogined {
            HimaTabView(user: user!)
        } else {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [.orange, .orange.opacity(0.3)]), startPoint: .top, endPoint: .bottom)
                    .opacity(0.6)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                VStack(spacing: 30) {
                    Image("hima-man")
                        .resizable()
                        .scaledToFit()
                    
                    Text("HimaSoku")
                        .fontWeight(.bold)
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .offset(y: -60)
                    Button("Googleでログイン") {
                        googleAuth()
                    }
                    .fontWeight(.bold)
                    .frame(width: 200, height: 70, alignment: .center)
                    .background(Color.white)
                    .cornerRadius(15)
                    .clipped()
                    .shadow(radius: 8)
                }
                .offset(y: -100)

                
            }
            .ignoresSafeArea()
            .environment(\.user, self.user ?? User(id: "", name: ""))
        }

    }
}
extension LoginView {
    
    private func googleAuth() {
           
           guard let clientID:String = FirebaseApp.app()?.options.clientID else { return }
           let config:GIDConfiguration = GIDConfiguration(clientID: clientID)
           
           let windowScene:UIWindowScene? = UIApplication.shared.connectedScenes.first as? UIWindowScene
           let rootViewController:UIViewController? = windowScene?.windows.first!.rootViewController!
           
           GIDSignIn.sharedInstance.configuration = config
           
           GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController!) { result, error in
               guard error == nil else {
                   print("GIDSignInError: \(error!.localizedDescription)")
                   return
               }
               
               guard let user = result?.user,
                     let idToken = user.idToken?.tokenString
               else {
                   return
               }
               
               let credential = GoogleAuthProvider.credential(withIDToken: idToken,accessToken: user.accessToken.tokenString)
               self.login(credential: credential)
           }
       }
       
    private func login(credential: AuthCredential) {
           Auth.auth().signIn(with: credential) { (authResult, error) in
               if let error = error {
                   print("SignInError: \(error.localizedDescription)")
                   return
               }
               guard let firebase_uid = authResult?.user.uid, let name = authResult?.user.displayName else {
                   return
               }
               
               self.user = User(id: firebase_uid, name: name)
               if let user = user {
                   KeychainManager.shared.save(key: KeychainKey.user_name.rawValue, stringData: user.name)
                   KeychainManager.shared.save(key: KeychainKey.user_id.rawValue, stringData: user.id)
                   
                   let params = ["firebase_uid": user.id, "name": user.name, "email": authResult!.user.email! ]
                   
                   Task {
                       do {
                           let status = try await APIClient.shared.postData(path: "/users", params: params)
                           
                           switch status {
                           case .success:
                               print("ユーザー情報保存成功")
                           case .failure:
                               self.isLogined = false
                               return
                           }
                           
                           guard let device_token = UserDefaults.standard.string(forKey: "device_token") else { return }
                           
                           let result = try await APIClient.shared.postDeviceToken(path: "/devices", uid: firebase_uid, deviceId: device_token)
                           switch result {
                           case .success:
                               self.isLogined = true
                               return
                           case .failure:
                               self.isLogined = false
                               return
                           }
                       } catch {
                           print(error.localizedDescription)
                       }
                   }

               }
           }
       }
}

#Preview {
    LoginView()
}
