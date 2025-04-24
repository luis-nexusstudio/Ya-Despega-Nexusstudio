//
//  HomeViewModel.swift
//  YD_App
//
//  Created by Luis Melendez on 20/03/25.
//

import SwiftUI
import MapKit

class HomeViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var event: Event
    @Published var speakers: [Speaker]
    @Published var region: MKCoordinateRegion
    
    // MARK: - Initialization
    init() {
        // Primero definimos la ubicación que usaremos en ambos lugares
        let eventLocation = CLLocationCoordinate2D(latitude: 21.1236, longitude: -101.6820)
        
        // Inicializamos event
        self.event = Event(
            title: "Ya Despega",
            dateRange: "Jul 29 - Ago 02, 2025",
            description: "Ya Despega es un congreso de 3 días para jóvenes, líderes juveniles, pastores e hijos de pastor. Durante estos días los jóvenes son ministrados y retados a responder al gran llamado que Dios nos ha dado como generación para impactar nuestra nación, y serán provistos de herramientas prácticas espirituales para potencializar sus dones y talentos.",
            location: eventLocation
        )
        
        // Inicializamos speakers
        self.speakers = [
            Speaker(id: "1", name: "Conferencista 1", iconName: "person.fill", bio: nil),
            Speaker(id: "2", name: "Conferencista 2", iconName: "person.fill", bio: nil),
            Speaker(id: "3", name: "Conferencista 3", iconName: "person.fill", bio: nil),
            Speaker(id: "4", name: "Conferencista 4", iconName: "person.fill", bio: nil),
            Speaker(id: "5", name: "Conferencista 5", iconName: "person.fill", bio: nil),
            Speaker(id: "6", name: "Conferencista 6", iconName: "person.fill", bio: nil)
        ]
        
        // Finalmente inicializamos region usando la ubicación que ya definimos
        self.region = MKCoordinateRegion(
            center: eventLocation,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }
    
    // MARK: - Public Methods
    func fetchEventData() async {
        // Aquí iría la lógica para obtener datos reales de la API
        // Por ahora usamos los datos mock
    }
    
    func fetchSpeakers() async {
        // Lógica para obtener speakers reales
    }
}
