//
//  MyTicketsViewModel.swift
//  YD_App
//
//  Created by Luis Melendez on 22/05/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class MyTicketsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var orders: [Order] = []
    @Published var isLoading: Bool = false
    @Published var currentAppError: AppErrorProtocol?
    @Published var isRetrying: Bool = false
    @Published var currentSortOption: OrderSortOption = .dateDesc
    
    // 🆕 SessionManager integration
    private let sessionManager = SessionManager.shared
    
    // MARK: - Computed Properties (sin cambios)
    var hasOrders: Bool {
        return !orders.isEmpty
    }
    
    var approvedOrders: [Order] {
        return orders.filter { $0.status.lowercased() == "approved" }
    }
    
    var pendingOrders: [Order] {
        return orders.filter { $0.status.lowercased() == "pending" }
    }
    
    var sortedOrders: [Order] {
        switch currentSortOption {
        case .dateDesc:
            return orders.sorted { order1, order2 in
                guard let date1 = order1.createdAt, let date2 = order2.createdAt else {
                    return false
                }
                return date1 > date2
            }
        case .dateAsc:
            return orders.sorted { order1, order2 in
                guard let date1 = order1.createdAt, let date2 = order2.createdAt else {
                    return false
                }
                return date1 < date2
            }
        case .statusApproved:
            return orders.sorted { order1, order2 in
                if order1.status.lowercased() == "approved" && order2.status.lowercased() != "approved" {
                    return true
                } else if order1.status.lowercased() != "approved" && order2.status.lowercased() == "approved" {
                    return false
                } else {
                    guard let date1 = order1.createdAt, let date2 = order2.createdAt else {
                        return false
                    }
                    return date1 > date2
                }
            }
        case .statusPending:
            return orders.sorted { order1, order2 in
                if order1.status.lowercased() == "pending" && order2.status.lowercased() != "pending" {
                    return true
                } else if order1.status.lowercased() != "pending" && order2.status.lowercased() == "pending" {
                    return false
                } else {
                    guard let date1 = order1.createdAt, let date2 = order2.createdAt else {
                        return false
                    }
                    return date1 > date2
                }
            }
        case .priceDesc:
            return orders.sorted { $0.total > $1.total }
        case .priceAsc:
            return orders.sorted { $0.total < $1.total }
        }
    }
    
    // MARK: - Initialization
    init() {
        print("🎫 [MyTicketsViewModel] Inicializado con SessionManager")
        setupSessionObserver()
    }
    
    // 🆕 NUEVO: Setup session observer
    private func setupSessionObserver() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SessionDidEnd"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.clearSessionData()
        }
    }
    
    // 🆕 NUEVO: Clear session data
    func clearSessionData() {
        print("🧹 [MyTicketsViewModel] Limpiando órdenes por fin de sesión")
        orders = []
        currentAppError = nil
        isRetrying = false
    }
    
    // MARK: - 🆕 MÉTODOS MEJORADOS
    func fetchOrders() {
        guard !isLoading else { return }
        
        isLoading = true
        currentAppError = nil
        
        Task {
            do {
                // 🆕 Usar SessionManager para operación autenticada
                let fetchedOrders = try await sessionManager.performAuthenticatedOperation { token in
                    try await self.fetchOrdersWithToken(token: token)
                }
                
                await MainActor.run {
                    self.orders = fetchedOrders
                    self.isLoading = false
                    self.isRetrying = false
                }
                
            } catch {
                await MainActor.run {
                    self.handleError(error)
                    self.isLoading = false
                    self.isRetrying = false
                }
            }
        }
    }
    
    // 🆕 NUEVO: Método separado para fetch con token
    private func fetchOrdersWithToken(token: String) async throws -> [Order] {
        guard let url = URL(string: "http://localhost:4000/api/orders") else {
            throw OrderError.urlInvalid
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0

        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OrderError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            do {
                let orders = try JSONDecoder().decode([Order].self, from: data)
                return orders
            } catch {
                print("❌ Error al decodificar órdenes:", error)
                throw OrderError.decodingError
            }
            
        case 401:
            throw OrderError.unauthorized
            
        case 404:
            throw OrderError.notFound
            
        case 500...599:
            throw OrderError.serverError
            
        default:
            throw OrderError.requestFailed
        }
    }
    
    func refreshOrders() {
        fetchOrders()
    }
    
    func retryFetch() {
        guard !isRetrying else { return }
        isRetrying = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isRetrying = false
            self.fetchOrders()
        }
    }
    
    // Resto de métodos sin cambios
    func fetchOrderByExternalReference(_ externalRef: String, completion: @escaping (Order?) -> Void) {
        // Implementación usando SessionManager si es necesario
        // Por ahora mantener la implementación actual de OrderService
        OrderService.fetchOrderByExternalReferenceWithRetry(ref: externalRef) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let order):
                    if let index = self.orders.firstIndex(where: { $0.external_reference == externalRef }) {
                        self.orders[index] = order
                    } else {
                        self.orders.insert(order, at: 0)
                    }
                    completion(order)
                case .failure(let error):
                    print("❌ Error al obtener orden por external_reference: \(error)")
                    completion(nil)
                }
            }
        }
    }
    
    func changeSortOption(_ option: OrderSortOption) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentSortOption = option
        }
    }
    
    // MARK: - Lifecycle
    func onAppear() {
        if orders.isEmpty {
            fetchOrders()
        }
    }
    
    func onDisappear() {
        // Limpiar recursos si es necesario
    }
    
    private func handleError(_ error: Error) {
        print("❌ [MyTicketsViewModel] Error:", error.localizedDescription)
        self.currentAppError = error.toAppError()
    }
}
