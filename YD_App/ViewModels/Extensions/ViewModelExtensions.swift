//
//  ViewModelExtensions.swift
//  YD_App
//
//  Created by Pedro Martinez on 05/06/25.
//


import SwiftUI
import Combine

// MARK: - Protocolo para ViewModels que necesitan limpiar datos
protocol SessionAwareViewModel: ObservableObject {
    func clearSessionData()
}

// MARK: - Extensión para CartViewModel
extension CartViewModel: SessionAwareViewModel {
    func clearSessionData() {
        print("🧹 [CartViewModel] Limpiando datos del carrito")
        clearCart()
    }
    
    // Agregar esto en el init() de CartViewModel:
    func setupSessionObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSignOut),
            name: NSNotification.Name("UserDidSignOut"),
            object: nil
        )
    }
    
    @objc private func handleSignOut() {
        clearSessionData()
    }
}

// MARK: - Extensión para MyTicketsViewModel
extension MyTicketsViewModel: SessionAwareViewModel {
    func clearSessionData() {
        print("🧹 [MyTicketsViewModel] Limpiando órdenes")
        orders = []
        currentAppError = nil
        isRetrying = false
    }
    
    // Agregar en el init():
    func setupSessionObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSignOut),
            name: NSNotification.Name("UserDidSignOut"),
            object: nil
        )
    }
    
    @objc private func handleSignOut() {
        clearSessionData()
    }
}

// MARK: - Extensión para EventViewModel
extension EventViewModel: SessionAwareViewModel {
    func clearSessionData() {
        print("🧹 [EventViewModel] Limpiando datos del evento")
        eventDetails = nil
        currentAppError = nil
        isRetrying = false
    }
}

// MARK: - Extensión para HomeViewModel
extension HomeViewModel: SessionAwareViewModel {
    func clearSessionData() {
        print("🧹 [HomeViewModel] Limpiando datos de home")
        homeEventData = nil
        currentAppError = nil
        isRetrying = false
    }
}
