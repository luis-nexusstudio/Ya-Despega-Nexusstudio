//
//  ForgotPAsswordView.swift
//  YD_App
//
//  Created by Pedro Martinez on 01/06/25.
//


import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ForgotPasswordViewModel()
    
    @State private var email = ""
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    
    var body: some View {
        BackgroundGeneralView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "lock.rotation")
                            .font(.system(size: 60))
                            .foregroundColor(Color("PrimaryColor"))
                            .padding(.top, 40)
                        
                        Text("¿Olvidaste tu contraseña?")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        
                        Text("No te preocupes, te enviaremos un correo con las instrucciones para restablecerla.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 30)
                    
                    // Email Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Correo electrónico")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        TextField("ejemplo@correo.com", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    // Buttons
                    VStack(spacing: 16) {
                        Button(action: resetPassword) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "envelope.badge.fill")
                                    Text("Enviar correo")
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("PrimaryColor"))
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.isLoading || email.isEmpty)
                        .opacity(viewModel.isLoading || email.isEmpty ? 0.6 : 1.0)
                        
                        Button(action: { dismiss() }) {
                            Text("Regresar al inicio de sesión")
                                .foregroundColor(Color("PrimaryColor"))
                                .fontWeight(.medium)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    Spacer(minLength: 50)
                }
            }
            .ignoresSafeArea(.keyboard)
        }
        .alert("Correo enviado", isPresented: $showSuccessAlert) {
            Button("Aceptar") {
                dismiss()
            }
        } message: {
            Text("Hemos enviado las instrucciones a \(email). Revisa tu bandeja de entrada.")
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("Entendido", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Ocurrió un error al enviar el correo.")
        }
    }
    
    private func resetPassword() {
        guard !email.isEmpty else { return }
        
        viewModel.sendPasswordReset(email: email) { success in
            if success {
                showSuccessAlert = true
            } else {
                showErrorAlert = true
            }
        }
    }
}

struct ForgotPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPasswordView()
            .previewDevice("iPhone 15 Pro")
    }
}
