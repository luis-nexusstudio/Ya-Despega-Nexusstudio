//
//  MyTicketsView.swift
//  YD_App
//
//  Created by Luis Melendez on 20/03/25.
//

import SwiftUI

struct MyTicketsView: View {
    @EnvironmentObject var paymentCoordinator: PaymentCoordinator
    
    var body: some View {
        VStack {
            switch paymentCoordinator.estadoPago {
            case .exitoso:
                Text("✅ Pago exitoso")
                    .foregroundColor(.green)
            case .pendiente:
                Text("⏳ Pago pendiente de aprobación")
                    .foregroundColor(.orange)
            case .fallido:
                Text("❌ Pago rechazado o fallido")
                    .foregroundColor(.red)
            case .ninguno:
                EmptyView()
            }

            // Aquí irían tus boletos u otra info
            Text("Lista de boletos...")
        }
        .onAppear {
            // Resetea el estado después de mostrarlo
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                paymentCoordinator.estadoPago = .ninguno
            }
        }
    }
}
