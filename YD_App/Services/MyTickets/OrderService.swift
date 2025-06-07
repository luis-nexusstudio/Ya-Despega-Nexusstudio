//
//  OrderService.swift
//  YD_App
//
//  Created by Luis Melendez on 25/01/25.
//

import Foundation
import FirebaseAuth
import SwiftUICore

enum OrderError: AppErrorProtocol {
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
            return "Error procesando información de órdenes."
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
        case .urlInvalid: return "ORD_001"
        case .requestFailed: return "ORD_002"
        case .decodingError: return "ORD_003"
        case .unauthorized: return "ORD_004"
        case .notFound: return "ORD_005"
        case .timeout: return "ORD_006"
        case .retryExhausted: return "ORD_007"
        case .invalidResponse: return "ORD_008"
        case .serverUnreachable: return "ORD_009"
        case .serverError: return "ORD_010"
        case .noInternet: return "ORD_011"
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
// MARK: - OrderService
class OrderService {
    
    // MARK: - Constants
    static let baseURL = "http://localhost:4000/api/orders"
    private static let maxRetries = 5
    private static let retryDelay: TimeInterval = 2.0
    private static let timeoutInterval: TimeInterval = 30.0
    
    // MARK: - Public Methods
    
    /// Obtener todas las órdenes del usuario autenticado usando SessionManager
    static func fetchAllOrders(completion: @escaping (Result<[Order], OrderError>) -> Void) {
        guard let url = URL(string: baseURL) else {
            completion(.failure(.urlInvalid))
            return
        }

        Task {
            do {
                let result = try await SessionManager.shared.performAuthenticatedOperation { token in
                    return try await performRequest(url: url, token: token)
                }
                
                let orders = try JSONDecoder().decode([Order].self, from: result)
                await MainActor.run {
                    completion(.success(orders))
                }
            } catch {
                await MainActor.run {
                    completion(.failure(mapToOrderError(error)))
                }
            }
        }
    }
    
    /// Buscar orden por external_reference con retry logic usando SessionManager
    static func fetchOrderByExternalReferenceWithRetry(
        ref: String,
        completion: @escaping (Result<Order, OrderError>) -> Void
    ) {
        print("🔍 Iniciando búsqueda de orden con retry logic para ref: \(ref)")
        
        func attemptFetch(attempt: Int) {
            print("🔄 Intento \(attempt)/\(maxRetries)")
            
            fetchOrderByExternalReference(ref: ref) { result in
                switch result {
                case .success(let order):
                    if order.isProcessed {
                        print("✅ Orden confirmada: \(order.status)")
                        completion(.success(order))
                        return
                    } else if attempt < maxRetries {
                        print("⏳ Orden sin procesar, reintentando en \(retryDelay)s...")
                        DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) {
                            attemptFetch(attempt: attempt + 1)
                        }
                    } else {
                        print("⚠️ Orden encontrada pero sin información de pago completa")
                        completion(.success(order))
                    }
                    
                case .failure(.notFound):
                    if attempt < maxRetries {
                        print("🔍 Orden no encontrada, reintentando en \(retryDelay)s...")
                        DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) {
                            attemptFetch(attempt: attempt + 1)
                        }
                    } else {
                        print("❌ Orden no encontrada después de \(maxRetries) intentos")
                        completion(.failure(.retryExhausted))
                    }
                    
                case .failure(let error):
                    print("❌ Error no recuperable: \(error)")
                    completion(.failure(error))
                }
            }
        }
        
        attemptFetch(attempt: 1)
    }
    
    /// Buscar orden individual por external_reference usando SessionManager
    static func fetchOrderByExternalReference(
        ref: String,
        completion: @escaping (Result<Order, OrderError>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/ref/\(ref)") else {
            completion(.failure(.urlInvalid))
            return
        }

        Task {
            do {
                let result = try await SessionManager.shared.performAuthenticatedOperation { token in
                    return try await performRequest(url: url, token: token)
                }
                
                let order = try JSONDecoder().decode(Order.self, from: result)
                await MainActor.run {
                    completion(.success(order))
                }
            } catch {
                await MainActor.run {
                    completion(.failure(mapToOrderError(error)))
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private static func performRequest(url: URL, token: String) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = timeoutInterval

        print("🌐 Realizando request a: \(url.absoluteString)")

        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Respuesta HTTP inválida")
            throw OrderError.invalidResponse
        }

        print("📡 Status code: \(httpResponse.statusCode)")

        switch httpResponse.statusCode {
        case 200...299:
            return data
        case 401:
            print("❌ No autorizado - Token inválido o expirado")
            throw OrderError.unauthorized
        case 404:
            print("❌ Recurso no encontrado")
            throw OrderError.notFound
        case 500...599:
            print("❌ Error del servidor: \(httpResponse.statusCode)")
            throw OrderError.serverError
        default:
            print("❌ Error HTTP: \(httpResponse.statusCode)")
            throw OrderError.requestFailed
        }
    }
    
    private static func mapToOrderError(_ error: Error) -> OrderError {
        if let orderError = error as? OrderError {
            return orderError
        }
        
        if let sessionError = error as? SessionError {
            switch sessionError {
            case .userNotAuthenticated, .tokenExpired, .invalidUser:
                return .unauthorized
            case .tokenRefreshFailed:
                return .requestFailed
            case .logoutFailed:
                return .serverError
            }
        }
        
        return error.toAppError() as? OrderError ?? .requestFailed
    }
}
