//
//  CartViewModel.swift
//  YD_App
//
//  Created by Luis Melendez on 04/04/25.
//


//
//  CartViewModel.swift
//  YD_App
//
//  Created by Luis Melendez on 04/04/25.
//

import SwiftUI
import FirebaseAuth
import Combine

@MainActor
class CartViewModel: ObservableObject {
    @Published var ticketCounts: [String: Int] = [:]
    @Published var latestExternalReference: String?
    @Published var currentAppError: AppErrorProtocol?

    private let sessionManager = SessionManager.shared
    
    init() {
        print("🛒 [CartViewModel] Inicializado con SessionManager")
    }
    
    // MARK: - Computed Properties (mantener existentes pero mejoradas)
    func totalTickets(for eventDetails: EventDetails?) -> Int {
        guard let eventDetails = eventDetails else {
            return 0
        }
        
        let total = eventDetails.tickets.reduce(0) { total, ticket in
            total + (ticketCounts[ticket.id] ?? 0)
        }
        return total
    }
    
    func subTotalPrice(for eventDetails: EventDetails?) -> Double {
        guard let eventDetails = eventDetails else { return 0 }
        let raw = eventDetails.tickets.reduce(0.0) { sum, ticket in
            let count = ticketCounts[ticket.id] ?? 0
            return sum + ticket.precio * Double(count)
        }
        return roundTo2(value: raw)
    }
    
    func serviceFeeAmount(for eventDetails: EventDetails?) -> Double {
        guard let eventDetails = eventDetails else { return 0 }
        return roundTo2(value: subTotalPrice(for: eventDetails) * eventDetails.cuota_servicio)
    }
    
    func totalPrice(for eventDetails: EventDetails?) -> Double {
        let subtotal = subTotalPrice(for: eventDetails)
        let fee = serviceFeeAmount(for: eventDetails)
        return roundTo2(value: subtotal + fee)
    }
    
    // MARK: - Cart Actions (mantener existentes)
    func increment(ticket: Ticket) {
        ticketCounts[ticket.id, default: 0] += 1
        print("🛒 [CartViewModel] Incrementado ticket \(ticket.id): \(ticketCounts[ticket.id] ?? 0)")
    }
    
    func decrement(_ ticket: Ticket) {
        let oldValue = ticketCounts[ticket.id] ?? 0
        ticketCounts[ticket.id] = max(0, oldValue - 1)
        print("🛒 [CartViewModel] Decrementado ticket \(ticket.id): \(ticketCounts[ticket.id] ?? 0)")
    }
    
    func clearCart() {
        print("🗑️ [CartViewModel] Limpiando carrito")
        ticketCounts = [:]
        latestExternalReference = nil
        currentAppError = nil
    }
    
    // MARK: - 🆕 CHECKOUT MEJORADO CON SESSIONMANAGER
    func fetchCheckoutURL(eventDetails: EventDetails, completion: @escaping (URL?) -> Void) {
        currentAppError = nil
        
        print("🔗 [CartViewModel] Creando checkout URL con SessionManager...")
        
        Task {
            do {
                // ✅ USAR SESSIONMANAGER PARA LA OPERACIÓN
                let checkoutURL = try await sessionManager.performAuthenticatedOperation { token in
                    try await self.createCheckoutWithToken(eventDetails: eventDetails, token: token)
                }
                
                await MainActor.run {
                    self.latestExternalReference = checkoutURL.externalReference
                    completion(checkoutURL.url)
                    print("✅ [CartViewModel] Checkout URL creado exitosamente")
                }
                
            } catch {
                await MainActor.run {
                    self.handleError(error: error)
                    completion(nil)
                    print("❌ [CartViewModel] Error en checkout: \(error)")
                }
            }
        }
    }
    
    // MARK: - 🆕 MÉTODO SEPARADO PARA CHECKOUT CON TOKEN
    private func createCheckoutWithToken(eventDetails: EventDetails, token: String) async throws -> (url: URL, externalReference: String) {
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

        let payload: [String: Any] = [
            "items": itemsPayload,
            "payerEmail": sessionManager.userEmail ?? ""
        ]

        guard let bodyData = try? JSONSerialization.data(withJSONObject: payload) else {
            throw CommonAppError.validationFailed("Error preparando datos")
        }

        guard let url = URL(string: "http://localhost:4000/api/create-preference") else {
            throw CommonAppError.serverError
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = bodyData

        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CommonAppError.serverError
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
            throw CommonAppError.serverError
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let urlString = json["checkoutUrl"] as? String,
              let checkoutURL = URL(string: urlString),
              let externalRef = json["externalReference"] as? String else {
            throw CommonAppError.serverError
        }

        return (url: checkoutURL, externalReference: externalRef)
    }
    
    // MARK: - Private Helper
    private func roundTo2(value: Double) -> Double {
        (value * 100).rounded() / 100
    }
    
    private func handleError(error: Error) {
        self.currentAppError = error.toAppError()
    }
    
    // MARK: - SessionAwareViewModel
    func clearSessionData() {
        print("🧹 [CartViewModel] Limpiando datos del carrito")
        clearCart()
    }
}
