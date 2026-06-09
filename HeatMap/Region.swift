import Foundation
import CoreLocation

struct Region: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let center: CLLocation
}

struct Activity: Identifiable {
    let id = UUID()
    let name: String
    let coordinates: [CLLocationCoordinate2D]
    
    // Computed property to convert the first coordinate to a CLLocation object
    var startLocation: CLLocation? {
        guard let firstCoord = coordinates.first else { return nil }
        return CLLocation(latitude: firstCoord.latitude, longitude: firstCoord.longitude)
    }
}