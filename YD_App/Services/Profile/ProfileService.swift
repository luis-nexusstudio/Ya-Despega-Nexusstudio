//
//  ProfileService.swift
//  YD_App
//
//  Created by Pedro Martinez on 19/05/25.
//

import Foundation
import FirebaseAuth

class ProfileService {
    // URLs para los endpoints de la API
    private let baseURL = "http://localhost:4000/api"
    private let userEndpoint = "/user/"
    
    // Obtener el token de Firebase para autenticación
    private func getAuthToken(completion: @escaping (String?) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            print("🔴 No hay usuario autenticado para obtener token")
            completion(nil)
            return
        }
        
        currentUser.getIDToken { token, error in
            if let error = error {
                print("🔴 Error al obtener token: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let token = token else {
                print("🔴 No se pudo obtener token")
                completion(nil)
                return
            }
            
            print("🟢 Token obtenido correctamente")
            completion(token)
        }
    }
    
    // Función para obtener el usuario por email
    func fetchUserByEmail(email: String, completion: @escaping (Result<UserProfileModel, Error>) -> Void) {
        // Obtener token de autenticación
        getAuthToken { [weak self] token in
            guard let self = self else { return }
            guard let token = token else {
                completion(.failure(NSError(domain: "ProfileService", code: 401, userInfo: [NSLocalizedDescriptionKey: "No se pudo obtener token de autenticación"])))
                return
            }
            
            guard let url = URL(string: "\(self.baseURL)\(self.userEndpoint)?email=\(email)") else {
                print("🔴 URL inválida")
                completion(.failure(NSError(domain: "ProfileService", code: 0, userInfo: [NSLocalizedDescriptionKey: "URL inválida"])))
                return
            }
            
            print("🔍 Buscando usuario con email: \(email) en URL: \(url.absoluteString)")
            
            var request = URLRequest(url: url)
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("🔴 Error en la solicitud HTTP: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("🔴 Respuesta HTTP inválida")
                    completion(.failure(NSError(domain: "ProfileService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Respuesta HTTP inválida"])))
                    return
                }
                
                print("🔵 Código de respuesta HTTP: \(httpResponse.statusCode)")
                
                guard httpResponse.statusCode == 200 else {
                    print("🔴 Error de servidor: \(httpResponse.statusCode)")
                    completion(.failure(NSError(domain: "ProfileService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Error del servidor: \(httpResponse.statusCode)"])))
                    return
                }
                
                guard let data = data else {
                    print("🔴 No se recibieron datos")
                    completion(.failure(NSError(domain: "ProfileService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No se recibieron datos"])))
                    return
                }
                
                // Imprimir la respuesta para depuración
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("🟢 Respuesta JSON: \(jsonString)")
                }
                
                // Intentar convertir a JSON para inspección
                if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) {
                    print("🔵 Estructura JSON recibida: \(jsonObject)")
                }
                
                // Usar el método de decodificación personalizado
                if let userProfile = UserProfileModel.decode(from: data) {
                    print("🟢 Usuario encontrado y decodificado: \(userProfile.id)")
                    completion(.success(userProfile))
                } else {
                    print("🔴 No se pudo decodificar la respuesta JSON a UserProfileModel")
                    completion(.failure(NSError(domain: "ProfileService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Error al decodificar datos de usuario"])))
                }
            }.resume()
        }
    }
    
    // Función para actualizar el perfil de usuario
    func updateUserProfile(profile: UserProfileModel, completion: @escaping (Result<UserProfileModel, Error>) -> Void) {
        // Obtener token de autenticación
        getAuthToken { [weak self] token in
            guard let self = self else { return }
            guard let token = token else {
                completion(.failure(NSError(domain: "ProfileService", code: 401, userInfo: [NSLocalizedDescriptionKey: "No se pudo obtener token de autenticación"])))
                return
            }
            
            guard let url = URL(string: "\(self.baseURL)\(self.userEndpoint)\(profile.id)") else {
                print("🔴 URL inválida")
                completion(.failure(NSError(domain: "ProfileService", code: 0, userInfo: [NSLocalizedDescriptionKey: "URL inválida"])))
                return
            }
            
            print("🔄 Actualizando usuario con ID: \(profile.id) en URL: \(url.absoluteString)")
            
            // Usar el método toDictionary para convertir a [String: Any]
            let userData = profile.toDictionary()
            
            // Convertir a JSON
            guard let jsonData = try? JSONSerialization.data(withJSONObject: userData) else {
                print("🔴 Error al serializar JSON")
                completion(.failure(NSError(domain: "ProfileService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Error al serializar JSON"])))
                return
            }
            
            // Crear solicitud
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.httpBody = jsonData
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("🔴 Error en la solicitud HTTP: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("🔴 Respuesta HTTP inválida")
                    completion(.failure(NSError(domain: "ProfileService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Respuesta HTTP inválida"])))
                    return
                }
                
                print("🔵 Código de respuesta HTTP: \(httpResponse.statusCode)")
                
                guard httpResponse.statusCode == 200 else {
                    print("🔴 Error de servidor: \(httpResponse.statusCode)")
                    completion(.failure(NSError(domain: "ProfileService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Error del servidor: \(httpResponse.statusCode)"])))
                    return
                }
                
                guard let data = data else {
                    print("🔴 No se recibieron datos")
                    completion(.failure(NSError(domain: "ProfileService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No se recibieron datos"])))
                    return
                }
                
                // Imprimir la respuesta para depuración
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("🟢 Respuesta JSON: \(jsonString)")
                }
                
                // Intentar convertir a JSON para inspección
                if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) {
                    print("🔵 Estructura JSON recibida: \(jsonObject)")
                }
                
                // Usar el método de decodificación personalizado
                if let userProfile = UserProfileModel.decode(from: data) {
                    print("🟢 Usuario actualizado y decodificado: \(userProfile.id)")
                    completion(.success(userProfile))
                } else {
                    print("🔴 No se pudo decodificar la respuesta JSON a UserProfileModel")
                    completion(.failure(NSError(domain: "ProfileService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Error al decodificar datos de usuario"])))
                }
            }.resume()
        }
    }
}

// Estructura para la respuesta de la API, que contiene un campo "user"
struct ApiResponse: Codable {
    let message: String?
    let user: UserProfileModelCodable?
}
