//
//  AppErrorProtocol.swift
//  YD_App
//
//  Created by Luis Melendez on 02/06/25.
//

import Foundation
import SwiftUI

// MARK: - App Error Protocol
protocol AppErrorProtocol: Error {
    var userMessage: String { get }
    var errorCode: String { get }
    var shouldRetry: Bool { get }
    var icon: String { get }
    var iconColor: Color { get }
    var logMessage: String { get }
}

// MARK: - Error Severity
enum ErrorSeverity {
    case low
    case medium
    case high
    case critical
    
    var logLevel: String {
        switch self {
        case .low: return "INFO"
        case .medium: return "WARN"
        case .high: return "ERROR"
        case .critical: return "CRITICAL"
        }
    }
}

// MARK: - Common App Error (Unifica AppError)
enum CommonAppError: AppErrorProtocol {
    case noInternet
    case serverUnreachable
    case serverError
    case unauthorized
    case notFound
    case timeout
    case unknown(String)
    case validationFailed(String)
    case emailAlreadyExists
    case weakPassword
    
    // MARK: - AppErrorProtocol Implementation
    var userMessage: String {
        switch self {
        case .noInternet:
            return "Sin conexión a internet. Verifica tu conexión e intenta nuevamente."
        case .serverUnreachable:
            return "No se pudo conectar al servidor. Intenta más tarde."
        case .serverError:
            return "Error del servidor. Intenta nuevamente en unos minutos."
        case .unauthorized:
            return "Tu sesión ha expirado. Inicia sesión nuevamente."
        case .notFound:
            return "La información solicitada no fue encontrada."
        case .timeout:
            return "La operación tardó demasiado. Intenta nuevamente."
        case .unknown(let message):
            return message
        case .validationFailed(let message):
            return message
        case .emailAlreadyExists:
            return "Este correo ya está registrado. Intenta con otro."
        case .weakPassword:
            return "La contraseña no cumple los requisitos de seguridad."
        }
    }
    
    var errorCode: String {
        switch self {
        case .noInternet: return "NET_001"
        case .serverUnreachable: return "NET_002"
        case .serverError: return "SRV_001"
        case .unauthorized: return "AUTH_001"
        case .notFound: return "SRV_002"
        case .timeout: return "NET_003"
        case .unknown: return "GEN_001"
        case .validationFailed: return "VAL_001"
        case .emailAlreadyExists: return "VAL_002"
        case .weakPassword: return "VAL_003"
        }
    }
    
    var shouldRetry: Bool {
        switch self {
        case .noInternet, .serverUnreachable, .timeout: return true
        case .serverError: return true
        case .unauthorized, .notFound: return false
        case .validationFailed, .emailAlreadyExists, .weakPassword: return false
        case .unknown: return false
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
        case .validationFailed, .emailAlreadyExists, .weakPassword:
            return "exclamationmark.triangle"
        case .unknown:
            return "questionmark.circle"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .noInternet, .serverUnreachable:
            return .red
        case .serverError, .timeout:
            return .orange
        case .unauthorized:
            return .yellow
        case .notFound:
            return .gray
        case .validationFailed, .emailAlreadyExists, .weakPassword:
            return .red
        case .unknown:
            return .blue
        }
    }
    
    var logMessage: String {
        return "[\(errorCode)] \(userMessage)"
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .validationFailed, .emailAlreadyExists, .weakPassword:
            return .low
        case .notFound, .timeout:
            return .medium
        case .noInternet, .serverUnreachable, .serverError:
            return .high
        case .unauthorized:
            return .high
        case .unknown:
            return .medium
        }
    }
}
