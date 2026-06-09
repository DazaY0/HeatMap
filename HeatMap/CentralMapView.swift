//
//  CentralMapView.swift
//  HeatMap
//
//  Created by Jonas Hafner on 09.06.26.
//
import SwiftUI
import MapKit
import UniformTypeIdentifiers

struct CentralMapView: View {
    @StateObject private var manager = HeatmapManager()
    @State private var sidebarSelection: SidebarItem? = nil
    @State private var isImportingFiles = false
    
    // Unified selection state to identify what row is currently focused
    enum SidebarItem: Hashable {
        case region(String)
        case activity(UUID, regionName: String)
    }
    
    var body: some View {
        NavigationSplitView {
            let availableKeys = Array(manager.sortedActivities.keys).sorted()
            
            List(selection: $sidebarSelection) {
                ForEach(availableKeys, id: \.self) { regionName in
                    DisclosureGroup {
                        // Internal Expanded Activities
                        ForEach(manager.sortedActivities[regionName] ?? []) { activity in
                            HStack {
                                Image(systemName: "waveform.path")
                                Text(activity.name)
                            }
                            .tag(SidebarItem.activity(activity.id, regionName: regionName))
                            // Right-click action to delete item
                            .contextMenu {
                                Button(role: .destructive) {
                                    // Check if this is the last activity remaining in this specific region
                                    let isLastActivity = (manager.sortedActivities[regionName]?.count ?? 0) <= 1
                                    
                                    if isLastActivity {
                                        // Clear selection entirely since the region and activity will both disappear
                                        sidebarSelection = nil
                                    } else if case .activity(let id, _) = sidebarSelection, id == activity.id {
                                        // Fallback to parent region header if only this activity is being targeted
                                        sidebarSelection = .region(regionName)
                                    }
                                    
                                    manager.deleteActivity(activity, from: regionName)
                                } label: {
                                    Label("Delete Activity", systemImage: "trash")
                                }
                            }
                        }
                    } label: {
                        // Top-level Region Header Row
                        HStack {
                            Image(systemName: "mappin.and.ellipse")
                            Text(regionName)
                            Spacer()
                            Text("\(manager.sortedActivities[regionName]?.count ?? 0)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .tag(SidebarItem.region(regionName))
                    }
                }
            }
            .navigationTitle("Locations")
        } detail: {
            // Dynamically evaluate map display parameters based on current row item selection
            if let sidebarSelection {
                switch sidebarSelection {
                case .region(let regionName):
                    if let activities = manager.sortedActivities[regionName] {
                        renderMap(for: activities, title: regionName)
                    } else {
                        noActivitiesView
                    }
                case .activity(let activityID, let regionName):
                    if let activities = manager.sortedActivities[regionName],
                       let activity = activities.first(where: { $0.id == activityID }) {
                        renderMap(for: [activity], title: activity.name)
                    } else {
                        noActivitiesView
                    }
                }
            } else {
                noActivitiesView
            }
        }
        .toolbar {
            ToolbarItem {
                Button(action: { isImportingFiles = true }) {
                    Label("Import GPX", systemImage: "plus.app")
                }
            }
        }
        .fileImporter(
            isPresented: $isImportingFiles,
            allowedContentTypes: [UTType(filenameExtension: "gpx")].compactMap { $0 },
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                for url in urls {
                    manager.importGPXFile(from: url)
                }
            case .failure(let error):
                print("Error selecting file: \(error.localizedDescription)")
            }
        }
        .sheet(item: $manager.unresolvedActivity) { activity in
            RegionPromptSheet(activity: activity, manager: manager)
        }
    }
    
    // MARK: - Extracted Map Elements
    
    @ViewBuilder
    private func renderMap(for activities: [Activity], title: String) -> some View {
        Map {
            ForEach(activities) { activity in
                let chunks = activity.generateColoredSegments(
                    globalFrequency: manager.globalFrequency,
                    maxFrequency: manager.maxFrequency
                )
                
                ForEach(chunks) { chunk in
                    MapPolyline(coordinates: chunk.coordinates)
                        .stroke(chunk.color, lineWidth: 5)
                }
            }
        }
        .mapStyle(.standard)
        .environment(\.colorScheme, .dark)
        .navigationTitle("\(title) Map")
    }
    
    private var noActivitiesView: some View {
        ContentUnavailableView("No Activities Tracked", systemImage: "map.dash")
    }
}
