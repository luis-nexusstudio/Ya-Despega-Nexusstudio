//
//  AppCoordinator.swift
//  YD_App
//
//  Created by Luis Melendez on 20/03/25.
//


import SwiftUI
import Combine

class AppCoordinator: ObservableObject {
    @Published var currentView: AnyView = AnyView(SplashScreenView()) // 👈 inicia con splash
    private var loginCoordinator: LoginCoordinator?

    init() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
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
