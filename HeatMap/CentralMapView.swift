import SwiftUI
import MapKit

struct CentralMapView: View {
    @StateObject private var manager = HeatmapManager()
    @State private var selectedRegionName: String? = "Vienna"
    
    var body: some View {
        NavigationSplitView {
            // Include predefined regions plus "Other" if it contains activities
            let availableKeys = Array(manager.sortedActivities.keys).sorted()
            
            List(availableKeys, id: \.self, selection: $selectedRegionName) { regionName in
                NavigationLink(value: regionName) {
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                        Text(regionName)
                        Spacer()
                        Text("\(manager.sortedActivities[regionName]?.count ?? 0)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Locations")
        } detail: {
            if let selectedRegionName, let activities = manager.sortedActivities[selectedRegionName] {
                Map {
                    ForEach(activities) { activity in
                        MapPolyline(coordinates: activity.coordinates)
                            .stroke(Color.orange.opacity(0.1), lineWidth: 3)
                    }
                }
                .mapStyle(.standard(darkWithLabels: true))
                .navigationTitle("\(selectedRegionName) Map")
            } else {
                ContentUnavailableView("No Activities Tracked", systemImage: "map.dash")
            }
        }
        .onAppear {
            // Mock data insertion for testing logic on launch
            loadSampleData()
        }
    }
    
    private func loadSampleData() {
        // Example track in Vienna
        let viennaTrack = [
            CLLocationCoordinate2D(latitude: 48.2100, longitude: 16.3700),
            CLLocationCoordinate2D(latitude: 48.2200, longitude: 16.3800)
        ]
        // Example track in South Tyrol (Brixen area)
        let southTyrolTrack = [
            CLLocationCoordinate2D(latitude: 46.7100, longitude: 11.6500),
            CLLocationCoordinate2D(latitude: 46.7200, longitude: 11.6600)
        ]
        
        manager.processNewActivity(Activity(name: "Morning Run Vienna", coordinates: viennaTrack))
        manager.processNewActivity(Activity(name: "Alps Trail Ride", coordinates: southTyrolTrack))
    }
}