//
//  CartModel.swift
//  YD_App
//
//  Created by Luis Melendez on 04/04/25.
//
import Foundation

struct EventDetails: Decodable {
    let id: String
    let nombre: String
    let fecha_inicio: FirebaseTimestamp
    let fecha_fin: FirebaseTimestamp
    let ubicacion: String
    let estatus_activo: Bool
    let cuota_servicio: Double
    let detalles: String
    let terminos: [String]
    let tickets: [Ticket]
}

struct FirebaseTimestamp: Decodable {
    let _seconds: Int
    let _nanoseconds: Int

    var date: Date {
        Date(timeIntervalSince1970: TimeInterval(_seconds))
    }
}

struct Ticket: Decodable, Identifiable {
  let id: String
  let descripcion: String
  let tipo: String
  let precio: Double
  let disponibilidad: Int
  let beneficios: [String]?
}
