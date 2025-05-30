//
//  HomeView.swift
//  YD_App
//
//  NUEVA ARQUITECTURA - Con manejo de errores estandarizado
//  Updated by Luis Melendez on 27/05/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var eventViewModel: EventViewModel
    @EnvironmentObject var cartViewModel: CartViewModel
    @State private var showTicketPopup = false
    @Binding var selectedTab: Int

    var body: some View {
        BackgroundGeneralView {
            ZStack(alignment: .bottom) {
                if homeViewModel.isLoading {
                    loadingView
                } else if let appError = homeViewModel.currentAppError {
                    StandardErrorView(
                        error: appError ,
                        isRetrying: homeViewModel.isRetrying,
                        onRetry: {
                            eventViewModel.retryLoad()
                            homeViewModel.retryLoadData()
                        }
                    )
                } else if homeViewModel.homeEventData == nil && homeViewModel.speakers.isEmpty {
                    emptyStateView
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 20) {
                            EventHeader(title: homeViewModel.eventTitle, dateRange: homeViewModel.eventDateRange)
                            AboutSection(text: homeViewModel.eventDescription)
                            LineUpSection(speakers: homeViewModel.speakers)
                            LocationSection(locationName: homeViewModel.locationName,
                                            latitude: homeViewModel.homeEventData?.coordenadas.lat ?? 0.0,
                                            longitude: homeViewModel.homeEventData?.coordenadas.lng ?? 0.0)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 60)
                        .padding(.bottom, 120)
                    }
                    
                    if !homeViewModel.isLoading && homeViewModel.currentAppError == nil {
                        FloatingButton(action: {
                            showTicketPopup = true
                        })
                        .padding(.bottom, 36)
                        .sheet(isPresented: $showTicketPopup) {
                            TicketPopupView(selectedTab: $selectedTab)
                                .presentationDetents([.fraction(0.8), .large])
                        }
                    }
                }
            }
            
        }
        
    }
    
    private var loadingView: some View {
        StandardLoadingView(message: "Cargando información del evento")
    }
    
    private var emptyStateView: some View {
        StandardEmptyStateView(
            title: "Sin información",
            message: "No contamos con información relacionada a este evento",
            icon: "info"
        )
    }
}


// MARK: - Components (sin cambios)
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
        .frame(minHeight: 200)
        .frame(maxWidth: .infinity)
        .padding(.bottom, 40)
    }
}

struct LineUpSection: View {
    let speakers: [LineupSpeaker]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Line Up")
                .font(.title.bold())
                .foregroundColor(Color("PrimaryColor"))

            if speakers.isEmpty {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    VStack(spacing: 12) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        
                        Text("Información del lineup próximamente...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(40)
                }
                .frame(height: 150)
            } else {
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
        }
        .padding(.bottom, 40)
    }
}

struct SpeakerCard: View {
    let speaker: LineupSpeaker

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(.systemBackground))
                    .frame(width: 80, height: 80)
                    .shadow(color: .black.opacity(0.1), radius: 5)
                
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(Color("PrimaryColor"))
            }

            VStack(spacing: 4) {
                Text(speaker.nombre)
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                if !speaker.informacion.isEmpty {
                    Text(speaker.informacion)
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
            }
        }
        .frame(width: 120)
        .padding(.vertical, 8)
    }
}

struct LocationSection: View {
    let locationName: String
    let latitude: Double
    let longitude: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ubicación")
                .font(.title.bold())
                .foregroundColor(Color("PrimaryColor"))

            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                
                VStack(spacing: 16) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color("PrimaryColor"))
                    
                    Text(locationName)
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    VStack(spacing: 8) {
                        Text("Lat: \(latitude, specifier: "%.4f"), Lng: \(longitude, specifier: "%.4f")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .opacity(0.7)
                        
                        Button(action: openInMaps) {
                            HStack {
                                Image(systemName: "map.fill")
                                Text("Ver en Mapas")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color("PrimaryColor"))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(40)
            }
            .frame(height: 400)
        }
    }
    
    private func openInMaps() {
        let urlString = "http://maps.apple.com/?ll=\(latitude),\(longitude)&q=\(locationName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
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

// MARK: - TICKET POPUP ACTUALIZADO
struct TicketPopupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var eventViewModel: EventViewModel
    @EnvironmentObject var cartViewModel: CartViewModel
    @Binding var selectedTab: Int
    @State private var ticketSelection: [String: Int] = [:]
    
    var totalTickets: Int {
        ticketSelection.values.reduce(0, +)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Boletos Disponibles")
                    .font(.title2.bold())
                Spacer()
            }
            .padding(.top, 20)
            
            Divider()
            
            if eventViewModel.isLoading {
                StandardLoadingView(message: "Cargando boletos disponibles...")
                    .frame(maxHeight: .infinity)
                
            } else if let appError = eventViewModel.currentAppError {
                StandardErrorView(
                    error: appError,
                    isRetrying: eventViewModel.isRetrying,
                    onRetry: {
                        eventViewModel.retryLoad()
                    }
                )
                .frame(maxHeight: .infinity)
                
            } else if let details = eventViewModel.eventDetails, !details.tickets.isEmpty {
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
                
            } else {
                StandardEmptyStateView(
                    title: "No hay boletos disponibles",
                    message: "Los boletos para este evento aún no están disponibles o se agotaron",
                    icon: "ticket.badge.minus",
                    actionTitle: "Cerrar",
                    action: {
                        dismiss()
                    }
                )
                .frame(maxHeight: .infinity)
            }
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

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    @State static var selectedTab = 0

    static var previews: some View {
        HomeView(selectedTab: $selectedTab)
            .environmentObject(EventViewModel(eventId: "8avevXHoe4aXoMQEDOic"))
            .environmentObject(CartViewModel())
            .environmentObject(HomeViewModel(eventId: "8avevXHoe4aXoMQEDOic"))
            .previewDevice("iPhone 15 Pro")
    }
}
