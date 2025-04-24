//
//  AppCoordinator.swift
//  YD_App
//
//  Created by Luis Melendez on 20/03/25.
//


import SwiftUI
import Combine

class AppCoordinator: ObservableObject {
    @Published var currentView: AnyView = AnyView(EmptyView()) // Valor por defecto
    
    private var loginCoordinator: LoginCoordinator?

    init() {
        // Llama a showLogin después de que self se inicialice completamente
        DispatchQueue.main.async {
            self.showLogin()
        }
    }

    func showLogin() {
        loginCoordinator = LoginCoordinator(onLoginSuccess: {
            self.showMainView()
        })
        self.currentView = loginCoordinator!.currentView
    }

    func showMainView() {
        self.currentView = AnyView(MainView())
    }
}
