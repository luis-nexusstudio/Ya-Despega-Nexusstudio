//
//  Validations.swift
//  YD_App
//
//  Created by Luis Melendez on 02/06/25.
//

//
//  UserDataValidator.swift
//  YD_App
//
//  🆕 NUEVO ARCHIVO - Crear en: YD_App/Utils/Validation/
//

import Foundation
import SwiftUICore

// MARK: - Validation Result
enum ValidationResult {
    case valid
    case invalid([ValidationError])
    
    var isValid: Bool {
        switch self {
        case .valid: return true
        case .invalid: return false
        }
    }
    
    var errors: [ValidationError] {
        switch self {
        case .valid: return []
        case .invalid(let errors): return errors
        }
    }
    
    var firstErrorMessage: String? {
        errors.first?.localizedDescription
    }
}

// MARK: - Validation Errors
enum ValidationError: Error, LocalizedError {
    case invalidEmail
    case weakPassword
    case missingRequiredField(String)
    case invalidPhoneNumber
    case passwordTooShort
    case passwordMissingUppercase
    case passwordMissingSpecialChar
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Formato de correo inválido"
        case .weakPassword:
            return "La contraseña no cumple los requisitos de seguridad"
        case .missingRequiredField(let field):
            return "\(field) es requerido"
        case .invalidPhoneNumber:
            return "Formato de número celular inválido"
        case .passwordTooShort:
            return "La contraseña debe tener al menos 6 caracteres"
        case .passwordMissingUppercase:
            return "La contraseña debe tener al menos una mayúscula"
        case .passwordMissingSpecialChar:
            return "La contraseña debe tener al menos un carácter especial"
        }
    }
}

// MARK: - User Data Validator
struct UserDataValidator {
    
    // MARK: - Main Validation Method
    static func validate(_ userData: RegisterFormData) -> ValidationResult {
        var errors: [ValidationError] = []
        
        // Validar campos requeridos
        if userData.nombres.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(.missingRequiredField("Nombres"))
        }
        
        if userData.apellidoPaterno.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(.missingRequiredField("Apellido paterno"))
        }
        
        if userData.apellidoMaterno.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(.missingRequiredField("Apellido materno"))
        }
        
        if userData.numeroCelular.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(.missingRequiredField("Número celular"))
        }
        
        if userData.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(.missingRequiredField("Correo electrónico"))
        }
        
        if userData.password.isEmpty {
            errors.append(.missingRequiredField("Contraseña"))
        }
        
        // Validar formato de email
        if !userData.email.isEmpty && !isValidEmail(userData.email) {
            errors.append(.invalidEmail)
        }
        
        // Validar número celular
        if !userData.numeroCelular.isEmpty && !isValidPhoneNumber(userData.numeroCelular) {
            errors.append(.invalidPhoneNumber)
        }
        
        // Validar contraseña
        let passwordErrors = validatePassword(userData.password)
        errors.append(contentsOf: passwordErrors)
        
        return errors.isEmpty ? .valid : .invalid(errors)
    }
    
    // MARK: - Individual Validation Methods
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    static func isValidPhoneNumber(_ phone: String) -> Bool {
        // Remover espacios y caracteres especiales
        let cleaned = phone.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        // Validar que tenga 10 dígitos
        return cleaned.count == 10
    }
    
    static func validatePassword(_ password: String) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        if password.count < 6 {
            errors.append(.passwordTooShort)
        }
        
        if !hasUppercaseLetter(password) {
            errors.append(.passwordMissingUppercase)
        }
        
        if !hasSpecialCharacter(password) {
            errors.append(.passwordMissingSpecialChar)
        }
        
        return errors
    }
    
    static func hasUppercaseLetter(_ password: String) -> Bool {
        return password.rangeOfCharacter(from: .uppercaseLetters) != nil
    }
    
    static func hasSpecialCharacter(_ password: String) -> Bool {
        return password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")) != nil
    }
    
    // MARK: - Real-time Validation (for UI feedback)
    static func validateEmailRealTime(_ email: String) -> Bool {
        return email.isEmpty || isValidEmail(email)
    }
    
    static func validatePasswordRealTime(_ password: String) -> PasswordStrength {
        return PasswordStrength.evaluate(password)
    }
}

// MARK: - Password Strength (movido aquí desde RegisterView)
enum PasswordStrength {
    case weak, fair, good, strong
    
    var description: String {
        switch self {
        case .weak: return "Débil"
        case .fair: return "Regular"
        case .good: return "Buena"
        case .strong: return "Fuerte"
        }
    }
    
    var color: Color {
        switch self {
        case .weak: return .red
        case .fair: return .orange
        case .good: return .yellow
        case .strong: return .green
        }
    }
    
    var progress: Double {
        switch self {
        case .weak: return 0.25
        case .fair: return 0.5
        case .good: return 0.75
        case .strong: return 1.0
        }
    }
    
    static func evaluate(_ password: String) -> PasswordStrength {
        var score = 0
        
        if password.count >= 6 { score += 1 }
        if password.count >= 8 { score += 1 }
        if UserDataValidator.hasUppercaseLetter(password) { score += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil { score += 1 }
        if UserDataValidator.hasSpecialCharacter(password) { score += 1 }
        
        switch score {
        case 0...2: return .weak
        case 3: return .fair
        case 4: return .good
        default: return .strong
        }
    }
}
