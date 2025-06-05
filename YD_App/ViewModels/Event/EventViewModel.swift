//
//  EventViewModel.swift
//  YD_App
//
//  Created by Luis Melendez on 27/05/25.
//

import Foundation
import SwiftUI
import FirebaseAuth

@MainActor
class EventViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var eventDetails: EventDetails?
    @Published var isLoading = false
    @Published var currentAppError: AppErrorProtocol?
    @Published var isRetrying = false
    
    // MARK: - Private Properties
    private let eventId: String
    
    // MARK: - Computed Properties
    var hasData: Bool {
        eventDetails != nil
    }
    
    var hasTickets: Bool {
        eventDetails?.tickets.isEmpty == false
    }
    
    // MARK: - Initialization
    init(eventId: String) {
        self.eventId = eventId
        loadEventDetails()
    }
    
    // MARK: - Public Methods
    func loadEventDetails() {
        guard !isLoading else { return }
        
        isLoading = true
        currentAppError = nil
        
        print("🎫 [EventViewModel] Cargando detalles del evento: \(eventId)")
                
        EventService.getEventDetails(eventId: eventId) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.isLoading = false
                self.isRetrying = false  // ✅ Resetear estado de reintento

                switch result {
                case .success(let data):
                    self.eventDetails = data
                    print("✅ [HomeViewModel] Datos de Home cargados exitosamente")
                    
                case .failure(let error):
                    self.handleError(error)  // ✅ Usar manejo centralizado
                    print("❌ [HomeViewModel] Error cargando Home: \(error.localizedDescription)")
                }
            }
        }
        
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

}
