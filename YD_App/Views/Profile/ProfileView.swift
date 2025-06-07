
import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingLogoutAlert = false
    
    @State private var showingPasswordChange = false
    @State private var showingHelpPopup = false
    
    var body: some View {
        BackgroundGeneralView {
            VStack(spacing: 0) {
                // Header similar al RegisterView
                profileHeader
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 32) {
                        profileFormSection
                        actionSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            viewModel.fetchUserProfile()
        }
        .navigationBarHidden(true)
        .alert("Cerrar sesión", isPresented: $showingLogoutAlert) {
            Button("Cerrar sesión", role: .destructive) {
                viewModel.signOut { success in
                    if success {
                        print("🟢 Sesión cerrada exitosamente")
                    } else {
                        print("🔴 Error al cerrar sesión")
                    }
                }
            }
            Button("Cancelar", role: .cancel) { }
        } message: {
            Text("¿Estás seguro que deseas cerrar la sesión?")
        }
        .sheet(isPresented: $showingPasswordChange) {
            ModernPasswordChangeView()
                .presentationDetents([.fraction(0.8), .large])
        }
        .sheet(isPresented: $showingHelpPopup) {
            ModernHelpView()
                .presentationDetents([.fraction(0.8), .large])
        }
    }
}

// MARK: - View Sections
private extension ProfileView {
    var profileHeader: some View {
        HStack {
            Button {
                showingHelpPopup = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 16, weight: .medium))
                    Text("Ayuda")
                        .font(.body)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial.opacity(0.3))
                )
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .frame(height: 50)
    }
    
    
    
    var profileFormSection: some View {
        VStack(spacing: 20) {
            if viewModel.isLoading {
                loadingSection
            } else if viewModel.hasError {
                errorSection
            } else if let userProfile = viewModel.userProfile {
                UserProfileForm(userProfile: userProfile, viewModel: viewModel)
            } else {
                emptySection
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 5)
        )
    }
    
    var actionSection: some View {
        VStack(spacing: 16) {
            // Botón cambio de contraseña
            Button(action: {
                showingPasswordChange = true
            }) {
                HStack {
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 18))
                    Text("Cambiar contraseña")
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
            
            // Botón cerrar sesión
            Button(action: {
                showingLogoutAlert = true
            }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 18))
                    Text("Cerrar sesión")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.red, lineWidth: 2)
                        )
                )
            }
        }
    }
    
    var loadingSection: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color("PrimaryColor")))
                .scaleEffect(1.5)
            
            Text("Cargando información...")
                .font(.headline)
                .foregroundColor(Color("PrimaryColor"))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }
    
    var errorSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text("Error al cargar")
                .font(.headline)
                .foregroundColor(.red)
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Reintentar") {
                viewModel.fetchUserProfile()
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 30)
            .padding(.vertical, 12)
            .background(Color("PrimaryColor"))
            .cornerRadius(12)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }
    
    var emptySection: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No hay información disponible")
                .font(.headline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }
}

// MARK: - User Profile Form Component
struct UserProfileForm: View {
    let userProfile: UserProfileModel
    @ObservedObject var viewModel: ProfileViewModel
    
    @State private var isEditing = false
    @State private var editedNombres = ""
    @State private var editedApellidoPaterno = ""
    @State private var editedApellidoMaterno = ""
    @State private var editedNumeroCelular = ""
    @State private var showingSaveAlert = false
    @FocusState private var focusedField: ProfileField?
    
    var body: some View {
        VStack(spacing: 20) {
            // Header con botones de acción
            formHeader
            
            Divider()
                .background(.gray.opacity(0.3))
            
            // Información personal
            VStack(spacing: 16) {
                Text("Información personal")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ModernProfileField(
                    icon: "person.text.rectangle",
                    title: "Nombres",
                    text: isEditing ? $editedNombres : .constant(userProfile.nombres),
                    isEditing: isEditing,
                    field: .nombres,
                    focusedField: $focusedField
                ) {
                    focusedField = .apellidoPaterno
                }
                
                HStack(spacing: 12) {
                    ModernProfileField(
                        icon: "person",
                        title: "Apellido paterno",
                        text: isEditing ? $editedApellidoPaterno : .constant(userProfile.apellidoPaterno),
                        isEditing: isEditing,
                        field: .apellidoPaterno,
                        focusedField: $focusedField
                    ) {
                        focusedField = .apellidoMaterno
                    }
                    
                    ModernProfileField(
                        icon: "person",
                        title: "Apellido materno",
                        text: isEditing ? $editedApellidoMaterno : .constant(userProfile.apellidoMaterno),
                        isEditing: isEditing,
                        field: .apellidoMaterno,
                        focusedField: $focusedField
                    ) {
                        focusedField = .numeroCelular
                    }
                }
            }
            
            Divider()
                .background(.gray.opacity(0.3))
            
            // Información de contacto
            VStack(spacing: 16) {
                Text("Información de contacto")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ModernProfileField(
                    icon: "phone",
                    title: "Número celular",
                    text: isEditing ? $editedNumeroCelular : .constant(userProfile.numeroCelular),
                    keyboard: .phonePad,
                    isEditing: isEditing,
                    field: .numeroCelular,
                    focusedField: $focusedField,
                    validation: { newValue in
                        let filtered = newValue.filter { "0123456789".contains($0) }
                        return String(filtered.prefix(10))
                    }
                ) {
                    if isEditing && isFormValid {
                        confirmSave()
                    }
                }
                
                ModernProfileField(
                    icon: "envelope",
                    title: "Correo electrónico",
                    text: .constant(userProfile.email),
                    keyboard: .emailAddress,
                    isEditing: false,
                    field: .email,
                    focusedField: $focusedField
                )
            }
        }
        .onAppear {
            setupEditingValues()
        }
        .alert("Guardar cambios", isPresented: $showingSaveAlert) {
            Button("Confirmar") {
                saveChanges()
            }
            Button("Cancelar", role: .cancel) { }
        } message: {
            Text("¿Estás seguro que deseas guardar los cambios?")
        }
    }
    
    private var formHeader: some View {
        HStack {
            Text(isEditing ? "Editando información" : "Mi información")
                .font(.headline)
                .foregroundColor(Color("PrimaryColor"))
            
            Spacer()
            
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .progressViewStyle(CircularProgressViewStyle(tint: Color("PrimaryColor")))
            } else if !isEditing {
                Button(action: startEditing) {
                    Image(systemName: "pencil")
                        .font(.title2)
                        .foregroundColor(Color("PrimaryColor"))
                }
            } else {
                HStack(spacing: 12) {
                    Button(action: confirmSave) {
                        Image(systemName: "checkmark")
                            .font(.title2)
                            .foregroundColor(isFormValid ? Color("PrimaryColor") : .gray)
                    }
                    .disabled(!isFormValid)
                    
                    Button(action: cancelEditing) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(Color("PrimaryColor"))
                    }
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        guard isEditing else { return false }
        return !editedNombres.isEmpty &&
               !editedApellidoPaterno.isEmpty &&
               !editedApellidoMaterno.isEmpty &&
               !editedNumeroCelular.isEmpty
    }
    
    private func setupEditingValues() {
        editedNombres = userProfile.nombres
        editedApellidoPaterno = userProfile.apellidoPaterno
        editedApellidoMaterno = userProfile.apellidoMaterno
        editedNumeroCelular = userProfile.numeroCelular
    }
    
    private func startEditing() {
        setupEditingValues()
        isEditing = true
        focusedField = .nombres
    }
    
    private func cancelEditing() {
        isEditing = false
        focusedField = nil
        setupEditingValues()
    }
    
    private func confirmSave() {
        guard isFormValid else { return }
        showingSaveAlert = true
    }
    
    private func saveChanges() {
        var updatedProfile = userProfile
        updatedProfile.nombres = editedNombres.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedProfile.apellidoPaterno = editedApellidoPaterno.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedProfile.apellidoMaterno = editedApellidoMaterno.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedProfile.numeroCelular = editedNumeroCelular.trimmingCharacters(in: .whitespacesAndNewlines)
        
        viewModel.updateUserProfile(updatedProfile: updatedProfile) { success in
            if success {
                isEditing = false
                focusedField = nil
            }
        }
    }
}

// MARK: - Focus Field Enum
enum ProfileField: CaseIterable {
    case nombres, apellidoPaterno, apellidoMaterno, numeroCelular, email
}

// MARK: - Modern Profile Field Component
struct ModernProfileField: View {
    let icon: String
    let title: String
    @Binding var text: String
    let keyboard: UIKeyboardType
    let isEditing: Bool
    let field: ProfileField
    @FocusState.Binding var focusedField: ProfileField?
    let validation: ((String) -> String)?
    let onSubmit: () -> Void
    
    init(
        icon: String,
        title: String,
        text: Binding<String>,
        keyboard: UIKeyboardType = .default,
        isEditing: Bool = false,
        field: ProfileField,
        focusedField: FocusState<ProfileField?>.Binding,
        validation: ((String) -> String)? = nil,
        onSubmit: @escaping () -> Void = {}
    ) {
        self.icon = icon
        self.title = title
        self._text = text
        self.keyboard = keyboard
        self.isEditing = isEditing
        self.field = field
        self._focusedField = focusedField
        self.validation = validation
        self.onSubmit = onSubmit
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)
            
            if isEditing {
                TextField("", text: $text)
                    .keyboardType(keyboard)
                    .autocapitalization(keyboard == .emailAddress ? .none : .words)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: field)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                            .stroke(
                                focusedField == field ? Color("PrimaryColor").opacity(0.4) : Color.clear,
                                lineWidth: 1.5
                            )
                    )
                    .onSubmit(onSubmit)
                    .onChange(of: text) { newValue in
                        if let validation = validation {
                            text = validation(newValue)
                        }
                    }
            } else {
                Text(text.isEmpty ? "Sin información" : text)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.tertiarySystemBackground))
                    )
                    .foregroundColor(text.isEmpty ? .secondary : .primary)
            }
        }
    }
}

// MARK: - Modern Password Change View
struct ModernPasswordChangeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false
    @FocusState private var focusedField: PasswordField?
    
    var body: some View {
        BackgroundGeneralView {
            VStack(spacing: 0) {
                
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 32) {
                        headerSection
                        formSection
                        actionSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .alert("Cambio exitoso", isPresented: $showSuccessAlert) {
            Button("Aceptar", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Tu contraseña ha sido actualizada correctamente.")
        }
    }
    
    
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Cambiar contraseña")
                .font(.largeTitle.bold())
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 20)
    }
    
    private var formSection: some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                Text("Información de seguridad")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ProfileSecureField(
                    icon: "lock",
                    title: "Contraseña actual",
                    placeholder: "Ingrese su contraseña actual",
                    text: $currentPassword,
                    field: .current,
                    focusedField: $focusedField
                ) {
                    focusedField = .new
                }
                
                ProfileSecureField(
                    icon: "lock.rotation",
                    title: "Nueva contraseña",
                    placeholder: "Mín. 6 caracteres, 1 mayúscula y 1 especial",
                    text: $newPassword,
                    field: .new,
                    focusedField: $focusedField
                ) {
                    focusedField = .confirm
                }
                
                ProfileSecureField(
                    icon: "checkmark.seal",
                    title: "Confirmar nueva contraseña",
                    placeholder: "Repita la nueva contraseña",
                    text: $confirmPassword,
                    field: .confirm,
                    focusedField: $focusedField
                ) {
                    if isFormValid {
                        updatePassword()
                    }
                }
            }
            
            // Indicadores de validación
            if !newPassword.isEmpty {
                VStack(spacing: 8) {
                    ValidationIndicator(
                        text: "Mínimo 6 caracteres",
                        isValid: newPassword.count >= 6
                    )
                    
                    ValidationIndicator(
                        text: "Al menos una letra mayúscula",
                        isValid: containsUppercase(newPassword)
                    )
                    
                    ValidationIndicator(
                        text: "Al menos un carácter especial (!@#$%^&*)",
                        isValid: containsSpecialCharacter(newPassword)
                    )
                    
                    ValidationIndicator(
                        text: "Las contraseñas coinciden",
                        isValid: passwordsMatch && !confirmPassword.isEmpty
                    )
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 5)
        )
    }
    
    private var actionSection: some View {
        VStack(spacing: 16) {
            Button(action: updatePassword) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    
                    Text(isLoading ? "Actualizando..." : "Cambiar contraseña")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            isFormValid && !isLoading
                                ? Color("PrimaryColor")
                                : Color.gray
                        )
                )
            }
            .disabled(!isFormValid || isLoading)
            .animation(.easeInOut, value: isFormValid)
            
            if let error = errorMessage {
                ProfileErrorMessageView(error: error)
            }
        }
    }
    
    private var isFormValid: Bool {
        return !currentPassword.isEmpty &&
               !newPassword.isEmpty &&
               !confirmPassword.isEmpty &&
               newPassword == confirmPassword &&
               newPassword.count >= 6 &&
               containsSpecialCharacter(newPassword) &&
               containsUppercase(newPassword)
    }
    
    private var passwordsMatch: Bool {
        return newPassword == confirmPassword && !newPassword.isEmpty && !confirmPassword.isEmpty
    }
    
    private func containsSpecialCharacter(_ password: String) -> Bool {
        let specialCharacters = "!@#$%^&*()_+-=[]{}|;':\",./<>?"
        return password.rangeOfCharacter(from: CharacterSet(charactersIn: specialCharacters)) != nil
    }
    
    private func containsUppercase(_ password: String) -> Bool {
        return password.rangeOfCharacter(from: .uppercaseLetters) != nil
    }
    
    private func updatePassword() {
        guard isFormValid else { return }
        
        errorMessage = nil
        isLoading = true
        focusedField = nil
        
        guard let user = Auth.auth().currentUser,
              let email = user.email else {
            errorMessage = "No hay usuario autenticado"
            isLoading = false
            return
        }
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        
        user.reauthenticate(with: credential) { _, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "La contraseña actual es incorrecta"
                    self.isLoading = false
                }
                return
            }
            
            user.updatePassword(to: newPassword) { error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
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
                    } else {
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

// MARK: - Password Field Enum
enum PasswordField: CaseIterable {
    case current, new, confirm
}

// MARK: - Profile Secure Field Component
struct ProfileSecureField: View {
    let icon: String
    let title: String
    let placeholder: String
    @Binding var text: String
    let field: PasswordField
    @FocusState.Binding var focusedField: PasswordField?
    let onSubmit: () -> Void
    
    @State private var isSecured = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)
            
            HStack {
                Group {
                    if isSecured {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .focused($focusedField, equals: field)
                .onSubmit(onSubmit)
                
                Button(action: { isSecured.toggle() }) {
                    Image(systemName: isSecured ? "eye.slash" : "eye")
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
                    .stroke(
                        focusedField == field ? Color("PrimaryColor").opacity(0.4) : Color.clear,
                        lineWidth: 1.5
                    )
            )
        }
    }
}

// MARK: - Modern Help View
struct ModernHelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        BackgroundGeneralView {
            VStack(spacing: 0) {

                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 32) {
                        headerSection
                        helpSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
    }
    
    
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Preguntas Frecuentes")
                .font(.largeTitle.bold())
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 20)
    }
    
    private var helpSection: some View {
        VStack(spacing: 20) {
            ModernHelpItemCard(
                question: "¿Cómo actualizo mi información?",
                answer: "Puedes actualizar tu información personal haciendo clic en el icono de lápiz (editar) en la sección de 'Mi información'."
            )
            
            ModernHelpItemCard(
                question: "¿Olvidé mi contraseña?",
                answer: "Si olvidaste tu contraseña, puedes usar la opción 'Recuperar contraseña' en la pantalla de inicio de sesión."
            )
            
            ModernHelpItemCard(
                question: "¿Cómo puedo contactar soporte?",
                answer: "Puedes contactar a nuestro equipo de soporte al correo soporte@yadespega.com o llamando al (477) 123-4567."
            )
            
            ModernHelpItemCard(
                question: "¿Cómo cambio mi contraseña?",
                answer: "Puedes cambiar tu contraseña en la opción 'Cambio de contraseña' que aparece en tu perfil."
            )
            
            ModernHelpItemCard(
                question: "¿Cómo compro boletos?",
                answer: "Desde la pantalla principal, presiona 'Comprar Boletos', selecciona la cantidad de boletos que deseas y procede al pago."
            )
            
            ModernHelpItemCard(
                question: "¿Dónde veo mis boletos?",
                answer: "Puedes ver tus boletos comprados en la pestaña 'Tickets' de la aplicación."
            )
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 5)
        )
    }
}

// MARK: - Modern Help Item Card
struct ModernHelpItemCard: View {
    let question: String
    let answer: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color("PrimaryColor"))
                    
                    Text(question)
                        .font(.headline)
                        .foregroundColor(Color("PrimaryColor"))
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14))
                        .foregroundColor(Color("PrimaryColor"))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                Text(answer)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .padding(.leading, 32)
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color("PrimaryColor").opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Validation Indicator Component
struct ValidationIndicator: View {
    let text: String
    let isValid: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isValid ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 14))
                .foregroundColor(isValid ? .green : .gray)
            
            Text(text)
                .font(.caption)
                .foregroundColor(isValid ? .green : .gray)
            
            Spacer()
        }
    }
}

// MARK: - Profile Error Message Component
struct ProfileErrorMessageView: View {
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

// MARK: - Preview
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(ProfileViewModel())
            .previewDevice("iPhone 15 Pro")
            .previewDisplayName("Modern Profile View")
    }
}
