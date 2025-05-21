//
//  CartViewModel.swift
//  YD_App
//
//  Created by Luis Melendez on 04/04/25.
//

import SwiftUI
import FirebaseAuth

enum EstadoPago: String {
    case exitoso
    case pendiente
    case fallido
    case ninguno
}

class CartViewModel: ObservableObject {

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var eventDetails: EventDetails? {
        didSet {
            ticketCounts = [:]
            eventDetails?.tickets.forEach { ticketCounts[$0.id] = 0 }
        }
    }
    @Published var ticketCounts: [String:Int] = [:]


    init(eventId: String) {
        
        guard !eventId.isEmpty else {
            self.errorMessage = "ID de evento inválido"
            return
        }
        fetchEventDetails(eventId: eventId)
    }

    func fetchEventDetails(eventId: String) {
        isLoading = true
        errorMessage = nil

        EventService.getEventDetails(eventId: eventId) { [weak self] details, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error
                } else {
                    self?.eventDetails = details
                }
            }
        }
    }
    
    private func roundTo2(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }

    var totalTickets: Int {
        ticketCounts.values.reduce(0, +)
    }

    var subTotalPrice: Double {
        guard let ev = eventDetails else { return 0 }
        let raw = ev.tickets.reduce(0) { sum, t in
            let cnt = ticketCounts[t.id] ?? 0
            return sum + t.precio * Double(cnt)
        }
        return roundTo2(raw)
    }

    var serviceFeeAmount: Double {
        guard let ev = eventDetails else { return 0 }
        return roundTo2(subTotalPrice * ev.cuota_servicio)
    }

    var totalPrice: Double {
        roundTo2(subTotalPrice + serviceFeeAmount)
    }

    func increment(_ ticket: Ticket) {
        ticketCounts[ticket.id, default: 0] += 1
    }
    
    func decrement(_ ticket: Ticket) {
        ticketCounts[ticket.id] = max(0, (ticketCounts[ticket.id] ?? 0) - 1)
    }
    
    func clearCart() {
        print("🗑️ CartViewModel.clearCart() – tickets antes: \(ticketCounts)")
        ticketCounts.keys.forEach { ticketCounts[$0] = 0 }
        print("🗑️ CartViewModel.clearCart() – tickets después: \(ticketCounts)")
    }

    private func makeItemsPayload() -> [[String: Any]] {
        guard let details = eventDetails else { return [] }
        var items: [[String: Any]] = []
        for ticket in details.tickets {
            let count = ticketCounts[ticket.id] ?? 0
            guard count > 0 else { continue }
            items.append([
                "name": ticket.descripcion,
                "qty": count,
                "price": ticket.precio
            ])
        }
        let fee = serviceFeeAmount
        if fee > 0 {
            items.append([
                "name": "Cuota (\(Int(details.cuota_servicio*100))%)",
                "qty": 1,
                "price": fee
            ])
        }
        return items
    }

    func fetchCheckoutURL(completion: @escaping (URL?) -> Void) {
        guard let details = eventDetails else {
            completion(nil)
            return
        }

        CheckoutService.createCheckoutURL(eventDetails: details, ticketCounts: ticketCounts) { url in
            DispatchQueue.main.async {
                completion(url)
            }
        }
    }
}
