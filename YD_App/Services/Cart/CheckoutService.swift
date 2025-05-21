//
//  CheckoutService.swift
//  YD_App
//
//  Created by Luis Melendez on 13/05/25.
//

import Foundation
import FirebaseAuth

class CheckoutService {
    static func createCheckoutURL(eventDetails: EventDetails, ticketCounts: [String: Int], completion: @escaping (URL?) -> Void) {

        guard let user = Auth.auth().currentUser else {
            completion(nil)
            return
        }

        user.getIDToken { idToken, error in
            guard let idToken = idToken, error == nil else {
                completion(nil)
                return
            }

            // Cálculo de subtotal y cuota redondeada a 2 decimales
            let subtotal = eventDetails.tickets.reduce(0.0) { acc, t in
                let count = ticketCounts[t.id] ?? 0
                return acc + t.precio * Double(count)
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

            #if DEBUG
            print("🧾 Payload enviado:", payload)
            #endif

            guard let bodyData = try? JSONSerialization.data(withJSONObject: payload) else {
                completion(nil)
                return
            }

            var request = URLRequest(url: URL(string: "http://localhost:4000/api/create-preference")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
            request.httpBody = bodyData

            URLSession.shared.dataTask(with: request) { data, _, error in
                        guard
                            error == nil,
                            let data = data,
                            // parseamos un diccionario
                            let json = try? JSONSerialization.jsonObject(with: data) as? [String:Any],
                            // leemos el campo "checkoutUrl"
                            let urlString = json["checkoutUrl"] as? String,
                            let checkoutURL = URL(string: urlString)
                        else {
                            print("❌ Error al parsear checkoutUrl:", error ?? "unknown")
                            DispatchQueue.main.async { completion(nil) }
                            return
                        }

                        print("🔗 [DEBUG] checkoutUrl recibido:", checkoutURL.absoluteString)
                        DispatchQueue.main.async { completion(checkoutURL) }
                    }.resume()
        }
    }
}
