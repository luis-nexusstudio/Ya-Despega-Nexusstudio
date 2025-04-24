//
//  LoginView.swift
//  YD_App
//
//  Created by Luis Melendez on 20/03/25.
//

import SwiftUI

struct LoginView: View {
    @StateObject var authViewModel = LoginViewModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var showRegisterView = false
    var onLoginSuccess: () -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var loginError: String?

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                Spacer(minLength: 60)

                LogoHeader()

                CredentialFields(email: $email, password: $password)

                ForgotPasswordButton()

                LoginButton {
                    isLoading = true
                    loginError = nil
                    authViewModel.signInWithEmail(email: email, password: password) { success in
                        isLoading = false
                        if success {
                            onLoginSuccess()
                        } else {
                            loginError = "Correo o contraseña incorrectos"
                        }
                    }
                }

                if isLoading {
                    ProgressView()
                }

                if let error = loginError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.footnote)
                }

                DividerWithText(text: "O")

                SocialLoginButtons(
                    onGoogleLogin: {
                        if let rootVC = UIApplication.shared.windows.first?.rootViewController {
                            authViewModel.signInWithGoogle(presenting: rootVC) { success in
                                if success {
                                    onLoginSuccess()
                                }
                            }
                        }
                    },
                    onAppleLogin: {
                        // Aquí irá la lógica del login con Apple
                    }
                )

                Spacer(minLength: 40)

                RegisterButton(showRegister: $showRegisterView)
                    .sheet(isPresented: $showRegisterView) {
                        RegisterView(onRegisterSuccess: {
                            showRegisterView = false
                        })
                    }

                Spacer(minLength: 20)
            }
            .padding()
        }
        .ignoresSafeArea(.keyboard)
    }
}

// MARK: Imagen del Login
struct LogoHeader: View {
    var body: some View {
        VStack(spacing: 10) {
            Image("appLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)

            Text("Iniciar Sesión")
                .font(.largeTitle.bold())
        }
    }
}

// MARK: Text Fields del Login
struct CredentialFields: View {
    @Binding var email: String
    @Binding var password: String

    var body: some View {
        VStack(spacing: 16) {
            TextField("Correo electrónico", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)

            SecureField("Contraseña", text: $password)
                .textContentType(.password)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
        }
    }
}

// MARK: Boton para el olvido de contraseña
struct ForgotPasswordButton: View {
    var body: some View {
        Button("¿Olvidaste tu contraseña?") {
            // Acción de recuperación
        }
        .font(.footnote)
        .foregroundColor(.blue)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

struct LoginButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Iniciar Sesión")
                .foregroundColor(.white)
                .frame(width: 200)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

// MARK: División de los tipos de auth
struct DividerWithText: View {
    let text: String

    var body: some View {
        HStack {
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.gray.opacity(0.4))

            Text(text)
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.horizontal, 8)

            Rectangle()
                .frame(height: 1)
                .foregroundColor(.gray.opacity(0.4))
        }
        .padding(.vertical, 10)
    }
}

// MARK: Auth Redes Sociales
struct SocialLoginButtons: View {
    let onGoogleLogin: () -> Void
    let onAppleLogin: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Button(action: onGoogleLogin) {
                HStack {
                    Image(systemName: "globe")
                    Text("Iniciar sesión con Google")
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.4)))
            }

            Button(action: onAppleLogin) {
                HStack {
                    Image(systemName: "applelogo")
                    Text("Iniciar sesión con Apple")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.black)
                .cornerRadius(12)
            }
        }
    }
}

// MARK: Botón de registro
struct RegisterButton: View {
    @Binding var showRegister: Bool

    var body: some View {
        Button(action: {
            showRegister = true
        }) {
            (
                Text("¿No tienes cuenta? ")
                    .foregroundColor(.primary) +
                Text("Regístrate")
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
            )
        }
    }
}

// MARK: Vista previa con un ViewModel inyectado
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView {
            // Acción simulada para vista previa
            print("Login exitoso (preview)")
        }
        .previewDevice("iPhone 15 Pro")
    }
}
