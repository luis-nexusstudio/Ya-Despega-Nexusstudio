//
//  YD_AppApp.swift
//  YD_App
//
//  Created by Luis Melendez on 20/03/25.
//

import SwiftUI

@main
struct YD_AppApp: App {
    @StateObject private var appCoordinator = AppCoordinator()

        var body: some Scene {
            WindowGroup {
                appCoordinator.currentView
            }
        }
}
