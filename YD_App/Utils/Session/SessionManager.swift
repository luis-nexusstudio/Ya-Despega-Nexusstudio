//
//  SessionManager.swift
//  YD_App
//
//  🔧 OPTIMIZACIONES FINALES basadas en tu versión mejorada
//

import Foundation
import FirebaseAuth
import SwiftUI

// MARK: - Session Errors (sin cambios, están perfectos)
enum SessionError: AppErrorProtocol {
    case userNotAuthenticated
    case tokenExpired
    case tokenRefreshFailed
    case logoutFailed
    case invalidUser
    
    var userMessage: String {
        switch self {
        case .userNotAuthenticated:
            return "No hay una sesión activa. Inicia sesión para continuar."
        case .tokenExpired:
            return "Tu sesión ha expirado. Inicia sesión nuevamente."
        case .tokenRefreshFailed:
            return "Error al renovar la sesión. Inicia sesión nuevamente."
        case .logoutFailed:
            return "Error al cerrar sesión. Intenta nuevamente."
        case .invalidUser:
            return "Usuario inválido. Inicia sesión nuevamente."
        }
    }
    
    var errorCode: String {
        switch self {
        case .userNotAuthenticated: return "SES_001"
        case .tokenExpired: return "SES_002"
        case .tokenRefreshFailed: return "SES_003"
        case .logoutFailed: return "SES_004"
        case .invalidUser: return "SES_005"
        }
    }
    
    var shouldRetry: Bool {
        switch self {
        case .userNotAuthenticated, .tokenExpired, .invalidUser:
            return false
        case .tokenRefreshFailed, .logoutFailed:
            return true
        }
    }
    
    var icon: String {
        switch self {
        case .userNotAuthenticated, .tokenExpired, .invalidUser:
            return "person.crop.circle.badge.exclamationmark"
        case .tokenRefreshFailed, .logoutFailed:
            return "exclamationmark.triangle"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .userNotAuthenticated, .tokenExpired, .invalidUser:
            return .orange
        case .tokenRefreshFailed, .logoutFailed:
            return .red
        }
    }
    
    var logMessage: String {
        return "[\(errorCode)] Session Error: \(userMessage)"
    }
}

// MARK: - Session User Info (sin cambios, está perfecto)
struct SessionUser {
    let uid: String
    let email: String
    let isEmailVerified: Bool
    let displayName: String?
    
    init(from user: User) {
        self.uid = user.uid
        self.email = user.email ?? ""
        self.isEmailVerified = user.isEmailVerified
        self.displayName = user.displayName
    }
}

// MARK: - SessionManager - OPTIMIZACIONES FINALES
@MainActor
class SessionManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = SessionManager()
    
    // MARK: - Published Properties
    @Published var isAuthenticated: Bool = false
    @Published var currentSessionUser: SessionUser?
    @Published var sessionError: AppErrorProtocol?
    @Published var isInitializing: Bool = true
    
    // MARK: - Private Properties
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var tokenExpirationTimer: Timer?
    private var isPerformingOperation = false
    private var initializationCompletion: (() -> Void)?  // 🆕 CALLBACK PARA COMPLETAR INIT
    
    // MARK: - Constants
    private let tokenRefreshThreshold: TimeInterval = 300 // 5 minutos
    
    // MARK: - Computed Properties
    var currentUser: User? {
        return Auth.auth().currentUser
    }
    
    var userId: String? {
        return currentSessionUser?.uid
    }
    
    var userEmail: String? {
        return currentSessionUser?.email
    }
    
    var isEmailVerified: Bool {
        return currentSessionUser?.isEmailVerified ?? false
    }
    
    // 🔧 OPTIMIZACIÓN: Estado más preciso
    var isReady: Bool {
        return !isInitializing && (isAuthenticated || currentUser == nil)
    }
    
    // MARK: - Initialization
    private init() {
        print("🔧 [SessionManager] Inicializando...")
        setupAuthStateListener()
        
        // 🆕 TIMEOUT DE SEGURIDAD para evitar inicialización infinita
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            if self.isInitializing {
                print("⚠️ [SessionManager] Timeout de inicialización - forzando completado")
                self.forceCompleteInitialization()
            }
        }
    }
    
    // MARK: - Public Methods (mantienes todos tus métodos, solo pequeños ajustes)
    
    func getCurrentToken() async throws -> String {
        // 🔧 OPTIMIZACIÓN: Usar waitForInitialization que ya tienes
        try await waitForInitialization()
        
        guard let user = currentUser else {
            print("❌ [SessionManager] No hay usuario actual para obtener token")
            throw SessionError.userNotAuthenticated
        }
        
        do {
            let token = try await user.getIDToken(forcingRefresh: false)
            
            // Solo limpiar errores de sesión específicos
            if let error = sessionError as? SessionError {
                switch error {
                case .tokenExpired, .tokenRefreshFailed:
                    sessionError = nil
                default:
                    break
                }
            }
            
            print("✅ [SessionManager] Token obtenido exitosamente")
            return token
        } catch {
            print("❌ [SessionManager] Error obteniendo token: \(error)")
            
            if isAuthenticationError(error) {
                sessionError = SessionError.userNotAuthenticated
                throw SessionError.userNotAuthenticated
            } else {
                sessionError = SessionError.tokenRefreshFailed
                throw SessionError.tokenRefreshFailed
            }
        }
    }
    
    func getFreshToken() async throws -> String {
        try await waitForInitialization()
        
        guard let user = currentUser else {
            print("❌ [SessionManager] No hay usuario para token fresco")
            throw SessionError.userNotAuthenticated
        }
        
        do {
            print("🔄 [SessionManager] Obteniendo token fresco...")
            let token = try await user.getIDToken(forcingRefresh: true)
            
            if sessionError != nil {
                sessionError = nil
            }
            
            print("✅ [SessionManager] Token fresco obtenido exitosamente")
            return token
        } catch {
            print("❌ [SessionManager] Error obteniendo token fresco: \(error)")
            
            if isAuthenticationError(error) {
                sessionError = SessionError.userNotAuthenticated
                throw SessionError.userNotAuthenticated
            } else {
                sessionError = SessionError.tokenRefreshFailed
                throw SessionError.tokenRefreshFailed
            }
        }
    }
    
    // 🔧 OPTIMIZACIÓN: Verificación más clara
    func requireAuthentication() throws {
        guard isReady else {
            print("⚠️ [SessionManager] SessionManager aún inicializando")
            throw SessionError.userNotAuthenticated
        }
        
        guard isAuthenticated, currentUser != nil else {
            print("❌ [SessionManager] Usuario no autenticado")
            throw SessionError.userNotAuthenticated
        }
        
        // Solo verificar errores críticos de sesión
        if let error = sessionError as? SessionError {
            switch error {
            case .userNotAuthenticated, .tokenExpired, .invalidUser:
                print("❌ [SessionManager] Error crítico de sesión: \(error.errorCode)")
                throw error
            default:
                break
            }
        }
        
        print("✅ [SessionManager] Autenticación verificada")
    }
    
    func performAuthenticatedOperation<T>(
        operation: @escaping (String) async throws -> T
    ) async throws -> T {
        // Prevenir operaciones concurrentes
        if isPerformingOperation {
            print("⚠️ [SessionManager] Operación ya en progreso, esperando...")
            while isPerformingOperation {
                try await Task.sleep(nanoseconds: 200_000_000)
            }
        }
        
        isPerformingOperation = true
        defer { isPerformingOperation = false }
        
        try requireAuthentication()
        
        do {
            let token = try await getCurrentToken()
            let result = try await operation(token)
            print("✅ [SessionManager] Operación autenticada exitosa")
            return result
        } catch {
            print("⚠️ [SessionManager] Error en operación, verificando si es de token...")
            
            if isTokenError(error) {
                print("🔄 [SessionManager] Error de token detectado, intentando con token fresco...")
                
                do {
                    let freshToken = try await getFreshToken()
                    let result = try await operation(freshToken)
                    print("✅ [SessionManager] Operación exitosa con token fresco")
                    return result
                } catch {
                    print("❌ [SessionManager] Retry falló: \(error)")
                    
                    if isAuthenticationError(error) {
                        sessionError = SessionError.tokenExpired
                        throw SessionError.userNotAuthenticated
                    }
                    throw error
                }
            }
            throw error
        }
    }
    
    func signOut() async throws {
        print("🚪 [SessionManager] Iniciando cierre de sesión...")
        
        isPerformingOperation = true
        defer { isPerformingOperation = false }
        
        do {
            try Auth.auth().signOut()
            
            isAuthenticated = false
            currentSessionUser = nil
            sessionError = nil
            
            tokenExpirationTimer?.invalidate()
            tokenExpirationTimer = nil
            
            await clearAllSessionData()
            
            print("✅ [SessionManager] Sesión cerrada exitosamente")
            
        } catch {
            print("❌ [SessionManager] Error cerrando sesión: \(error)")
            
            isAuthenticated = false
            currentSessionUser = nil
            sessionError = SessionError.logoutFailed
            
            throw SessionError.logoutFailed
        }
    }
    
    // MARK: - 🔧 MÉTODOS PRIVADOS OPTIMIZADOS
    
    private func setupAuthStateListener() {
        print("🔧 [SessionManager] Configurando auth state listener...")
        
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            Task { @MainActor in
                guard let self = self else { return }
                
                print("🔄 [SessionManager] Estado de auth cambió - Usuario: \(user?.email ?? "ninguno")")
                
                if let user = user {
                    await self.handleUserAuthenticated(user)
                } else {
                    await self.handleUserNotAuthenticated()
                }
                
                // 🔧 OPTIMIZACIÓN: Completar inicialización de forma más controlada
                self.completeInitializationIfNeeded()
            }
        }
    }
    
    // 🆕 MÉTODO OPTIMIZADO: Completar inicialización solo cuando sea apropiado
    private func completeInitializationIfNeeded() {
        if isInitializing {
            isInitializing = false
            print("✅ [SessionManager] Inicialización completada")
            
            // 🔧 NOTIFICAR DE FORMA MÁS CLARA
            NotificationCenter.default.post(
                name: NSNotification.Name("SessionManagerInitialized"),
                object: nil
            )
            
            initializationCompletion?()
            initializationCompletion = nil
        }
    }
    
    // 🆕 MÉTODO DE SEGURIDAD: Forzar completar inicialización
    private func forceCompleteInitialization() {
        if isInitializing {
            print("🔧 [SessionManager] Forzando completado de inicialización")
            completeInitializationIfNeeded()
        }
    }
    
    private func handleUserAuthenticated(_ user: User) async {
        print("✅ [SessionManager] Procesando usuario autenticado: \(user.email ?? "sin email")")
        
        do {
            _ = try await user.getIDTokenResult(forcingRefresh: false)
            
            currentSessionUser = SessionUser(from: user)
            isAuthenticated = true
            sessionError = nil
            
            setupTokenMonitoringIfNeeded()
            
            print("✅ [SessionManager] Usuario configurado exitosamente")
        } catch {
            print("❌ [SessionManager] Token inválido para usuario: \(error)")
            
            isAuthenticated = false
            currentSessionUser = nil
            sessionError = SessionError.invalidUser
        }
    }
    
    private func handleUserNotAuthenticated() async {
        print("❌ [SessionManager] Procesando usuario no autenticado")
        
        isAuthenticated = false
        currentSessionUser = nil
        
        if !(sessionError is SessionError) {
            sessionError = nil
        }
        
        tokenExpirationTimer?.invalidate()
        tokenExpirationTimer = nil
        
        await clearAllSessionData()
    }
    
    private func setupTokenMonitoringIfNeeded() {
        guard tokenExpirationTimer == nil else { return }
        
        tokenExpirationTimer = Timer.scheduledTimer(withTimeInterval: 180, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkTokenExpirationSafely()
            }
        }
        print("⏰ [SessionManager] Monitoreo de token configurado")
    }
    
    private func checkTokenExpirationSafely() async {
        guard isAuthenticated,
              !isPerformingOperation,
              sessionError == nil,
              let user = currentUser else {
            return
        }
        
        do {
            let result = try await user.getIDTokenResult(forcingRefresh: false)
            let timeUntilExpiration = result.expirationDate.timeIntervalSinceNow
            
            if timeUntilExpiration < tokenRefreshThreshold {
                print("⚠️ [SessionManager] Token próximo a expirar en \(timeUntilExpiration)s, renovando...")
                await scheduleTokenRefresh()
            }
        } catch {
            print("❌ [SessionManager] Error verificando expiración de token: \(error)")
            
            if isAuthenticationError(error) {
                sessionError = SessionError.tokenExpired
            }
        }
    }
    
    private func scheduleTokenRefresh() async {
        guard let user = currentUser, !isPerformingOperation else { return }
        
        do {
            _ = try await user.getIDToken(forcingRefresh: true)
            print("✅ [SessionManager] Token renovado automáticamente")
            
            if let error = sessionError as? SessionError {
                switch error {
                case .tokenExpired, .tokenRefreshFailed:
                    sessionError = nil
                default:
                    break
                }
            }
        } catch {
            print("❌ [SessionManager] Error renovando token automáticamente: \(error)")
            if isAuthenticationError(error) {
                sessionError = SessionError.tokenRefreshFailed
            }
        }
    }
    
    private func isAuthenticationError(_ error: Error) -> Bool {
        let nsError = error as NSError
        
        let authErrorCodes = [
            17011, // ERROR_USER_NOT_FOUND
            17014, // ERROR_USER_TOKEN_EXPIRED
            17009, // ERROR_INVALID_USER_TOKEN
            17017  // ERROR_USER_DISABLED
        ]
        
        return nsError.domain == "FIRAuthErrorDomain" && authErrorCodes.contains(nsError.code)
    }
    
    private func isTokenError(_ error: Error) -> Bool {
        let nsError = error as NSError
        
        return nsError.code == 401 ||
               nsError.code == 403 ||
               isAuthenticationError(error) ||
               nsError.localizedDescription.lowercased().contains("token") ||
               nsError.localizedDescription.lowercased().contains("unauthorized")
    }
    
    private func clearAllSessionData() async {
        print("🧹 [SessionManager] Limpiando datos de sesión...")
        
        NotificationCenter.default.post(
            name: NSNotification.Name("SessionDidEnd"),
            object: nil
        )
        
        print("✅ [SessionManager] Datos de sesión limpiados")
    }
    
    // MARK: - Deinit
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
        tokenExpirationTimer?.invalidate()
        print("🔧 [SessionManager] Deinicializado")
    }
}

// MARK: - EXTENSIONES (sin cambios, están perfectas)
extension SessionManager {
    
    func withCurrentUserId<T>(
        operation: @escaping (String) async throws -> T
    ) async throws -> T {
        guard let uid = userId else {
            throw SessionError.userNotAuthenticated
        }
        return try await operation(uid)
    }
    
    func withCurrentUserEmail<T>(
        operation: @escaping (String) async throws -> T
    ) async throws -> T {
        guard let email = userEmail, !email.isEmpty else {
            throw SessionError.invalidUser
        }
        return try await operation(email)
    }
    
    // 🔧 OPTIMIZACIÓN MENOR: Timeout más realista
    func waitForInitialization(timeout: TimeInterval = 3.0) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        
        while isInitializing && Date() < deadline {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 segundos
        }
        
        if isInitializing {
            print("⚠️ [SessionManager] Timeout esperando inicialización")
            throw SessionError.userNotAuthenticated
        }
    }
}
