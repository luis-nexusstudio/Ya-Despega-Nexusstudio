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
import UIKit
import AuthenticationServices

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
    
    func signInWithApple(from viewController: UIViewController, completion: @escaping (Result<ASAuthorizationAppleIDCredential, Error>) -> Void) {
        // Crear el proveedor de Apple ID y la solicitud
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        // Configurar el controlador de autorización
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        
        // Crear y asignar el delegado
        let delegate = AppleSignInDelegate(viewController: viewController, completion: completion)
        authorizationController.delegate = delegate
        authorizationController.presentationContextProvider = delegate
        
        // Mantener una referencia fuerte al delegado
        objc_setAssociatedObject(viewController, &AssociatedKeys.delegateKey, delegate, .OBJC_ASSOCIATION_RETAIN)
        
        // Iniciar el proceso de autenticación
        authorizationController.performRequests()
    }

    // Claves para objc_setAssociatedObject
    private struct AssociatedKeys {
        static var delegateKey = "AppleSignInDelegateKey"
    }

    // Clase delegada para manejar la respuesta de Sign in with Apple
    private class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
        
        weak var viewController: UIViewController?
        var completion: (Result<ASAuthorizationAppleIDCredential, Error>) -> Void
        
        init(viewController: UIViewController, completion: @escaping (Result<ASAuthorizationAppleIDCredential, Error>) -> Void) {
            self.viewController = viewController
            self.completion = completion
            super.init()
        }
        
        // ASAuthorizationControllerDelegate
        func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                // Éxito - devolvemos las credenciales
                completion(.success(appleIDCredential))
            } else {
                // No se recibió un credential de tipo ASAuthorizationAppleIDCredential
                completion(.failure(NSError(domain: "com.appleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "No se recibió un credential válido"])))
            }
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            // Error en el proceso de autenticación
            completion(.failure(error))
        }
        
        // ASAuthorizationControllerPresentationContextProviding
        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            return viewController!.view.window!
        }
    }
}
