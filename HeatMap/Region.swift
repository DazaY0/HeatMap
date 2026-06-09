//
//  Region.swift
//  HeatMap
//
//  Created by Jonas Hafner on 09.06.26.
//


import Foundation
import CoreLocation

struct Region: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    let latitude: Double
    let longitude: Double
        
    var center: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
        
    init(id: UUID = UUID(), name: String, latitude: Double, longitude: Double) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
    }
}
