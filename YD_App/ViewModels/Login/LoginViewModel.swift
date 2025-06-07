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

@MainActor
class LoginViewModel: ObservableObject {
    @Published var isLoggedIn = false
    private let sessionManager = SessionManager.shared

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

            Auth.auth().signIn(with: credential) { [weak self] authResult, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Firebase Sign-In error:", error.localizedDescription)
                    completion(false)
                    return
                }

                print("Google Sign-In success:", authResult?.user.email ?? "")
                
                Task { @MainActor in
                    self.isLoggedIn = true
                    completion(true)
                }
            }
        }
    }

    // 🟡 Inicio de sesión con correo y contraseña
    func signInWithEmail(email: String, password: String, completion: @escaping (Bool) -> Void) {
        // Validación básica
        guard !email.isEmpty, !password.isEmpty else {
            print("Email o contraseña vacíos")
            completion(false)
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Email Sign-In error:", error.localizedDescription)
                
                // Manejar errores específicos si lo deseas
                if let errorCode = AuthErrorCode(rawValue: error._code) {
                    switch errorCode {
                    case .wrongPassword:
                        print("Contraseña incorrecta")
                    case .invalidEmail:
                        print("Email inválido")
                    case .userNotFound:
                        print("Usuario no encontrado")
                    default:
                        print("Error de autenticación: \(errorCode)")
                    }
                }
                
                completion(false)
                return
            }

            print("Email Sign-In success:", authResult?.user.email ?? "")
            
            Task { @MainActor in
                self.isLoggedIn = true
                completion(true)
            }
        }
    }
    
    
}
