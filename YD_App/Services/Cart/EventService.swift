//
//  EventService.swift
//  YD_App
//
//  Created by Luis Melendez on 14/05/25.
//

import Foundation
import FirebaseAuth

struct EventService {
    static func getEventDetails(eventId: String, completion: @escaping (Result<EventDetails, Error>) -> Void) {
        
        guard let user = Auth.auth().currentUser else {
            let error = NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "No autorizado"])
            completion(.failure(error))
            return
        }
        
        user.getIDToken { token, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let token = token else {
                let error = NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "Token inválido"])
                completion(.failure(error))
                return
            }
            
            guard let url = URL(string: "http://localhost:4000/api/event-details/\(eventId)") else {
                let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "URL inválida"])
                completion(.failure(error))
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Respuesta inválida"])
                        completion(.failure(error))
                        return
                    }
                    
                    if httpResponse.statusCode == 401 {
                        let error = NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "No autorizado"])
                        completion(.failure(error))
                        return
                    }
                    
                    guard let data = data else {
                        let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                        completion(.failure(error))
                        return
                    }
                    
                    do {
                        let details = try JSONDecoder().decode(EventDetails.self, from: data)
                        completion(.success(details))
                    } catch {
                        completion(.failure(error))
                    }
                }
            }.resume()
        }
    }
}
