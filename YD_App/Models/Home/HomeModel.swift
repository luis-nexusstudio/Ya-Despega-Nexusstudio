//
//  HomeModel.swift
//  YD_App
//
//  Created by Luis Melendez on 20/03/25.
//

import Foundation
import SwiftUI

// MARK: - Estructuras compartidas (pueden ser usadas por ambos)
struct Coordenadas: Decodable {
    let lat: Double
    let lng: Double
}

struct LineupSpeaker: Decodable, Identifiable {
    let nombre: String
    let informacion: String
    
    var id: String { nombre }
}

// MARK: - 🏠 SOLO MODELOS PARA HOME API
struct HomeEventResponse: Decodable {
    let success: Bool
    let data: HomeEventData?
    let error: String?
    let message: String?
}

struct HomeEventData: Decodable {
    let id: String
    let fecha_inicio: FirebaseTimestamp
    let fecha_fin: FirebaseTimestamp
    let informacion_evento: String  // ✅ Campo correcto para Home API
    let lineup: [LineupSpeaker]?  // ✅ Array directo desde backend
    let ubicacion: String  // ✅ String simple para Home API
    let coordenadas: Coordenadas  // ✅ Objeto separado para Home API
    let nombre: String
    let terminos: [String]
    
    // Computed properties para compatibilidad
    var fechaInicio: FirebaseTimestamp { fecha_inicio }
    var fechaFin: FirebaseTimestamp { fecha_fin }
    var ubicacionNombre: String { ubicacion }
}
