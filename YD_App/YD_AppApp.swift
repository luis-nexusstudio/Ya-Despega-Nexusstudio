//
//  YD_AppApp.swift
//  YD_App
//
//  Created by Luis Melendez on 20/03/25.
//

import SwiftUI
import FirebaseCore

@main
struct YD_AppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appCoordinator = AppCoordinator()
    @StateObject private var paymentCoordinator = PaymentCoordinator()
    @StateObject private var cartViewModel = CartViewModel(eventId: "8avevXHoe4aXoMQEDOic")

    init() {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.black

        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            appCoordinator.currentView
                .environmentObject(paymentCoordinator)
                .environmentObject(cartViewModel)
        }
    }
}
