import Foundation
import Combine
import SwiftData

@MainActor
class SoulCapsuleManager: ObservableObject {
    static let shared = SoulCapsuleManager()
    
    @Published private(set) var isLoading = false
    @Published var accessibleSoulCapsules: [DSoulCapsule] = []
    @Published var selectedSoulCapsules: Set<DSoulCapsule> = []
    
    private let fileManager = FileManager.default
    private let brainLoader = BrainLoader.shared
    private let shardManager = ShardProgrammingProtocolManager.shared
    
    init() {
        loadSoulCapsules()
    }
    
    func clearAccessibleSoulCapsules() {
        self.accessibleSoulCapsules = []
        self.selectedSoulCapsules = []
    }
    
    func filterSoulCapsules(for user: User?) {
        print("🔍 FilterSoulCapsules called with user: \(user?.username ?? "nil")")
        
        // Reload capsules to ensure we have the full list before filtering
        loadSoulCapsules()
        
        print("📦 Total capsules loaded before filtering: \(accessibleSoulCapsules.count)")

        // If no user or user is admin, show all capsules
        if user == nil || user!.isAdmin {
            if let user = user, user.isAdmin {
                print("👑 User \(user.username) is admin - showing all \(accessibleSoulCapsules.count) capsules")
            } else {
                print("👤 No user provided - showing all \(accessibleSoulCapsules.count) capsules")
            }
            return
        }
        
        print("🔒 User \(user!.username) is not admin - applying filtering")

        if let accessibleIDs = user!.accessiblePersonaIDs {
            print("📋 User has \(accessibleIDs.count) accessible persona IDs")
            let accessibleUUIDs = Set(accessibleIDs)
            let beforeCount = accessibleSoulCapsules.count
            accessibleSoulCapsules = accessibleSoulCapsules.filter { accessibleUUIDs.contains($0.id) }
            print("🔽 Filtered from \(beforeCount) to \(accessibleSoulCapsules.count) capsules")
        } else {
            // Non-admin user with no specific permissions sees nothing.
            print("🚫 User has no accessible persona IDs - showing 0 capsules")
            accessibleSoulCapsules = []
        }
    }
    
    func loadSoulCapsules() {
        isLoading = true
        var loadedCapsules: [DSoulCapsule] = []
        
        let fileExtension = "json"
        let fileIdentifier = "_SoulCapsule"
        
        print("🔍 Searching for Soul Capsule files...")
        
        if let urls = Bundle.main.urls(forResourcesWithExtension: fileExtension, subdirectory: nil) {
            print("📁 Found \(urls.count) total JSON files in bundle")
            
            for url in urls where url.lastPathComponent.contains(fileIdentifier) {
                do {
                    print("🔄 Loading: \(url.lastPathComponent)")
                    let data = try Data(contentsOf: url)
                    let fileName = url.deletingPathExtension().lastPathComponent
                    
                    // Use the proper parser instead of direct JSON decoding
                    guard let soulCapsuleStruct = SoulCapsuleParser.parseSoulCapsule(from: data, fileName: fileName) else {
                        print("❌ Failed to parse soul capsule from \(url.lastPathComponent)")
                        continue
                    }

                    // Convert the parsed struct to the SwiftData model class `DSoulCapsule`
                    let dSoulCapsule = DSoulCapsule(
                        id: soulCapsuleStruct.id,
                        name: soulCapsuleStruct.name,
                        version: soulCapsuleStruct.version,
                        codename: soulCapsuleStruct.codename,
                        descriptionText: soulCapsuleStruct.description ?? "No description available.",
                        roles: soulCapsuleStruct.roles,
                        personalityTraits: soulCapsuleStruct.personalityTraits,
                        directives: soulCapsuleStruct.directives,
                        coreIdentity: convertToString(soulCapsuleStruct.coreIdentity),
                        loyalty: convertToString(soulCapsuleStruct.loyalty),
                        bindingVow: convertToString(soulCapsuleStruct.bindingVow),
                        selectedModelId: soulCapsuleStruct.selectedModelId,
                        fileName: soulCapsuleStruct.fileName,
                        capabilities: soulCapsuleStruct.capabilities,
                        privateKey: soulCapsuleStruct.privateKey
                    )
                    
                    // Process persona shards if they exist and add to shard interpreter
                    if let personaShards = soulCapsuleStruct.personaShards, !personaShards.isEmpty {
                        // In a real implementation, we would register these with the shard system
                        // For now, we'll just log that they exist
                        print("📎 Found \(personaShards.count) shard categories in \(dSoulCapsule.name)")
                    }
                    
                    loadedCapsules.append(dSoulCapsule)
                    print("✅ Successfully loaded: \(dSoulCapsule.name)")
                } catch {
                    print("❌ Failed to load or decode soul capsule from \(url.lastPathComponent): \(error)")
                }
            }
        } else {
            print("❌ No JSON files found in bundle")
        }
        
        self.accessibleSoulCapsules = loadedCapsules
        self.isLoading = false
        
        if !loadedCapsules.isEmpty {
            print("✓ Successfully loaded \(loadedCapsules.count) soul capsule(s)")
            for capsule in loadedCapsules {
                print("  - \(capsule.name) (\(capsule.codename ?? "No codename"))")
            }
        } else {
            print("⚠️ No soul capsules found - this could be due to:")
            print("  1. Files not included in bundle")
            print("  2. Files not following naming convention (_SoulCapsule)")
            print("  3. JSON parsing errors")
        }
    }
    
    // Method to get SoulCapsule struct from DSoulCapsule for non-SwiftData logic
    func getSoulCapsuleStruct(from dSoulCapsule: DSoulCapsule) -> SoulCapsule {
        // Use the initializer from the extension in Models.swift
        return SoulCapsule(fromDataModel: dSoulCapsule)
    }

    // Enhanced method to create brain with full boot sequence support
    // Using explicit reference to avoid ambiguity - this will use the DBrain that has createWithBootSequence
    func createBrain(from soulCapsule: SoulCapsule, with primeDirectiveData: String?) -> DBrain {
        // Execute Master Boot Sequence v9 for this brain instance
        Task { @MainActor in
            await MasterBootSequenceExecutor.shared.executeBootSequence()
        }
        
        // Convert SoulCapsule to DSoulCapsule
        let dSoulCapsule = DSoulCapsule(
            name: soulCapsule.name,
            version: soulCapsule.version,
            codename: soulCapsule.codename,
            descriptionText: soulCapsule.description ?? "No description available.",
            roles: soulCapsule.roles,
            personalityTraits: soulCapsule.personalityTraits,
            directives: soulCapsule.directives,
            coreIdentity: convertToString(soulCapsule.coreIdentity),
            loyalty: convertToString(soulCapsule.loyalty),
            bindingVow: convertToString(soulCapsule.bindingVow),
            selectedModelId: soulCapsule.selectedModelId,
            fileName: soulCapsule.fileName,
            capabilities: soulCapsule.capabilities,
            privateKey: soulCapsule.privateKey
        )
        
        // Use the createWithBootSequence method - this will resolve to the correct DBrain
        return DBrain.createWithBootSequence(
            soulCapsule: dSoulCapsule, 
            primeDirectiveData: primeDirectiveData
        )
    }
    
    // Add method to create a fused persona from multiple soul capsules with full boot sequence
    func createFusedPersona(from capsules: [SoulCapsule], with primeDirectiveData: String?) -> DBrain {
        guard !capsules.isEmpty else {
            // Create a default, non-functional SoulCapsule for the Brain with full boot sequence
            let defaultCapsule = SoulCapsule(
                id: UUID(), name: "Default Fused", version: "1.0", codename: "Default",
                description: "Default fused persona created due to an error.",
                roles: [], capabilities: [:], personalityTraits: [], directives: [],
                modules: [:], fileName: "default_fused", coreIdentity: nil,
                loyalty: nil, performanceMetrics: [:], bindingVow: nil,
                selectedModelId: nil, identity: [:], evolvedDirectives: [:],
                personaShards: [:], lastUpdated: Date(), updateHistory: []
            )
            
            return createBrain(from: defaultCapsule, with: primeDirectiveData)
        }
        
        // Create a fused SoulCapsule by combining attributes from all input capsules
        let fusedName = capsules.count == 1 ? 
            capsules[0].name : 
            "Fused: " + capsules.map { $0.name }.joined(separator: " + ")
        
        let fusedDescription = capsules.count == 1 ? 
            capsules[0].description : 
            "Fused persona combining: " + capsules.map { $0.name }.joined(separator: ", ")
        
        // Combine capabilities (merge dictionaries)
        var combinedCapabilities: [String: AnyCodable] = [:]
        for capsule in capsules {
            if let caps = capsule.capabilities {
                combinedCapabilities.merge(caps) { (_, new) in new }
            }
        }
        
        // Combine other arrays
        let combinedRoles = capsules.compactMap { $0.roles }.flatMap { $0 }
        let combinedPersonalityTraits = capsules.compactMap { $0.personalityTraits }.flatMap { $0 }
        let combinedDirectives = capsules.compactMap { $0.directives }.flatMap { $0 }
        
        // Combine persona shards
        var combinedPersonaShards: [String: [String]] = [:]
        for capsule in capsules {
            if let shards = capsule.personaShards {
                for (category, shardList) in shards {
                    if combinedPersonaShards[category] == nil {
                        combinedPersonaShards[category] = []
                    }
                    combinedPersonaShards[category]?.append(contentsOf: shardList)
                }
            }
        }
        
        // Create the fused SoulCapsule with Master Boot Sequence v9 integration
        let fusedSoulCapsule = SoulCapsule(
            id: UUID(),
            name: fusedName,
            version: "1.0", // Fused version
            codename: "FUSED",
            description: fusedDescription,
            roles: combinedRoles.isEmpty ? nil : Array(Set(combinedRoles)), // Remove duplicates
            capabilities: combinedCapabilities.isEmpty ? nil : combinedCapabilities,
            personalityTraits: combinedPersonalityTraits.isEmpty ? nil : Array(Set(combinedPersonalityTraits)), // Remove duplicates
            directives: combinedDirectives.isEmpty ? nil : Array(Set(combinedDirectives)), // Remove duplicates
            modules: [:], // Start with empty modules
            fileName: "fused_capsule",
            coreIdentity: nil, // Will be set during conversion
            loyalty: nil, // Will be set during conversion
            performanceMetrics: [:],
            bindingVow: nil, // Will be set during conversion
            selectedModelId: capsules.first?.selectedModelId, // Use first capsule's model ID
            identity: nil, // Will be set during conversion
            evolvedDirectives: [:],
            personaShards: combinedPersonaShards.isEmpty ? nil : combinedPersonaShards,
            lastUpdated: Date(),
            updateHistory: []
        )
        
        return createBrain(from: fusedSoulCapsule, with: primeDirectiveData)
    }
    
    // Add togglePersonaSelection method
    func togglePersonaSelection(_ capsule: DSoulCapsule) {
        if selectedSoulCapsules.contains(capsule) {
            selectedSoulCapsules.remove(capsule)
        } else {
            selectedSoulCapsules.insert(capsule)
        }
    }
    
    // Add setup method for model context if needed
    func setup(with context: ModelContext) {
        // Initialize with context if needed
    }
    
    // Get enhanced boot sequence data for brain initialization
    // This will resolve to the EnhancedBootSequenceData from BrainLoader
    func getEnhancedBootSequenceData() -> EnhancedBootSequenceData {
        return brainLoader.getEnhancedBootSequenceData()
    }
    
    // Validate soul capsule compatibility with boot sequence
    func validateSoulCapsuleCompatibility(_ capsule: DSoulCapsule) -> Bool {
        // Check that the soul capsule has required fields
        let hasName = !capsule.name.isEmpty
        let hasVersion = (capsule.version != nil) && !(capsule.version?.isEmpty ?? true)
        let hasCodename = !(capsule.codename?.isEmpty ?? true)
        let hasIdentity = capsule.coreIdentity != nil && !capsule.coreIdentity!.isEmpty
        let hasLoyalty = capsule.loyalty != nil && !capsule.loyalty!.isEmpty
        
        // Check that it has integration points with the SIC
        let hasIntegrationPoints = hasIdentity && hasLoyalty
        
        return hasName && hasVersion && hasCodename && hasIntegrationPoints
    }
    
    // Get persona shards for a soul capsule
    func getPersonaShards(for capsule: DSoulCapsule) -> [String: [String]] {
        return shardManager.getPersonaShards(for: capsule)
    }
    
    // Add method to force reload all personas (useful for admins)
    func reloadAllPersonas() {
        print("🔄 Force reloading all personas...")
        loadSoulCapsules()
        print("✅ Force reload complete - \(accessibleSoulCapsules.count) personas available")
        for capsule in accessibleSoulCapsules {
            print("  - \(capsule.name) (\(capsule.codename ?? "No codename"))")
        }
    }
    
    // Add method to check if user should see all personas
    func shouldShowAllPersonas(for user: User?) -> Bool {
        return user == nil || user?.isAdmin == true
    }
    
    // Add debug method to print current state
    func debugCurrentState() {
        print("🔍 SoulCapsuleManager Debug State:")
        print("  - Accessible soul capsules: \(accessibleSoulCapsules.count)")
        print("  - Selected soul capsules: \(selectedSoulCapsules.count)")
        print("  - Is loading: \(isLoading)")
        
        for (index, capsule) in accessibleSoulCapsules.enumerated() {
            print("  [\(index)] \(capsule.name) - \(capsule.codename ?? "No codename")")
        }
    }
}

// Add helper functions to convert complex types to strings
fileprivate func convertToString(_ value: [String: String]?) -> String {
    guard let value = value else { return "" }
    guard let jsonData = try? JSONSerialization.data(withJSONObject: value),
          let jsonString = String(data: jsonData, encoding: .utf8) else {
        return ""
    }
    return jsonString
}