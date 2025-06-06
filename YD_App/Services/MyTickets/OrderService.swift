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
    
    /// Obtener todas las órdenes del usuario autenticado
    static func fetchAllOrders(completion: @escaping (Result<[Order], OrderError>) -> Void) {
        guard let url = URL(string: baseURL) else {
            completion(.failure(.urlInvalid))
            return
        }

        performAuthenticatedRequest(url: url) { result in
            switch result {
            case .success(let data):
                do {
                    let orders = try JSONDecoder().decode([Order].self, from: data)
                    completion(.success(orders))
                } catch {
                    print("❌ Error al decodificar órdenes:", error)
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
    
    /// Buscar orden por external_reference con retry logic
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
                    // ✅ Orden encontrada
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
        
        // Iniciar el primer intento
        attemptFetch(attempt: 1)
    }
    
    /// Buscar orden individual por external_reference (sin retry)
    static func fetchOrderByExternalReference(
        ref: String,
        completion: @escaping (Result<Order, OrderError>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/ref/\(ref)") else {
            completion(.failure(.urlInvalid))
            return
        }

        performAuthenticatedRequest(url: url) { result in
            switch result {
            case .success(let data):
                do {
                    let order = try JSONDecoder().decode(Order.self, from: data)
                    completion(.success(order))
                } catch {
                    print("❌ Error al decodificar orden:", error)
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
    
    // MARK: - Private Methods
    
    /// Realizar request autenticado con Firebase Auth
    private static func performAuthenticatedRequest(
        url: URL,
        completion: @escaping (Result<Data, OrderError>) -> Void
    ) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(.unauthorized))
            return
        }

        user.getIDToken { token, error in
            guard let token = token, error == nil else {
                print("❌ Error obteniendo token:", error?.localizedDescription ?? "Unknown")
                completion(.failure(.unauthorized))
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = timeoutInterval

            print("🌐 Realizando request a: \(url.absoluteString)")

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

                    // Manejar códigos de estado HTTP específicos
                    switch httpResponse.statusCode {
                    case 200...299:
                        guard let data = data else {
                            completion(.failure(.invalidResponse))
                            return
                        }
                        completion(.success(data))
                        
                    case 401:
                        print("❌ No autorizado - Token inválido o expirado")
                        completion(.failure(.unauthorized))
                        
                    case 404:
                        print("❌ Recurso no encontrado")
                        completion(.failure(.notFound))
                        
                    case 500...599:
                        print("❌ Error del servidor: \(httpResponse.statusCode)")
                        completion(.failure(.serverError))
                        
                    default:
                        print("❌ Error HTTP: \(httpResponse.statusCode)")
                        completion(.failure(.requestFailed))
                    }
                }
            }.resume()
        }
    }
}
