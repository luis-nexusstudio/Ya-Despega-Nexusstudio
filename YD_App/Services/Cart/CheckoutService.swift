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
    private static let baseURL = "http://localhost:4000/api"
    
    static func createCheckoutURL(
        eventDetails: EventDetails,
        ticketCounts: [String: Int],
        completion: @escaping (Result<CheckoutResponse, CheckoutError>) -> Void
    ) {
        Task {
            do {
                // Usar SessionManager para obtener usuario y email
                try await SessionManager.shared.requireAuthentication()
                
                guard let userEmail = await SessionManager.shared.userEmail else {
                    await MainActor.run {
                        completion(.failure(.unauthorized))
                    }
                    return
                }
                
                // Preparar payload
                let payload = prepareCheckoutPayload(
                    eventDetails: eventDetails,
                    ticketCounts: ticketCounts,
                    userEmail: userEmail
                )
                
                guard let bodyData = try? JSONSerialization.data(withJSONObject: payload) else {
                    await MainActor.run {
                        completion(.failure(.invalidResponse))
                    }
                    return
                }

                guard let url = URL(string: "\(baseURL)/create-preference") else {
                    await MainActor.run {
                        completion(.failure(.serverError))
                    }
                    return
                }

                // Usar SessionManager para realizar operación autenticada
                let result = try await SessionManager.shared.performAuthenticatedOperation { token in
                    return try await performCheckoutRequest(url: url, bodyData: bodyData, token: token)
                }
                
                await MainActor.run {
                    completion(.success(result))
                }
                
            } catch {
                await MainActor.run {
                    completion(.failure(mapToCheckoutError(error)))
                }
            }
        }
    }
    
    private static func prepareCheckoutPayload(
        eventDetails: EventDetails,
        ticketCounts: [String: Int],
        userEmail: String
    ) -> [String: Any] {
        // Cálculo de subtotal y cuota
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

        return [
            "items": itemsPayload,
            "payerEmail": userEmail
        ]
    }
    
    private static func performCheckoutRequest(
        url: URL,
        bodyData: Data,
        token: String
    ) async throws -> CheckoutResponse {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = bodyData

        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CheckoutError.invalidResponse
        }

        if httpResponse.statusCode >= 400 {
            if httpResponse.statusCode == 403 {
                // Manejar error de verificación específicamente
                if let jsonData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let verificationRequired = jsonData["verification_required"] as? Bool,
                   verificationRequired {
                    throw CheckoutError.emailNotVerified
                }
            }
            throw CheckoutError.serverError
        }

        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let urlString = json["checkoutUrl"] as? String,
            let checkoutURL = URL(string: urlString),
            let externalRef = json["externalReference"] as? String
        else {
            throw CheckoutError.invalidResponse
        }

        return CheckoutResponse(url: checkoutURL, externalReference: externalRef)
    }
    
    private static func mapToCheckoutError(_ error: Error) -> CheckoutError {
        if let checkoutError = error as? CheckoutError {
            return checkoutError
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
        
        return error.toAppError() as? CheckoutError ?? .requestFailed
    }
}
