//
//  Extension.swift
//  YD_App
//
//  Created by Luis Melendez on 21/05/25.
//

import Foundation
import SwiftUI

// MARK: - String Extensions
extension String {
    /// Formatea una fecha ISO8601 para mostrar en las órdenes
    func formatAsOrderDate() -> String {
        // Intentar múltiples formatos de fecha
        let formatters = [
            // ISO 8601 con fracciones de segundo
            { () -> DateFormatter in
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                return formatter
            }(),
            // ISO 8601 sin fracciones
            { () -> DateFormatter in
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                return formatter
            }(),
            // Formato básico
            { () -> DateFormatter in
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                return formatter
            }()
        ]
        
        for formatter in formatters {
            if let date = formatter.date(from: self) {
                let displayFormatter = DateFormatter()
                displayFormatter.dateStyle = .medium
                displayFormatter.timeStyle = .short
                displayFormatter.locale = Locale(identifier: "es_MX")
                return displayFormatter.string(from: date)
            }
        }
        
        // Si ningún formato funciona, intentar con ISO8601DateFormatter
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = isoFormatter.date(from: self) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            displayFormatter.locale = Locale(identifier: "es_MX")
            return displayFormatter.string(from: date)
        }
        
        return "Fecha inválida"
    }
}

// MARK: - Sorting Options
enum OrderSortOption: String, CaseIterable {
    case dateDesc = "Más recientes"
    case dateAsc = "Más antiguos"
    case statusApproved = "Aprobados primero"
    case statusPending = "Pendientes primero"
    case priceDesc = "Mayor precio"
    case priceAsc = "Menor precio"
    
    var icon: String {
        switch self {
        case .dateDesc, .dateAsc:
            return "calendar"
        case .statusApproved, .statusPending:
            return "checkmark.circle"
        case .priceDesc, .priceAsc:
            return "dollarsign.circle"
        }
    }
}


// MARK: - Order Extensions (propiedades adicionales, no duplicadas)
extension Order {
    /// Descripción del método de pago más reciente
    var paymentMethodDescription: String {
        guard let latestAttempt = payment_attempts?.last,
              let method = latestAttempt.method else {
            return "Sin información de pago"
        }
        
        switch method.lowercased() {
        case "oxxo": return "OXXO"
        case "spei": return "Transferencia SPEI"
        case "account_money": return "Dinero en cuenta"
        case "credit_card": return "Tarjeta de crédito"
        case "debit_card": return "Tarjeta de débito"
        case "visa": return "Visa"
        case "mastercard": return "Mastercard"
        case "amex": return "American Express"
        default: return method.capitalized
        }
    }
    
    /// Estado más detallado del pago
    var detailedPaymentStatus: String {
        guard let latestAttempt = payment_attempts?.last else {
            return "Sin intentos de pago"
        }
        
        switch latestAttempt.status.lowercased() {
        case "approved": return "Pago aprobado"
        case "pending": return "Pago pendiente"
        case "rejected": return "Pago rechazado"
        case "cancelled": return "Pago cancelado"
        case "charged_back": return "Contracargo"
        case "refunded": return "Reembolsado"
        default: return latestAttempt.status.capitalized
        }
    }
    
    /// Ícono que representa el estado
    var statusIcon: String {
        switch status.lowercased() {
        case "approved": return "checkmark.circle.fill"
        case "pending": return "clock.circle.fill"
        case "rejected", "cancelled": return "xmark.circle.fill"
        default: return "questionmark.circle.fill"
        }
    }
    
    /// Indica si la orden puede ser cancelada
    var canBeCancelled: Bool {
        return status.lowercased() == "pending"
    }
    
    /// Total formateado como moneda mexicana
    var formattedTotal: String {
        return total.formatted(.currency(code: "MXN"))
    }
}

// MARK: - PaymentAttempt Extensions
extension PaymentAttempt {
    /// Descripción legible del estado del intento de pago
    var localizedStatusDetail: String {
        guard let detail = status_detail else { return status.capitalized }
        
        switch detail.lowercased() {
        case "pending_contingency": return "Validación pendiente"
        case "pending_review_manual": return "Revisión manual"
        case "cc_rejected_insufficient_amount": return "Fondos insuficientes"
        case "cc_rejected_bad_filled_security_code": return "Código de seguridad incorrecto"
        case "cc_rejected_bad_filled_date": return "Fecha de vencimiento incorrecta"
        case "cc_rejected_bad_filled_other": return "Datos incorrectos"
        case "cc_rejected_high_risk": return "Transacción de alto riesgo"
        default: return detail.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}

// MARK: - URL Extensions
extension URL: Identifiable {
    public var id: String { absoluteString }
}

// MARK: - Double Extensions
extension Double {
    /// Formatea el número como moneda mexicana
    var asMXNCurrency: String {
        return self.formatted(.currency(code: "MXN"))
    }
}

// Extension para formatear rangos de fechas
extension Date {
    func formatDateRange(to endDate: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_MX") // Para español mexicano
        
        // Verificar si están en el mismo año
        let sameYear = calendar.component(.year, from: self) == calendar.component(.year, from: endDate)
        
        // Verificar si están en el mismo mes
        let sameMonth = calendar.component(.month, from: self) == calendar.component(.month, from: endDate) && sameYear
        
        if sameMonth {
            // Mismo mes: "Jul 29 - 02, 2025"
            formatter.dateFormat = "MMM d"
            let startFormatted = formatter.string(from: self)
            
            formatter.dateFormat = "d, yyyy"
            let endFormatted = formatter.string(from: endDate)
            
            return "\(startFormatted) - \(endFormatted)"
        } else if sameYear {
            // Diferente mes, mismo año: "Jul 29 - Ago 02, 2025"
            formatter.dateFormat = "MMM d"
            let startFormatted = formatter.string(from: self)
            
            formatter.dateFormat = "MMM d, yyyy"
            let endFormatted = formatter.string(from: endDate)
            
            return "\(startFormatted) - \(endFormatted)"
        } else {
            // Diferente año: "Jul 29, 2025 - Ene 02, 2026"
            formatter.dateFormat = "MMM d, yyyy"
            let startFormatted = formatter.string(from: self)
            let endFormatted = formatter.string(from: endDate)
            
            return "\(startFormatted) - \(endFormatted)"
        }
    }
}

struct FirebaseTimestamp: Decodable {
    let _seconds: Int
    let _nanoseconds: Int

    var date: Date {
        Date(timeIntervalSince1970: TimeInterval(_seconds))
    }
}

