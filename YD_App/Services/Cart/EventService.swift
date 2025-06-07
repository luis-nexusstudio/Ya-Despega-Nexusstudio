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
        
        Task {
            do {
                try await SessionManager.shared.requireAuthentication()
                
                guard let url = URL(string: "http://localhost:4000/api/event-details/\(eventId)") else {
                    await MainActor.run {
                        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "URL inválida"])))
                    }
                    return
                }

                let result = try await SessionManager.shared.performAuthenticatedOperation { token in
                    return try await performEventRequest(url: url, token: token)
                }
                
                let details = try JSONDecoder().decode(EventDetails.self, from: result)
                await MainActor.run {
                    completion(.success(details))
                }
            } catch {
                await MainActor.run {
                    completion(.failure(error))
                }
            }
        }
    }
    
    private static func performEventRequest(url: URL, token: String) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Respuesta inválida"])
        }
        
        if httpResponse.statusCode == 401 {
            throw SessionError.userNotAuthenticated
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Error del servidor"])
        }
        
        return data
    }
}
