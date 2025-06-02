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
    
    enum CodingKeys: String, CodingKey {
        case id, nombres, email, rol_id
        case apellido_paterno
        case apellido_materno
        case numero_celular
        case fecha_registro
    }
}

// MARK: - Firestore Timestamp Model
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

// MARK: - Register Request Model
struct RegisterRequest: Codable {
    let email: String
    let password: String
    let nombres: String
    let apellido_paterno: String
    let apellido_materno: String
    let numero_celular: String
}
