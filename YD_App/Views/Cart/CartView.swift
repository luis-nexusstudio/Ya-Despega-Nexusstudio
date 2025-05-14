//
//  CartView.swift
//  YD_App
//
//  Created by Luis Melendez on 20/03/25.
//

import SwiftUI

struct CartView: View {
    @EnvironmentObject var cartViewModel: CartViewModel
    @Binding var selectedTab: Int
    
    // Filtra solo los tipos de boletos con cantidad > 0
    var ticketSections: [(type: String, binding: Binding<Int>)] {
        guard let details = cartViewModel.eventDetails else { return [] }

        return details.tickets.compactMap { ticket in
            let binding = Binding(
                get: { cartViewModel.ticketCounts[ticket.id] ?? 0 },
                set: { cartViewModel.ticketCounts[ticket.id] = $0 }
            )
            return (ticket.descripcion.uppercased(), binding)
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            if cartViewModel.totalTickets > 0 {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        ViewHeader(title: "Resumen de compra")
                        
                        Divider()
                        .background(.black)
                        
                        // Sección editable por tipo de boleto
                        ForEach(ticketSections, id: \.type) { section in
                            EditableOrderSection(
                                image: section.type == "GENERAL"
                                    ? Image(systemName: "person.fill")
                                    : Image(systemName: "star.fill"),
                                title: "YA DESPEGA - \(section.type)",
                                date: cartViewModel.eventDetails?.fecha_inicio.date.formatted(date: .long, time: .omitted) ?? "",
                                location: cartViewModel.eventDetails?.ubicacion ?? "",
                                count: section.binding
                            )
                        }
                        
                        DetailsView(cartViewModel: cartViewModel)
                        
                        OrderSummaryView(selectedTab: $selectedTab)
                        
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 60)
                }
            } else {
                // Vista vacía
                EmptyCartView()
            }
        }
    }
}

// MARK: Encabezado de la vista de carrito
struct ViewHeader: View {
    let title: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title.bold())
                .foregroundColor(.primary)
        }
        .padding(.bottom, 10)
    }
}

// MARK: Sección editable por tipo de boleto
struct EditableOrderSection: View {
    let image: Image
    let title: String
    let date: String
    let location: String
    @Binding var count: Int

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

            HStack(alignment: .top, spacing: 15) {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipped()
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 10) {
                    Text(title)
                        .font(.headline)

                    Text(date)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(location)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    // ➖➕ Contador
                    HStack {
                        Button(action: {
                            if count > 0 { count -= 1 }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundColor(count > 0 ? .red : .gray)
                            
                        }
                        .disabled(count == 0)

                        Text("\(count)")
                            .font(.body.monospacedDigit())
                            .frame(minWidth: 30)

                        Button(action: {
                            count += 1
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                        }
                    }
                }

                Spacer()
            }
            .padding()
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }
}

// MARK: Terminos y condiciones del evento
struct DetailsView: View {
    let cartViewModel: CartViewModel

    var body: some View {
        if let details = cartViewModel.eventDetails {
            VStack(alignment: .leading, spacing: 10) {
                Text(details.detalles)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if !details.terminos.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(details.terminos, id: \.self) { term in
                            HStack(alignment: .top, spacing: 5) {
                                Text("•")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text(term)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
    }
}

// OrderSummaryView.swift
import SwiftUI

struct OrderSummaryView: View {
    @EnvironmentObject var cartViewModel: CartViewModel
    @EnvironmentObject var paymentCoordinator: PaymentCoordinator
    @State private var isExpanded: Bool = true
    @State private var checkoutURL: URL?
    @Binding var selectedTab: Int

    var body: some View {
        ScrollViewReader { scrollProxy in
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 0) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isExpanded.toggle()
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            withAnimation {
                                scrollProxy.scrollTo("summaryBottom", anchor: .bottom)
                            }
                        }
                    }) {
                        HStack {
                            Text("Resumen del pedido")
                                .font(.headline)
                                .foregroundColor(.primary)

                            Spacer()

                            Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())

                    if isExpanded {
                        VStack(spacing: 20) {
                            HStack {
                                Text("Boletos")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(cartViewModel.totalTickets)")
                                    .bold()
                            }

                            HStack {
                                Text("Subtotal")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(cartViewModel.subTotalPrice.formatted(.currency(code: "MXN")))
                                    .bold()
                            }

                            HStack {
                                Text("Cuota de servicio (4%)")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(cartViewModel.serviceFeeAmount.formatted(.currency(code: "MXN")))
                                    .bold()
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 15)
                        .transition(.opacity)
                    }

                    Divider()
                        .padding(.horizontal, isExpanded ? 0 : 16)

                    HStack {
                        VStack(alignment: .leading) {
                            Text("Total")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(cartViewModel.totalPrice.formatted(.currency(code: "MXN")))
                                .font(.system(size: 18, weight: .bold))
                        }

                        Spacer()

                        Button(action: {
                            cartViewModel.fetchCheckoutURL { url in
                                if let url = url {
                                    checkoutURL = url
                                    print("OrderSummaryView: opening checkout URL -> \(url)")
                                } else {
                                    print("OrderSummaryView: failed to get checkout URL")
                                }
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image("mercado_pago_icon") // asegúrate de tenerlo en tus Assets
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 50)
                                
                                Text("Pagar ahora")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .frame(width: 200, height: 50)
                            .background(Color(red: 0.0, green: 0.62, blue: 0.89)) // #009ee3
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                        }
                        .padding()
                    }
                    .padding()
                    .id("summaryBottom")
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: -2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(.systemGray4), lineWidth: 0.5)
                )
                .padding(.bottom, 10)
                .frame(maxWidth: .infinity)

            }
            .edgesIgnoringSafeArea(.bottom)
        }
        .fullScreenCover(item: $checkoutURL) { url in
            SafariView(url: url)
                .ignoresSafeArea()
        }
        .onChange(of: paymentCoordinator.redirigirATab) {
            if let tab = paymentCoordinator.redirigirATab {
                selectedTab = tab
                paymentCoordinator.resetEstadoPago()
            }
        }
    }
}

extension URL: Identifiable {
    public var id: String { absoluteString }
}


// MARK: Vista para carrito vacío
struct EmptyCartView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "cart.badge.minus")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 200)
                .padding()

            Text("Tu carrito está vacío")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            Text("Tu carrito está vacío. ¡Hora de llenarlo!.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .ignoresSafeArea()
    }
}
