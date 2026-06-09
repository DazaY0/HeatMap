//
//  HeatmapManager.swift
//  HeatMap
//
//  Created by Jonas Hafner on 09.06.26.
//
import SwiftUI
import CoreLocation
import Combine

class HeatmapManager: ObservableObject {
    @Published var regions: [Region] = []
    @Published var sortedActivities: [String: [Activity]] = [:]
    @Published var globalFrequency: [String: Int] = [:]
    
    // UI binding hooks for resolving locations
    @Published var unresolvedActivity: Activity? = nil
    
    var maxFrequency: Int { globalFrequency.values.max() ?? 1 }
    private let gpxParser = GPXParser()
    
    private var saveURL: URL {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appPath = paths[0].appendingPathComponent("MacHeatMap")
        try? FileManager.default.createDirectory(at: appPath, withIntermediateDirectories: true)
        return appPath.appendingPathComponent("state.json")
    }
    
    struct SaveState: Codable {
        let regions: [Region]
        let sortedActivities: [String: [Activity]]
        let globalFrequency: [String: Int]
    }
    
    init() {
        loadFromDisk()
    }
    
    func importGPXFile(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        
        let coords = gpxParser.parseGPX(at: url)
        guard !coords.isEmpty else { return }
        
        let activityName = url.deletingPathExtension().lastPathComponent
        let newActivity = Activity(name: activityName, coordinates: coords)
        
        processNewActivity(newActivity)
    }
    
    func processNewActivity(_ activity: Activity) {
        guard let startLoc = activity.startLocation else { return }
        let fiftyKilometers: CLLocationDistance = 50_000
        
        let bestMatch = regions
            .map { (region: $0, distance: $0.center.distance(from: startLoc)) }
            .filter { $0.distance <= fiftyKilometers }
            .min(by: { $0.distance < $1.distance })?.region
        
        if let matchedRegion = bestMatch {
            finalizeActivityAssignment(activity, regionName: matchedRegion.name)
        } else {
            // No region nearby! Suspend assignment and trigger the setup popup modal
            DispatchQueue.main.async {
                self.unresolvedActivity = activity
            }
        }
    }
    
    // Explicit router called by the UI when setting locations up manually
    func finalizeActivityAssignment(_ activity: Activity, regionName: String) {
        var uniqueCells = Set<String>()
        for coord in activity.coordinates {
            uniqueCells.insert(Activity.gridKey(for: coord))
        }
        
        DispatchQueue.main.async {
            for key in uniqueCells {
                self.globalFrequency[key, default: 0] += 1
            }
            self.sortedActivities[regionName, default: []].append(activity)
            self.saveToDisk()
        }
    }
    
    func createNewRegion(name: String, coord: CLLocationCoordinate2D) {
        let newRegion = Region(name: name, latitude: coord.latitude, longitude: coord.longitude)
        DispatchQueue.main.async {
            self.regions.append(newRegion)
            self.saveToDisk()
        }
    }
    
    // MARK: - Disk I/O Encoding
    func saveToDisk() {
        do {
            let state = SaveState(regions: regions, sortedActivities: sortedActivities, globalFrequency: globalFrequency)
            let data = try JSONEncoder().encode(state)
            try data.write(to: saveURL, options: .atomic)
        } catch {
            print("Failed to store heatmap history: \(error.localizedDescription)")
        }
    }
    
    private func loadFromDisk() {
        FileManager.default.fileExists(atPath: saveURL.path)
        do {
            let data = try Data(contentsOf: saveURL)
            let state = try JSONDecoder().decode(SaveState.self, from: data)
            self.regions = state.regions
            self.sortedActivities = state.sortedActivities
            self.globalFrequency = state.globalFrequency
        } catch {
            print("Error parsing layout cache file: \(error.localizedDescription)")
        }
    }
    func deleteActivity(_ activity: Activity, from regionName: String) {
        var uniqueCells = Set<String>()
        for coord in activity.coordinates {
            uniqueCells.insert(Activity.gridKey(for: coord))
        }
        
        DispatchQueue.main.async {
            // 1. Clean up the global heatmap frequency grid
            for key in uniqueCells {
                if let currentCount = self.globalFrequency[key] {
                    if currentCount <= 1 {
                        self.globalFrequency.removeValue(forKey: key)
                    } else {
                        self.globalFrequency[key] = currentCount - 1
                    }
                }
            }
            
            // 2. Remove the activity from the region
            self.sortedActivities[regionName]?.removeAll(where: { $0.id == activity.id })
            
            // 3. NEW: If no activities are left, completely delete the region
            if let remaining = self.sortedActivities[regionName], remaining.isEmpty {
                self.sortedActivities.removeValue(forKey: regionName)
                self.regions.removeAll(where: { $0.name == regionName })
            }
            
            // 4. Save changes to disk
            self.saveToDisk()
        }
    }
}
