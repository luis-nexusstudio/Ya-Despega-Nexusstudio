//
//  AuthStateManager.swift
//  YD_App
//
//  Created by Pedro Martinez - FIXED VERSION
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

// MARK: - AuthStateManager MEJORADO
@MainActor
class AuthStateManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = AuthStateManager()
    
    // MARK: - Published Properties
    @Published var authState: AuthState = .unknown
    @Published var isLoading: Bool = true
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let sessionManager = SessionManager.shared
    private var hasPerformedInitialCheck = false // 🆕 PREVENIR MÚLTIPLES CHECKS
    
    // MARK: - Computed Properties
    var isAuthenticated: Bool {
        return sessionManager.isAuthenticated && sessionManager.isReady
    }
    
    var currentUser: User? {
        return sessionManager.currentUser
    }
    
    var userEmail: String? {
        return sessionManager.userEmail
    }
    
    var userId: String? {
        return sessionManager.userId
    }
    
    var isEmailVerified: Bool {
        return sessionManager.isEmailVerified
    }
    
    // 🆕 NUEVO: Estado combinado más confiable
    var isReady: Bool {
        return sessionManager.isReady && !isLoading
    }
    
    // MARK: - Initialization
    private init() {
        print("🔧 [AuthStateManager] Inicializando con SessionManager...")
        setupSessionManagerObserver()
    }
    
    // MARK: - 🆕 CONFIGURACIÓN MEJORADA DE OBSERVADORES
    private func setupSessionManagerObserver() {
        // 🆕 Observar estado de inicialización del SessionManager
        sessionManager.$isInitializing
            .sink { [weak self] isInitializing in
                Task { @MainActor in
                    guard let self = self else { return }
                    
                    if !isInitializing && !self.hasPerformedInitialCheck {
                        print("🔄 [AuthStateManager] SessionManager listo, verificando estado inicial...")
                        await self.performInitialAuthCheck()
                    }
                }
            }
            .store(in: &cancellables)
        
        // 🆕 Observar cambios en autenticación (MEJORADO)
        sessionManager.$isAuthenticated
            .combineLatest(sessionManager.$isInitializing)
            .sink { [weak self] (isAuthenticated, isInitializing) in
                Task { @MainActor in
                    guard let self = self else { return }
                    
                    // Solo procesar si SessionManager está listo
                    guard !isInitializing else { return }
                    
                    await self.updateAuthState(isAuthenticated: isAuthenticated)
                }
            }
            .store(in: &cancellables)
           
        // 🆕 Observar errores de sesión CRÍTICOS únicamente
        sessionManager.$sessionError
            .compactMap { $0 }
            .sink { [weak self] error in
                Task { @MainActor in
                    guard let self = self else { return }
                    
                    print("⚠️ [AuthStateManager] Error de sesión recibido: \(error.errorCode)")
                    
                    // Solo cambiar estado para errores críticos
                    if self.isCriticalSessionError(error) {
                        print("🚨 [AuthStateManager] Error crítico, marcando como no autenticado")
                        self.authState = .unauthenticated
                        self.isLoading = false
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    /// 🆕 MÉTODO NUEVO: Verificación inicial de autenticación
    private func performInitialAuthCheck() async {
        guard !hasPerformedInitialCheck else { return }
        hasPerformedInitialCheck = true
        
        print("🔍 [AuthStateManager] Realizando verificación inicial de autenticación...")
        
        // Esperar un poco más para asegurar que SessionManager esté completamente configurado
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 segundos
        
        await updateAuthState(isAuthenticated: sessionManager.isAuthenticated)
    }
    
    /// 🆕 MÉTODO NUEVO: Actualización centralizada del estado de auth
    private func updateAuthState(isAuthenticated: Bool) async {
        print("🔄 [AuthStateManager] Actualizando estado: autenticado=\(isAuthenticated)")
        
        if isAuthenticated {
            print("✅ [AuthStateManager] Usuario autenticado confirmado")
            self.authState = .authenticated
        } else {
            print("❌ [AuthStateManager] Usuario no autenticado confirmado")
            self.authState = .unauthenticated
        }
        
        self.isLoading = false
    }
    
    /// 🆕 MÉTODO NUEVO: Detectar errores críticos de sesión
    private func isCriticalSessionError(_ error: AppErrorProtocol) -> Bool {
        switch error.errorCode {
        case "SES_001", "SES_002", "SES_005": // userNotAuthenticated, tokenExpired, invalidUser
            return true
        default:
            return false
        }
    }
    
    // MARK: - 🆕 MÉTODOS PÚBLICOS MEJORADOS
    
    /// Actualiza el estado después de un login exitoso
    func handleSuccessfulLogin() {
        print("🎉 [AuthStateManager] Login exitoso - delegando a SessionManager")
        // SessionManager detectará el cambio automáticamente
        // Solo actualizar loading state
        isLoading = true
    }
    
    /// Actualiza el estado después de un registro exitoso
    func handleSuccessfulRegistration() {
        print("🎉 [AuthStateManager] Registro exitoso - delegando a SessionManager")
        // SessionManager detectará el cambio automáticamente
        isLoading = true
    }
    
    /// Cierra la sesión usando SessionManager
    func signOut() {
        print("🚪 [AuthStateManager] Iniciando sign out via SessionManager...")
        isLoading = true
        
        Task {
            do {
                try await sessionManager.signOut()
                print("✅ [AuthStateManager] Sign out exitoso")
            } catch {
                print("❌ [AuthStateManager] Error en sign out: \(error)")
                // Forzar estado no autenticado incluso si falla
                await MainActor.run {
                    self.authState = .unauthenticated
                    self.isLoading = false
                }
            }
        }
    }
    
    /// 🆕 NUEVO: Obtener token con manejo de AuthStateManager
    func getCurrentToken() async throws -> String {
        guard authState == .authenticated else {
            throw SessionError.userNotAuthenticated
        }
        return try await sessionManager.getCurrentToken()
    }
        
    /// 🆕 NUEVO: Obtener token fresco
    func getFreshToken() async throws -> String {
        guard authState == .authenticated else {
            throw SessionError.userNotAuthenticated
        }
        return try await sessionManager.getFreshToken()
    }
        
    /// 🆕 MEJORADO: Verificación de estado más robusta
    func checkAuthStatus() async -> Bool {
        // Esperar a que termine la inicialización
        while isLoading {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        
        return authState == .authenticated && sessionManager.isAuthenticated
    }
    
    /// 🆕 NUEVO: Forzar verificación completa de autenticación
    func forceAuthCheck() async {
        print("🔄 [AuthStateManager] Forzando verificación de autenticación...")
        isLoading = true
        
        try? await sessionManager.waitForInitialization()
        await updateAuthState(isAuthenticated: sessionManager.isAuthenticated)
    }
    
    /// 🆕 NUEVO: Verificar si el usuario está listo para operar
    func ensureReady() async throws {
        // Esperar a que estemos completamente listos
        while !isReady {
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        
        guard authState == .authenticated else {
            throw SessionError.userNotAuthenticated
        }
    }
    
    // MARK: - 🆕 MÉTODOS DE CONVENIENCIA DELEGADOS
    
    /// Realizar operación autenticada (delegado a SessionManager)
    func performAuthenticatedOperation<T>(
        operation: @escaping (String) async throws -> T
    ) async throws -> T {
        try await ensureReady()
        return try await sessionManager.performAuthenticatedOperation(operation: operation)
    }
    
    /// Obtener UID actual
    func withCurrentUserId<T>(
        operation: @escaping (String) async throws -> T
    ) async throws -> T {
        try await ensureReady()
        return try await sessionManager.withCurrentUserId(operation: operation)
    }
    
    /// Obtener email actual
    func withCurrentUserEmail<T>(
        operation: @escaping (String) async throws -> T
    ) async throws -> T {
        try await ensureReady()
        return try await sessionManager.withCurrentUserEmail(operation: operation)
    }
}
