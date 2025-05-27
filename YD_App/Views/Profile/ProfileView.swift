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
                                        .foregroundColor(.red)
                                    Text("Cerrar sesión")
                                        .foregroundColor(.red)
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
                .navigationTitle("Mi información")
                .onAppear {
                    viewModel.fetchUserProfile()
                }
            }
        }
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Cabecera
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
                                .foregroundColor(.blue)
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
                                .foregroundColor(.blue)
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
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                        
                        Button(action: {
                            // Cancelar edición
                            isEditing = false
                        }) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.red)
                                .clipShape(Circle())
                        }
                    }
                }
            }
            
            if viewModel.hasError {
                Text(viewModel.errorMessage ?? "Error desconocido")
                    .foregroundColor(.red)
                    .padding()
                
                Button("Reintentar") {
                    viewModel.fetchUserProfile()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            
            // Formulario
            VStack(spacing: 20) {
                // Nombres
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nombres")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if isEditing {
                        TextField("Ingrese sus nombres", text: $editedNombres)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .autocapitalization(.words)
                    } else {
                        Text(viewModel.userProfile?.nombres ?? "Cargando...")
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                
                // Apellido Paterno
                VStack(alignment: .leading, spacing: 8) {
                    Text("Apellido Paterno")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if isEditing {
                        TextField("Ingrese su apellido paterno", text: $editedApellidoPaterno)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .autocapitalization(.words)
                    } else {
                        Text(viewModel.userProfile?.apellidoPaterno ?? "Cargando...")
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                
                // Apellido Materno
                VStack(alignment: .leading, spacing: 8) {
                    Text("Apellido Materno")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if isEditing {
                        TextField("Ingrese su apellido materno", text: $editedApellidoMaterno)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .autocapitalization(.words)
                    } else {
                        Text(viewModel.userProfile?.apellidoMaterno ?? "Cargando...")
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                
                // Número de Celular
                VStack(alignment: .leading, spacing: 8) {
                    Text("Número de Celular")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if isEditing {
                        TextField("Ingrese su número de celular", text: $editedNumeroCelular)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
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
                        .foregroundColor(.secondary)
                    
                    Text(viewModel.userProfile?.email ?? "Cargando...")
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
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
    }
}

struct PasswordChangeView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                        .multilineTextAlignment(.center)
                }
                
                SecureField("Contraseña actual", text: $currentPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                SecureField("Nueva contraseña", text: $newPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                SecureField("Confirmar contraseña", text: $confirmPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                if isLoading {
                    ProgressView()
                        .padding()
                } else {
                    Button("Cambiar contraseña") {
                        updatePassword()
                    }
                    .disabled(currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty || newPassword != confirmPassword)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .padding()
        }
        .navigationTitle("Cambio de contraseña")
        .alert("Cambio exitoso", isPresented: $showSuccessAlert) {
            Button("Aceptar", role: .cancel) {
                // Volver a la pantalla anterior cuando se acepta la alerta
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Tu contraseña ha sido actualizada correctamente.")
        }
    }
    
    private func updatePassword() {
        // Validaciones básicas
        if newPassword.count < 6 {
            errorMessage = "La nueva contraseña debe tener al menos 6 caracteres"
            return
        }
        
        if newPassword != confirmPassword {
            errorMessage = "Las contraseñas no coinciden"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
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
                    self.errorMessage = "Error de autenticación: \(error.localizedDescription)"
                    self.isLoading = false
                }
                return
            }
            
            // Cambiar la contraseña
            user.updatePassword(to: newPassword) { error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        self.errorMessage = "Error al cambiar contraseña: \(error.localizedDescription)"
                    } else {
                        // Éxito
                        self.currentPassword = ""
                        self.newPassword = ""
                        self.confirmPassword = ""
                        self.showSuccessAlert = true
                    }
                }
            }
        }
    }
}

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Preguntas Frecuentes")
                    .font(.title2.bold())
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

struct HelpItemCard: View {
    let question: String
    let answer: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icono y pregunta en la parte superior
            HStack(spacing: 12) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                
                Text(question)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            
            // Respuesta en la parte inferior
            Text(answer)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .padding(.leading, 36) // Alineado con el texto de la pregunta
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(ProfileViewModel())
            .previewDevice("iPhone 15 Pro")
            .previewDisplayName("Profile View")
    }
}
