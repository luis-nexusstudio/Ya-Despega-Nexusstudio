//
//  HomeViewModel.swift
//  YD_App
//
//  SOLO CORRECCIONES CRÍTICAS - Updated by Luis Melendez on 26/05/25.
//

import SwiftUI
import MapKit
import Combine

// MARK: - ✅ SOLUCIÓN INMEDIATA: Agregar completion

@MainActor
class HomeViewModel: ObservableObject {
    @Published var homeEventData: HomeEventData?
    @Published var isLoading = false
    @Published var currentAppError: AppErrorProtocol?
    @Published var isRetrying = false
    @Published var region: MKCoordinateRegion
    
    private let eventId: String
    private let sessionManager = SessionManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var hasInitialLoad = false // 🆕 PREVENIR MÚLTIPLES CARGAS
    
    // MARK: - Initialization
    init(eventId: String) {
        self.eventId = eventId
        self.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 21.1236, longitude: -101.6820),
            span: MKCoordinateSpan(latitudeDelta: 0.09, longitudeDelta: 0.09)
        )
        
        print("🏠 [HomeViewModel] Inicializado con SessionManager para evento: \(eventId)")
        setupSessionObserver()
    }
    
    // MARK: - 🆕 SETUP DE OBSERVADOR DE SESSIONMANAGER
    private func setupSessionObserver() {
        sessionManager.$isAuthenticated
            .combineLatest(sessionManager.$isInitializing)
            .sink { [weak self] (isAuthenticated, isInitializing) in
                guard let self = self else { return }
                
                if isAuthenticated && !isInitializing && !self.hasInitialLoad {
                    print("🏠 [HomeViewModel] SessionManager listo, cargando datos...")
                    self.hasInitialLoad = true
                    
                    // 🔧 QUICK FIX: Pequeño delay para que termine de configurarse
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.fetchHomeEventData()
                    }
                }
            }
            .store(in: &cancellables)
    }
    // MARK: - Public Methods
    func fetchHomeEventData() {
        guard !isLoading else { return }
        
        // ✅ VERIFICAR QUE SESSIONMANAGER ESTÉ LISTO
        guard sessionManager.isReady && sessionManager.isAuthenticated else {
            print("⚠️ [HomeViewModel] SessionManager no está listo aún")
            return
        }
        
        isLoading = true
        currentAppError = nil
        
        print("🏠 [HomeViewModel] Cargando datos de Home para eventId: \(eventId)")
        
        Task {
            do {
                // ✅ USAR SESSIONMANAGER PARA LA OPERACIÓN
                let data = try await sessionManager.performAuthenticatedOperation { token in
                    try await self.fetchHomeEventWithToken(token: token)
                }
                
                await MainActor.run {
                    self.homeEventData = data
                    self.updateRegion(for: data.coordenadas)
                    self.isLoading = false
                    self.isRetrying = false
                    print("✅ [HomeViewModel] Datos de Home cargados exitosamente")
                }
                
            } catch {
                await MainActor.run {
                    self.handleError(error)
                    self.isLoading = false
                    self.isRetrying = false
                    print("❌ [HomeViewModel] Error cargando Home: \(error)")
                }
            }
        }
    }
    
    // MARK: - 🆕 MÉTODO SEPARADO PARA FETCH CON TOKEN
    private func fetchHomeEventWithToken(token: String) async throws -> HomeEventData {
        guard let url = URL(string: "http://localhost:4000/api/home-event/\(eventId)") else {
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
        
        let homeResponse = try JSONDecoder().decode(HomeEventResponse.self, from: data)
        
        guard homeResponse.success, let homeData = homeResponse.data else {
            throw CommonAppError.serverError
        }
        
        return homeData
    }
    
    func refreshData() {
        print("🔄 [HomeViewModel] Refrescando datos de Home")
        fetchHomeEventData()
    }
    
    func retryLoadData() {
        guard !isRetrying else { return }
        isRetrying = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.fetchHomeEventData()
        }
    }
    
    private func updateRegion(for coordinates: Coordenadas) {
        let coordinate = CLLocationCoordinate2D(
            latitude: coordinates.lat,
            longitude: coordinates.lng
        )
        
        withAnimation(.easeInOut(duration: 0.5)) {
            region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.09, longitudeDelta: 0.09)
            )
        }
    }
    
    private func handleError(_ error: Error) {
        self.currentAppError = error.toAppError()
    }
    
    // MARK: - SessionAwareViewModel
    func clearSessionData() {
        print("🧹 [HomeViewModel] Limpiando datos de home")
        homeEventData = nil
        currentAppError = nil
        isRetrying = false
        hasInitialLoad = false // 🆕 RESETEAR FLAG
    }
    
    // MARK: - Computed Properties (mantener existentes)
    var hasData: Bool { homeEventData != nil }
    var eventTitle: String { homeEventData?.nombre ?? "Ya Despega" }
    var eventDateRange: String {
        guard let data = homeEventData else { return "Cargando fechas..." }
        return data.fechaInicio.date.formatDateRange(to: data.fechaFin.date)
    }
    var eventDescription: String { homeEventData?.informacion_evento ?? "Cargando información del evento..." }
    var speakers: [LineupSpeaker] { homeEventData?.lineup ?? [] }
    var eventTerms: [String] { homeEventData?.terminos ?? [] }
    var locationName: String { homeEventData?.ubicacionNombre ?? "Cargando ubicación..." }
}
