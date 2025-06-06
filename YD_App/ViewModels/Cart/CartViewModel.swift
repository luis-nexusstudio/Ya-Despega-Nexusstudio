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

// MARK: - CartViewModel ACTUALIZADO con métodos que reciben EventDetails
class CartViewModel: ObservableObject {
    @Published var ticketCounts: [String: Int] = [:]
    @Published var latestExternalReference: String?
    @Published var currentAppError: AppErrorProtocol?

    init() {
        print("🛒 [CartViewModel] Inicializado (sin eventId)")
    }
    
    // MARK: - Computed Properties que dependen del EventViewModel
    // ✅ CORREGIDO: Ahora usa EventDetails en lugar de EventDetailsData
    func totalTickets(for eventDetails: EventDetails?) -> Int {
        guard let eventDetails = eventDetails else {
            print("🛒 [CartViewModel] totalTickets: No hay eventDetails")
            return 0
        }
        
        let total = eventDetails.tickets.reduce(0) { total, ticket in
            total + (ticketCounts[ticket.id] ?? 0)
        }
        
        print("🛒 [CartViewModel] totalTickets: \(total)")
        return total
    }
    
    func subTotalPrice(for eventDetails: EventDetails?) -> Double {
        guard let eventDetails = eventDetails else { return 0 }
        let raw = eventDetails.tickets.reduce(0.0) { sum, ticket in
            let count = ticketCounts[ticket.id] ?? 0
            return sum + ticket.precio * Double(count)
        }
        return roundTo2(value:raw)
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
    
    // MARK: - Cart Actions
    // ✅ CORREGIDO: Ahora usa Ticket en lugar de TicketType
    func increment( ticket: Ticket) {
        ticketCounts[ticket.id, default: 0] += 1
        print("🛒 [CartViewModel] Incrementado ticket \(ticket.id): \(ticketCounts[ticket.id] ?? 0)")
    }
    
    func decrement(_ ticket: Ticket) {
        let oldValue = ticketCounts[ticket.id] ?? 0
        ticketCounts[ticket.id] = max(0, oldValue - 1)
        print("🛒 [CartViewModel] Decrementado ticket \(ticket.id): \(ticketCounts[ticket.id] ?? 0)")
    }
    
    func clearCart() {
        print("🗑️ [CartViewModel] Limpiando carrito - antes: \(ticketCounts)")
        ticketCounts = [:]
        latestExternalReference = nil
        currentAppError = nil
        print("🗑️ [CartViewModel] Carrito limpio")
    }
    
    // ✅ CORREGIDO: Ahora usa EventDetails
    func fetchCheckoutURL(eventDetails: EventDetails, completion: @escaping (URL?) -> Void) {
        currentAppError = nil
        
        print("🔗 [CartViewModel] Creando checkout URL...")
        
        CheckoutService.createCheckoutURL(eventDetails: eventDetails, ticketCounts: ticketCounts) { [weak self] result in
            switch result {
            case .success(let response):
                print("✅ [CartViewModel] Checkout URL creado exitosamente")
                self?.latestExternalReference = response.externalReference
                completion(response.url)
                
            case .failure(let error):
                print("❌ [CartViewModel] Error en checkout:", error.localizedDescription)
                self?.handleError(error: error)

                completion(nil)
            }
        }
    }
    
    // MARK: - Private Helper
    private func roundTo2( value: Double) -> Double {
        (value * 100).rounded() / 100
    }
    
    private func handleError( error: Error) {
        print("VIEWMODEL CARTVIEW ERROR:",error.toAppError())
        self.currentAppError = error.toAppError()
    }
}
