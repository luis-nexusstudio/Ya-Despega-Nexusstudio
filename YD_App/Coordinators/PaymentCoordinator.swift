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

    private var cancellables = Set<AnyCancellable>()

    init() {
        NotificationCenter.default.publisher(for: .checkoutSuccess)
            .sink { [weak self] _ in
                self?.estadoPago = .exitoso
                self?.redirigirATab = 2
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .checkoutPending)
            .sink { [weak self] _ in
                self?.estadoPago = .pendiente
                self?.redirigirATab = 2
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .checkoutFailure)
            .sink { [weak self] _ in
                self?.estadoPago = .fallido
                self?.redirigirATab = 2
            }
            .store(in: &cancellables)
    }

    func resetEstadoPago() {
        estadoPago = .ninguno
        redirigirATab = nil
    }
}
