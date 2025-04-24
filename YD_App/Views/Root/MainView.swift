//
//  MainView.swift
//  YD_App
//
//  Created by Luis Melendez on 20/03/25.
//

import SwiftUI

struct MainView: View {
    @StateObject private var cartViewModel = CartViewModel()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            CartView()  // Pantalla Carrito de Compras
                .tabItem {
                    Label("Carrito", systemImage: cartViewModel.totalTickets > 0 ? "cart.fill.badge.plus" : "cart")
                }
                .tag(1)
                .badge(cartViewModel.totalTickets > 0 ? cartViewModel.totalTickets : 0)

            MyTicketsView() 
                .tabItem {
                    Label("Mis Tickets", systemImage: "ticket.fill")
                }
                .tag(2)

            
        }
        .environmentObject(cartViewModel)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .environmentObject(CartViewModel())  // Agrega el EnvironmentObject
            .previewDevice( "IPhone 16 Pro")
    }
}
