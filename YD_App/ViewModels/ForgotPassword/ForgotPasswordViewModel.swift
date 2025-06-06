//
//  ForgotPasswordViewModel.swift
//  YD_App
//
//  Created by Pedro Martinez on 29/05/25.
//

import Foundation
import FirebaseAuth

class ForgotPasswordViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func sendPasswordReset(email: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    // Manejo de errores específicos
                    let authError = error as NSError
                    
                    switch authError.code {
                    case AuthErrorCode.invalidEmail.rawValue:
                        self?.errorMessage = "El correo electrónico no es válido."
                    case AuthErrorCode.userNotFound.rawValue:
                        self?.errorMessage = "No existe una cuenta con este correo electrónico."
                    case AuthErrorCode.networkError.rawValue:
                        self?.errorMessage = "Error de conexión. Verifica tu internet."
                    case AuthErrorCode.tooManyRequests.rawValue:
                        self?.errorMessage = "Demasiados intentos. Intenta más tarde."
                    default:
                        self?.errorMessage = "Error: \(error.localizedDescription)"
                    }
                    
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
    }
}
