//
//  MainCoordinator.swift
//  YD_App
//
//  Created by Luis Melendez on 25/03/25.
//

import SwiftUI

class MainCoordinator: ObservableObject {
    @Published var currentView: AnyView

    init() {
        // Inicialmente muestra la vista principal
        self.currentView = AnyView(MainView())
    }
}
