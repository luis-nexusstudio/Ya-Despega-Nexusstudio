//
//  RegisterService.swift
//  YD_App
//
//  Created by Luis Melendez on 25/01/25.
//

import Foundation
import FirebaseAuth
import SwiftUICore

// MARK: - Error Types
enum RegisterError: AppErrorProtocol {
    case urlInvalid
    case requestFailed
    case decodingError
    case encodingError
    case emailAlreadyExists
    case timeout
    case serverUnreachable
    case serverError
    case noInternet
    case invalidResponse
    case validationFailed(String)
    
    // MARK: - AppErrorProtocol Implementation
    var userMessage: String {
        switch self {
        case .urlInvalid:
            return "Error de configuración. Contacta soporte."
        case .requestFailed:
            return "Error de conexión. Verifica tu internet."
        case .decodingError:
            return "Error procesando respuesta del servidor."
        case .encodingError:
            return "Error preparando datos. Intenta nuevamente."
        case .emailAlreadyExists:
            return "Este correo ya está registrado. Intenta con otro."
        case .timeout:
            return "La operación tardó demasiado. Intenta nuevamente."
        case .serverUnreachable:
            return "No se pudo conectar al servidor. Intenta más tarde."
        case .serverError:
            return "Error del servidor. Intenta nuevamente."
        case .noInternet:
            return "Sin conexión a internet. Verifica tu conexión."
        case .invalidResponse:
            return "Respuesta inválida del servidor."
        case .validationFailed(let message):
            return message
        }
    }
    
    var errorCode: String {
        switch self {
        case .urlInvalid: return "REG_001"
        case .requestFailed: return "REG_002"
        case .decodingError: return "REG_003"
        case .encodingError: return "REG_004"
        case .emailAlreadyExists: return "REG_005"
        case .timeout: return "REG_006"
        case .serverUnreachable: return "REG_007"
        case .serverError: return "REG_008"
        case .noInternet: return "REG_009"
        case .invalidResponse: return "REG_010"
        case .validationFailed: return "REG_011"
        }
    }
    
    var shouldRetry: Bool {
        switch self {
        case .urlInvalid, .decodingError, .encodingError, .emailAlreadyExists, .invalidResponse, .validationFailed:
            return false
        case .requestFailed, .timeout, .serverUnreachable, .serverError, .noInternet:
            return true
        }
    }
    
    var icon: String {
        switch self {
        case .noInternet: return "wifi.slash"
        case .serverUnreachable, .serverError: return "antenna.radiowaves.left.and.right"
        case .timeout: return "clock.badge.exclamationmark"
        case .emailAlreadyExists, .validationFailed: return "exclamationmark.triangle"
        default: return "exclamationmark.circle"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .noInternet, .emailAlreadyExists: return .red
        case .serverUnreachable, .serverError, .timeout: return .orange
        case .validationFailed: return .red
        default: return .gray
        }
    }
    
    var logMessage: String {
        return "[\(errorCode)] Register Error: \(userMessage)"
    }
}

// MARK: - RegisterService
class RegisterService {
    
    // MARK: - Constants
    static let baseURL = "http://localhost:4000/api/user/add"
    private static let timeoutInterval: TimeInterval = 30.0
    
    // MARK: - Public Methods
    
    /// Registrar nuevo usuario
    static func registerUser(
        email: String,
        password: String,
        nombres: String,
        apellidoPaterno: String,
        apellidoMaterno: String,
        numeroCelular: String,
        completion: @escaping (Result<RegisteredUser, RegisterError>) -> Void
    ) {
        print("🔄 Iniciando registro para: \(email)")
        
        // Crear URL
        guard let url = URL(string: baseURL) else {
            completion(.failure(.urlInvalid))
            return
        }
        
        // Preparar request body
        let registerRequest = RegisterRequest(
            email: email,
            password: password,
            nombres: nombres,
            apellido_paterno: apellidoPaterno,
            apellido_materno: apellidoMaterno,
            numero_celular: numeroCelular
        )
        
        // Encodificar datos
        guard let jsonData = try? JSONEncoder().encode(registerRequest) else {
            completion(.failure(.encodingError))
            return
        }
        
        // Debug: Imprimir datos que se envían
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("📤 Datos enviados:", jsonString)
        }
        
        // Configurar request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = timeoutInterval
        
        print("🌐 Enviando request a: \(url.absoluteString)")
        
        // Realizar request
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                // Manejar errores de red específicos
                if let error = error {
                    print("❌ Error de red:", error.localizedDescription)
                    let nsError = error as NSError
                    
                    switch nsError.code {
                    case NSURLErrorTimedOut:
                        completion(.failure(.timeout))
                    case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
                        completion(.failure(.noInternet))
                    case NSURLErrorCannotConnectToHost, NSURLErrorCannotFindHost:
                        completion(.failure(.serverUnreachable))
                    case NSURLErrorDNSLookupFailed:
                        completion(.failure(.serverUnreachable))
                    default:
                        completion(.failure(.requestFailed))
                    }
                    return
                }
                
                // Validar respuesta HTTP
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ Respuesta HTTP inválida")
                    completion(.failure(.invalidResponse))
                    return
                }
                
                print("📡 Status code: \(httpResponse.statusCode)")
                
                guard let data = data else {
                    completion(.failure(.invalidResponse))
                    return
                }
                
                // Manejar códigos de estado HTTP específicos
                switch httpResponse.statusCode {
                case 200...299:
                    // Registro exitoso
                    do {
                        let registerResponse = try JSONDecoder().decode(RegisterResponse.self, from: data)
                        if let user = registerResponse.user {
                            print("✅ Usuario registrado exitosamente: \(user.email)")
                            print("📧 Correo de verificación enviado automáticamente")
                            completion(.success(user))
                        } else {
                            print("❌ Registro falló: \(registerResponse.message)")
                            completion(.failure(.validationFailed(registerResponse.message)))

                        }
                    } catch {
                        print("❌ Error al decodificar respuesta:", error)
                        if let jsonString = String(data: data, encoding: .utf8) {
                            print("📄 JSON recibido:", jsonString)
                        }
                        completion(.failure(.decodingError))
                    }
                    
                case 401:
                    // No autorizado
                    print("❌ No autorizado - Endpoint requiere autenticación")
                    completion(.failure(.validationFailed("Error de autenticación")))
                    
                case 400:
                    // Error de validación del servidor
                    print("❌ Error 400 - Validación fallida")
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("📄 Respuesta del servidor:", jsonString)
                    }
                    
                    // Parsear como error simple {"error": "mensaje"}
                    do {
                        if let errorDict = try JSONSerialization.jsonObject(with: data) as? [String: String],
                           let errorMessage = errorDict["error"] {
                            print("📄 Error parseado:", errorMessage)
                            if errorMessage.lowercased().contains("email") ||
                               errorMessage.lowercased().contains("correo") ||
                               errorMessage.lowercased().contains("already") ||
                               errorMessage.lowercased().contains("registrado") {
                                completion(.failure(.emailAlreadyExists))
                            } else {
                                completion(.failure(.validationFailed(errorMessage)))
                            }
                        } else {
                            completion(.failure(.validationFailed("Error de validación")))
                        }
                    } catch {
                        print("❌ No se pudo parsear error 400")
                        completion(.failure(.validationFailed("Error de validación")))
                    }
                    
                case 422:
                    // Error de validación de datos (Unprocessable Entity)
                    print("❌ Error 422 - Datos no válidos")
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("📄 Respuesta del servidor:", jsonString)
                    }
                    do {
                        // Intentar parsear como array de errores de validación
                        if let errorDict = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let errors = errorDict["errors"] as? [[String: Any]] {
                            let errorMessages = errors.compactMap { $0["msg"] as? String }
                            let combinedMessage = errorMessages.joined(separator: "\n")
                            print("📄 Errores de validación:", combinedMessage)
                            completion(.failure(.validationFailed(combinedMessage.isEmpty ? "Datos inválidos" : combinedMessage)))
                        } else {
                            // Intentar parsear como RegisterResponse
                            let errorResponse = try JSONDecoder().decode(RegisterResponse.self, from: data)
                            print("📄 Error parseado:", errorResponse.message)
                            completion(.failure(.validationFailed(errorResponse.message)))
                        }
                    } catch {
                        print("❌ No se pudo parsear error 422")
                        completion(.failure(.validationFailed("Error en formato de datos enviados")))
                    }
                    
                case 500...599:
                    print("❌ Error del servidor: \(httpResponse.statusCode)")
                    completion(.failure(.serverError))
                    
                default:
                    print("❌ Error HTTP inesperado: \(httpResponse.statusCode)")
                    completion(.failure(.serverError))
                }
            }
        }.resume()
    }
    
}
