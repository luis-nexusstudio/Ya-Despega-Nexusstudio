//
//  RegisterView.swift
//  YD_App
//
//  Created by Luis Melendez on 24/04/25.
//

import SwiftUI

// MARK: - Form Data Model
struct RegisterFormData {
    var nombres = ""
    var apellidoPaterno = ""
    var apellidoMaterno = ""
    var numeroCelular = ""
    var email = ""
    var password = ""
    
    // Solo validaciones básicas aquí
    var hasBasicData: Bool {
        !nombres.isEmpty && !email.isEmpty && !password.isEmpty
    }
}

struct RegisterView: View {
    @StateObject private var viewModel = RegisterViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var onRegisterSuccess: () -> Void = {}
    
    @State private var formData = RegisterFormData()
    @FocusState private var focusedField: RegisterField?
    
    var body: some View {
        ZStack {
            BackgroundGeneralView {
                VStack(spacing: 0) {
                    // Custom header with dismiss button
                    modalHeader
                    
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
            
            if viewModel.registerState != .idle {
                RegisterFeedbackOverlay(state: viewModel.registerState, error: viewModel.currentAppError)
            }
        }
        .onSubmit {
            focusNextField()
        }
    }
}

// MARK: - View Sections
private extension RegisterView {
    var modalHeader: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                    Text("Cancelar")
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
    
    var headerSection: some View {
        VStack(spacing: 8) {
            Text("Crea tu cuenta")
                .font(.largeTitle.bold())
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 20)
    }
    
    var formSection: some View {
        VStack(spacing: 20) {
            // Nombre completo
            VStack(spacing: 16) {
                Text("Información personal")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ModernField(
                    icon: "person.text.rectangle",
                    title: "Nombres",
                    placeholder: "Ej: Luis Manuel",
                    text: $formData.nombres,
                    field: .nombres,
                    focusedField: $focusedField
                ) {
                    focusedField = .apellidoPaterno
                }
                
                HStack(spacing: 12) {
                    ModernField(
                        icon: "person",
                        title: "Apellido paterno",
                        placeholder: "Ej: Meléndez",
                        text: $formData.apellidoPaterno,
                        field: .apellidoPaterno,
                        focusedField: $focusedField
                    ) {
                        focusedField = .apellidoMaterno
                    }
                    
                    ModernField(
                        icon: "person",
                        title: "Apellido materno",
                        placeholder: "Ej: Rocha",
                        text: $formData.apellidoMaterno,
                        field: .apellidoMaterno,
                        focusedField: $focusedField
                    ) {
                        focusedField = .numeroCelular
                    }
                }
            }
            
            Divider()
                .background(.white.opacity(0.3))
            
            // Información de contacto
            VStack(spacing: 16) {
                Text("Información de contacto")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ModernField(
                    icon: "phone",
                    title: "Número celular",
                    placeholder: "Ej: 4772948285",
                    text: $formData.numeroCelular,
                    keyboard: .phonePad,
                    field: .numeroCelular,
                    focusedField: $focusedField
                ) {
                    focusedField = .email
                }
                
                ModernField(
                    icon: "envelope",
                    title: "Correo electrónico",
                    placeholder: "ejemplo@correo.com",
                    text: $formData.email,
                    keyboard: .emailAddress,
                    field: .email,
                    focusedField: $focusedField
                ) {
                    focusedField = .password
                }
                
                ModernSecureField(
                    icon: "lock",
                    title: "Contraseña",
                    placeholder: "Mínimo 6 caracteres",
                    text: $formData.password,
                    field: .password,
                    focusedField: $focusedField,
                    viewModel: viewModel
                ) {
                    if viewModel.isFormValid(
                        nombres: formData.nombres,
                        apellidoPaterno: formData.apellidoPaterno,
                        apellidoMaterno: formData.apellidoMaterno,
                        numeroCelular: formData.numeroCelular,
                        email: formData.email,
                        password: formData.password
                    ) {
                        register()
                    }
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
    
    var actionSection: some View {
        VStack(spacing: 16) {
            Button(action: register) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    
                    Text(viewModel.isLoading ? "Registrando..." : "Crear cuenta")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            viewModel.isFormValid(
                                nombres: formData.nombres,
                                apellidoPaterno: formData.apellidoPaterno,
                                apellidoMaterno: formData.apellidoMaterno,
                                numeroCelular: formData.numeroCelular,
                                email: formData.email,
                                password: formData.password
                            ) && !viewModel.isLoading
                                ? Color("PrimaryColor")
                                : Color.gray
                        )
                )
            }
            .disabled(!viewModel.isFormValid(
                nombres: formData.nombres,
                apellidoPaterno: formData.apellidoPaterno,
                apellidoMaterno: formData.apellidoMaterno,
                numeroCelular: formData.numeroCelular,
                email: formData.email,
                password: formData.password
            ) || viewModel.isLoading)
            .animation(.easeInOut, value: viewModel.isFormValid(
                nombres: formData.nombres,
                apellidoPaterno: formData.apellidoPaterno,
                apellidoMaterno: formData.apellidoMaterno,
                numeroCelular: formData.numeroCelular,
                email: formData.email,
                password: formData.password
            ))
            
            if let error = viewModel.currentAppError {
                ErrorMessageView(error: error.localizedDescription)
            }
        }
    }
}

// MARK: - Helper Methods
private extension RegisterView {
    func register() {
        focusedField = nil
        viewModel.resetState()
        
        viewModel.registerUser(
            email: formData.email.trimmingCharacters(in: .whitespacesAndNewlines),
            password: formData.password,
            nombres: formData.nombres.trimmingCharacters(in: .whitespacesAndNewlines),
            apellidoPaterno: formData.apellidoPaterno.trimmingCharacters(in: .whitespacesAndNewlines),
            apellidoMaterno: formData.apellidoMaterno.trimmingCharacters(in: .whitespacesAndNewlines),
            numeroCelular: formData.numeroCelular.trimmingCharacters(in: .whitespacesAndNewlines)
        ) {
            // Solo navegación, no lógica de negocio
            onRegisterSuccess()
        }
    }
    
    func focusNextField() {
        switch focusedField {
        case .nombres:
            focusedField = .apellidoPaterno
        case .apellidoPaterno:
            focusedField = .apellidoMaterno
        case .apellidoMaterno:
            focusedField = .numeroCelular
        case .numeroCelular:
            focusedField = .email
        case .email:
            focusedField = .password
        case .password:
            if viewModel.isFormValid(
                nombres: formData.nombres,
                apellidoPaterno: formData.apellidoPaterno,
                apellidoMaterno: formData.apellidoMaterno,
                numeroCelular: formData.numeroCelular,
                email: formData.email,
                password: formData.password
            ) {
                register()
            }
        case .none:
            break
        }
    }
}

// MARK: - Focus Field Enum
enum RegisterField: CaseIterable {
    case nombres, apellidoPaterno, apellidoMaterno, numeroCelular, email, password
}

// MARK: - Modern Field Component
struct ModernField: View {
    let icon: String
    let title: String
    let placeholder: String
    @Binding var text: String
    let keyboard: UIKeyboardType
    let field: RegisterField
    @FocusState.Binding var focusedField: RegisterField?
    let onSubmit: () -> Void
    
    init(
        icon: String,
        title: String,
        placeholder: String,
        text: Binding<String>,
        keyboard: UIKeyboardType = .default,
        field: RegisterField,
        focusedField: FocusState<RegisterField?>.Binding,
        onSubmit: @escaping () -> Void = {}
    ) {
        self.icon = icon
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.keyboard = keyboard
        self.field = field
        self._focusedField = focusedField
        self.onSubmit = onSubmit
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
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
        }
    }
}

// MARK: - Modern Secure Field Component
struct ModernSecureField: View {
    let icon: String
    let title: String
    let placeholder: String
    @Binding var text: String
    let field: RegisterField
    @FocusState.Binding var focusedField: RegisterField?
    let viewModel: RegisterViewModel
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
            
            // Password strength indicator
            if !text.isEmpty {
                VStack(spacing: 8) {
                    PasswordStrengthView(password: text, viewModel: viewModel)
                    PasswordRequirementsView(password: text)
                }
            }
        }
    }
}

// MARK: - Password Requirements View
struct PasswordRequirementsView: View {
    let password: String
    
    private var meetsLength: Bool {
        password.count >= 6
    }
    
    private var hasSpecialChar: Bool {
        UserDataValidator.hasSpecialCharacter(password)
    }
        
    private var hasUppercase: Bool {
        UserDataValidator.hasUppercaseLetter(password)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            RequirementRow(
                text: "Mínimo 6 caracteres",
                isMet: meetsLength
            )
            
            RequirementRow(
                text: "Al menos una mayúscula (A-Z)",
                isMet: hasUppercase
            )
            
            RequirementRow(
                text: "Al menos un carácter especial (!@#$%^&*)",
                isMet: hasSpecialChar
            )
        }
    }
}

// MARK: - Requirement Row
struct RequirementRow: View {
    let text: String
    let isMet: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .font(.caption2)
                .foregroundColor(isMet ? .green : .gray)
            
            Text(text)
                .font(.caption2)
                .foregroundColor(isMet ? .green : .gray)
            
            Spacer()
        }
    }
}

// MARK: - Password Strength Indicator
struct PasswordStrengthView: View {
    let password: String
    let viewModel: RegisterViewModel
    
    private var strength: PasswordStrength {
        UserDataValidator.validatePasswordRealTime(password)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Seguridad:")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(strength.description)
                    .font(.caption2.weight(.medium))
                    .foregroundColor(strength.color)
            }
            
            ProgressView(value: strength.progress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: strength.color))
                .frame(height: 2)
        }
    }
}

// MARK: - Error Message View
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

// MARK: - Register Feedback Overlay
struct RegisterFeedbackOverlay: View {
    let state: RegisterState
    let error: AppErrorProtocol?
    
    var body: some View {
        ZStack {
            Color.white.opacity(0.5)
                .ignoresSafeArea()
            
            switch state {
            case .loading:
                loadingView
            case .success:
                successView
            case .error:
                errorView
            case .idle:
                EmptyView()
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color("PrimaryColor")))
                .scaleEffect(1.5)
            
            Text("Registrando usuario...")
                .font(.headline)
                .foregroundColor(Color("SecondaryColor"))
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var successView: some View {
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                VStack(spacing: 8) {
                    Text("¡Cuenta creada!")
                        .font(.title2.bold())
                        .foregroundColor(Color("SecondaryColor"))

                    Text("Te hemos enviado un correo de verificación")
                        .font(.subheadline)
                        .foregroundColor(Color("SecondaryColor").opacity(0.9))
                        .multilineTextAlignment(.center)
                    
                    Text("Revisa tu bandeja de entrada y verifica tu email para poder realizar compras")
                        .font(.caption)
                        .foregroundColor(Color("SecondaryColor").opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
            .scaleEffect(0.8)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                }
            }
        }
    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.red)
            
            VStack(spacing: 8) {
                Text("Error al registrar")
                    .font(.title2.bold())
                    .foregroundColor(Color("SecondaryColor"))

                Text(error?.localizedDescription ?? "Inténtalo nuevamente")
                    .font(.subheadline)
                    .foregroundColor(Color("SecondaryColor").opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Preview
struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView()
            .previewDevice("iPhone 15 Pro")
    }
}
