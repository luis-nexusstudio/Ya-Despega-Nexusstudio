//
//  ProfileViewModel.swift
//  YD_App
//
//  Created by Pedro Martinez on 19/05/25.
//

import SwiftUI
import FirebaseAuth
import Combine

class ProfileViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var userProfile: UserProfileModel?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasError = false
    
    // Servicio para manejar las solicitudes de perfil
    private let profileService = ProfileService()
    
    // Para manejar suscripciones de Combine
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        // Al inicializar, intentamos cargar los datos del usuario
        fetchUserProfile()
    }
    
    // MARK: - Public Methods
    
    /// Carga los datos del perfil del usuario actualmente autenticado
    func fetchUserProfile() {
        // Verificamos si hay un usuario autenticado
        guard let currentUser = Auth.auth().currentUser,
              let email = currentUser.email else {
            print("🔴 Error: No hay usuario autenticado o no tiene email")
            self.errorMessage = "No hay usuario autenticado o no tiene email"
            self.hasError = true
            return
        }
        
        print("🟢 Usuario autenticado con ID: \(currentUser.uid), Email: \(email)")
        self.isLoading = true
        self.hasError = false
        
        // Utilizar el servicio para buscar el usuario por email
        profileService.fetchUserByEmail(email: email) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let profileData):
                    print("🟢 Perfil cargado exitosamente: \(profileData.nombreCompleto)")
                    self.userProfile = profileData
                    self.hasError = false
                    
                case .failure(let error):
                    print("🔴 Error al cargar perfil: \(error.localizedDescription)")
                    self.errorMessage = "Error al cargar los datos: \(error.localizedDescription)"
                    self.hasError = true
                }
            }
        }
    }
    
    /// Actualiza los datos del perfil del usuario
    func updateUserProfile(updatedProfile: UserProfileModel, completion: @escaping (Bool) -> Void) {
        self.isLoading = true
        
        // Utilizar el servicio para actualizar el perfil
        profileService.updateUserProfile(profile: updatedProfile) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let updatedProfileData):
                    print("🟢 Perfil actualizado exitosamente")
                    self.userProfile = updatedProfileData
                    self.hasError = false
                    completion(true)
                    
                case .failure(let error):
                    print("🔴 Error al actualizar perfil: \(error.localizedDescription)")
                    self.errorMessage = "Error al actualizar perfil: \(error.localizedDescription)"
                    self.hasError = true
                    completion(false)
                }
            }
        }
    }
    
    /// Cierra la sesión del usuario actual - ACTUALIZADO PARA USAR SESSIONMANAGER
    func signOut(completion: @escaping (Bool) -> Void) {
        print("🟡 Intentando cerrar sesión...")
        
        Task {
            do {
                // Usar SessionManager para cerrar sesión
                try await SessionManager.shared.signOut()
                // Limpiar datos locales del perfil
                await MainActor.run {
                    self.userProfile = nil
                    self.errorMessage = nil
                    self.hasError = false
                }
                
                print("🟢 Sesión cerrada exitosamente")
                await MainActor.run {
                    completion(true)
                }
            } catch {
                print("🔴 Error al cerrar sesión: \(error.localizedDescription)")
                await MainActor.run {
                    self.errorMessage = "Error al cerrar sesión: \(error.localizedDescription)"
                    self.hasError = true
                    completion(false)
                }
            }
        }
    }
}
