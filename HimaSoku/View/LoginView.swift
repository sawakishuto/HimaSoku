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


struct LoginView: View {
    @State var name: String = ""
    @State var password: String = ""
    @State var isLogined: Bool = false
    var body: some View {
        if isLogined {
            HimaTabView()
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
               print(authResult?.user.uid)
               print(authResult?.user.displayName)
               authResult?.user.getIDToken { (idToken, error) in
                   print(idToken)
               }
           }
       }
}

#Preview {
    LoginView()
}
