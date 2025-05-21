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
        BackgroundGeneralView {
            ZStack(alignment: .bottom) {
                if cartViewModel.totalTickets > 0 {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Resumen de compra")
                                .font(.title.bold())
                                .padding(.bottom, 10)
                                .foregroundColor(Color("PrimaryColor"))
                            
                            Divider()
                            
                            ForEach(ticketSections, id: \.type) { section in
                                EditableOrderSection(
                                    image: section.type == "GENERAL"
                                        ? Image(systemName: "person.fill")
                                        : Image(systemName: "star.fill"),
                                    title: "YD - \(section.type)",
                                    date: cartViewModel.eventDetails?.fecha_inicio.date.formatted(date: .long, time: .omitted) ?? "",
                                    location: cartViewModel.eventDetails?.ubicacion ?? "",
                                    count: section.binding
                                )
                            }
                            
                            if let details = cartViewModel.eventDetails {
                                DetailsView(details: details)
                            }
                            
                            OrderSummaryView(selectedTab: $selectedTab)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 60)
                    }
                } else {
                    EmptyCartView()
                }
            }
        }
    }
}

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
                .shadow(radius: 4)

            HStack(alignment: .top, spacing: 15) {
                image
                    .resizable()
                    .frame(width: 100, height: 100)
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 10) {
                    Text(title).font(.headline)
                    Text(date).font(.subheadline).foregroundColor(.secondary)
                    Text(location).font(.subheadline).foregroundColor(.secondary)

                    HStack {
                        Button(action: { if count > 0 { count -= 1 } }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundColor(count > 0 ? .red : .gray)
                        }
                        .disabled(count == 0)

                        Text("\(count)")
                            .frame(minWidth: 30)
                            .font(.body.monospacedDigit())

                        Button(action: { count += 1 }) {
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
    }
}

struct DetailsView: View {
    let details: EventDetails

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(details.detalles)
                .font(.subheadline)
                .foregroundColor(.gray)

            ForEach(details.terminos, id: \.self) { term in
                HStack(alignment: .top, spacing: 5) {
                    Text("•").foregroundColor(.gray)
                    Text(term).foregroundColor(.gray)
                }
            }
        }
    }
}

struct OrderSummaryView: View {
    @EnvironmentObject var cartViewModel: CartViewModel
    @EnvironmentObject var paymentCoordinator: PaymentCoordinator
    @State private var isExpanded = true
    @Binding var selectedTab: Int
    @State private var showRedirecting = false
    @State private var safariURL: URL?

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
                            Spacer()
                            Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .contentShape(Rectangle())
                    }

                    if isExpanded {
                        VStack(spacing: 20) {
                            HStack {
                                Text("Boletos").foregroundColor(.secondary)
                                Spacer()
                                Text("\(cartViewModel.totalTickets)").bold()
                            }
                            HStack {
                                Text("Subtotal").foregroundColor(.secondary)
                                Spacer()
                                Text(cartViewModel.subTotalPrice.formatted(.currency(code: "MXN")))
                                    .bold()
                                    .foregroundColor(Color("MoneyGreen"))
                            }
                            HStack {
                                Text("Cuota de servicio (4%)").foregroundColor(.secondary)
                                Spacer()
                                Text(cartViewModel.serviceFeeAmount.formatted(.currency(code: "MXN")))
                                    .bold()
                                    .foregroundColor(Color("MoneyGreen"))
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
                            Text("Total").font(.subheadline).foregroundColor(.secondary)
                            Text(cartViewModel.totalPrice.formatted(.currency(code: "MXN")))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Color("MoneyGreen"))
                        }

                        Spacer()

                        Button(action: {
                            showRedirecting = true
                            cartViewModel.fetchCheckoutURL { url in
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    showRedirecting = false
                                    if let finalURL = url {
                                        print("🔗 [DEBUG] URL de checkout:", finalURL.absoluteString)
                                        safariURL = finalURL
                                    }
                                }
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image("mercado_pago_icon")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 30)
                                Text("Pagar ahora")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .frame(width: 200, height: 50)
                            .background(Color(red: 0.0, green: 0.62, blue: 0.89))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                        }
                    }
                    .padding()
                    .id("summaryBottom")
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: -2)
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
        .fullScreenCover(isPresented: $showRedirecting) {
            // Sigue usando tu vista de “Conectando…” intacta
            RedirectingView()
        }
        .fullScreenCover(item: $safariURL) { url in
            SafariView(url: url)
                .ignoresSafeArea()
        }
        .onChange(of: paymentCoordinator.redirigirATab) { newTab in
            guard let tab = newTab else { return }
            print("🔄 OrderSummaryView.onChange – redirigirATab=\(tab), estadoPago=\(paymentCoordinator.estadoPago.rawValue)")

            selectedTab = tab

            if paymentCoordinator.estadoPago == .exitoso ||
               paymentCoordinator.estadoPago == .pendiente {
                print("🧹 OrderSummaryView clearCart() llamado porque estadoPago=\(paymentCoordinator.estadoPago.rawValue)")
                cartViewModel.clearCart()
            } else {
                print("🚫 No limpio carrito porque estadoPago=\(paymentCoordinator.estadoPago.rawValue)")
            }

            paymentCoordinator.resetEstadoPago()
        }
    }
}

extension URL: Identifiable {
    public var id: String { absoluteString }
}

struct RedirectingView: View {
    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            let logoWidth = isLandscape ? geometry.size.width * 0.45 : geometry.size.width * 0.4
            let fontSize = isLandscape ? geometry.size.width * 0.035 : geometry.size.width * 0.045

            BackgroundGeneralView {
                VStack(spacing: isLandscape ? 30 : 40) {
                    // Logo grande y balanceado
                    Image("mercado_pago_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: logoWidth)
                        .shadow(radius: 4)

                    // Texto tamaño medio
                    Text("Conectando con Mercado Pago…")
                        .font(.system(size: fontSize, weight: .medium))
                        .foregroundColor(.white)

                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color("PrimaryColor")))
                        .scaleEffect(1.4)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 32)
            }
        }
    }
}

struct EmptyCartView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "cart.badge.minus")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 200)
                .padding()
                .foregroundColor(Color("PrimaryColor"))
            
            Text("Tu carrito está vacío")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            Text("Tu carrito está vacío. ¡Hora de llenarlo!")
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .ignoresSafeArea()
    }
}

struct CartView_Previews: PreviewProvider {
    @State static var selectedTab = 0

    static var previews: some View {
        CartView(selectedTab: $selectedTab)
            .environmentObject(CartViewModel(eventId: ""))
        .previewDevice("iPhone 15 Pro")
    }
}
