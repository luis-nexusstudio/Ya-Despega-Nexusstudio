//
//  CartViewModel.swift
//  YD_App
//
//  Created by Luis Melendez on 04/04/25.
//

import SwiftUI
import FirebaseAuth

class CartViewModel: ObservableObject {

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // Almacena detalles del evento y reinicia contadores al cambiar
    @Published var eventDetails: EventDetails? {
        didSet {
            ticketCounts = [:]
            eventDetails?.tickets.forEach { ticketCounts[$0.id] = 0 }
        }
    }
    @Published var ticketCounts: [String:Int] = [:]

    private let baseURL = URL(string: "http://localhost:3000/api")!

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
        Auth.auth().currentUser?.getIDToken { [weak self] token, error in
            guard let self = self,
                  let token = token,
                  error == nil else {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.errorMessage = "No hay token válido"
                }
                
                return
            }
            print(token)
            let url = baseURL.appendingPathComponent("event-details/\(eventId)")
            var req = URLRequest(url: url)
            req.httpMethod = "GET"
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            URLSession.shared.dataTask(with: req) { data, resp, err in
                DispatchQueue.main.async { self.isLoading = false }
                if let err = err {
                    DispatchQueue.main.async { self.errorMessage = "Error red: \(err.localizedDescription)" }
                    return
                }
                if let http = resp as? HTTPURLResponse,
                   !(200..<300).contains(http.statusCode) {
                    DispatchQueue.main.async { self.errorMessage = "HTTP \(http.statusCode)" }
                    return
                }
                guard let data = data else {
                    DispatchQueue.main.async { self.errorMessage = "Respuesta vacía" }
                    return
                }
                do {
                    let details = try JSONDecoder().decode(EventDetails.self, from: data)
                    print("✅ Evento decodificado correctamente: \(details)")
                    DispatchQueue.main.async { self.eventDetails = details }
                } catch {
                    print("❌ Error al decodificar evento:", error)
                    print("🧾 Raw JSON:", String(data: data, encoding: .utf8) ?? "No se pudo mostrar")
                    DispatchQueue.main.async { self.errorMessage = "Decode error: \(error)" }
                }
            }.resume()
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
        ticketCounts.keys.forEach { ticketCounts[$0] = 0 }
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
        Auth.auth().currentUser?.getIDToken { [weak self] idToken, error in
            guard let self = self,
                  let idToken = idToken,
                  error == nil,
                  let details = self.eventDetails
            else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            // Ahora uso self.makeItemsPayload() dentro de la clausura
            let itemsPayload = self.makeItemsPayload()
            guard !itemsPayload.isEmpty else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            let payload: [String: Any] = [
                "items":      itemsPayload,
                "payerEmail": Auth.auth().currentUser?.email ?? ""
            ]

            let url = self.baseURL.appendingPathComponent("create-preference")
            guard let body = try? JSONSerialization.data(withJSONObject: payload) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
            req.httpBody = body

            URLSession.shared.dataTask(with: req) { [weak self] data, resp, err in
                guard let self = self else { return }
                // chequeo de código HTTP…
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let prefId = json["preferenceId"] as? String
                else {
                    DispatchQueue.main.async { completion(nil) }
                    return
                }
                let redirectURL = URL(string: "https://www.mercadopago.com.mx/checkout/v1/redirect?pref_id=\(prefId)")
                DispatchQueue.main.async { completion(redirectURL) }
            }.resume()
        }
    }
}
