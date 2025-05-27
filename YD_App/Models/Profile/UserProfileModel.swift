//
//  UserProfileModel.swift
//  YD_App
//
//  Created by Pedro Martinez on 19/05/25.
//

import Foundation
import FirebaseAuth

struct UserProfileModel: Identifiable {
    var id: String
    var email: String
    var nombres: String
    var apellidoPaterno: String
    var apellidoMaterno: String
    var numeroCelular: String
    
    // Propiedades computadas útiles
    var nombreCompleto: String {
        "\(nombres) \(apellidoPaterno) \(apellidoMaterno)"
    }
    
    var iniciales: String {
        guard !nombres.isEmpty else { return "" }
        
        let primeraInicial = nombres.prefix(1)
        let segundaInicial = apellidoPaterno.prefix(1)
        
        if segundaInicial.isEmpty {
            return String(primeraInicial)
        } else {
            return "\(primeraInicial)\(segundaInicial)"
        }
    }
    
    // Constructor con valores por defecto
    init(id: String = "",
         email: String = "",
         nombres: String = "",
         apellidoPaterno: String = "",
         apellidoMaterno: String = "",
         numeroCelular: String = "") {
        
        self.id = id
        self.email = email
        self.nombres = nombres
        self.apellidoPaterno = apellidoPaterno
        self.apellidoMaterno = apellidoMaterno
        self.numeroCelular = numeroCelular
    }
    
    // Crear a partir del usuario de Firebase Auth (datos básicos)
    static func fromFirebaseUser(_ user: User) -> UserProfileModel {
        return UserProfileModel(
            id: user.uid,
            email: user.email ?? ""
        )
    }
}

// MARK: - Codable Extension
// Estructura intermedia para codificación/decodificación
struct UserProfileModelCodable: Codable {
    var id: String
    var email: String
    var nombres: String
    var apellido_paterno: String
    var apellido_materno: String
    var numero_celular: String
    var rol_id: String?
    
    // Constructor desde UserProfileModel
    init(from model: UserProfileModel) {
        self.id = model.id
        self.email = model.email
        self.nombres = model.nombres
        self.apellido_paterno = model.apellidoPaterno
        self.apellido_materno = model.apellidoMaterno
        self.numero_celular = model.numeroCelular
        self.rol_id = nil  // No lo usamos, pero lo incluimos para compatibilidad
    }
    
    // Convertir a UserProfileModel
    func toModel() -> UserProfileModel {
        return UserProfileModel(
            id: self.id,
            email: self.email,
            nombres: self.nombres,
            apellidoPaterno: self.apellido_paterno,
            apellidoMaterno: self.apellido_materno,
            numeroCelular: self.numero_celular
        )
    }
}

// MARK: - Funciones de ayuda para codificación/decodificación JSON
extension UserProfileModel {
    // Decodificar desde Data con manejo específico para esta API
    static func decode(from data: Data) -> UserProfileModel? {
        do {
            // Primero intentamos imprimir el JSON para diagnóstico
            if let jsonString = String(data: data, encoding: .utf8) {
                print("🟢 JSON recibido: \(jsonString)")
            }
            
            // Intenta primero decodificar como JSON genérico para inspeccionar la estructura
            if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                print("🔵 Estructura JSON recibida: \(jsonObject.keys)")
                
                // Extraer el objeto "user" de la respuesta (formato especial de esta API)
                if let userDict = jsonObject["user"] as? [String: Any] {
                    print("🟢 Objeto user encontrado")
                    
                    // Extrayendo campos directamente desde el diccionario
                    let id = userDict["id"] as? String ?? ""
                    let email = userDict["email"] as? String ?? ""
                    let nombres = userDict["nombres"] as? String ?? ""
                    let apellidoPaterno = userDict["apellido_paterno"] as? String ?? ""
                    let apellidoMaterno = userDict["apellido_materno"] as? String ?? ""
                    let numeroCelular = userDict["numero_celular"] as? String ?? ""
                    
                    return UserProfileModel(
                        id: id,
                        email: email,
                        nombres: nombres,
                        apellidoPaterno: apellidoPaterno,
                        apellidoMaterno: apellidoMaterno,
                        numeroCelular: numeroCelular
                    )
                }
            }
            
            // Si no encontramos un objeto "user", intentamos decodificar directamente
            let decoder = JSONDecoder()
            let codableModel = try decoder.decode(UserProfileModelCodable.self, from: data)
            return codableModel.toModel()
        } catch {
            print("🔴 Error decodificando UserProfileModel: \(error.localizedDescription)")
            
            // Si falla, intentamos imprimir el JSON para diagnóstico
            if let jsonString = String(data: data, encoding: .utf8) {
                print("🔴 JSON recibido: \(jsonString)")
            }
            
            return nil
        }
    }
    
    // Codificar a Data
    func encode() -> Data? {
        do {
            let codableModel = UserProfileModelCodable(from: self)
            let encoder = JSONEncoder()
            return try encoder.encode(codableModel)
        } catch {
            print("🔴 Error codificando UserProfileModel: \(error.localizedDescription)")
            return nil
        }
    }
    
    // Codificar a diccionario [String: Any]
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "email": email,
            "nombres": nombres,
            "apellido_paterno": apellidoPaterno,
            "apellido_materno": apellidoMaterno,
            "numero_celular": numeroCelular
        ]
    }
}
