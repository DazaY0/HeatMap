//
//  GPXParser.swift
//  HeatMap
//
//  Created by Jonas Hafner on 09.06.26.
//


class GPXParser: NSObject, XMLParserDelegate {
    private var coordinates: [CLLocationCoordinate2D] = []
    
    func parseGPX(data: Data) -> [CLLocationCoordinate2D] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return coordinates
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "trkpt", 
           let latString = attributeDict["lat"], let lat = Double(latString),
           let lonString = attributeDict["lon"], let lon = Double(lonString) {
            coordinates.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }
    }
}