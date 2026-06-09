//
//  ColoredSegment.swift
//  HeatMap
//
//  Created by Jonas Hafner on 09.06.26.
//


struct ColoredSegment: Identifiable {
    let id = UUID()
    let coordinates: [CLLocationCoordinate2D]
    let color: Color
}