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
        [
            ("GENERAL", $cartViewModel.generalTicketCount),
            ("VIP", $cartViewModel.vipTicketCount)
        ]
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            if cartViewModel.totalTickets > 0 {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        ViewHeader(title: "TU ORDEN")
                        
                        Divider()
                        .background(.black)
                        
                        // Sección editable por tipo de boleto
                        ForEach(ticketSections, id: \.type) { section in
                            EditableOrderSection(
                                image: section.type == "GENERAL"
                                    ? Image(systemName: "person.fill")
                                    : Image(systemName: "star.fill"),
                                title: "YA DESPEGA - \(section.type)",
                                date: cartViewModel.eventDetails.dateEvent,
                                location: cartViewModel.eventDetails.location,
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
        .background(Color(.systemGroupedBackground))
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
        // Descripción del evento
        Text(cartViewModel.eventDetails.details)
            .font(.subheadline)
            .foregroundColor(.gray)
            .frame(maxWidth: .infinity, alignment: .leading)
        
        // Términos y condiciones
        if !cartViewModel.eventDetails.terms.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(cartViewModel.eventDetails.terms, id: \.self) { term in
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

struct OrderSummaryView: View {
    @EnvironmentObject var cartViewModel: CartViewModel
    @State private var isExpanded: Bool = true
    @Namespace private var animationNamespace
    
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
                        
                        Button(action: {
                            // Acción de pago
                        }) {
                            Text("Pagar ahora")
                                .font(.headline)
                                .frame(width: 150, height: 50)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
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
                .padding(.horizontal)
                .padding(.bottom, 10)
                .frame(maxWidth: .infinity)
            }
            .edgesIgnoringSafeArea(.bottom)
            
        }
    }
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

            Text("Agrega boletos para continuar con tu compra.")
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

// MARK: Vista previa con un ViewModel inyectado
struct CartView_Previews: PreviewProvider {
    static var previews: some View {
        CartView()
            .environmentObject(CartViewModel())
            .previewDevice("iPhone 16 Pro")
    }
}
