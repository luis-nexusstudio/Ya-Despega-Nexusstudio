
import SwiftUI

struct LoginView: View {
    @StateObject var authViewModel = LoginViewModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var showRegisterView = false
    @State private var showForgotPassword = false
    var onLoginSuccess: () -> Void
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var loginError: String?
    
    var body: some View {
        BackgroundGeneralView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 22) {
                    LogoHeader()
                    
                    CredentialFields(email: $email, password: $password)
                    
                    ForgotPasswordButton(showForgotPassword: $showForgotPassword)
                    
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
                    
                    // 🎯 AQUÍ ES DONDE CAMBIAS - Actualizar el RegisterButton
                    RegisterButton(showRegister: $showRegisterView)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 40)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .ignoresSafeArea(.keyboard)
        }.sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
        // 🚀 MOVER EL MODAL AQUÍ - Al nivel del BackgroundGeneralView
        .fullScreenCover(isPresented: $showRegisterView) {
            RegisterView(onRegisterSuccess: {
                showRegisterView = false
                // Opcional: Hacer login automático tras registro exitoso
                // onLoginSuccess()
            })
            
        }
    }
    
    // MARK: Imagen del Login
    struct LogoHeader: View {
        var body: some View {
            VStack(spacing: 10) {
                Image("ImagenFooterYD")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 400)
                    .padding(.top, 30)
            }
        }
    }
    
    // MARK: Text Fields del Login
    struct CredentialFields: View {
        @Binding var email: String
        @Binding var password: String
        
        var body: some View {
            VStack(spacing: 18) {
                TextField("Correo electrónico", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                
                SecureField("Contraseña", text: $password)
                    .textContentType(.password)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
        }
    }
    
    // MARK: Boton para el olvido de contraseña
    struct ForgotPasswordButton: View {
        @Binding var showForgotPassword: Bool
        
        var body: some View {
            Button("¿Olvidaste tu contraseña?") {
                showForgotPassword = true
            }
            .font(.footnote)
            .foregroundColor(Color("PrimaryColor"))
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
                    .background(Color("PrimaryColor"))
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
                    .cornerRadius(12)
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
                    .background(Color("SecondaryColor"))
                    .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: Botón de registro - SIMPLIFICADO
    struct RegisterButton: View {
        @Binding var showRegister: Bool
        
        var body: some View {
            Button(action: {
                showRegister = true
            }) {
                (
                    Text("¿No tienes cuenta? ")
                        .foregroundColor(.white) +
                    Text("Regístrate")
                        .foregroundColor(Color("PrimaryColor"))
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
}
