//
//  HomeViewModel.swift
//  YD_App
//
//  SOLO CORRECCIONES CRÍTICAS - Updated by Luis Melendez on 26/05/25.
//

import SwiftUI
import MapKit

// MARK: - 3. HomeViewModel (SOLO responsable de datos de Home específicos)
class HomeViewModel: ObservableObject {
    @Published var homeEventData: HomeEventData?
    @Published var isLoading = false
    @Published var currentAppError: AppError?
    @Published var isRetrying = false  // ✅ AGREGADO para indicar reintento
    @Published var region: MKCoordinateRegion
    
    private let eventId: String
    
    // MARK: - Computed Properties
    var hasData: Bool {
        homeEventData != nil
    }
    
    var eventTitle: String {
        homeEventData?.nombre ?? "Ya Despega"
    }
    
    var eventDateRange: String {
        guard let data = homeEventData else { return "Cargando fechas..." }
        return data.fechaInicio.date.formatDateRange(to: data.fechaFin.date)
    }
    
    var eventDescription: String {
        homeEventData?.informacion_evento ?? "Cargando información del evento..."
    }
    
    var speakers: [LineupSpeaker] {
        homeEventData?.lineup ?? []
    }
    
    var eventTerms: [String] {
        homeEventData?.terminos ?? []
    }
    
    // ✅ CORREGIDO: Ahora usa ubicacionNombre en lugar de ubicacion directamente
    var locationName: String {
        homeEventData?.ubicacionNombre ?? "Cargando ubicación..."
    }
    
    // MARK: - Initialization
    init(eventId: String) {
        self.eventId = eventId
        self.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 21.1236, longitude: -101.6820),
            span: MKCoordinateSpan(latitudeDelta: 0.09, longitudeDelta: 0.09)
        )
        
        fetchHomeEventData()
    }
    
    // MARK: - Methods
    func fetchHomeEventData() {
        guard !isLoading else { return }
        
        isLoading = true
        currentAppError = nil
        
        print("🏠 [HomeViewModel] Cargando datos de Home para eventId: \(eventId)")
        
        HomeService.getHomeEvent(eventId: eventId) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.isLoading = false
                self.isRetrying = false  // ✅ Resetear estado de reintento
                
                switch result {
                case .success(let data):
                    self.homeEventData = data
                    self.updateRegion(for: data.coordenadas)
                    print("✅ [HomeViewModel] Datos de Home cargados exitosamente")
                    
                case .failure(let error):
                    self.handleError(error)  // ✅ Usar manejo centralizado
                    print("❌ [HomeViewModel] Error cargando Home: \(error.localizedDescription)")
                }
            }
        }
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


}
