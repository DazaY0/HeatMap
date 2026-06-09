//
//  Activity.swift
//  HeatMap
//
//  Created by Jonas Hafner on 09.06.26.
//
import Foundation
import CoreLocation
import SwiftUI

struct GPSPoint: Codable, Hashable {
    let latitude: Double
    let longitude: Double
    
    var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct Activity: Identifiable, Hashable, Equatable, Codable {
    let id: UUID
    let name: String
    let points: [GPSPoint] // Swift can now automatically encode/decode this array
    
    var coordinates: [CLLocationCoordinate2D] {
        points.map { $0.clCoordinate }
    }
    
    init(id: UUID = UUID(), name: String, coordinates: [CLLocationCoordinate2D]) {
        self.id = id
        self.name = name
        self.points = coordinates.map { GPSPoint(latitude: $0.latitude, longitude: $0.longitude) }
    }
    
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Activity, rhs: Activity) -> Bool { lhs.id == rhs.id }
    
    var startLocation: CLLocation? {
        guard let first = points.first else { return nil }
        return CLLocation(latitude: first.latitude, longitude: first.longitude)
    }
    
    static func gridKey(for coord: CLLocationCoordinate2D) -> String {
        let latKey = Int(round(coord.latitude * 3000))
        let lonKey = Int(round(coord.longitude * 3000))
        return "\(latKey)_\(lonKey)"
    }
    
    func generateColoredSegments(globalFrequency: [String: Int], maxFrequency: Int) -> [ColoredSegment] {
        let coords = self.coordinates
        guard coords.count > 1 else { return [] }
        
        var segments: [ColoredSegment] = []
        var currentChunk: [CLLocationCoordinate2D] = [coords[0]]
        
        let firstKey = Activity.gridKey(for: coords[0])
        var currentCount = globalFrequency[firstKey] ?? 1
        
        for i in 1..<coords.count {
            let coord = coords[i]
            let key = Activity.gridKey(for: coord)
            let count = globalFrequency[key] ?? 1
            
            if count == currentCount {
                currentChunk.append(coord)
            } else {
                currentChunk.append(coord)
                let segmentColor = calculateGradientColor(for: currentCount, maxFrequency: maxFrequency)
                segments.append(ColoredSegment(coordinates: currentChunk, color: segmentColor))
                
                currentChunk = [coord]
                currentCount = count
            }
        }
        
        if currentChunk.count > 1 {
            let segmentColor = calculateGradientColor(for: currentCount, maxFrequency: maxFrequency)
            segments.append(ColoredSegment(coordinates: currentChunk, color: segmentColor))
        }
        
        return segments
    }
    
    private func calculateGradientColor(for count: Int, maxFrequency: Int) -> Color {
        let maxCeiling = max(maxFrequency, 2)
        let fraction = Double(count - 1) / Double(maxCeiling - 1)
        
        if fraction <= 0.5 {
            return Color.lerp(from: .orange, to: .yellow, fraction: fraction * 2.0)
        } else {
            return Color.lerp(from: .yellow, to: .white, fraction: (fraction - 0.5) * 2.0)
        }
    }
}
import SwiftUI
import AppKit

extension Color {
    /// Blends smoothly between two colors based on a fraction (0.0 to 1.0)
    static func lerp(from: Color, to: Color, fraction: Double) -> Color {
        let f = max(0, min(1, fraction))
        
        let c1 = NSColor(from).usingColorSpace(.deviceRGB) ?? .orange
        let c2 = NSColor(to).usingColorSpace(.deviceRGB) ?? .yellow
        
        let r = c1.redComponent + (c2.redComponent - c1.redComponent) * f
        let g = c1.greenComponent + (c2.greenComponent - c1.greenComponent) * f
        let b = c1.blueComponent + (c2.blueComponent - c1.blueComponent) * f
        
        return Color(red: r, green: g, blue: b)
    }
}
