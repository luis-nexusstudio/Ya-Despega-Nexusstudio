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

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            appCoordinator.currentView
                .environmentObject(paymentCoordinator)
        }
    }
}
