//
//  CheckoutService.swift
//  YD_App
//
//  Created by Luis Melendez on 13/05/25.
//

import Foundation
import FirebaseAuth
import SwiftUI

enum CheckoutError: AppErrorProtocol {
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
    case emailNotVerified
    
    
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
        case .emailNotVerified:
            return "Verifica tu correo electrónico para continuar."
        }
        
    }
    
    var errorCode: String {
        switch self {
        case .urlInvalid: return "CHE_001"
        case .requestFailed: return "CHE_002"
        case .decodingError: return "CHE_003"
        case .unauthorized: return "CHE_004"
        case .notFound: return "CHE_005"
        case .timeout: return "CHE_006"
        case .retryExhausted: return "CHE_007"
        case .invalidResponse: return "CHE_008"
        case .serverUnreachable: return "CHE_009"
        case .serverError: return "CHE_010"
        case .noInternet: return "CHE_011"
        case .emailNotVerified: return "CHE_012"
        }
    }
    
    var shouldRetry: Bool {
        switch self {
        case .urlInvalid, .decodingError, .unauthorized, .notFound, .retryExhausted, .invalidResponse:
            return false
        case .requestFailed, .timeout, .serverUnreachable, .serverError, .noInternet, .emailNotVerified:
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


struct CheckoutResponse {
    let url: URL
    let externalReference: String
}

class CheckoutService {
    private static let baseURL = "http://localhost:4000/api" // TODO: Move to configuration
    
    static func createCheckoutURL(
        eventDetails: EventDetails,
        ticketCounts: [String: Int],
        completion: @escaping (Result<CheckoutResponse, CheckoutError>) -> Void
    ) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(.unauthorized))
            return
        }

        user.getIDToken { idToken, error in
            if error != nil {
                completion(.failure(.unauthorized))
                return
            }
            
            guard let idToken = idToken else {
                completion(.failure(.unauthorized))
                return
            }

            // Cálculo de subtotal y cuota redondeada a 2 decimales
            let subtotal = eventDetails.tickets.reduce(0.0) { acc, ticket in
                let count = ticketCounts[ticket.id] ?? 0
                return acc + ticket.precio * Double(count)
            }
            let serviceFee = (subtotal * eventDetails.cuota_servicio * 100).rounded() / 100

            // Construcción de ítems
            var itemsPayload: [[String: Any]] = []
            for ticket in eventDetails.tickets {
                let count = ticketCounts[ticket.id] ?? 0
                guard count > 0 else { continue }
                itemsPayload.append([
                    "name": ticket.descripcion.trimmingCharacters(in: .whitespacesAndNewlines),
                    "qty": count,
                    "price": round(ticket.precio * 100) / 100
                ])
            }
            
            if serviceFee > 0 {
                itemsPayload.append([
                    "name": "Cuota (\(Int(eventDetails.cuota_servicio * 100))%)",
                    "qty": 1,
                    "price": serviceFee
                ])
            }

            let payload: [String: Any] = [
                "items": itemsPayload,
                "payerEmail": user.email ?? ""
            ]

            guard let bodyData = try? JSONSerialization.data(withJSONObject: payload) else {
                completion(.failure(.invalidResponse))
                return
            }

            guard let url = URL(string: "\(baseURL)/create-preference") else {
                completion(.failure(.serverError))
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
            request.httpBody = bodyData

            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    if error != nil {
                        completion(.failure(.serverError))
                        return
                    }

                    guard let data = data else {
                        completion(.failure(.invalidResponse))
                        return
                    }

                    guard let httpResponse = response as? HTTPURLResponse else {
                        completion(.failure(.invalidResponse))
                        return
                    }

                    if httpResponse.statusCode >= 400 {
                        _ = String(data: data, encoding: .utf8) ?? "Error desconocido"
                        
                        // 🔐 MANEJAR ERROR DE VERIFICACIÓN ESPECÍFICAMENTE
                        if httpResponse.statusCode == 403 {
                            // Intentar parsear como error de verificación
                            print("ENTRO AL ERROR DE VALIDAR")
                            if let jsonData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                               let verificationRequired = jsonData["verification_required"] as? Bool,
                                verificationRequired {
                                    completion(.failure(.emailNotVerified))
                                    return
                                }
                            }
                                                
                        completion(.failure(.serverError))
                        return
                    }

                    guard
                        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                        let urlString = json["checkoutUrl"] as? String,
                        let checkoutURL = URL(string: urlString),
                        let externalRef = json["externalReference"] as? String
                    else {
                        completion(.failure(.invalidResponse))
                        return
                    }

                    let response = CheckoutResponse(url: checkoutURL, externalReference: externalRef)
                    completion(.success(response))
                }
            }.resume()
        }
    }
}
