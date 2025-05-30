//
//  OrdersModel.swift
//  YD_App
//
//  Created by Luis Melendez on 22/05/25.
//

import Foundation
import SwiftUI

// MARK: - Models
struct Order: Decodable, Hashable, Identifiable {
    let id: String
    let items: [OrderItem]
    let total: Double
    let status: String
    let createdAt: String?
    let payment_attempts: [PaymentAttempt]?
    let external_reference: String?
    
    // MARK: - Computed Properties (mantener aquí, no duplicar en extensiones)
    var localizedStatus: String {
        switch status.lowercased() {
        case "approved": return "Aprobado"
        case "pending": return "Pendiente"
        case "rejected": return "Rechazado"
        case "cancelled": return "Cancelado"
        case "failure": return "Fallido"
        default: return status.capitalized
        }
    }
    
    var statusColor: Color {
        switch status.lowercased() {
        case "approved": return .green
        case "pending": return .orange
        case "rejected", "cancelled", "failure": return .red
        default: return .gray
        }
    }
    
    var hasPaymentAttempts: Bool {
        return !(payment_attempts?.isEmpty ?? true)
    }
    
    var isProcessed: Bool {
        return status.lowercased() != "pending" || hasPaymentAttempts
    }
    
    // MARK: - Additional computed properties
    var itemCount: Int {
        return items.reduce(0) { $0 + $1.qty }
    }
    
    var displayDate: String {
        return createdAt?.formatAsOrderDate() ?? "Sin fecha"
    }
}

struct OrderItem: Decodable, Hashable {
    let name: String
    let qty: Int

    enum CodingKeys: String, CodingKey {
        case name = "title"
        case qty = "quantity"
    }
}

struct PaymentAttempt: Decodable, Hashable {
    let id: Int?           // ← Cambiar de String? a Int?
    let method: String?
    let status: String
    let status_detail: String?
    let createdAt: String?
    let type: String?
    
    enum CodingKeys: String, CodingKey {
        case id           // ← FALTABA ESTA LÍNEA
        case method
        case status
        case type
        case status_detail
        case createdAt
    }
}
