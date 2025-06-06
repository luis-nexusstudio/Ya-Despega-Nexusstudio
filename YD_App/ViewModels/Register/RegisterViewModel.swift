//
//  RegisterViewModel.swift
//  YD_App
//
//  Created by Luis Melendez on 24/04/25.
//

import SwiftUI
import FirebaseAuth

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
    @Published var currentAppError: AppErrorProtocol?
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
        
        let formData = RegisterFormData(
            nombres: nombres,
            apellidoPaterno: apellidoPaterno,
            apellidoMaterno: apellidoMaterno,
            numeroCelular: numeroCelular,
            email: email,
            password: password
        )
        
        let validationResult = UserDataValidator.validate(formData)
        
        if !validationResult.isValid {
            currentAppError = CommonAppError.unknown(validationResult.firstErrorMessage ?? "Datos inválidos")
            registerState = .error
            return
        }
                
        isLoading = true
        registerState = .loading
        currentAppError = nil

        
        Task {
            do {
                let user = try await registerUserAsync(
                    email: email,
                    password: password,
                    nombres: nombres,
                    apellidoPaterno: apellidoPaterno,
                    apellidoMaterno: apellidoMaterno,
                    numeroCelular: numeroCelular)
                
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
    
    // ✅ REEMPLAZAR el método isFormValid
    func isFormValid(nombres: String, apellidoPaterno: String, apellidoMaterno: String, numeroCelular: String, email: String, password: String) -> Bool {
        let formData = RegisterFormData(
            nombres: nombres,
            apellidoPaterno: apellidoPaterno,
            apellidoMaterno: apellidoMaterno,
            numeroCelular: numeroCelular,
            email: email,
            password: password
        )
            
        return UserDataValidator.validate(formData).isValid
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
        self.currentAppError = error.toAppError()
    }
}
