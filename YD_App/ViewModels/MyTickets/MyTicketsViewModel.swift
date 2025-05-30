//
//  MyTicketsViewModel.swift
//  YD_App
//
//  Created by Luis Melendez on 22/05/25.
//

import Foundation
import SwiftUI

@MainActor
class MyTicketsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var orders: [Order] = []
    @Published var isLoading: Bool = false
    @Published var currentAppError: AppError?
    @Published var isRetrying: Bool = false
    @Published var currentSortOption: OrderSortOption = .dateDesc
    
    // MARK: - Computed Properties
    var hasOrders: Bool {
        return !orders.isEmpty
    }
    
    var approvedOrders: [Order] {
        return orders.filter { $0.status.lowercased() == "approved" }
    }
    
    var pendingOrders: [Order] {
        return orders.filter { $0.status.lowercased() == "pending" }
    }
    
    // Computed property para ordenar las órdenes
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
                // Primero aprobados, luego el resto
                if order1.status.lowercased() == "approved" && order2.status.lowercased() != "approved" {
                    return true
                } else if order1.status.lowercased() != "approved" && order2.status.lowercased() == "approved" {
                    return false
                } else {
                    // Si tienen el mismo estado, ordenar por fecha
                    guard let date1 = order1.createdAt, let date2 = order2.createdAt else {
                        return false
                    }
                    return date1 > date2
                }
            }
        case .statusPending:
            return orders.sorted { order1, order2 in
                // Primero pendientes, luego el resto
                if order1.status.lowercased() == "pending" && order2.status.lowercased() != "pending" {
                    return true
                } else if order1.status.lowercased() != "pending" && order2.status.lowercased() == "pending" {
                    return false
                } else {
                    // Si tienen el mismo estado, ordenar por fecha
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
    
    // MARK: - Public Methods
    func fetchOrders() {
        guard !isLoading else { return }
        
        isLoading = true
        currentAppError = nil
        
        Task {
            do {
                let fetchedOrders = try await fetchOrdersAsync()
                self.orders = fetchedOrders
                self.isLoading = false
            } catch {
                self.handleError(error)
                self.isLoading = false
            }
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
    
    func fetchOrderByExternalReference(_ externalRef: String, completion: @escaping (Order?) -> Void) {
        OrderService.fetchOrderByExternalReferenceWithRetry(ref: externalRef) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let order):
                    // Actualizar la orden en la lista si ya existe
                    if let index = self.orders.firstIndex(where: { $0.external_reference == externalRef }) {
                        self.orders[index] = order
                    } else {
                        // Agregar nueva orden al principio de la lista
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
    
    // Método para cambiar la opción de ordenamiento
    func changeSortOption(_ option: OrderSortOption) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentSortOption = option
        }
    }
    
    // MARK: - Private Methods
    private func fetchOrdersAsync() async throws -> [Order] {
        return try await withCheckedThrowingContinuation { continuation in
            OrderService.fetchAllOrders { result in
                switch result {
                case .success(let orders):
                    continuation.resume(returning: orders)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
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
        print(error.toAppError())
        self.currentAppError = error.toAppError()
    }


    
}
