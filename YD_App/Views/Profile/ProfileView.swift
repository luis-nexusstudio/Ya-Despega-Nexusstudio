//
//  ProfileView.swift
//  YD_App
//
//  Created by Pedro Martinez on 01/05/25.
//

import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingLogoutAlert = false
    @State private var shouldNavigateToLogin = false
    
    var body: some View {
        NavigationView {
            BackgroundGeneralView {
                VStack(alignment: .leading, spacing: 12) {
                    // Título personalizado justificado a la izquierda
                    HStack {
                        Text("Mi información")
                            .font(.largeTitle.bold())
                            .foregroundColor(Color("PrimaryColor"))
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 4)
                    
                    ScrollView {
                        VStack(spacing: 12) {
                            // Formulario de información del usuario
                            UserInfoFormSection(viewModel: viewModel)
                            
                            // Opciones adicionales
                            VStack(spacing: 0) {
                                // Cambio de contraseña (justificado a la derecha, tamaño reducido)
                                NavigationLink(destination: PasswordChangeView()) {
                                    HStack {
                                        Spacer()
                                        Text("Cambio de contraseña")
                                            .foregroundColor(.blue)
                                            .font(.subheadline)
                                        Image(systemName: "lock.fill")
                                            .foregroundColor(.blue)
                                            .font(.subheadline)
                                    }
                                    .padding(.vertical, 8)
                                }
                                
                                Divider()
                                    .padding(.vertical, 8)
                                
                                // Cerrar sesión (centrado)
                                Button(action: {
                                    showingLogoutAlert = true
                                }) {
                                    HStack {
                                        Spacer()
                                        Image(systemName: "rectangle.portrait.and.arrow.right")
                                            .foregroundColor(Color("PrimaryColor"))
                                        Text("Cerrar sesión")
                                            .foregroundColor(Color("PrimaryColor"))
                                            .fontWeight(.medium)
                                        Spacer()
                                    }
                                    .padding(.vertical, 12)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                }
                .onAppear {
                    viewModel.fetchUserProfile()
                }
            }
        }
        .navigationBarHidden(true)
        .alert("Cerrar sesión", isPresented: $showingLogoutAlert) {
            Button("Cerrar sesión", role: .destructive) {
                // Cerrar sesión usando el ViewModel
                viewModel.signOut { success in
                    if success {
                        print("🟢 Sesión cerrada exitosamente")
                        // Indicar que debemos navegar al login
                        shouldNavigateToLogin = true
                    } else {
                        print("🔴 Error al cerrar sesión")
                    }
                }
            }
            Button("Cancelar", role: .cancel) { }
        } message: {
            Text("¿Estás seguro que deseas cerrar la sesión?")
        }
        // Usar una navegación programática para ir al login cuando sea necesario
        .fullScreenCover(isPresented: $shouldNavigateToLogin) {
            LoginView {
                // Callback cuando el login es exitoso
                shouldNavigateToLogin = false
            }
        }
    }
}

// MARK: - UserInfoFormSection

// Componente separado para el formulario de información de usuario
struct UserInfoFormSection: View {
    @ObservedObject var viewModel: ProfileViewModel
    
    @State private var isEditing = false
    @State private var editedNombres = ""
    @State private var editedApellidoPaterno = ""
    @State private var editedApellidoMaterno = ""
    @State private var editedNumeroCelular = ""
    @State private var showingSaveAlert = false
    @State private var showingHelpPopup = false
    @State private var showingPasswordChangePopup = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack {
                Spacer()
                
                if viewModel.isLoading {
                    ProgressView()
                } else if !isEditing {
                    HStack(spacing: 12) {
                        Button(action: {
                            // Mostrar vista de ayuda como popup
                            showingHelpPopup = true
                        }) {
                            Image(systemName: "questionmark.circle")
                                .font(.title2)
                                .foregroundColor(Color("PrimaryColor"))
                        }
                        
                        Button(action: {
                            // Comenzar edición
                            if let userProfile = viewModel.userProfile {
                                editedNombres = userProfile.nombres
                                editedApellidoPaterno = userProfile.apellidoPaterno
                                editedApellidoMaterno = userProfile.apellidoMaterno
                                editedNumeroCelular = userProfile.numeroCelular
                                isEditing = true
                            }
                        }) {
                            Image(systemName: "pencil")
                                .font(.title2)
                                .foregroundColor(Color("PrimaryColor"))
                        }
                        .disabled(viewModel.userProfile == nil)
                    }
                } else {
                    HStack(spacing: 12) {
                        Button(action: {
                            // Guardar cambios - activar alerta
                            showingSaveAlert = true
                        }) {
                            Image(systemName: "checkmark")
                                .font(.title2)
                                .foregroundColor(Color("PrimaryColor"))
                        }
                        
                        Button(action: {
                            // Cancelar edición
                            isEditing = false
                        }) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(Color("PrimaryColor"))
                        }
                    }
                }
            }
            .padding(.bottom, 0)
            
            if viewModel.hasError {
                Text(viewModel.errorMessage ?? "Error desconocido")
                    .foregroundColor(.red)
                    .padding()
                
                Button("Reintentar") {
                    viewModel.fetchUserProfile()
                }
                .padding()
                .background(Color("PrimaryColor"))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            
            // Formulario
            VStack(spacing: 20) {
                // Nombres
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nombres")
                        .font(.headline)
                        .foregroundColor(Color("PrimaryColor"))
                    
                    if isEditing {
                        TextField("Ingrese sus nombres", text: $editedNombres)
                        .foregroundColor(.black)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .autocapitalization(.words)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color("PrimaryColor"), lineWidth: 2)
                        )
                    } else {
                        Text(viewModel.userProfile?.nombres ?? "Cargando...")
                            .font(.body)
                            .foregroundColor(.black)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .cornerRadius(8)
                    }
                }
                
                // Apellido Paterno
                VStack(alignment: .leading, spacing: 8) {
                    Text("Apellido Paterno")
                        .font(.headline)
                        .foregroundColor(Color("PrimaryColor"))
                    
                    if isEditing {
                        TextField("Ingrese su apellido paterno", text: $editedApellidoPaterno)
                        .foregroundColor(.black)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .autocapitalization(.words)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color("PrimaryColor"), lineWidth: 2)
                        )
                    } else {
                        Text(viewModel.userProfile?.apellidoPaterno ?? "Cargando...")
                            .font(.body)
                            .foregroundColor(.black)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .cornerRadius(8)
                    }
                }
                
                // Apellido Materno
                VStack(alignment: .leading, spacing: 8) {
                    Text("Apellido Materno")
                        .font(.headline)
                        .foregroundColor(Color("PrimaryColor"))
                    
                    if isEditing {
                        TextField("Ingrese su apellido materno", text: $editedApellidoMaterno)
                        .foregroundColor(.black)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .autocapitalization(.words)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color("PrimaryColor"), lineWidth: 2)
                        )
                    } else {
                        Text(viewModel.userProfile?.apellidoMaterno ?? "Cargando...")
                            .font(.body)
                            .foregroundColor(.black)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .cornerRadius(8)
                    }
                }
                
                // Número de Celular
                VStack(alignment: .leading, spacing: 8) {
                    Text("Número de Celular")
                        .font(.headline)
                        .foregroundColor(Color("PrimaryColor"))
                    
                    if isEditing {
                        TextField("Ingrese su número de celular", text: $editedNumeroCelular)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color("PrimaryColor"), lineWidth: 2)
                        )
                        .onChange(of: editedNumeroCelular) { newValue in
                            // Filtrar caracteres no numéricos
                            let filtered = newValue.filter { "0123456789".contains($0) }
                            
                            // Limitar a 10 dígitos
                            if filtered.count > 10 {
                                editedNumeroCelular = String(filtered.prefix(10))
                            } else if filtered != newValue {
                                editedNumeroCelular = filtered
                            }
                        }
                    } else {
                        Text(viewModel.userProfile?.numeroCelular ?? "Cargando...")
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                
                // Email (solo lectura)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.headline)
                        .foregroundColor(Color("PrimaryColor"))
                    
                    Text(viewModel.userProfile?.email ?? "Cargando...")
                        .font(.body)
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal)
        .alert("Guardar cambios", isPresented: $showingSaveAlert) {
            Button("Confirmar") {
                // Guardar cambios cuando el usuario confirma
                if let userProfile = viewModel.userProfile {
                    var updatedProfile = userProfile
                    updatedProfile.nombres = editedNombres
                    updatedProfile.apellidoPaterno = editedApellidoPaterno
                    updatedProfile.apellidoMaterno = editedApellidoMaterno
                    updatedProfile.numeroCelular = editedNumeroCelular
                    
                    viewModel.updateUserProfile(updatedProfile: updatedProfile) { success in
                        if success {
                            print("Información guardada exitosamente")
                            isEditing = false
                        }
                    }
                }
            }
            Button("Cancelar", role: .cancel) {
                // Si cancela la alerta, no hacer nada
                print("Guardado cancelado")
            }
        } message: {
            Text("¿Estás seguro que deseas guardar los cambios?")
        }
        .sheet(isPresented: $showingHelpPopup) {
            HelpView()
                .presentationDetents([.fraction(0.8), .large])
        }
        .sheet(isPresented: $showingPasswordChangePopup) {
            PasswordChangeView()
                .presentationDetents([.fraction(0.7), .large])
        }
    }
}

// MARK: - PasswordChangeView (Mejorada)

struct PasswordChangeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false
    
    var body: some View {
        BackgroundGeneralView {
            VStack(spacing: 16) {
                // Header simplificado - solo título centrado
                HStack {
                    Spacer()
                    Text("Cambio de contraseña")
                        .font(.title2.bold())
                        .foregroundColor(Color("PrimaryColor"))
                    Spacer()
                }
                .padding(.top, 60)
                
                Divider()
                    .background(Color.white.opacity(0.3))
                
                // Contenido principal en ScrollView
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Mensaje de error si existe
                        if let errorMessage = errorMessage {
                            VStack(spacing: 8) {
                                HStack(spacing: 12) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.red)
                                    
                                    Text("Error")
                                        .font(.headline)
                                        .foregroundColor(.red)
                                    
                                    Spacer()
                                }
                                
                                Text(errorMessage)
                                    .font(.body)
                                    .foregroundColor(.black)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red, lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                        
                        // Tarjeta de formulario
                        VStack(spacing: 20) {
                            // Header del formulario
                            HStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color("PrimaryColor"))
                                
                                Text("Ingresa tu información")
                                    .font(.headline)
                                    .foregroundColor(Color("PrimaryColor"))
                                
                                Spacer()
                            }
                            
                            // Campos de contraseña - centrados con padding simétrico
                            VStack(spacing: 16) {
                                // Contraseña actual
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Contraseña actual")
                                        .font(.subheadline)
                                        .foregroundColor(Color("PrimaryColor"))
                                    
                                    SecureField("Ingrese su contraseña actual", text: $currentPassword)
                                        .textContentType(.password)
                                        .padding()
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color("PrimaryColor"), lineWidth: 1)
                                        )
                                }
                                
                                // Nueva contraseña
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Nueva contraseña")
                                        .font(.subheadline)
                                        .foregroundColor(Color("PrimaryColor"))
                                    
                                    SecureField("Ingrese su nueva contraseña", text: $newPassword)
                                        .textContentType(.newPassword)
                                        .padding()
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(
                                                    newPassword.count >= 6 ? Color.green : Color("PrimaryColor"),
                                                    lineWidth: 1
                                                )
                                        )
                                }
                                
                                // Confirmar contraseña
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Confirmar nueva contraseña")
                                        .font(.subheadline)
                                        .foregroundColor(Color("PrimaryColor"))
                                    
                                    SecureField("Confirme su nueva contraseña", text: $confirmPassword)
                                        .textContentType(.newPassword)
                                        .padding()
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(
                                                    passwordsMatch ? Color.green : Color("PrimaryColor"),
                                                    lineWidth: 1
                                                )
                                        )
                                }
                            }
                            
                            // Indicadores de validación visual
                            VStack(alignment: .leading, spacing: 8) {
                                ValidationIndicator(
                                    text: "Mínimo 6 caracteres",
                                    isValid: newPassword.count >= 6
                                )
                                
                                ValidationIndicator(
                                    text: "Las contraseñas coinciden",
                                    isValid: passwordsMatch && !confirmPassword.isEmpty
                                )
                            }
                            
                            // Botón de acción
                            VStack(spacing: 12) {
                                if isLoading {
                                    VStack(spacing: 12) {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: Color("PrimaryColor")))
                                            .scaleEffect(1.2)
                                        
                                        Text("Actualizando contraseña...")
                                            .font(.subheadline)
                                            .foregroundColor(Color("PrimaryColor"))
                                    }
                                    .padding()
                                } else {
                                    Button(action: {
                                        updatePassword()
                                    }) {
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 18))
                                            Text("Cambiar contraseña")
                                                .font(.headline)
                                        }
                                        .foregroundColor(.white)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            isFormValid ? Color("PrimaryColor") : Color.gray
                                        )
                                        .cornerRadius(12)
                                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                                    }
                                    .disabled(!isFormValid)
                                    .opacity(isFormValid ? 1.0 : 0.6)
                                }
                                
                                // Información adicional
                                VStack(spacing: 8) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "info.circle")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.7))
                                        Text("La nueva contraseña debe tener al menos 6 caracteres")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.7))
                                        Spacer()
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color("PrimaryColor"), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    }
                    .padding(.bottom, 20)
                }
            }
            .padding(.horizontal, 25)
            .padding(.bottom, 20)
        }
        .alert("Cambio exitoso", isPresented: $showSuccessAlert) {
            Button("Aceptar", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Tu contraseña ha sido actualizada correctamente.")
        }
    }
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        return !currentPassword.isEmpty &&
               !newPassword.isEmpty &&
               !confirmPassword.isEmpty &&
               newPassword == confirmPassword &&
               newPassword.count >= 6
    }
    
    private var passwordsMatch: Bool {
        return newPassword == confirmPassword && !newPassword.isEmpty && !confirmPassword.isEmpty
    }
    
    // MARK: - Methods
    
    private func updatePassword() {
        // Limpiar errores previos
        errorMessage = nil
        
        // Validaciones básicas
        guard newPassword.count >= 6 else {
            errorMessage = "La nueva contraseña debe tener al menos 6 caracteres"
            return
        }
        
        guard newPassword == confirmPassword else {
            errorMessage = "Las contraseñas no coinciden"
            return
        }
        
        guard currentPassword != newPassword else {
            errorMessage = "La nueva contraseña debe ser diferente a la actual"
            return
        }
        
        isLoading = true
        
        // Obtener el usuario actual
        guard let user = Auth.auth().currentUser else {
            errorMessage = "No hay usuario autenticado"
            isLoading = false
            return
        }
        
        guard let email = user.email else {
            errorMessage = "El usuario no tiene email registrado"
            isLoading = false
            return
        }
        
        // Reautenticar al usuario con su contraseña actual
        let credential = EmailAuthProvider.credential(
            withEmail: email,
            password: currentPassword
        )
        
        user.reauthenticate(with: credential) { _, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "La contraseña actual es incorrecta"
                    self.isLoading = false
                    print("Error de reautenticación: \(error.localizedDescription)")
                }
                return
            }
            
            // Cambiar la contraseña
            user.updatePassword(to: newPassword) { error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        // Manejar diferentes tipos de errores de Firebase
                        if let errorCode = AuthErrorCode(rawValue: error._code) {
                            switch errorCode {
                            case .weakPassword:
                                self.errorMessage = "La contraseña es muy débil. Intenta con una más segura."
                            case .networkError:
                                self.errorMessage = "Error de conexión. Verifica tu internet e intenta de nuevo."
                            default:
                                self.errorMessage = "Error al cambiar contraseña: \(error.localizedDescription)"
                            }
                        } else {
                            self.errorMessage = "Error al cambiar contraseña: \(error.localizedDescription)"
                        }
                        print("Error al cambiar contraseña: \(error)")
                    } else {
                        // Éxito - limpiar campos
                        self.currentPassword = ""
                        self.newPassword = ""
                        self.confirmPassword = ""
                        self.showSuccessAlert = true
                        print("✅ Contraseña actualizada exitosamente")
                    }
                }
            }
        }
    }
}

// MARK: - ValidationIndicator

struct ValidationIndicator: View {
    let text: String
    let isValid: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isValid ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 14))
                .foregroundColor(isValid ? .green : .white.opacity(0.5))
            
            Text(text)
                .font(.caption)
                .foregroundColor(isValid ? .green : .white.opacity(0.7))
            
            Spacer()
        }
    }
}

// MARK: - HelpView

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Preguntas Frecuentes")
                    .font(.title2.bold())
                    .foregroundColor(Color("PrimaryColor"))
                Spacer()
            }
            .padding(.top, 60)
            
            Divider()
            
            // Lista de preguntas frecuentes
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    HelpItemCard(
                        question: "¿Cómo actualizo mi información?",
                        answer: "Puedes actualizar tu información personal haciendo clic en el icono de lápiz (editar) en la sección de 'Mi información'."
                    )
                    
                    HelpItemCard(
                        question: "¿Olvidé mi contraseña?",
                        answer: "Si olvidaste tu contraseña, puedes usar la opción 'Recuperar contraseña' en la pantalla de inicio de sesión."
                    )
                    
                    HelpItemCard(
                        question: "¿Cómo puedo contactar soporte?",
                        answer: "Puedes contactar a nuestro equipo de soporte al correo soporte@yadespega.com o llamando al (477) 123-4567."
                    )
                    
                    HelpItemCard(
                        question: "¿Cómo cambio mi contraseña?",
                        answer: "Puedes cambiar tu contraseña en la opción 'Cambio de contraseña' que aparece en tu perfil."
                    )
                    
                    HelpItemCard(
                        question: "¿Cómo compro boletos?",
                        answer: "Desde la pantalla principal, presiona 'Comprar Boletos', selecciona la cantidad de boletos que deseas y procede al pago."
                    )
                    
                    HelpItemCard(
                        question: "¿Dónde veo mis boletos?",
                        answer: "Puedes ver tus boletos comprados en la pestaña 'Tickets' de la aplicación."
                    )
                }
                .padding(.bottom, 20)
            }
        }
        .padding(.horizontal, 25)
        .padding(.bottom, 20)
    }
}

// MARK: - HelpItemCard

struct HelpItemCard: View {
    let question: String
    let answer: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icono y pregunta en la parte superior
            HStack(spacing: 12) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color("PrimaryColor"))
                
                Text(question)
                    .font(.headline)
                    .foregroundColor(Color("PrimaryColor"))
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            
            // Respuesta en la parte inferior
            Text(answer)
                .font(.body)
                .foregroundColor(.black)
                .multilineTextAlignment(.leading)
                .padding(.leading, 32) // Alineado con el texto de la pregunta
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color("PrimaryColor"), lineWidth: 1)
        )
    }
}

// MARK: - Preview

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(ProfileViewModel())
            .previewDevice("iPhone 15 Pro")
            .previewDisplayName("Profile View")
    }
}
