//
//  RegisterViewModel.swift
//  YD_App
//
//  Created by Luis Melendez on 24/04/25.
//

import SwiftUI

// MARK: - Register State
enum RegisterState {
    case idle
    case loading
    case success
    case error
}

// MARK: - RegisterViewModel
@MainActor
class RegisterViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isLoading: Bool = false
    @Published var currentAppError: AppError?
    @Published var isRetrying: Bool = false
    @Published var registerState: RegisterState = .idle
    @Published var registeredUser: RegisteredUser?
    
    // MARK: - Computed Properties
    var hasError: Bool {
        return currentAppError != nil
    }
    
    var isRegistrationComplete: Bool {
        return registeredUser != nil && registerState == .success
    }
    
    // MARK: - Public Methods
    
    /// Registrar usuario usando el backend
    func registerUser(
        email: String,
        password: String,
        nombres: String,
        apellidoPaterno: String,
        apellidoMaterno: String,
        numeroCelular: String,
        onSuccess: @escaping () -> Void
    ) {
        guard !isLoading else { return }
        
        // Validación previa
        if let validationError = validateUserData(email: email, password: password, nombres: nombres, apellidoPaterno: apellidoPaterno, numeroCelular: numeroCelular) {
            currentAppError = AppError.unknown(validationError)
            registerState = .error
            return
        }
        
        isLoading = true
        registerState = .loading
        currentAppError = nil
        
        Task {
            do {
                let user = try await registerUserAsync(email: email, password: password, nombres: nombres, apellidoPaterno: apellidoPaterno, apellidoMaterno: apellidoMaterno, numeroCelular: numeroCelular)
                
                self.registeredUser = user
                self.registerState = .success
                AuthStateManager.shared.handleSuccessfulRegistration()
                self.isLoading = false
                
                // Manejar timing en ViewModel
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    onSuccess() // Callback para navegación
                    self.registerState = .idle
                }
                
            } catch {
                self.handleError(error)
                self.registerState = .error
                self.isLoading = false
                
                // Auto-reset después del error
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.registerState = .idle
                }
            }
        }
    }
    
    /// Retry registro
    func retryRegister(email: String, password: String, nombres: String, apellidoPaterno: String, apellidoMaterno: String, numeroCelular: String, onSuccess: @escaping () -> Void) {
        guard !isRetrying else { return }
        isRetrying = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isRetrying = false
            self.registerUser(email: email, password: password, nombres: nombres, apellidoPaterno: apellidoPaterno, apellidoMaterno: apellidoMaterno, numeroCelular: numeroCelular, onSuccess: onSuccess)
        }
    }
    
    /// Reset del estado del ViewModel
    func resetState() {
        currentAppError = nil
        isLoading = false
        registerState = .idle
        registeredUser = nil
        isRetrying = false
    }
    
    /// Validar formato de contraseña
    func isValidPassword(_ password: String) -> Bool {
        return password.count >= 6 &&
               hasSpecialCharacter(password) &&
               hasUppercaseLetter(password)
    }
    
    /// Verificar si tiene carácter especial
    func hasSpecialCharacter(_ password: String) -> Bool {
        return password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")) != nil
    }
    
    /// Verificar si tiene al menos una mayúscula
    func hasUppercaseLetter(_ password: String) -> Bool {
        return password.rangeOfCharacter(from: .uppercaseLetters) != nil
    }
    
    /// Validar si el formulario completo es válido
    func isFormValid(nombres: String, apellidoPaterno: String, apellidoMaterno: String, numeroCelular: String, email: String, password: String) -> Bool {
        return !nombres.isEmpty &&
               !apellidoPaterno.isEmpty &&
               !apellidoMaterno.isEmpty &&
               !numeroCelular.isEmpty &&
               !email.isEmpty &&
               isValidPassword(password)
    }
    
    /// Validar datos antes del registro
    func validateUserData(
        email: String,
        password: String,
        nombres: String,
        apellidoPaterno: String,
        numeroCelular: String
    ) -> String? {
        if email.isEmpty {
            return "El correo es requerido"
        }
        
        if password.isEmpty {
            return "La contraseña es requerida"
        }
        
        if password.count < 6 {
            return "La contraseña debe tener al menos 6 caracteres"
        }
        
        if !hasSpecialCharacter(password) {
            return "La contraseña debe tener al menos un carácter especial"
        }
        
        if !hasUppercaseLetter(password) {
            return "La contraseña debe tener al menos una mayúscula"
        }
        
        if nombres.isEmpty {
            return "El nombre es requerido"
        }
        
        if apellidoPaterno.isEmpty {
            return "El apellido paterno es requerido"
        }
        
        if numeroCelular.isEmpty {
            return "El número celular es requerido"
        }
        
        return nil
    }
    
    // MARK: - Private Methods
    
    private func registerUserAsync(email: String, password: String, nombres: String, apellidoPaterno: String, apellidoMaterno: String, numeroCelular: String) async throws -> RegisteredUser {
        return try await withCheckedThrowingContinuation { continuation in
            RegisterService.registerUser(email: email, password: password, nombres: nombres, apellidoPaterno: apellidoPaterno, apellidoMaterno: apellidoMaterno, numeroCelular: numeroCelular) { result in
                switch result {
                case .success(let user):
                    continuation.resume(returning: user)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Lifecycle
    func onAppear() {
        // Preparar ViewModel si es necesario
    }
    
    func onDisappear() {
        // Limpiar recursos si es necesario
    }
    
    private func handleError(_ error: Error) {
        print("❌ RegisterViewModel error:", error.toAppError())
        self.currentAppError = error.toAppError()
    }
}
