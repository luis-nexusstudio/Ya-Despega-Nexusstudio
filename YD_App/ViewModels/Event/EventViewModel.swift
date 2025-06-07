//
//  EventViewModel.swift
//  YD_App
//
//  Created by Luis Melendez on 27/05/25.
//

import Foundation
import SwiftUI
import FirebaseAuth
import Combine


@MainActor
class EventViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var eventDetails: EventDetails?
    @Published var isLoading = false
    @Published var currentAppError: AppErrorProtocol?
    @Published var isRetrying = false
    
    // MARK: - Private Properties
    private let eventId: String
    private let sessionManager = SessionManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var hasInitialLoad = false // 🆕 PREVENIR MÚLTIPLES CARGAS
    
    // MARK: - Initialization
    init(eventId: String) {
        self.eventId = eventId
        print("🎫 [EventViewModel] Inicializado con SessionManager para evento: \(eventId)")
        setupSessionObserver()
    }
    
    // MARK: - 🆕 SETUP DE OBSERVADOR DE SESSIONMANAGER
    private func setupSessionObserver() {
        sessionManager.$isAuthenticated
            .combineLatest(sessionManager.$isInitializing)
            .sink { [weak self] (isAuthenticated, isInitializing) in
                guard let self = self else { return }
                
                if isAuthenticated && !isInitializing && !self.hasInitialLoad {
                    print("🎫 [EventViewModel] SessionManager listo, cargando datos...")
                    self.hasInitialLoad = true
                    
                    // 🔧 QUICK FIX: Pequeño delay para que termine de configurarse
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.loadEventDetails()
                    }
                }
            }
            .store(in: &cancellables)
    }
    // MARK: - Public Methods
    func loadEventDetails() {
        guard !isLoading else { return }
        
        // ✅ VERIFICAR QUE SESSIONMANAGER ESTÉ LISTO
        guard sessionManager.isReady && sessionManager.isAuthenticated else {
            print("⚠️ [EventViewModel] SessionManager no está listo aún")
            return
        }
        
        isLoading = true
        currentAppError = nil
        
        print("🎫 [EventViewModel] Cargando detalles del evento: \(eventId)")
        
        Task {
            do {
                // ✅ USAR SESSIONMANAGER PARA LA OPERACIÓN
                let details = try await sessionManager.performAuthenticatedOperation { token in
                    try await self.fetchEventDetailsWithToken(token: token)
                }
                
                await MainActor.run {
                    self.eventDetails = details
                    self.isLoading = false
                    self.isRetrying = false
                    print("✅ [EventViewModel] Datos cargados exitosamente")
                }
                
            } catch {
                await MainActor.run {
                    self.handleError(error)
                    self.isLoading = false
                    self.isRetrying = false
                    print("❌ [EventViewModel] Error cargando datos: \(error)")
                }
            }
        }
    }
    
    // MARK: - 🆕 MÉTODO SEPARADO PARA FETCH CON TOKEN
    private func fetchEventDetailsWithToken(token: String) async throws -> EventDetails {
        guard let url = URL(string: "http://localhost:4000/api/event-details/\(eventId)") else {
            throw CommonAppError.serverError
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CommonAppError.serverError
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw CommonAppError.unauthorized
            }
            throw CommonAppError.serverError
        }
        
        return try JSONDecoder().decode(EventDetails.self, from: data)
    }
    
    func refreshData() {
        print("🔄 [EventViewModel] Refrescando datos del evento")
        loadEventDetails()
    }
    
    func retryLoad() {
        guard !isRetrying else { return }
        isRetrying = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.loadEventDetails()
        }
    }
    
    private func handleError(_ error: Error) {
        self.currentAppError = error.toAppError()
    }
    
    // MARK: - SessionAwareViewModel
    func clearSessionData() {
        print("🧹 [EventViewModel] Limpiando datos del evento")
        eventDetails = nil
        currentAppError = nil
        isRetrying = false
        hasInitialLoad = false // 🆕 RESETEAR FLAG
    }
}
