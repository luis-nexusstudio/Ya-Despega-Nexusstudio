//
//  HomeService.swift
//  YD_App
//
//  Created by Luis Melendez on 26/05/25.
//

import Foundation
import FirebaseAuth
// MARK: - Home Event Service
class HomeService {
    private static let baseURL = URL(string: "http://localhost:4000/api")!
       
       /// Obtiene la información del evento principal para la vista Home
       /// - Parameters:
       ///   - eventId: ID del evento a obtener
       ///   - completion: Closure que devuelve el resultado
       static func getHomeEvent(eventId: String, completion: @escaping (Result<HomeEventData, Error>) -> Void) {
           guard !eventId.isEmpty else {
               completion(.failure(NSError(domain: "Validation", code: 400, userInfo: [NSLocalizedDescriptionKey: "EventId no puede estar vacío"])))
               return
           }
           
           guard let user = Auth.auth().currentUser else {
               completion(.failure(NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Usuario no autenticado"])))
               return
           }
           
           user.getIDToken { token, error in
               guard let token = token, error == nil else {
                   completion(.failure(error ?? NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Token inválido"])))
                   return
               }
               
               let url = baseURL.appendingPathComponent("home-event/\(eventId)")
               var request = URLRequest(url: url)
               request.httpMethod = "GET"
               request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
               request.setValue("application/json", forHTTPHeaderField: "Content-Type")
               
               #if DEBUG
               print("🌐 [HomeEventService] Requesting home event data for eventId: \(eventId)")
               print("🔗 [HomeEventService] URL: \(url.absoluteString)")
               #endif
               
               URLSession.shared.dataTask(with: request) { data, response, error in
                   if let error = error {
                       #if DEBUG
                       print("❌ [HomeEventService] Network error: \(error.localizedDescription)")
                       #endif
                       completion(.failure(error))
                       return
                   }
                   
                   guard let httpResponse = response as? HTTPURLResponse else {
                       completion(.failure(NSError(domain: "Network", code: 0, userInfo: [NSLocalizedDescriptionKey: "Respuesta inválida"])))
                       return
                   }
                   
                   guard let data = data else {
                       completion(.failure(NSError(domain: "Network", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Sin datos en respuesta"])))
                       return
                   }
                   
                   #if DEBUG
                   if let jsonString = String(data: data, encoding: .utf8) {
                       print("🧾 [HomeEventService] Response (\(httpResponse.statusCode)): \(jsonString)")
                   }
                   #endif
                   
                   do {
                       let response = try JSONDecoder().decode(HomeEventResponse.self, from: data)
                       
                       if response.success, let homeEventData = response.data {
                           #if DEBUG
                           print("✅ [HomeEventService] Home event data decoded successfully")
                           #endif
                           completion(.success(homeEventData))
                       } else {
                           let errorMessage = response.message ?? response.error ?? "Error desconocido"
                           completion(.failure(NSError(domain: "API", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                       }
                   } catch {
                       #if DEBUG
                       print("❌ [HomeEventService] Decode error: \(error)")
                       #endif
                       completion(.failure(error))
                   }
               }.resume()
           }
       }
}
