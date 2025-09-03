//
//  ChamberManager.swift
//  DCourt
//

import Foundation
import SwiftData
import Combine

@MainActor
class ChamberManager: ObservableObject {
    @Published var chambers: [Chamber] = []
    @Published var currentChamber: Chamber?
    
    private var modelContext: ModelContext?
    private let memoryManager = MemoryManager.shared
    
    // Make the initializer public and handle nil context
    init(modelContext: ModelContext?) {
        self.modelContext = modelContext
        // Only load chambers if we have a valid context
        if modelContext != nil {
            loadChambers()
        }
    }
    
    // Add setup method for model context
    func setup(with context: ModelContext) {
        self.modelContext = context
        memoryManager.setup(with: context.container)
        loadChambers()
    }
    
    // Save a chamber to SwiftData
    func saveChamber(_ chamber: Chamber, context: ModelContext) {
        do {
            _ = chamber.saveToSwiftData(context: context)
            
            // Save to persistent storage
            try context.save()
            
            // Update our local cache
            if let index = chambers.firstIndex(where: { $0.id == chamber.id }) {
                chambers[index] = chamber
            } else {
                chambers.append(chamber)
            }
        } catch {
            print("Failed to save chamber: \(error)")
        }
    }
    
    // Load all chambers from SwiftData
    func loadChambers() {
        guard let context = modelContext else {
            print("⚠️ Cannot load chambers: ModelContext not initialized")
            return
        }
        
        do {
            let fetchDescriptor = FetchDescriptor<DChatChamber>()
            let dataChambers = try context.fetch(fetchDescriptor)
            
            self.chambers = dataChambers.map { Chamber(fromDataModel: $0) }
        } catch {
            print("Failed to load chambers: \(error)")
        }
    }
    
    // Create a new chamber using the memory manager
    func createChamber(name: String, council: [DBrain]) async throws {
        guard modelContext != nil else {
            throw MemoryError.swiftDataNotInitialized
        }
        
        let dataChamber = try await memoryManager.createChamber(named: name, council: council)
        
        let chamberStruct = Chamber(fromDataModel: dataChamber)
        
        // Save to our local cache
        self.chambers.append(chamberStruct)
    }
    
    // Add createCouncilChamber method
    func createCouncilChamber(name: String, soulCapsules: Set<DSoulCapsule>) async {
        let primeDirective = BootSequenceManager.shared.primeDirectiveData
        let brains = soulCapsules.map { capsule in
            DBrain.createWithBootSequence(soulCapsule: capsule, primeDirectiveData: primeDirective)
        }
        
        do {
            try await createChamber(name: name, council: brains)
        } catch {
            print("Failed to create council chamber: \(error)")
            // Fallback to sync method
            createChamberSync(name: name, council: brains)
        }
    }
    
    // Synchronous fallback method
    private func createChamberSync(name: String, council: [DBrain]) {
        guard let context = modelContext else {
            print("⚠️ Cannot create chamber sync: ModelContext not initialized")
            return
        }
        
        let chamberStruct = Chamber(
            name: name,
            council: council
        )
        
        // Save the actual data model
        let dataChamber = DChatChamber(name: name, council: council)
        dataChamber.id = chamberStruct.id
        context.insert(dataChamber)
        try? context.save()
        
        self.chambers.append(chamberStruct)
    }
    
    // Enhanced method to create a fused persona chamber
    func createFusedPersonaChamber(name: String, soulCapsules: Set<DSoulCapsule>) async {
        // Convert DSoulCapsules to SoulCapsules
        let soulCapsuleStructs = soulCapsules.map { SoulCapsule(fromDataModel: $0) }
        
        let primeDirective = BootSequenceManager.shared.primeDirectiveData
        
        // Create a fused persona using SoulCapsuleManager
        let fusedBrain = SoulCapsuleManager.shared.createFusedPersona(from: soulCapsuleStructs, with: primeDirective)
        
        do {
            try await createChamber(name: name, council: [fusedBrain])
        } catch {
            print("Failed to create fused persona chamber: \(error)")
            // Create using sync method
            guard let context = modelContext else {
                print("⚠️ Cannot create fused persona chamber: ModelContext not initialized")
                return
            }
            
            let chamberStruct = Chamber(
                name: name,
                council: [fusedBrain]
            )
            
            // Save to SwiftData
            let dataChamber = DChatChamber(name: name, council: [fusedBrain])
            dataChamber.id = chamberStruct.id
            context.insert(dataChamber)
            try? context.save()
            
            self.chambers.append(chamberStruct)
        }
    }
    
    // Delete chambers at specified offsets
    func deleteChamber(at offsets: IndexSet) {
        guard let context = modelContext else {
            print("⚠️ Cannot delete chamber: ModelContext not initialized")
            return
        }
        
        // Delete from SwiftData
        for index in offsets.sorted().reversed() {
            if index < chambers.count {
                let chamber = chambers[index]
                let chamberId = chamber.id
                
                // Delete from SwiftData
                do {
                    let fetchDescriptor = FetchDescriptor<DChatChamber>(predicate: #Predicate<DChatChamber> { $0.id == chamberId })
                    let dataChambers = try context.fetch(fetchDescriptor)
                    
                    if let dataChamber = dataChambers.first {
                        context.delete(dataChamber)
                        try context.save()
                    }
                } catch {
                    print("Failed to delete chamber from SwiftData: \(error)")
                }
                
                // Remove from local cache
                chambers.remove(at: index)
            }
        }
    }
    
    // Add a message to a chamber
    func addMessageToChamber(_ message: Message, chamberId: UUID, context: ModelContext) {
        guard let chamberIndex = chambers.firstIndex(where: { $0.id == chamberId }) else { return }
        
        chambers[chamberIndex].addMessage(message)
        
        // Save to SwiftData
        saveChamber(chambers[chamberIndex], context: context)
    }
    
    // Create a new chamber with soul capsules
    func createNewChamber(named name: String, with soulCapsules: [SoulCapsule], primeDirectiveData: String?) -> Chamber {
        let primeDirective = BootSequenceManager.shared.primeDirectiveData
        // This is just returning a Chamber struct for UI purposes
        let structBrains = soulCapsules.map { SoulCapsuleManager.shared.createBrain(from: $0, with: primeDirective) }
        
        let chamber = Chamber(
            name: name,
            council: structBrains
        )
        
        self.chambers.append(chamber)
        return chamber
    }
}