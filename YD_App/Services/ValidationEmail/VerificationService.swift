//
//  Validation.swift
//  YD_App
//
//  Created by Luis Melendez on 02/06/25.
//

//
//  VerificationService.swift
//  YD_App
//
//  Created by Luis Melendez on 02/06/25.
//

import Foundation
import FirebaseAuth
import SwiftUICore

enum VerificationError: AppErrorProtocol {
    case urlInvalid
    case requestFailed
    case decodingError
    case unauthorized
    case notFound
    case timeout
    case retryExhausted
    case invalidResponse
    case serverUnreachable
    case serverError
    case noInternet
    
    var userMessage: String {
        switch self {
        case .urlInvalid:
            return "Error de configuración. Contacta soporte."
        case .requestFailed:
            return "Error de conexión. Verifica tu internet."
        case .decodingError:
            return "Error procesando información."
        case .unauthorized:
            return "Tu sesión ha expirado. Inicia sesión nuevamente."
        case .notFound:
            return "La información solicitada no fue encontrada."
        case .timeout:
            return "La operación tardó demasiado. Intenta nuevamente."
        case .retryExhausted:
            return "No se pudo obtener la información tras varios intentos."
        case .invalidResponse:
            return "Respuesta inválida del servidor."
        case .serverUnreachable:
            return "No se pudo conectar al servidor. Intenta más tarde."
        case .serverError:
            return "Error del servidor. Intenta nuevamente en unos minutos."
        case .noInternet:
            return "Sin conexión a internet. Verifica tu conexión e intenta nuevamente."
        }
        
    }
    
    var errorCode: String {
        switch self {
        case .urlInvalid: return "VER_001"
        case .requestFailed: return "VER_002"
        case .decodingError: return "VER_003"
        case .unauthorized: return "VER_004"
        case .notFound: return "VER_005"
        case .timeout: return "VER_006"
        case .retryExhausted: return "OVER_007"
        case .invalidResponse: return "VER_008"
        case .serverUnreachable: return "VER_009"
        case .serverError: return "VER_010"
        case .noInternet: return "VER_011"
        }
    }
    
    var shouldRetry: Bool {
        switch self {
        case .urlInvalid, .decodingError, .unauthorized, .notFound, .retryExhausted, .invalidResponse:
            return false
        case .requestFailed, .timeout, .serverUnreachable, .serverError, .noInternet:
            return true
        }
    }

    
    var icon: String {
        switch self {
        case .noInternet:
            return "wifi.slash"
        case .serverUnreachable:
            return "antenna.radiowaves.left.and.right"
        case .serverError:
            return "exclamationmark.icloud"
        case .unauthorized:
            return "lock.shield"
        case .notFound:
            return "magnifyingglass.circle"
        case .timeout:
            return "clock.badge.exclamationmark"
        default: return "exclamationmark.circle"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .noInternet, .serverUnreachable:
            return .red
        case .serverError, .timeout:
            return .orange
        case .unauthorized:
            return .yellow
        case .notFound:
            return .gray
        default: return .blue
        }
    }
    
    var logMessage: String {
        return "[\(errorCode)] Order Error: \(userMessage)"
    }
}


// MARK: - VerificationService
class VerificationService {
    
    // MARK: - Constants
    static let baseURL = "http://localhost:4000/api"
    private static let timeoutInterval: TimeInterval = 30.0
    
    // MARK: - Public Methods
    
    /// Obtener estado detallado de verificación
    static func getVerificationStatus(completion: @escaping (Result<VerificationData, VerificationError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/verification/status") else {
            completion(.failure(.urlInvalid))
            return
        }
        
        print("🔐 [VerificationService] Obteniendo estado de verificación...")
        
        performAuthenticatedRequest(url: url, method: "GET") { result in
            switch result {
            case .success(let data):
                do {
                    let response = try JSONDecoder().decode(VerificationStatusResponse.self, from: data)
                    
                    if response.success, let verificationData = response.data {
                        print("✅ [VerificationService] Estado obtenido - Verificado: \(verificationData.verified)")
                        completion(.success(verificationData))
                    } else {
                        let errorMessage = response.error ?? "Error desconocido"
                        print("❌ [VerificationService] Error del servidor: \(errorMessage)")
                        completion(.failure(.serverError))
                    }
                } catch {
                    print("❌ [VerificationService] Error decodificando verificación:", error)
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("📄 JSON recibido:", jsonString)
                    }
                    completion(.failure(.decodingError))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Verificar si el usuario puede realizar compras
    static func canPurchase(completion: @escaping (Result<Bool, VerificationError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/verification/can-purchase") else {
            completion(.failure(.urlInvalid))
            return
        }
        
        print("🛒 [VerificationService] Verificando permisos de compra...")
        
        performAuthenticatedRequest(url: url, method: "GET") { result in
            switch result {
            case .success(let data):
                do {
                    let response = try JSONDecoder().decode(CanPurchaseResponse.self, from: data)
                    
                    if response.success {
                        print("✅ [VerificationService] Puede comprar: \(response.canPurchase)")
                        completion(.success(response.canPurchase))
                    } else {
                        let errorMessage = response.error ?? "Error verificando permisos"
                        print("❌ [VerificationService] Error verificando permisos: \(errorMessage)")
                        completion(.failure(.serverError))
                    }
                } catch {
                    print("❌ [VerificationService] Error decodificando can-purchase:", error)
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("📄 JSON recibido:", jsonString)
                    }
                    completion(.failure(.decodingError))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Verificación rápida y silenciosa (sin logs detallados)
    static func quickVerificationCheck(completion: @escaping (Bool) -> Void) {
        canPurchase { result in
            switch result {
            case .success(let canPurchase):
                completion(canPurchase)
            case .failure:
                completion(false)
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Realizar request autenticado con Firebase Auth
    private static func performAuthenticatedRequest(
        url: URL,
        method: String,
        completion: @escaping (Result<Data, VerificationError>) -> Void
    ) {
        guard let user = Auth.auth().currentUser else {
            print("❌ [VerificationService] Usuario no autenticado")
            completion(.failure(.unauthorized))
            return
        }

        user.getIDToken { token, error in
            guard let token = token, error == nil else {
                print("❌ [VerificationService] Error obteniendo token:", error?.localizedDescription ?? "Unknown")
                completion(.failure(.unauthorized))
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = method  // 🔥 AHORA ES CONFIGURABLE
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = timeoutInterval

            print("🌐 [VerificationService] \(method) Request a: \(url.absoluteString)")

            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    // Manejar errores de red específicos
                    if let error = error {
                        print("❌ [VerificationService] Error de red:", error.localizedDescription)
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
                        print("❌ [VerificationService] Respuesta HTTP inválida")
                        completion(.failure(.requestFailed))
                        return
                    }

                    print("📡 [VerificationService] Status code: \(httpResponse.statusCode)")

                    // Manejar códigos de estado HTTP específicos
                    switch httpResponse.statusCode {
                    case 200...299:
                        guard let data = data else {
                            completion(.failure(.requestFailed))
                            return
                        }
                        completion(.success(data))
                        
                    case 401:
                        print("❌ [VerificationService] No autorizado - Token inválido o expirado")
                        completion(.failure(.unauthorized))
                        
                    case 403:
                        print("⚠️ [VerificationService] Acceso prohibido - Email no verificado")
                        // Devolver los datos para que el caller pueda manejar la respuesta
                        if let data = data {
                            completion(.success(data))
                        } else {
                            completion(.failure(.unauthorized))
                        }
                        
                    case 404:
                        print("❌ [VerificationService] Endpoint no encontrado")
                        completion(.failure(.notFound))  // 🔥 CAMBIADO PARA SER MÁS ESPECÍFICO
                        
                    case 500...599:
                        print("❌ [VerificationService] Error del servidor: \(httpResponse.statusCode)")
                        completion(.failure(.serverError))
                        
                    default:
                        print("❌ [VerificationService] Error HTTP inesperado: \(httpResponse.statusCode)")
                        completion(.failure(.requestFailed))
                    }
                }
            }.resume()
        }
    }
    
}
