//
//  UserModel.swift
//  YD_App
//
//  Created by Luis Melendez on 24/04/25.
//

import Foundation

// MARK: - Register Response Models
struct RegisterResponse: Codable {
    let message: String
    let user: RegisteredUser?
    let requiresEmailVerification: Bool? // ✅ YA LO TIENES
}

struct RegisteredUser: Codable {
    let id: String
    let nombres: String
    let apellido_paterno: String
    let apellido_materno: String
    let numero_celular: String
    let email: String
    let rol_id: String
    let fecha_registro: FirestoreTimestamp?
    
    // ✅ AGREGAR SOLO ESTOS CAMPOS MÍNIMOS para email verification
    let email_verification_status: String?
    let email_verified_at: String?
    
    enum CodingKeys: String, CodingKey {
        case id, nombres, email, rol_id
        case apellido_paterno
        case apellido_materno
        case numero_celular
        case fecha_registro
        // ✅ AGREGAR las nuevas keys
        case email_verification_status
        case email_verified_at
    }
    
    // ✅ COMPUTED PROPERTIES útiles
    var isEmailVerified: Bool {
        return email_verification_status?.lowercased() == "verified"
    }
    
    var needsEmailVerification: Bool {
        return email_verification_status?.lowercased() == "pending"
    }
    
    var verificationStatusText: String {
        switch email_verification_status?.lowercased() {
        case "verified":
            return "Verificado"
        case "pending":
            return "Pendiente"
        default:
            return "Sin verificar"
        }
    }
}

// MARK: - Firestore Timestamp Model (sin cambios)
struct FirestoreTimestamp: Codable {
    let _seconds: Int
    let _nanoseconds: Int
    
    var date: Date {
        Date(timeIntervalSince1970: TimeInterval(_seconds))
    }
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Register Request Model (sin cambios)
struct RegisterRequest: Codable {
    let email: String
    let password: String
    let nombres: String
    let apellido_paterno: String
    let apellido_materno: String
    let numero_celular: String
}
