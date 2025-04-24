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
        ZStack(alignment: .bottom) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    EventHeader(title: viewModel.event.title, dateRange: viewModel.event.dateRange)
                    
                    AboutSection(text: viewModel.event.description)
                    
                    LineUpSection(speakers: viewModel.speakers)
                    
                    LocationSection(region: $viewModel.region)
                    
                    Spacer().frame(height: 80)
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
            }
            
            FloatingButton(action: { showTicketPopup = true })
                .sheet(isPresented: $showTicketPopup) {
                    TicketPopupView(selectedTab: $selectedTab)
                        .presentationDetents([.fraction(0.8), .large])
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
                .foregroundColor(.primary)
            
            Text(dateRange)
                .font(.subheadline)
                .foregroundColor(.secondary)
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
        .frame(maxWidth: .infinity) // 👈 Responsivo
        .padding(.bottom, 40)
    }
}

struct LineUpSection: View {
    let speakers: [Speaker]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Line Up")
                .font(.title.bold())
                .foregroundColor(.primary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) { // Usar LazyHStack
                    ForEach(speakers) { speaker in
                        SpeakerCard(speaker: speaker)
                            .id(speaker.id) // Identificador único
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
                .foregroundColor(.primary)
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
                .foregroundColor(.primary)
            
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
                Text("Ver Boletos")
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.black)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.2), radius: 5)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }
}

// MARK: - Ticket Views

struct TicketPopupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var cartViewModel: CartViewModel
    @Binding var selectedTab: Int
    @State private var ticketSelection: [TicketType: Int] = [
        .general: 0,
        .vip: 0
    ]
    
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
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    TicketOptionView(
                        type: "General",
                        price: "$500",
                        benefits: ["Acceso a todas las conferencias", "Material digital"],
                        imageName: "ticket-general",
                        count: Binding(
                            get: { ticketSelection[.general] ?? 0 },
                            set: { ticketSelection[.general] = $0 }
                        )
                    )
                    
                    TicketOptionView(
                        type: "VIP",
                        price: "$600",
                        benefits: ["Meet & greet con conferencistas", "Acceso preferencial", "Todo lo del general"],
                        imageName: "ticket-vip",
                        count: Binding(
                            get: { ticketSelection[.vip] ?? 0 },
                            set: { ticketSelection[.vip] = $0 }
                        )
                    )
                }
                .padding(.bottom, 20)
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
                .background(Color.blue)
                .cornerRadius(10)
            }
            .disabled(totalTickets == 0)
            .opacity(totalTickets == 0 ? 0.6 : 1)
        }
        .padding(.horizontal, 25)
        .padding(.bottom, 20)
    }
    
    private func addToCart() {
        for (type, count) in ticketSelection {
            if count > 0 {
                cartViewModel.addTickets(type: type, count: count)
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
                        .foregroundColor(.blue)
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

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(selectedTab: .constant(0))
                .environmentObject(CartViewModel()) // Agrega esta línea
                .preferredColorScheme(.light) // Opcional para vista en modo claro
            
    }
}
