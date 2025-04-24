//
//  CartModel.swift
//  YD_App
//
//  Created by Luis Melendez on 04/04/25.
//
import Foundation

struct Details {
    let dateEvent: String
    let location: String
    let details: String
    let terms: [String]
    let generalPrice: Double
    let vipPrice: Double
    let serviceFee: Double
}

struct TicketSection {
    let type: String
    let count: Int
}
