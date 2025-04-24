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
    @StateObject private var appCoordinator = AppCoordinator()

    init() {
        print("CLIENT ID:", FirebaseApp.app()?.options.clientID ?? "NO CLIENT ID")
        FirebaseApp.configure()
    
    }
    var body: some Scene {
        WindowGroup {
            appCoordinator.currentView
        }
    }
}
