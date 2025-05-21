//
//  HomeView.swift
//  YD_App
//
//  Created by Luis Melendez on 04/04/25.
//

import SwiftUI
import MapKit

// MARK: - Main View
struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showTicketPopup = false
    @Binding var selectedTab: Int
    @EnvironmentObject var cartViewModel: CartViewModel

    var body: some View {
        BackgroundGeneralView {
            ZStack(alignment: .bottom) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        EventHeader(title: viewModel.event.title, dateRange: viewModel.event.dateRange)
                        AboutSection(text: viewModel.event.description)
                        LineUpSection(speakers: viewModel.speakers)
                        LocationSection(region: $viewModel.region)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 60)
                    .padding(.bottom, 120)
                }

                FloatingButton(action: { showTicketPopup = true })
                    .padding(.bottom, 36)
                    .sheet(isPresented: $showTicketPopup) {
                        TicketPopupView(selectedTab: $selectedTab)
                            .presentationDetents([.fraction(0.8), .large])
                    }
            }
        }
    }
}

// MARK: - Components

struct EventHeader: View {
    let title: String
    let dateRange: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title.bold())
                .foregroundColor(Color("PrimaryColor"))

            Text(dateRange)
                .font(.subheadline)
                .foregroundColor(.white)
        }
        .padding(.bottom, 10)
    }
}

struct AboutSection: View {
    let text: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

            VStack(alignment: .leading, spacing: 8) {
                Text("Acerca de")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(text)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .padding(20)
        }
        .frame(height: 300)
        .frame(maxWidth: .infinity)
        .padding(.bottom, 40)
    }
}

struct LineUpSection: View {
    let speakers: [Speaker]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Line Up")
                .font(.title.bold())
                .foregroundColor(Color("PrimaryColor"))

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(speakers) { speaker in
                        SpeakerCard(speaker: speaker)
                            .id(speaker.id)
                    }
                }
                .padding(.horizontal, 10)
            }
        }
        .padding(.bottom, 40)
    }
}

struct SpeakerCard: View {
    let speaker: Speaker

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: speaker.iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .padding()
                .background(Color(.systemBackground))
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.1), radius: 5)

            Text(speaker.name)
                .font(.caption)
                .foregroundColor(.white)
        }
        .frame(width: 120)
    }
}

struct LocationSection: View {
    @Binding var region: MKCoordinateRegion

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ubicación")
                .font(.title.bold())
                .foregroundColor(Color("PrimaryColor"))

            Map(coordinateRegion: $region)
                .frame(height: 200)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 5)
        }
    }
}

struct FloatingButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "ticket.fill")
                    .font(.title2)
                Text("Comprar Boletos")
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .padding(.vertical, 15)
            .padding(.horizontal, 60)
            .background(Color("PrimaryColor"))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.2), radius: 5)
        }
    }
}

// MARK: - Ticket Views

struct TicketPopupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var cartViewModel: CartViewModel
    @Binding var selectedTab: Int
    @State private var ticketSelection: [String: Int] = [:]
    
    var totalTickets: Int {
        ticketSelection.values.reduce(0, +)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Boletos Disponibles")
                    .font(.title2.bold())
                Spacer()
            }
            .padding(.top, 60)
            
            Divider()
            
            // Lista de boletos
            if let details = cartViewModel.eventDetails {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        ForEach(details.tickets) { ticket in
                            TicketOptionView(
                                type: ticket.descripcion,
                                price: ticket.precio.formatted(.currency(code: "MXN")),
                                benefits: ticket.beneficios ?? [],
                                imageName: "ticket-general",
                                count: Binding(
                                    get: { ticketSelection[ticket.id] ?? 0 },
                                    set: { ticketSelection[ticket.id] = $0 }
                                )
                            )
                        }
                    }
                    .padding(.bottom, 20)
                }
            } else {
                Text("Cargando boletos...")
                    .foregroundColor(.gray)
                    .padding()
            }
            
            // Botón de carrito
            Button(action: addToCart) {
                HStack {
                    Image(systemName: "cart.fill")
                    Text(totalTickets > 0 ?
                         "Agregar \(totalTickets) al carrito" :
                         "Agregar al carrito")
                }
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color("PrimaryColor"))
                .cornerRadius(10)
            }
            .disabled(totalTickets == 0)
            .opacity(totalTickets == 0 ? 0.6 : 1)
        }
        .padding(.horizontal, 25)
        .padding(.bottom, 20)
    }
    
    private func addToCart() {
        for (ticketId, count) in ticketSelection {
            if count > 0 {
                cartViewModel.ticketCounts[ticketId, default: 0] += count
            }
        }
        selectedTab = 1
        dismiss()
    }
}

struct TicketOptionView: View {
    let type: String
    let price: String
    let benefits: [String]
    let imageName: String
    @Binding var count: Int
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Imagen del boleto
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 100)
                .clipped()
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
            
            // Contenido
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(type)
                        .font(.headline)
                    
                    Spacer()
                    
                    Text(price)
                        .font(.body.bold())
                        .foregroundColor(Color("MoneyGreen"))
                }
                
                ForEach(benefits, id: \.self) { benefit in
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                        
                        Text(benefit)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Selector de cantidad
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
                .padding(.top, 5)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct HomeView_Previews: PreviewProvider {
    @State static var selectedTab = 0

    static var previews: some View {
        HomeView(selectedTab: $selectedTab)
        .previewDevice("iPhone 15 Pro")
    }
}

