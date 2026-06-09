class HeatmapManager: ObservableObject {
    // Define your base regions with center coordinates
    @Published var regions: [Region] = [
        Region(name: "Vienna", center: CLLocation(latitude: 48.2082, longitude: 16.3738)),
        Region(name: "South Tyrol", center: CLLocation(latitude: 46.7150, longitude: 11.6560))
    ]
    
    // Dictionary to hold sorted activities: [Region Name: [Activities]]
    @Published var sortedActivities: [String: [Activity]] = [:]
    
    func processNewActivity(_ activity: Activity) {
        guard let startLoc = activity.startLocation else { return }
        
        let fiftyKilometers: CLLocationDistance = 50_000 
        
        // Find the closest region within the 50km threshold
        let bestMatch = regions
            .map { (region: $0, distance: $0.center.distance(from: startLoc)) }
            .filter { $0.distance <= fiftyKilometers }
            .min(by: { $0.distance < $1.distance })?
            .region
        
        // Fallback to "Other" if no region matches the 50km criteria
        let targetRegionName = bestMatch?.name ?? "Other"
        
        DispatchQueue.main.async {
            self.sortedActivities[targetRegionName, default: []].append(activity)
        }
    }
}