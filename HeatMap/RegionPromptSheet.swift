//
//  RegionPromptSheet.swift
//  HeatMap
//
//  Created by Jonas Hafner on 09.06.26.
//


import SwiftUI

struct RegionPromptSheet: View {
    let activity: Activity
    @ObservedObject var manager: HeatmapManager
    @Environment(\.dismiss) var dismiss
    
    @State private var newRegionName: String = ""
    @State private var selectedExistingRegion: String = ""
    @State private var isCreatingNew = true
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Unrecognized Activity Location")
                .font(.headline)
            
            Text("The activity \"\(activity.name)\" was recorded outside your usual zones.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Picker("", selection: $isCreatingNew) {
                Text("Create New Region").tag(true)
                Text("Assign to Existing").tag(false)
            }
            .pickerStyle(.segmented)
            
            if isCreatingNew {
                TextField("Region Name (e.g., Salzburg)", text: $newRegionName)
                    .textFieldStyle(.roundedBorder)
            } else {
                Picker("Select Region", selection: $selectedExistingRegion) {
                    Text("-- Select --").tag("")
                    ForEach(manager.regions) { region in
                        Text(region.name).tag(region.name)
                    }
                }
                .disabled(manager.regions.isEmpty)
            }
            
            HStack {
                Button("Cancel", role: .cancel) {
                    manager.unresolvedActivity = nil
                    dismiss()
                }
                Spacer()
                Button("Confirm Configuration") {
                    guard let startCoord = activity.coordinates.first else { return }
                    
                    if isCreatingNew && !newRegionName.isEmpty {
                        manager.createNewRegion(name: newRegionName, coord: startCoord)
                        manager.finalizeActivityAssignment(activity, regionName: newRegionName)
                    } else if !isCreatingNew && !selectedExistingRegion.isEmpty {
                        manager.finalizeActivityAssignment(activity, regionName: selectedExistingRegion)
                    }
                    
                    manager.unresolvedActivity = nil
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isCreatingNew ? newRegionName.isEmpty : selectedExistingRegion.isEmpty)
            }
        }
        .padding()
        .frame(width: 400)
        .onAppear {
            if let firstRegion = manager.regions.first {
                selectedExistingRegion = firstRegion.name
            }
        }
    }
}