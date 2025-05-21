//
//  PaymentCoordinator.swift
//  YD_App
//
//  Created by Luis Melendez on 13/05/25.
//


import Foundation
import Combine

class PaymentCoordinator: ObservableObject {
    @Published var estadoPago: EstadoPago = .ninguno
    @Published var redirigirATab: Int? = nil
    @Published var preferenceId: String? = nil

    func resetEstadoPago() {
        estadoPago = .ninguno
        redirigirATab = nil
        preferenceId = nil
    }
}
