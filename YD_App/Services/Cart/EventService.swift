//
//  EventService.swift
//  YD_App
//
//  Created by Luis Melendez on 14/05/25.
//

import Foundation
import FirebaseAuth

class EventService {
    private static let baseURL = URL(string: "http://localhost:4000/api")!

    static func getEventDetails(eventId: String, completion: @escaping (EventDetails?, String?) -> Void) {
        Auth.auth().currentUser?.getIDToken { token, error in
            guard let token = token, error == nil else {
                completion(nil, "No hay token válido")
                return
            }

            let url = baseURL.appendingPathComponent("event-details/\(eventId)")
            var req = URLRequest(url: url)
            req.httpMethod = "GET"
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            URLSession.shared.dataTask(with: req) { data, resp, err in
                if let err = err {
                    completion(nil, "Error de red: \(err.localizedDescription)")
                    return
                }

                guard let http = resp as? HTTPURLResponse,
                      (200..<300).contains(http.statusCode),
                      let data = data else {
                    completion(nil, "HTTP inválido o sin datos")
                    return
                }

                do {
                    let details = try JSONDecoder().decode(EventDetails.self, from: data)
                    completion(details, nil)
                } catch {
                    let raw = String(data: data, encoding: .utf8) ?? "No se pudo mostrar JSON"
                    print("❌ Decode error:", error, "\n🧾 Raw:", raw)
                    completion(nil, "Error al decodificar evento")
                }
            }.resume()
        }
    }
}
