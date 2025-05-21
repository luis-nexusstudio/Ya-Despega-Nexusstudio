//
//  MainView.swift
//  YD_App
//
//  Created by Luis Melendez on 20/03/25.
//

import SwiftUI

struct MainView: View {
    // 1) Recibe los env–objects, no los creas aquí
    @EnvironmentObject var cartViewModel: CartViewModel
    @EnvironmentObject var paymentCoordinator: PaymentCoordinator

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
                          systemImage: cartViewModel.totalTickets > 0
                            ? "cart.fill.badge.plus"
                            : "cart"
                        )
                    }
                    .tag(1)
                    .badge(cartViewModel.totalTickets)

                MyTicketsView()
                    .tabItem { Label("Tickets", systemImage: "ticket.fill") }
                    .tag(2)

                ProfileView()
                    .tabItem { Label("Perfil", systemImage: "person.fill") }
                    .tag(3)
            }
            .tint(Color("PrimaryColor"))
            .background(Color.black.opacity(0.001))
        }
    }
}

struct MainView_Previews: PreviewProvider {
    @State static var selectedTab = 0

    static var previews: some View {
        MainView()
        .previewDevice("iPhone 15 Pro")
    }
}

