//
//  LoginViewModel.swift
//  YD_App
//
//  Created by Luis Melendez on 22/04/25.
//

import FirebaseAuth
import Firebase
import GoogleSignIn
import SwiftUI

class LoginViewModel: ObservableObject {
    @Published var isLoggedIn = false

    // 🔵 Inicio de sesión con Google
    func signInWithGoogle(presenting: UIViewController, completion: @escaping (Bool) -> Void) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("No clientID found")
            completion(false)
            return
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        GIDSignIn.sharedInstance.signIn(withPresenting: presenting) { result, error in
            if let error = error {
                print("Google Sign-In error:", error.localizedDescription)
                completion(false)
                return
            }

            guard
                let idToken = result?.user.idToken?.tokenString,
                let accessToken = result?.user.accessToken.tokenString
            else {
                completion(false)
                return
            }

            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("Firebase Sign-In error:", error.localizedDescription)
                    completion(false)
                    return
                }

                print("Google Sign-In success:", authResult?.user.email ?? "")
                self.isLoggedIn = true
                completion(true)
            }
        }
    }

    // 🟡 Inicio de sesión con correo y contraseña
    func signInWithEmail(email: String, password: String, completion: @escaping (Bool) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("Email Sign-In error:", error.localizedDescription)
                completion(false)
                return
            }

            print("Email Sign-In success:", authResult?.user.email ?? "")
            self.isLoggedIn = true
            completion(true)
        }
    }
}
