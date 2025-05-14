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

            let subtotal = eventDetails.tickets.reduce(0.0) { acc, t in
                let count = ticketCounts[t.id] ?? 0
                return acc + t.precio * Double(count)
            }
            let serviceFee = (subtotal * eventDetails.cuota_servicio).rounded(.toNearestOrEven)

            var itemsPayload: [[String: Any]] = []
            for ticket in eventDetails.tickets {
                let count = ticketCounts[ticket.id] ?? 0
                guard count > 0 else { continue }
                itemsPayload.append([
                    "name": ticket.descripcion,
                    "qty": count,
                    "price": ticket.precio
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
                completion(nil)
                return
            }

            var request = URLRequest(url: URL(string: "http://localhost:3000/api/create-preference")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
            request.httpBody = bodyData

            URLSession.shared.dataTask(with: request) { data, _, _ in
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let id = json["preferenceId"] as? String else {
                    completion(nil)
                    return
                }
                completion(URL(string: "https://www.mercadopago.com.mx/checkout/v1/redirect?pref_id=\(id)"))
            }.resume()
        }
    }
}
