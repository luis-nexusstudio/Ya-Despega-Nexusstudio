//
//  HomeModel.swift
//  YD_App
//
//  Created by Luis Melendez on 20/03/25.
//

import Foundation
import MapKit

// MARK: - Data Models
struct Event {
    let title: String
    let dateRange: String
    let description: String
    let location: CLLocationCoordinate2D
}

struct Speaker: Identifiable {
    let id: String
    let name: String
    let iconName: String
    let bio: String?
}
