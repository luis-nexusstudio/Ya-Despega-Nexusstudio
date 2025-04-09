//
//  CartViewModel.swift
//  YD_App
//
//  Created by Luis Melendez on 04/04/25.
//
import SwiftUI

class CartViewModel: ObservableObject {
    @Published var eventDetails: Details
    @Published var generalTicketCount: Int = 0
    @Published var vipTicketCount: Int = 0
    
    init() {
        self.eventDetails = Details(
            dateEvent: "Jul 29 - Ago 02, 2025",
            location: "Trigo y Miel, León, Guanajuato",
            details: "Permite el acceso a Ya Despega durante los tres días. Los miembros VIP pueden asistir a conferencias especiales y tener acceso anticipado al area de comidas.",
            terms: [
                "Se requiere registro para obtener una pulsera.",
                "La pulsera no tendrá validez si se manipula o se quita.",
                "La pulsera es única e intransferible."
            ],
            generalPrice: 500,
            vipPrice: 600,
            serviceFee: 0.04
            
        )
    }
    
    var totalTickets: Int {
        generalTicketCount + vipTicketCount
    }

    var subTotalPrice: Double {
        Double(generalTicketCount) * eventDetails.generalPrice +
        Double(vipTicketCount) * eventDetails.vipPrice
    }

    var serviceFeeAmount: Double {
        subTotalPrice * eventDetails.serviceFee // donde serviceFee es 0.04
    }

    var totalPrice: Double {
        subTotalPrice + serviceFeeAmount
    }
    
    // En CartViewModel:
    func addTickets(type: TicketType, count: Int) {
        guard count > 0 else { return }
        if type == .general {
            generalTicketCount += count
        } else {
            vipTicketCount += count
        }
    }
    
    func clearCart() {
        generalTicketCount = 0
        vipTicketCount = 0
    }
    
}

enum TicketType {
    case general
    case vip
}
