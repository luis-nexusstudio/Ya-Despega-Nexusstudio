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
    @State private var loginMethod: LoginMethod = .none // 🆕 Para rastrear el método de login
    
    // 🆕 Enum para diferentes métodos de login
    enum LoginMethod {
        case none
        case email
        case google
        case apple
        
        var loadingMessage: String {
            switch self {
            case .none:
                return ""
            case .email:
                return "Verificando credenciales..."
            case .google:
                return "Conectando con Google..."
            case .apple:
                return "Conectando con Apple..."
            }
        }
        
        var icon: String {
            switch self {
            case .none:
                return ""
            case .email:
                return "envelope.circle"
            case .google:
                return "globe"
            case .apple:
                return "applelogo"
            }
        }
    }
    
    var body: some View {
        ZStack {
            BackgroundGeneralView {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 22) {
                        LogoHeader()
                        
                        CredentialFields(email: $email, password: $password)
                        
                        ForgotPasswordButton(showForgotPassword: $showForgotPassword)
                        
                        LoginButton {
                            performEmailLogin()
                        }
                        
                        // 🔄 Remover el ProgressView individual ya que usamos el overlay
                        if let error = loginError {
                            ErrorMessageView(error: error)
                        }
                        
                        DividerWithText(text: "O")
                        
                        SocialLoginButtons(
                            onGoogleLogin: {
                                performGoogleLogin()
                            },
                            onAppleLogin: {
                                performAppleLogin()
                            }
                        )
                        
                        RegisterButton(showRegister: $showRegisterView)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 40)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .ignoresSafeArea(.keyboard)
            }
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView()
            }
            .fullScreenCover(isPresented: $showRegisterView) {
                RegisterView(onRegisterSuccess: {
                    showRegisterView = false
                })
            }
            
            // 🆕 OVERLAY DE LOADING PROFESIONAL
            if isLoading {
                LoginLoadingOverlay(
                    method: loginMethod,
                    onCancel: {
                        cancelLogin()
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .animation(.easeInOut(duration: 0.3), value: isLoading)
            }
        }
    }
    
    // MARK: - 🆕 Login Methods
    private func performEmailLogin() {
        guard !email.isEmpty && !password.isEmpty else {
            loginError = "Por favor completa todos los campos"
            return
        }
        
        startLogin(method: .email)
        
        authViewModel.signInWithEmail(email: email, password: password) { success in
            finishLogin(success: success, errorMessage: "Correo o contraseña incorrectos")
        }
    }
    
    private func performGoogleLogin() {
        guard let rootVC = UIApplication.shared.windows.first?.rootViewController else {
            loginError = "Error de configuración"
            return
        }
        
        startLogin(method: .google)
        
        authViewModel.signInWithGoogle(presenting: rootVC) { success in
            finishLogin(success: success, errorMessage: "Error al conectar con Google")
        }
    }
    
    private func performAppleLogin() {
        startLogin(method: .apple)
        
        // 🔄 Simular delay para Apple login (implementar cuando tengas el servicio real)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            finishLogin(success: false, errorMessage: "Login con Apple próximamente disponible")
        }
    }
    
    private func startLogin(method: LoginMethod) {
        loginMethod = method
        isLoading = true
        loginError = nil
        
        // Auto-timeout después de 30 segundos
        DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) {
            if isLoading {
                cancelLogin()
                loginError = "Tiempo de espera agotado. Intenta nuevamente."
            }
        }
    }
    
    private func finishLogin(success: Bool, errorMessage: String) {
        isLoading = false
        loginMethod = .none
        
        if success {
            onLoginSuccess()
        } else {
            loginError = errorMessage
        }
    }
    
    private func cancelLogin() {
        isLoading = false
        loginMethod = .none
        loginError = "Operación cancelada"
    }
    
    // MARK: - Existing Components (sin cambios mayores)
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
    
    // 🆕 NUEVO: Error Message View mejorado
    struct ErrorMessageView: View {
        let error: String
        
        var body: some View {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                
                Text(error)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.leading)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.red.opacity(0.1))
                    .stroke(.red.opacity(0.3), lineWidth: 1)
            )
            .transition(.opacity.combined(with: .scale))
        }
    }
}

// MARK: - 🆕 LOGIN LOADING OVERLAY COMPONENT
struct LoginLoadingOverlay: View {
    let method: LoginView.LoginMethod
    let onCancel: () -> Void
    
    @State private var animationScale: CGFloat = 1.0
    @State private var pulseAnimation: Bool = false
    
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
                    
                    Image(systemName: method.icon)
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(Color("PrimaryColor"))
                        .scaleEffect(animationScale)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: animationScale)
                }
                
                VStack(spacing: 12) {
                    Text("Iniciando sesión")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Text(method.loadingMessage)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                    
                    // Loading indicator
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color("PrimaryColor")))
                        .scaleEffect(1.2)
                }
                
                // Cancel button (aparecer después de 3 segundos)
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
                .opacity(pulseAnimation ? 1.0 : 0.0) // Aparece con la animación
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
            }
        }
    }
}

// MARK: - Preview
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView {
            print("Login exitoso (preview)")
        }
        .previewDevice("iPhone 15 Pro")
    }
}
