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
    @State private var showSendingEmailOverlay = false

    
    let onRetry: () -> Void
    
    var body: some View {
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
        .overlay {
            if verificationViewModel.isResendingEmail {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                
                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    
                    Text("Enviando email...")
                        .foregroundColor(.white)
                        .font(.headline)
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.black.opacity(0.8))
                )
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
            
            // Mensaje de reenvío si existe
            if let message = verificationViewModel.resendMessage {
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
            // Botón principal de reenvío
            Button(action: resendVerificationEmail) {
                HStack {
                    if verificationViewModel.isResendingEmail {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "envelope.arrow.triangle.branch")
                    }
                    
                    Text(verificationViewModel.isResendingEmail ? "Enviando..." : "Enviar email de verificación")
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
            .disabled(verificationViewModel.isResendingEmail)
            .opacity(verificationViewModel.isResendingEmail ? 0.8 : 1)
            
            // Botones secundarios
            HStack(spacing: 20) {
                // Verificar estado
                Button(action: {
                    verificationViewModel.checkVerificationStatus()
                }) {
                    HStack {
                        if verificationViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color("PrimaryColor")))
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        
                        Text(verificationViewModel.isLoading ? "Verificando..." : "Verificar estado")
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
                .disabled(verificationViewModel.isLoading)
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
    
    // MARK: - Actions
    private func resendVerificationEmail() {
        verificationViewModel.resendVerificationEmail()
    }
}

// MARK: - Helper Views
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
