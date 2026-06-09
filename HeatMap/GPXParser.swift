//
//  GPXParser.swift
//  HeatMap
//
//  Created by Jonas Hafner on 09.06.26.
//
import Foundation
import CoreLocation

class GPXParser: NSObject, XMLParserDelegate {
    private var coordinates: [CLLocationCoordinate2D] = []
        
        func parseGPX(at url: URL) -> [CLLocationCoordinate2D] {
            coordinates.removeAll()
            
            guard let parser = XMLParser(contentsOf: url) else { return [] }
            parser.delegate = self
            parser.parse()
            
            return coordinates
        }
        
        // Looks for '<trkpt lat="..." lon="..."> elements in the XML
        func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
            if elementName == "trkpt",
               let latString = attributeDict["lat"], let lat = Double(latString),
               let lonString = attributeDict["lon"], let lon = Double(lonString) {
                coordinates.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
            }
        }
}
