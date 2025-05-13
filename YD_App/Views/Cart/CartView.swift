//
//  CartView.swift
//  YD_App
//
//  Created by Luis Melendez on 20/03/25.
//

import SwiftUI

struct CartView: View {
    @EnvironmentObject var cartViewModel: CartViewModel
    
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
                        
                        OrderSummaryView()
                        
                        
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

struct OrderSummaryView: View {
    @EnvironmentObject var cartViewModel: CartViewModel
    @State private var isExpanded: Bool = true
    @Namespace private var animationNamespace
    @State private var checkoutURL: URL?

    var body: some View {
        ScrollViewReader { scrollProxy in
            VStack(spacing: 0) {
                Spacer()
                
                // Resumen fijo en la parte inferior
                VStack(spacing: 0) {
                    // Encabezado desplegable
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isExpanded.toggle()
                        }
                        // Ajustar el scroll después de la animación
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
                    
                    // Contenido desplegable
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
                    
                    // Línea divisoria
                    Divider()
                        .padding(.horizontal, isExpanded ? 0 : 16)
                    
                    // Total y botón de pago
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Total")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(cartViewModel.totalPrice.formatted(.currency(code: "MXN")))
                                .font(.system(size: 18, weight: .bold))
                        }
                        
                        Spacer()
                        
                        Button("Pagar ahora") {
                            cartViewModel.fetchCheckoutURL { url in
                                if let url = url {
                                    checkoutURL = url
                                } else {
                                    // Aquí podrías mostrar una alerta de fallo
                                }
                            }
                        }
                        .font(.headline)
                        .frame(width: 150, height: 50)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .padding()
                    }
                    .padding()
                    .id("summaryBottom") // Identificador para el scroll
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
        // El sheet solo aparece cuando checkoutURL no es nil
        .sheet(item: $checkoutURL) { url in
            SafariView(url: url)
                .ignoresSafeArea()
        }
    }
}

// MARK: - Hacer URL Identifiable para usar .sheet(item:)
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
