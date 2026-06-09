struct Activity: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let coordinates: [CLLocationCoordinate2D]
    let date: Date
    
    // Helper to get the starting location
    var startCoordinate: CLLocationCoordinate2D? {
        coordinates.first
    }
}