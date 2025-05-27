//
//  MyTicketsView.swift
//  YD_App
//
//  Created by Luis Melendez on 20/03/25.
//

import SwiftUI

struct MyTicketsView: View {
    @EnvironmentObject var paymentCoordinator: PaymentCoordinator

    @State private var order: Order?
    @State private var isLoading = false
    @State private var errorMsg: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Mis Tickets")
                .font(.largeTitle).bold()

            Text("Estado del pago: \(paymentCoordinator.estadoPago.rawValue.capitalized)")
                .font(.headline)
                .foregroundColor(color(for: paymentCoordinator.estadoPago))

            if isLoading {
                ProgressView("Cargando…")
            }
            else if let order = order {
                ForEach(order.items, id: \.self) { item in
                    Text("\(item.qty) × \(item.name)")
                }
                Text("Total: \(order.total.formatted(.currency(code: "MXN")))")
                    .font(.title2).bold()

                if let pref = paymentCoordinator.preferenceId {
                    //QRCodeView(dataString: pref)
                        //.frame(width: 200, height: 200)
                }
            }
            else if let err = errorMsg {
                Text(err).foregroundColor(.red)
            }
            else {
                Text("No hay datos de orden.").foregroundColor(.gray)
            }

            Spacer()
        }
        .padding()
        .onAppear {
            print("🔍 MyTicketsView.onAppear – prefId=\(String(describing: paymentCoordinator.preferenceId)), estadoPago=\(paymentCoordinator.estadoPago.rawValue)")
            guard
              let pref = paymentCoordinator.preferenceId,
              paymentCoordinator.estadoPago != .fallido
            else {
             print("⚠️ MyTicketsView: no voy a cargar orden (prefId faltante o fallo)")
              return
            }
            isLoading = true

            print("🌐 MyTicketsView llamando OrderService.fetchOrder(prefId: \(pref))")
            OrderService.fetchOrder(prefId: pref) { result in
                DispatchQueue.main.async {
                    isLoading = false
                    switch result {
                    case .success(let o):
                        print("✅ MyTicketsView: order fetched = \(o)")
                        order = o
                    case .failure(let e):
                        print("❌ MyTicketsView: error fetching order = \(e)")
                        errorMsg = "Error al cargar la orden."
                    }
                }
            }
        }
    }

    private func color(for estado: EstadoPago) -> Color {
        switch estado {
        case .exitoso: return .green
        case .pendiente: return .orange
        case .fallido: return .red
        default: return .primary
        }
    }
}
