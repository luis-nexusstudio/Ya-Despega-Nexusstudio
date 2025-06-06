//
//  AuthStateManager.swift
//  YD_App
//
//  Created by Pedro Martinez on 05/06/25.
//

import SwiftUI
import FirebaseAuth
import Combine

// MARK: - AuthState Enum
enum AuthState {
    case unknown        // Estado inicial, verificando autenticación
    case authenticated  // Usuario autenticado
    case unauthenticated // No hay usuario autenticado
}

// MARK: - AuthStateManager
@MainActor
class AuthStateManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = AuthStateManager()
    
    // MARK: - Published Properties
    @Published var authState: AuthState = .unknown
    @Published var currentUser: User?
    @Published var isLoading: Bool = true
    
    // MARK: - Private Properties
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var isAuthenticated: Bool {
        return authState == .authenticated
    }
    
    var userEmail: String? {
        return currentUser?.email
    }
    
    var userId: String? {
        return currentUser?.uid
    }
    
    // MARK: - Initialization
    private init() {
        setupAuthStateListener()
        checkInitialAuthState()
    }
    
    // MARK: - Auth State Management
    
    /// Configura el listener para cambios en el estado de autenticación
    private func setupAuthStateListener() {
        authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                print("🔐 [AuthStateManager] Estado de autenticación cambió")
                print("   - Usuario: \(user?.email ?? "ninguno")")
                
                self.currentUser = user
                
                if let user = user {
                    print("✅ [AuthStateManager] Usuario autenticado: \(user.email ?? "sin email")")
                    self.authState = .authenticated
                    
                    // Verificar si el token es válido
                    self.verifyUserToken()
                } else {
                    print("❌ [AuthStateManager] No hay usuario autenticado")
                    self.authState = .unauthenticated
                }
                
                self.isLoading = false
            }
        }
    }
    
    /// Verifica el estado inicial de autenticación
    private func checkInitialAuthState() {
        print("🔍 [AuthStateManager] Verificando estado inicial de autenticación")
        
        if let user = Auth.auth().currentUser {
            print("✅ [AuthStateManager] Usuario encontrado en caché: \(user.email ?? "sin email")")
            self.currentUser = user
            self.authState = .authenticated
            
            // Verificar token incluso si hay usuario en caché
            verifyUserToken()
        } else {
            print("❌ [AuthStateManager] No hay usuario en caché")
            self.authState = .unauthenticated
            self.isLoading = false
        }
    }
    
    /// Verifica que el token del usuario sea válido
    private func verifyUserToken() {
        guard let user = currentUser else { return }
        
        user.getIDTokenResult { [weak self] result, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ [AuthStateManager] Error verificando token: \(error.localizedDescription)")
                    // Si el token no es válido, cerrar sesión
                    self.signOut()
                } else if let result = result {
                    print("✅ [AuthStateManager] Token válido hasta: \(result.expirationDate)")
                    
                    // Verificar si el token está por expirar (menos de 5 minutos)
                    let timeUntilExpiration = result.expirationDate.timeIntervalSinceNow
                    if timeUntilExpiration < 300 { // 5 minutos
                        print("⚠️ [AuthStateManager] Token próximo a expirar, renovando...")
                        self.refreshToken()
                    }
                }
            }
        }
    }
    
    /// Renueva el token del usuario
    private func refreshToken() {
        currentUser?.getIDTokenForcingRefresh(true) { token, error in
            if let error = error {
                print("❌ [AuthStateManager] Error renovando token: \(error.localizedDescription)")
            } else {
                print("✅ [AuthStateManager] Token renovado exitosamente")
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Actualiza el estado después de un login exitoso
    func handleSuccessfulLogin() {
        print("🎉 [AuthStateManager] Login exitoso procesado")
        // El listener de Firebase se encargará de actualizar el estado
    }
    
    /// Actualiza el estado después de un registro exitoso
    func handleSuccessfulRegistration() {
        print("🎉 [AuthStateManager] Registro exitoso procesado")
        // El listener de Firebase se encargará de actualizar el estado
    }
    
    /// Cierra la sesión del usuario
    func signOut() {
        do {
            print("🚪 [AuthStateManager] Cerrando sesión...")
            try Auth.auth().signOut()
            
            // Limpiar datos locales si es necesario
            clearLocalData()
            
            print("✅ [AuthStateManager] Sesión cerrada exitosamente")
        } catch {
            print("❌ [AuthStateManager] Error al cerrar sesión: \(error.localizedDescription)")
        }
    }
    
    /// Limpia datos locales después de cerrar sesión
    private func clearLocalData() {
        // Aquí puedes limpiar cualquier dato en caché, UserDefaults, etc.
        print("🧹 [AuthStateManager] Limpiando datos locales")
        
        // Ejemplo: Limpiar UserDefaults específicos
        //UserDefaults.standard.removeObject(forKey: "cached_user_data")
        
        // Notificar a otras partes de la app que deben limpiar sus datos
        NotificationCenter.default.post(name: NSNotification.Name("UserDidSignOut"), object: nil)
    }
    
    // MARK: - Token Management
    
    /// Obtiene el token actual del usuario
    func getCurrentToken(completion: @escaping (String?) -> Void) {
        guard let user = currentUser else {
            completion(nil)
            return
        }
        
        user.getIDToken { token, error in
            if let error = error {
                print("❌ [AuthStateManager] Error obteniendo token: \(error.localizedDescription)")
                completion(nil)
            } else {
                completion(token)
            }
        }
    }
    
    /// Obtiene el token forzando renovación si es necesario
    func getFreshToken(completion: @escaping (String?) -> Void) {
        guard let user = currentUser else {
            completion(nil)
            return
        }
        
        user.getIDTokenForcingRefresh(true) { token, error in
            if let error = error {
                print("❌ [AuthStateManager] Error obteniendo token fresco: \(error.localizedDescription)")
                completion(nil)
            } else {
                completion(token)
            }
        }
    }
    
    // MARK: - Deinit
    
    deinit {
        // En Firebase Auth para iOS, el handler se remueve automáticamente
        // pero si quieres removerlo explícitamente:
        if let handler = authStateHandler {
            Auth.auth().removeStateDidChangeListener(handler)
        }
    }
}

// MARK: - Convenience Extensions

extension AuthStateManager {
    /// Verifica si hay una sesión activa de forma asíncrona
    func checkAuthStatus() async -> Bool {
        return await withCheckedContinuation { continuation in
            if let user = Auth.auth().currentUser {
                user.getIDTokenResult { result, error in
                    if error == nil && result != nil {
                        continuation.resume(returning: true)
                    } else {
                        continuation.resume(returning: false)
                    }
                }
            } else {
                continuation.resume(returning: false)
            }
        }
    }
}
