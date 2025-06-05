//
//  StandardErrorView.swift
//  YD_App
//
//  Created by Luis Melendez on 27/05/25.
//


import SwiftUI

// MARK: - Standard Error View
struct StandardErrorView: View {
    let error: AppErrorProtocol
    var isRetrying: Bool = false
    let onRetry: () -> Void
    
    var body: some View {
        
        if error.errorCode != "CHE_012"{
            VStack(spacing: 20) {
                Image(systemName: error.icon)
                    .font(.system(size: 60))
                    .foregroundColor(error.iconColor)
                
                Text(error.userMessage)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                // 🆕 MOSTRAR CÓDIGO DE ERROR EN DEBUG
                #if DEBUG
                Text("Error: \(error.errorCode)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                #endif
                
                if error.shouldRetry { // ← NUEVA LÓGICA
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
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }else{
            EmailVerificationErrorView(onRetry: onRetry)

        }
        
       
    }
}

struct StandardErrorVerification: View {
    let error: AppErrorProtocol
    var isRetrying: Bool = false
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: error.icon)
                .font(.system(size: 60))
                .foregroundColor(error.iconColor)
            
            Text(error.userMessage)
                .font(.headline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            // 🆕 MOSTRAR CÓDIGO DE ERROR EN DEBUG
            #if DEBUG
            Text("Error: \(error.errorCode)")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
            #endif
            
            if error.shouldRetry { // ← NUEVA LÓGICA
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

extension Error {
    func toAppError() -> AppErrorProtocol {
        // Si ya es un AppErrorProtocol, devolverlo
        if let appError = self as? AppErrorProtocol {
            return appError
        }
        
        // Convertir NSError a CommonAppError
        if let nsError = self as NSError? {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
                return CommonAppError.noInternet
            case NSURLErrorCannotConnectToHost, NSURLErrorCannotFindHost, NSURLErrorDNSLookupFailed:
                return CommonAppError.serverUnreachable
            case NSURLErrorTimedOut:
                return CommonAppError.timeout
            case 401:
                return CommonAppError.unauthorized
            case 404:
                return CommonAppError.notFound
            case 500...599:
                return CommonAppError.serverError
            default:
                return CommonAppError.unknown(nsError.localizedDescription)
            }
        }
        
        // Error genérico
        return CommonAppError.unknown(self.localizedDescription)
    }
}
