//
//  AuthenticationViewModel.swift
//  Messenger
//
//  Created by Mahmud CIKRIK on 6.01.2024.
//

import Foundation

class AuthenticationViewModel {
//    func signInWithGoogle() async -> Bool {
//        guard let clientID = FirebaseApp.app()?.options.clientID else { fatalError("No client ID found") }
//
//        // Create Google Sign In configuration object.
//        let config = GIDConfiguration(clientID: clientID)
//        GIDSignIn.sharedInstance.configuration = config
//        
//        guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
//              let window = await windowScene.windows.first,
//              let rootViewController = await window.rootViewController else {
//            print("There is no root view controller")
//            return false
//        }
//        
//        do {
//            let userAuthentication = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
//            let user = userAuthentication.user
//            guard let idToken = user.idToken else {
//                throw fatalError("token error")
//            }
//            let accessToken = user.accessToken
//            let credential = GoogleAuthProvider.credential(withIDToken: idToken.tokenString, accessToken: accessToken.tokenString)
//            let result = try await Auth.auth().signIn(with: credential)
//            let firebaseUser = result.user
//            print("User \(firebaseUser.uid) signed in with email \(firebaseUser.email ?? "unknown")")
//            return true
//        } catch {
//            print(error.localizedDescription)
//            let errorMessage = error.localizedDescription
//            return false
//        }
//            
//            
//        return false
//    }
}
