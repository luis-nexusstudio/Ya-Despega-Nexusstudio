//
//  AppDelegate.swift
//  YD_App
//
//  Created by Luis Melendez on 13/05/25.
//

import UIKit

// Notificaciones para comunicarte con SwiftUI
extension Notification.Name {
    static let checkoutSuccess = Notification.Name("checkoutSuccess")
    static let checkoutPending = Notification.Name("checkoutPending")
    static let checkoutFailure = Notification.Name("checkoutFailure")
}

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        
        return true
    }
}
