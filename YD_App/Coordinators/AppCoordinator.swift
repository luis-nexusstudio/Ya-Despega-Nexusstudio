//
//  AppCoordinator.swift - VERSIÓN FINAL
//  YD_App
//
//  Created by Luis Melendez on 20/03/25.
//

import SwiftUI
import Combine
import FirebaseAuth

class AppCoordinator: ObservableObject {
    @Published var currentView: AnyView = AnyView(SplashScreenView())
    private var loginCoordinator: LoginCoordinator?
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var hasDoneInitialCheck = false // ← 🔥 ESTO EVITA LA ANIMACIÓN RARA
    

    init() {
        startSplashSequence()
        // 🔥 NO setupAuthListener() en init para evitar conflictos
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }

    private func startSplashSequence() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            self.checkAuthenticationState()
        }
    }
    
    // 🔥 SIMPLIFICADO - Solo verificar una vez después del splash
    private func checkAuthenticationState() {
        guard !hasDoneInitialCheck else { return }
        hasDoneInitialCheck = true
        
        if let currentUser = Auth.auth().currentUser {
            print("🔍 Usuario encontrado: \(currentUser.email ?? "sin email")")
            
            // Verificar token válido
            currentUser.getIDTokenResult { [weak self] result, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Token inválido: \(error.localizedDescription)")
                        self?.showLogin()
                    } else if let result = result, result.expirationDate > Date() {
                        print("✅ Token válido, mostrando MainView")
                        self?.showMainView()
                        self?.setupAuthListener() // ← Configurar listener DESPUÉS del check inicial
                    } else {
                        print("⏰ Token expirado, mostrando Login")
                        self?.showLogin()
                    }
                }
            }
        } else {
            print("❌ No hay usuario, mostrando Login")
            self.showLogin()
        }
    }

    // 🔥 LISTENER SOLO DESPUÉS DEL CHECK INICIAL
    private func setupAuthListener() {
        guard authStateListener == nil else { return }
        
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                // Solo reaccionar si ya pasamos el check inicial
                guard self?.hasDoneInitialCheck == true else { return }
                
                if user != nil {
                    print("✅ Usuario autenticado - mostrando MainView")
                    self?.showMainView()
                } else {
                    print("❌ Usuario no autenticado - mostrando LoginView")
                    self?.showLogin()
                }
            }
        }
    }

    // MARK: - Navigation Methods
    func showLogin() {
        loginCoordinator = LoginCoordinator(onLoginSuccess: { [weak self] in
            self?.showMainView()
        })
        
        withAnimation(.easeInOut(duration: 0.3)) {
            self.currentView = loginCoordinator!.currentView
        }
        
        // Configurar listener si no existe
        if authStateListener == nil {
            setupAuthListener()
        }
    }

    func showMainView() {
        withAnimation(.easeInOut(duration: 0.3)) {
            self.currentView = AnyView(MainView())
        }
    }
    
    // MARK: - Public Methods
    func signOut() {
        do {
            try Auth.auth().signOut()
            showLogin()
        } catch {
            print("❌ Error al cerrar sesión: \(error.localizedDescription)")
        }
    }
}
