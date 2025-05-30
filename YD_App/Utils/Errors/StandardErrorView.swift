//
//  StandardErrorView.swift
//  YD_App
//
//  Created by Luis Melendez on 27/05/25.
//


import SwiftUI

// MARK: - Error Type Extension
enum AppError: Error, LocalizedError {
    case noInternet
    case serverUnreachable  // 🚀 nuevo
    case serverError
    case unauthorized
    case notFound
    case timeout
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .noInternet:
            return "Error de conexión. Verifica tu internet."
        case .serverUnreachable:
            return "No se pudo conectar al servidor. Intenta más tarde."
        case .serverError:
            return "Error del servidor. Intenta más tarde."
        case .unauthorized:
            return "Sesión expirada. Inicia sesión nuevamente."
        case .notFound:
            return "No se encontró la información solicitada."
        case .timeout:
            return "Tiempo de espera agotado. Intenta nuevamente."
        case .unknown(let message):
            return message
        }
    }
    
    var icon: String {
        switch self {
        case .noInternet:
            return "wifi.slash"
        case .serverUnreachable:
            return "antenna.radiowaves.left.and.right"
        case .serverError:
            return "exclamationmark.icloud"
        case .unauthorized:
            return "lock.shield"
        case .notFound:
            return "magnifyingglass.circle"
        case .timeout:
            return "clock.badge.exclamationmark"
        case .unknown:
            return "exclamationmark.triangle"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .noInternet, .serverUnreachable:
            return .red
        case .serverError:
            return .orange
        case .unauthorized:
            return .yellow
        case .notFound:
            return .gray
        case .timeout:
            return .orange
        case .unknown:
            return .orange
        }
    }
}

// MARK: - Standard Error View
struct StandardErrorView: View {
    let error: AppError
    var isRetrying: Bool = false
    let onRetry: () -> Void

    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: error.icon)
                .font(.system(size: 60))
                .foregroundColor(error.iconColor)
            
            Text(error.errorDescription ?? "Error desconocido")
                .font(.headline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: onRetry) {
                HStack {
                    if isRetrying {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    Text(isRetrying ? "Reintentando..." : "Reintentar")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .padding()
                .frame(minWidth: 120)
                .background(Color("PrimaryColor"))
                .cornerRadius(12)
            }
            .disabled(isRetrying)
            .opacity(isRetrying ? 0.8 : 1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Empty State View Reutilizable
struct StandardEmptyStateView: View {
    let title: String
    let message: String
    let icon: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        title: String,
        message: String,
        icon: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.icon = icon
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(Font.system(size: 80))
                .foregroundColor(Color("PrimaryColor"))
            
            Text(title)
                .font(Font.title2.bold())
                .foregroundColor(.white)
            
            Text(message)
                .font(Font.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(Font.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(minWidth: 120)
                        .background(Color("PrimaryColor"))
                        .cornerRadius(12)
                }
                .padding(.top, 10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Loading View Reutilizable
struct StandardLoadingView: View {
    let message: String
    
    init(message: String = "Cargando...") {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color("PrimaryColor")))
                .scaleEffect(1.2)
            
            Text(message)
                .font(Font.headline)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Extension para convertir errores
extension Error {
    func toAppError() -> AppError {
        
        if let orderError = self as? OrderError {
                switch orderError {
                    case .unauthorized:
                        return .unauthorized
                    case .notFound:
                        return .notFound
                    case .timeout:
                        return .timeout
                    case .noInternet:               // ← NUEVO
                        return .noInternet
                    case .serverUnreachable:        // ← NUEVO
                        return .serverUnreachable
                    case .serverError:              // ← NUEVO
                        return .serverError
                    case .requestFailed:
                        return .serverUnreachable   // ← CAMBIO: ya no es .noInternet
                    default:
                        return .serverError
                    }
                }
        
        if let nsError = self as NSError? {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet,
                 NSURLErrorNetworkConnectionLost:
                return .noInternet
            case -1004: // 🚀 server unreachable
                return .serverUnreachable
            case 1: // 🚀 server unreachable
                return .serverUnreachable
            case NSURLErrorTimedOut:
                return .timeout
            case 401:
                return .unauthorized
            case 404:
                return .notFound
            case 500...599:
                return .serverError
            default:
                return .unknown(nsError.localizedDescription)
            }
        }
        return .unknown(self.localizedDescription)
    }
}

