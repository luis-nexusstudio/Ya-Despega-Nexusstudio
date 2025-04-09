//
//  AppCoordinator.swift
//  YD_App
//
//  Created by Luis Melendez on 20/03/25.
//


import SwiftUI
import Combine

class AppCoordinator: ObservableObject {
    @Published var currentView: AnyView
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        let mainCoordinator = MainCoordinator()
        self.currentView = AnyView(MainView().environmentObject(mainCoordinator))

    }
}

