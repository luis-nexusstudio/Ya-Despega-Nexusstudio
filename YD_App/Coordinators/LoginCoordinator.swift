//
//  LoginCoordinator.swift
//  YD_App
//
//  Created by Luis Melendez on 22/04/25.
//

import SwiftUI

class LoginCoordinator: ObservableObject {
    @Published var currentView: AnyView
    var onLoginSuccess: () -> Void

    init(onLoginSuccess: @escaping () -> Void) {
        self.onLoginSuccess = onLoginSuccess
        let loginView = LoginView(onLoginSuccess: onLoginSuccess)
        self.currentView = AnyView(loginView)
    }
}
