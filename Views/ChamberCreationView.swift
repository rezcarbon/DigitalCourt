//
//  ChamberCreationView.swift
//  DCourt
//
//  Created by M Reezan M Fadzil on 13/08/2025.
//

import SwiftUI
import SwiftData

struct ChamberCreationView: View {
    @EnvironmentObject var soulCapsuleManager: SoulCapsuleManager
    @EnvironmentObject var chamberManager: ChamberManager
    
    @State private var showingCreationSheet = false
    @State private var newChamberName = ""
    @State private var selectedSoulCapsules: Set<DSoulCapsule> = []
    
    var body: some View {
        NavigationView {
            VStack {
                if selectedSoulCapsules.isEmpty {
                    emptyStateView
                } else {
                    capsuleSelectionView
                }
            }
            .navigationTitle("Create Chamber")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        showingCreationSheet = true
                    }
                    .disabled(selectedSoulCapsules.isEmpty)
                }
            }
            .sheet(isPresented: $showingCreationSheet) {
                ChamberNameInputSheet(
                    selectedCapsules: Array(selectedSoulCapsules),
                    onCreate: createNewChamber
                )
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("Select Soul Capsules")
                .font(.title2)
            
            Text("Choose one or more personas to create a council chamber")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var capsuleSelectionView: some View {
        List {
            ForEach(Array(selectedSoulCapsules), id: \.id) { capsule in
                HStack {
                    VStack(alignment: .leading) {
                        Text(capsule.name)
                            .font(.headline)
                        if let version = capsule.version {
                            Text("Version: \(version)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        selectedSoulCapsules.remove(capsule)
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    private func createNewChamber(named name: String, with capsules: [DSoulCapsule]) {
        // Convert DSoulCapsules to actual SoulCapsules
        let soulCapsules: [SoulCapsule] = capsules.compactMap { dCapsule in
            // Try to get the full SoulCapsule from the manager
            let soulCapsuleStruct = soulCapsuleManager.getSoulCapsuleStruct(from: dCapsule)
            return soulCapsuleStruct
        }
        
        _ = chamberManager.createNewChamber(named: name, with: soulCapsules, primeDirectiveData: nil)
        showingCreationSheet = false
        selectedSoulCapsules.removeAll()
    }
}

struct ChamberNameInputSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let selectedCapsules: [DSoulCapsule]
    let onCreate: (String, [DSoulCapsule]) -> Void
    
    @State private var chamberName = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Chamber Name", text: $chamberName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                List(selectedCapsules, id: \.id) { capsule in
                    Text(capsule.name)
                }
                
                Spacer()
            }
            .navigationTitle("Name Your Chamber")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        onCreate(chamberName, selectedCapsules)
                        dismiss()
                    }
                    .disabled(chamberName.isEmpty)
                }
            }
        }
    }
}