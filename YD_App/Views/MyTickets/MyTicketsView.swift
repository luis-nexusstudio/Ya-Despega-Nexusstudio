//
//  MyTicketsView.swift
//  YD_App
//
//  Created by Luis Melendez on 20/03/25.
//

import SwiftUI

struct MyTicketsView: View {
    @StateObject private var viewModel = MyTicketsViewModel()
    @State private var showingSortOptions = false

    var body: some View {
        BackgroundGeneralView {
            if viewModel.isLoading {
                loadingView
            } else if let appError = viewModel.currentAppError {
                StandardErrorView(
                    error: appError,
                    isRetrying: viewModel.isRetrying,
                    onRetry: {
                        viewModel.retryFetch()
                    }
                )
            } else if viewModel.orders.isEmpty {
                emptyStateView
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    headerView
                    ordersListView
                }
                .padding(.horizontal, 24)
                .refreshable {
                    viewModel.refreshOrders()
                }
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshTickets"))) { _ in
            print("📥 MyTicketsView: Recibiendo notificación RefreshTickets")
            viewModel.refreshOrders()
        }
        .actionSheet(isPresented: $showingSortOptions) {
            ActionSheet(
                title: Text("Ordenar por"),
                buttons: OrderSortOption.allCases.map { option in
                    .default(Text(option.rawValue)) {
                        viewModel.changeSortOption(option)
                    }
                } + [.cancel()]
            )
        }
    }
    
    private var loadingView: some View {
        StandardLoadingView(message: "Cargando tus órdenes…")
    }
    
    private var emptyStateView: some View {
        StandardEmptyStateView(
            title: "Aún no tienes tickets",
            message: "Tus tickets aparecerán aquí después de completar una compra",
            icon: "ticket"
        )
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mis Boletos")
                .font(Font.title.bold())
                .foregroundColor(Color("PrimaryColor"))
                .padding(.top, 60)
            
            HStack {
                Text("\(viewModel.orders.count) orden\(viewModel.orders.count == 1 ? "" : "es")")
                    .font(Font.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                sortingSelector
            }
        }
        .padding(.bottom, 20)
    }
    
    private var sortingSelector: some View {
        Button(action: {
            showingSortOptions = true
        }) {
            HStack(spacing: 6) {
                Image(systemName: viewModel.currentSortOption.icon)
                    .font(.system(size: 13))
                
                Text(viewModel.currentSortOption.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
            }
            .foregroundColor(Color("PrimaryColor"))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("PrimaryColor").opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color("PrimaryColor").opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    private var ordersListView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 16) {
                if !viewModel.isLoading && viewModel.currentAppError == nil {
                    Text("Desliza hacia abajo para actualizar")
                        .font(.caption)
                        .opacity(0.4)
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                }
                
                ForEach(viewModel.sortedOrders) { order in
                    OrderCardView(order: order)
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                }
                
                if viewModel.isLoading {
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color("PrimaryColor")))
                            .scaleEffect(0.8)
                        
                        Text("Actualizando...")
                            .font(Font.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding()
                }
            }
            .padding(.bottom, 100)
        }
    }
}

// MARK: - Order Card Component (sin cambios)
struct OrderCardView: View {
    let order: Order
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header del card
            orderHeader
                        
            // Footer expandible
            if isExpanded {
                
                orderContent

                orderDetails
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(order.statusColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var orderHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Estado y botón de expansión
            HStack {
                Text("Estado: \(order.localizedStatus)")
                    .font(Font.headline)
                    .foregroundColor(order.statusColor)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(Font.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            // Fecha de compra
            if let createdAt = order.createdAt {
                Text((createdAt.formatAsOrderDate()))
                    .font(Font.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Divider()


        }
        .padding(.top, 16)
        .padding(.horizontal, 16)
    }
    
    private var orderContent: some View {
        VStack(spacing: 16) {
            Spacer()
            // QR Code - centrado en lugar de los boletos
            if order.status == "approved" {
                VStack(spacing: 12) {
                    QRCodeView(dataString: order.id)
                        .frame(width: 120, height: 120)
                        .background(.clear)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 4)
                    
                    Text("Escanea para ver detalles")
                        .font(Font.subheadline)
                        .foregroundColor(Color("PrimaryColor"))
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            } else {
                // Puedes mostrar un mensaje opcional si el QR no aplica
                Text("QR disponible tras aprobación")
                    .font(Font.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
            }

            
            // Total
            HStack {
                Text("Total:")
                    .font(Font.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(order.total.formatted(.currency(code: "MXN")))
                    .font(Font.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color("MoneyGreen"))
            }
            
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    @ViewBuilder
    private var orderDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
            
            if let externalRef = order.external_reference {
                DetailRow(title: "Orden ID:", value: externalRef)
            }

            // Fecha del evento (estática, o cámbiala por una real si la tienes en el modelo)
            DetailRow(title: "Fecha del evento:", value: "Jul 29 - Ago 02, 2025")

            // Cantidad de boletos (sin contar cuota)
            let ticketCount = order.items.filter { !$0.name.lowercased().contains("cuota") }.reduce(0) { $0 + $1.qty }
            DetailRow(title: "Boletos:", value: "\(ticketCount)")

            // Medio de pago (solo el primero válido)
            if (order.payment_attempts?.last?.method) != nil {
                DetailRow(title: "Medio de pago:", value: order.paymentMethodDescription.capitalized)
            }

        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

}

// MARK: - QR Code View
struct QRCodeView: View {
    let dataString: String
    
    var body: some View {
        if let qrImage = generateQRCode(from: dataString) {
            Image(uiImage: qrImage)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .overlay(
                    Text("QR")
                        .font(Font.caption)
                        .foregroundColor(.gray)
                )
        }
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
        let data = Data(string.utf8)
        
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            
            let transform = CGAffineTransform(scaleX: 3, y: 3)
            
            if let output = filter.outputImage?.transformed(by: transform) {
                let context = CIContext()
                if let cgImage = context.createCGImage(output, from: output.extent) {
                    return UIImage(cgImage: cgImage)
                }
            }
        }
        
        return nil
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(Font.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(Font.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

struct MyTicketsView_Previews: PreviewProvider {
    static var previews: some View {
        MyTicketsView()
            .previewDevice("iPhone 15 Pro")
    }
}
