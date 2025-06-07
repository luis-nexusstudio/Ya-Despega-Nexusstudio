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
       
    static func getHomeEvent(eventId: String, completion: @escaping (Result<HomeEventData, Error>) -> Void) {
        guard !eventId.isEmpty else {
            completion(.failure(NSError(domain: "Validation", code: 400, userInfo: [NSLocalizedDescriptionKey: "EventId no puede estar vacío"])))
            return
        }
        
        Task {
            do {
                try await SessionManager.shared.requireAuthentication()
                
                let url = baseURL.appendingPathComponent("home-event/\(eventId)")
                
                let result = try await SessionManager.shared.performAuthenticatedOperation { token in
                    return try await performHomeEventRequest(url: url, token: token)
                }
                
                let response = try JSONDecoder().decode(HomeEventResponse.self, from: result)
                
                if response.success, let homeEventData = response.data {
                    await MainActor.run {
                        completion(.success(homeEventData))
                    }
                } else {
                    let errorMessage = response.message ?? response.error ?? "Error desconocido"
                    await MainActor.run {
                        completion(.failure(NSError(domain: "API", code: 400, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                    }
                }
            } catch {
                await MainActor.run {
                    completion(.failure(error))
                }
            }
        }
    }
    
    private static func performHomeEventRequest(url: URL, token: String) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        #if DEBUG
        print("🌐 [HomeEventService] Requesting home event data")
        print("🔗 [HomeEventService] URL: \(url.absoluteString)")
        #endif
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "Network", code: 0, userInfo: [NSLocalizedDescriptionKey: "Respuesta inválida"])
        }
        
        #if DEBUG
        if let jsonString = String(data: data, encoding: .utf8) {
            print("🧾 [HomeEventService] Response (\(httpResponse.statusCode)): \(jsonString)")
        }
        #endif
        
        guard httpResponse.statusCode == 200 else {
            throw NSError(domain: "Network", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Error del servidor"])
        }
        
        return data
    }
}
