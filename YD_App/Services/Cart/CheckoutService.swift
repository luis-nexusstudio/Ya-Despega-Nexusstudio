//
//  CheckoutService.swift
//  YD_App
//
//  Created by Luis Melendez on 13/05/25.
//

import Foundation
import FirebaseAuth

enum CheckoutError: Error, LocalizedError {
    case userNotAuthenticated
    case invalidToken
    case networkError(String)
    case invalidResponse
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "Usuario no autenticado"
        case .invalidToken:
            return "Token de autenticación inválido"
        case .networkError(let message):
            return "Error de red: \(message)"
        case .invalidResponse:
            return "Respuesta del servidor inválida"
        case .serverError(let message):
            return "Error del servidor: \(message)"
        }
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
            completion(.failure(.userNotAuthenticated))
            return
        }

        user.getIDToken { idToken, error in
            if let error = error {
                completion(.failure(.invalidToken))
                return
            }
            
            guard let idToken = idToken else {
                completion(.failure(.invalidToken))
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
                completion(.failure(.networkError("URL inválida")))
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
            request.httpBody = bodyData

            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        completion(.failure(.networkError(error.localizedDescription)))
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
                        let errorMessage = String(data: data, encoding: .utf8) ?? "Error desconocido"
                        completion(.failure(.serverError(errorMessage)))
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
