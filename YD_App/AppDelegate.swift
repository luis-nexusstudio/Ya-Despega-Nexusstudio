//
//  AppDelegate.swift
//  YD_App
//
//  Created by Luis Melendez on 13/05/25.
//

// AppDelegate.swift
import UIKit

// Notificaciones para comunicarte con SwiftUI
extension Notification.Name {
    static let checkoutSuccess = Notification.Name("checkoutSuccess")
    static let checkoutPending = Notification.Name("checkoutPending")
    static let checkoutFailure = Notification.Name("checkoutFailure")
}

class AppDelegate: NSObject, UIApplicationDelegate {
    // Este método se llama cuando alguien hace UIApplication.shared.open(URL)
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        print("AppDelegate open URL -> scheme: \(url.scheme ?? "nil"), host: \(url.host ?? "nil")")
        guard url.scheme == "ydapp" else { return false }

        switch url.host {
        case "success":
            print("AppDelegate: detected payment SUCCESS deep link")
            NotificationCenter.default.post(name: .checkoutSuccess, object: nil)
        case "pending":
            print("AppDelegate: detected payment PENDING deep link")
            NotificationCenter.default.post(name: .checkoutPending, object: nil)
        case "failure":
            print("AppDelegate: detected payment FAILURE deep link")
            NotificationCenter.default.post(name: .checkoutFailure, object: nil)
        default:
            break
        }
        return true
    }
}
