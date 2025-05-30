//
//  CartModel.swift
//  YD_App
//
//  Created by Luis Melendez on 04/04/25.
//
import Foundation

// MARK: - Estructura para ubicación (coincide con el JSON del Event Details API)
struct UbicacionEvento: Decodable {
    let ubicacion_nombre: String
    let ubicacion_lat: Double
    let ubicacion_lng: Double
}

// MARK: - EventDetails corregido para Event Details API
struct EventDetails: Decodable {
    let id: String
    let nombre: String
    let fecha_inicio: FirebaseTimestamp  // ✅ Usa FirebaseTimestamp del HomeModel
    let fecha_fin: FirebaseTimestamp
    let ubicacion: UbicacionEvento  // ✅ CORREGIDO: Ahora es un objeto
    let estatus_activo: Bool
    let cuota_servicio: Double
    let detalles: String
    let terminos: [String]
    let tickets: [Ticket]
    
    // Computed properties para compatibilidad con código existente
    var ubicacionNombre: String {
        return ubicacion.ubicacion_nombre
    }
    
    var coordenadas: Coordenadas {  // ✅ Usa Coordenadas del HomeModel
        return Coordenadas(lat: ubicacion.ubicacion_lat, lng: ubicacion.ubicacion_lng)
    }
    
    // Computed properties para fechas (compatibilidad)
    var fechaInicio: FirebaseTimestamp { fecha_inicio }
    var fechaFin: FirebaseTimestamp { fecha_fin }
}

struct Ticket: Decodable, Identifiable {
    let id: String
    let descripcion: String
    let tipo: String
    let precio: Double
    let disponibilidad: Int
    let beneficios: [String]?
}
