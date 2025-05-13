//
//  UserModel.swift
//  YD_App
//
//  Created by Luis Melendez on 24/04/25.
//

import Foundation

struct UserModel: Codable {
    var nombres: String
    var apellidoPaterno: String
    var apellidoMaterno: String
    var numeroCelular: String
    var rolId: String
    var fechaRegistro: Date
}

