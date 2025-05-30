//
//  MainView.swift
//  YD_App
//
//  NUEVA ARQUITECTURA - Updated by Luis Melendez on 26/05/25.
//

import SwiftUI

struct MainView: View {
    // 🔧 RECIBE TODOS LOS ENVIRONMENT OBJECTS
    @EnvironmentObject var cartViewModel: CartViewModel
    @EnvironmentObject var eventViewModel: EventViewModel  // ← NUEVO
    @EnvironmentObject var homeViewModel: HomeViewModel    // ← AGREGADO

    @State private var selectedTab = 0

    var body: some View {
        BackgroundGeneralView {
            TabView(selection: $selectedTab) {
                HomeView(selectedTab: $selectedTab)
                    .tabItem { Label("Inicio", systemImage: "house.fill") }
                    .tag(0)

                CartView(selectedTab: $selectedTab)
                    .tabItem {
                        Label(
                          "Carrito",
                          // 🔧 USAR EVENTVIEWMODEL PARA CALCULAR TOTAL
                          systemImage: totalTicketsInCart > 0
                            ? "cart.fill.badge.plus"
                            : "cart"
                        )
                    }
                    .tag(1)
                    .badge(totalTicketsInCart) // ← USAR COMPUTED PROPERTY

                MyTicketsView()
                    .tabItem { Label("Boletos", systemImage: "ticket.fill") }
                    .tag(2)

                ProfileView()
                    .tabItem { Label("Perfil", systemImage: "person.fill") }
                    .tag(3)
            }
            .tint(Color("PrimaryColor"))
            .background(Color.black.opacity(0.001))
        }
    }
    
    // 🔧 COMPUTED PROPERTY PARA TOTAL DE TICKETS
    private var totalTicketsInCart: Int {
        cartViewModel.totalTickets(for: eventViewModel.eventDetails)
    }
}

struct MainView_Previews: PreviewProvider {
    @State static var selectedTab = 0

    static var previews: some View {
        MainView()
            .environmentObject(CartViewModel())
            .environmentObject(EventViewModel(eventId: "8avevXHoe4aXoMQEDOic"))
            .environmentObject(HomeViewModel(eventId: "8avevXHoe4aXoMQEDOic"))
            .previewDevice("iPhone 15 Pro")
    }
}

