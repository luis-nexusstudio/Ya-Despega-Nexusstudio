//
//  VerificationViewModel.swift
//  YD_App
//
//  Created by Luis Melendez on 02/06/25.
//

import SwiftUI
import FirebaseAuth

@MainActor
class VerificationViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isVerified: Bool = false
    @Published var canPurchase: Bool = false
    @Published var isLoading: Bool = false
    @Published var verificationData: VerificationData?
    @Published var currentAppError: AppErrorProtocol?
    @Published var isRetrying: Bool = false
    
    // 🔥 NUEVAS PROPIEDADES PARA RESEND EMAIL
    @Published var isResendingEmail: Bool = false
    @Published var resendMessage: String?
    @Published var showResendSuccess: Bool = false
    @Published var resendError: String?
    
    // MARK: - Computed Properties
    var needsVerification: Bool {
        return !isVerified
    }
    
    var verificationMessage: String {
        if isVerified {
            return "✅ Tu correo está verificado"
        } else {
            return "📧 Debes verificar tu correo electrónico para continuar con la compra. Revisa tu bandeja de entrada."
        }
    }
    
    var shouldShowVerificationAlert: Bool {
        return needsVerification && !isLoading
    }
    
    // 🔥 NUEVO: Estado del botón de reenvío
    var canResendEmail: Bool {
        return !isResendingEmail && !isLoading && needsVerification
    }
    
    // MARK: - Initialization
    init() {
        // No cargar automáticamente al inicializar
        // Se cargará cuando sea necesario
    }
    
    // MARK: - Public Methods
    
    /// Verificar estado de verificación (llamar antes de comprar)
    func checkVerificationStatus() {
        guard !isLoading else { return }
        
        isLoading = true
        currentAppError = nil
        
        print("🔐 [VerificationViewModel] Verificando estado de email...")
        
        VerificationService.getVerificationStatus { [weak self] result in
            guard let self = self else { return }
            
            self.isLoading = false
            self.isRetrying = false
            
            switch result {
            case .success(let data):
                self.verificationData = data
                self.isVerified = data.verified
                self.canPurchase = data.canPurchase
                
                print("✅ [VerificationViewModel] Estado obtenido - Verificado: \(data.verified)")
                
            case .failure(let error):
                self.handleError(error)
                print("❌ [VerificationViewModel] Error verificando estado: \(error.localizedDescription)")
            }
        }
    }
    
    /// Verificación rápida solo para saber si puede comprar
    func quickCanPurchaseCheck(completion: @escaping (Bool) -> Void) {
        VerificationService.canPurchase { [weak self] result in
            switch result {
            case .success(let canPurchase):
                self?.canPurchase = canPurchase
                self?.isVerified = canPurchase // Asumir que si puede comprar, está verificado
                completion(canPurchase)
                
            case .failure(let error):
                self?.handleError(error)
                completion(false)
            }
        }
    }
    
    /// Reintentar verificación
    func retryVerification() {
        guard !isRetrying else { return }
        isRetrying = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.checkVerificationStatus()
        }
    }
    
    // 🔥 NUEVO: Reenviar email de verificación usando el backend
    func resendVerificationEmail() {
        guard !isResendingEmail else { return }
            
        isResendingEmail = true
        resendMessage = nil
        resendError = nil
        showResendSuccess = false
            
        print("📧 [VerificationViewModel] Iniciando reenvío de email desde cliente...")
            
        guard let user = Auth.auth().currentUser else {
            self.resendError = "No hay usuario autenticado"
            self.resendMessage = "❌ \(self.resendError ?? "")"
            self.isResendingEmail = false
            return
        }
            
            // Recargar usuario para verificar estado actual
        user.reload { [weak self] reloadError in
            guard let self = self else { return }
                
            if user.isEmailVerified {
                self.resendMessage = "✅ Tu email ya está verificado"
                self.showResendSuccess = true
                self.isVerified = true
                self.canPurchase = true
                self.isResendingEmail = false
                    
                // Limpiar mensaje después de unos segundos
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                    withAnimation {
                        self.resendMessage = nil
                        self.showResendSuccess = false
                    }
                }
                return
            }
                
            // Enviar email de verificación
            user.sendEmailVerification { [weak self] error in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    
                    self.isResendingEmail = false
                    
                    if let error = error {
                        self.resendError = "Error enviando email: \(error.localizedDescription)"
                        self.resendMessage = "❌ \(self.resendError ?? "")"
                        self.showResendSuccess = false
                            
                        print("❌ [VerificationViewModel] Error enviando email:", error.localizedDescription)
                            
                        // Limpiar mensaje de error después de más tiempo
                        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
                            withAnimation {
                                self.resendMessage = nil
                                self.resendError = nil
                            }
                        }
                    } else {
                        self.resendMessage = "✅ Email de verificación enviado correctamente"
                        self.showResendSuccess = true
                        
                        print("✅ [VerificationViewModel] Email enviado desde cliente iOS")
                        
                        // Limpiar mensaje después de unos segundos
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                            withAnimation {
                                self.resendMessage = nil
                                self.showResendSuccess = false
                            }
                        }
                    }
                }
            }
        }
    }
    /// Limpiar estado (útil al cerrar sesión)
    func resetState() {
        isVerified = false
        canPurchase = false
        verificationData = nil
        currentAppError = nil
        isLoading = false
        isRetrying = false
        // 🔥 LIMPIAR ESTADOS DE RESEND
        isResendingEmail = false
        resendMessage = nil
        showResendSuccess = false
        resendError = nil
    }
    
    /// Forzar recarga del estado (útil después de que el usuario diga que ya verificó)
    func forceRefresh() {
        print("🔄 [VerificationViewModel] Forzando recarga del estado...")
        resetState()
        checkVerificationStatus()
    }
    
    // 🔥 NUEVO: Limpiar solo mensajes de reenvío
    func clearResendMessages() {
        withAnimation {
            resendMessage = nil
            resendError = nil
            showResendSuccess = false
        }
    }
    
    // 🔥 NUEVO: Verificar si el proceso de reenvío fue exitoso
    var wasResendSuccessful: Bool {
        return showResendSuccess && resendError == nil
    }
    
    // MARK: - Private Methods
    
    private func handleError(_ error: Error) {
        print("VIEWMODEL VERIFICATION ERROR:",error.toAppError())
        self.currentAppError = error.toAppError()
    }
}
