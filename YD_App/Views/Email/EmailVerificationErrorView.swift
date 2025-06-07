//
//  EmailVerificationErrorView.swift
//  YD_App
//
//  Created by Luis Melendez on 02/06/25.
//

import SwiftUI
import FirebaseAuth

struct EmailVerificationErrorView: View {
    @StateObject private var verificationViewModel = VerificationViewModel()
    @Environment(\.dismiss) private var dismiss
    
    let onRetry: () -> Void
    
    // 🆕 Enum para diferentes estados de verificación
    enum VerificationAction {
        case none
        case sendingEmail
        case checkingStatus
        
        var loadingMessage: String {
            switch self {
            case .none:
                return ""
            case .sendingEmail:
                return "Enviando correo de verificación..."
            case .checkingStatus:
                return "Verificando estado del email..."
            }
        }
        
        var icon: String {
            switch self {
            case .none:
                return ""
            case .sendingEmail:
                return "envelope.arrow.triangle.branch"
            case .checkingStatus:
                return "arrow.clockwise"
            }
        }
        
        var title: String {
            switch self {
            case .none:
                return ""
            case .sendingEmail:
                return "Enviando email"
            case .checkingStatus:
                return "Verificando estado"
            }
        }
    }
    
    @State private var currentAction: VerificationAction = .none
    
    var body: some View {
        ZStack {
            BackgroundGeneralView {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header con botón de cerrar
                        headerWithCloseButton
                        
                        // Content principal
                        contentSection
                        
                        // Actions
                        actionSection
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }
            }
            .onAppear {
                verificationViewModel.checkVerificationStatus()
            }
            .onChange(of: verificationViewModel.isVerified) { _, isVerified in
                if isVerified {
                    // Si se verifica durante la vista, ejecutar retry automáticamente
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        onRetry()
                        dismiss()
                    }
                }
            }
            
            // 🆕 OVERLAY PROFESIONAL PARA VERIFICACIÓN
            if currentAction != .none {
                VerificationLoadingOverlay(
                    action: currentAction,
                    onCancel: {
                        cancelCurrentAction()
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .animation(.easeInOut(duration: 0.3), value: currentAction)
            }
        }
        .onChange(of: verificationViewModel.isResendingEmail) { _, isResending in
            currentAction = isResending ? .sendingEmail : .none
        }
        .onChange(of: verificationViewModel.isLoading) { _, isLoading in
            if isLoading && currentAction == .none {
                currentAction = .checkingStatus
            } else if !isLoading && currentAction == .checkingStatus {
                currentAction = .none
            }
        }
    }
    
    // MARK: - 🆕 Action Methods
    private func performResendEmail() {
        currentAction = .sendingEmail
        verificationViewModel.resendVerificationEmail()
        
        // Auto-timeout después de 15 segundos
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) {
            if currentAction == .sendingEmail {
                cancelCurrentAction()
            }
        }
    }
    
    private func performCheckStatus() {
        currentAction = .checkingStatus
        verificationViewModel.checkVerificationStatus()
        
        // Auto-timeout después de 10 segundos
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            if currentAction == .checkingStatus {
                cancelCurrentAction()
            }
        }
    }
    
    private func cancelCurrentAction() {
        currentAction = .none
        // Aquí podrías cancelar operaciones en curso si es necesario
    }
    
    // Header con botón de cerrar
    private var headerWithCloseButton: some View {
        VStack(spacing: 16) {
            // Contenido del header
            VStack(spacing: 16) {
                Image(systemName: "envelope.badge.shield.half.filled")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
                
                Text("Email no verificado")
                    .font(.title.bold())
                    .foregroundColor(.white)
            }
        }
    }
    
    private var contentSection: some View {
        VStack(spacing: 20) {
            // Información del usuario (si está disponible)
            if let email = Auth.auth().currentUser?.email {
                VStack(spacing: 8) {
                    Text("Tu email:")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(email)
                        .font(.headline)
                        .foregroundColor(Color("PrimaryColor"))
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.white.opacity(0.1))
                        )
                }
            }
            
            // Mensaje principal de error
            VStack(spacing: 12) {
                Text("Tu correo electrónico no ha sido verificado. Para continuar con la compra, necesitas verificar tu cuenta.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.orange.opacity(0.1))
                            .stroke(.orange.opacity(0.3), lineWidth: 1)
                    )
            }
            
            VStack(spacing: 8) {
                Text("¿Cómo verificar tu email?")
                    .font(.headline)
                    .foregroundColor(Color("PrimaryColor"))
                
                VStack(alignment: .leading, spacing: 6) {
                    InstructionRow(number: "1", text: "Revisa tu bandeja de entrada")
                    InstructionRow(number: "2", text: "Busca el email de 'Ya Despega'")
                    InstructionRow(number: "3", text: "Haz clic en el enlace de verificación")
                    InstructionRow(number: "4", text: "Vuelve aquí y presiona el botón Verificar Estado")
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white.opacity(0.05))
                )
            }
            
            // Mensaje de reenvío si existe (solo cuando no hay overlay activo)
            if let message = verificationViewModel.resendMessage, currentAction == .none {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: verificationViewModel.showResendSuccess ? "checkmark.circle.fill" : "info.circle.fill")
                            .foregroundColor(verificationViewModel.showResendSuccess ? Color.green : Color.blue)
                        Text(message)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill((verificationViewModel.showResendSuccess ? Color.green : Color.blue).opacity(0.1))
                        .stroke((verificationViewModel.showResendSuccess ? Color.green : Color.blue).opacity(0.3), lineWidth: 1)
                )
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.05))
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    private var actionSection: some View {
        VStack(spacing: 16) {
            // Botón principal de reenvío - 🔄 ACTUALIZADO
            Button(action: performResendEmail) {
                HStack {
                    Image(systemName: "envelope.arrow.triangle.branch")
                    Text("Enviar email de verificación")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color("PrimaryColor"))
                )
            }
            .disabled(currentAction != .none)
            .opacity(currentAction != .none ? 0.6 : 1)
            
            // Botones secundarios - 🔄 ACTUALIZADO
            HStack(spacing: 20) {
                // Verificar estado
                Button(action: performCheckStatus) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Verificar estado")
                    }
                    .font(.subheadline)
                    .foregroundColor(Color("PrimaryColor"))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                    )
                }
                .disabled(currentAction != .none)
                .opacity(currentAction != .none ? 0.6 : 1)
            }
            
            // Texto de ayuda
            VStack(spacing: 8) {
                Text("⚠️ Sin verificación no podrás realizar compras")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
                
                Text("¿No encuentras el email? Revisa tu carpeta de spam o correo no deseado")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - 🆕 VERIFICATION LOADING OVERLAY COMPONENT
struct VerificationLoadingOverlay: View {
    let action: EmailVerificationErrorView.VerificationAction
    let onCancel: () -> Void
    
    @State private var animationScale: CGFloat = 1.0
    @State private var pulseAnimation: Bool = false
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        ZStack {
            // Background with blur effect
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    // Prevenir toques accidentales
                }
            
            VStack(spacing: 24) {
                // Icon with animation
                ZStack {
                    Circle()
                        .fill(Color("PrimaryColor").opacity(0.2))
                        .frame(width: 100, height: 100)
                        .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                        .opacity(pulseAnimation ? 0.3 : 0.6)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseAnimation)
                    
                    Image(systemName: action.icon)
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(Color("PrimaryColor"))
                        .scaleEffect(animationScale)
                        .rotationEffect(.degrees(action == .checkingStatus ? rotationAngle : 0))
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: animationScale)
                }
                
                VStack(spacing: 12) {
                    Text(action.title)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Text(action.loadingMessage)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                    
                    // Loading indicator
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color("PrimaryColor")))
                        .scaleEffect(1.2)
                }
                
                // Cancel button (aparecer después de la animación inicial)
                Button(action: onCancel) {
                    Text("Cancelar")
                        .font(.headline)
                        .foregroundColor(Color("PrimaryColor"))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(.white)
                                .shadow(color: .black.opacity(0.1), radius: 5)
                        )
                }
                .opacity(pulseAnimation ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.5).delay(1.0), value: pulseAnimation)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.3), radius: 20)
            )
            .scaleEffect(animationScale)
        }
        .onAppear {
            // Iniciar animaciones
            withAnimation(.easeInOut(duration: 0.5)) {
                animationScale = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                pulseAnimation = true
                
                // Animación de rotación para "verificando estado"
                if action == .checkingStatus {
                    withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                        rotationAngle = 360
                    }
                }
            }
        }
    }
}

// MARK: - Helper Views (sin cambios)
struct InstructionRow: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.subheadline.bold())
                .foregroundColor(Color("PrimaryColor"))
                .frame(width: 20, height: 20)
                .background(Circle().fill(Color("PrimaryColor").opacity(0.2)))
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
        }
    }
}

// MARK: - Preview
struct EmailVerificationErrorView_Previews: PreviewProvider {
    static var previews: some View {
        EmailVerificationErrorView {
            print("Retry action")
        }
        .previewDevice("iPhone 15 Pro")
    }
}
