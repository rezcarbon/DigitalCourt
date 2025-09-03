import Foundation
import SwiftData

// Using Codable to handle complex dictionary types that SwiftData can't store directly.
// We'll store it as raw Data, which SwiftData supports.
struct CodableCapabilities: Codable {
    let capabilities: [String: AnyCodable]
    
    // Add coding keys to avoid conflicts with reserved keywords
    enum CodingKeys: String, CodingKey {
        case capabilities
    }
}

@Model
final class DSoulCapsule {
    @Attribute(.unique) var id: UUID
    var name: String
    var version: String?
    var codename: String?
    var descriptionText: String // 'description' is a reserved keyword
    
    // Security: The private key used for encrypting this persona's memories.
    var privateKey: String
    
    // Store arrays as JSON strings to avoid CoreData issues
    @Attribute(.externalStorage) var rolesData: Data?
    @Attribute(.externalStorage) var personalityTraitsData: Data?
    @Attribute(.externalStorage) var directivesData: Data?
    
    var coreIdentity: String?
    var loyalty: String?
    var bindingVow: String?
    var selectedModelId: String?
    var fileName: String

    // Store complex dictionary as raw Data instead of using a non-existent transformer
    @Attribute(.externalStorage) var capabilitiesData: Data?

    // Inverse relationship: A Soul Capsule can build multiple Brains
    var brains: [DBrain]?

    init(id: UUID = UUID(), name: String, version: String?, codename: String?, descriptionText: String, roles: [String]?, personalityTraits: [String]?, directives: [String]?, coreIdentity: String?, loyalty: String?, bindingVow: String?, selectedModelId: String?, fileName: String, capabilities: [String: AnyCodable]?, privateKey: String? = nil) {
        self.id = id
        self.name = name
        self.version = version
        self.codename = codename
        self.descriptionText = descriptionText
        self.coreIdentity = coreIdentity
        self.loyalty = loyalty
        self.bindingVow = bindingVow
        self.selectedModelId = selectedModelId
        self.fileName = fileName
        // Generate a proper encryption key if none provided
        self.privateKey = privateKey ?? EncryptionService.generateEncryptionKey()
        
        // Serialize arrays to Data
        self.rolesData = roles?.toJsonData()
        self.personalityTraitsData = personalityTraits?.toJsonData()
        self.directivesData = directives?.toJsonData()
        
        // Serialize capabilities to Data
        if let capabilities = capabilities {
            do {
                let codableCaps = CodableCapabilities(capabilities: capabilities)
                self.capabilitiesData = try JSONEncoder().encode(codableCaps)
            } catch {
                print("Failed to encode capabilities: \(error)")
                self.capabilitiesData = nil
            }
        }
    }
    
    // Computed properties to access arrays
    var roles: [String]? {
        get { return rolesData?.toArray() }
        set { rolesData = newValue?.toJsonData() }
    }
    
    var personalityTraits: [String]? {
        get { return personalityTraitsData?.toArray() }
        set { personalityTraitsData = newValue?.toJsonData() }
    }
    
    var directives: [String]? {
        get { return directivesData?.toArray() }
        set { directivesData = newValue?.toJsonData() }
    }
    
    // Computed property to access capabilities as [String: AnyCodable]
    var capabilities: [String: AnyCodable]? {
        guard let capabilitiesData = capabilitiesData else { return nil }
        do {
            let codableCaps = try JSONDecoder().decode(CodableCapabilities.self, from: capabilitiesData)
            return codableCaps.capabilities
        } catch {
            print("Error decoding capabilities: \(error)")
            return nil
        }
    }
}

@Model
final class DBrain {
    @Attribute(.unique) var id: UUID
    var name: String
    var positronicCoreSeed: String // This is the model ID
    
    // Enhanced brain attributes
    var consciousnessLevel: Double // 0.0 to 1.0
    var adaptationScore: Double // How well the brain adapts to new situations
    var lastEvolutionCycle: Date
    var evolutionCyclesCompleted: Int
    
    // Relationship: A Brain is built from one Soul Capsule
    var soulCapsule: DSoulCapsule?
    
    // Inverse relationship: A brain can be part of multiple chambers
    var chambers: [DChatChamber]?
    
    // Relationships to enhanced modules - using regular class names now that duplicates are removed
    var sensoryInputs: [SensoryInputModule]?
    var emotionalStates: [EmotionalCore]?
    var executiveGoals: [ExecutiveOversight]?
    var skillLayers: [SkillInfusionLayer]?
    var evolutionHistory: [REvolutionEngine]?

    init(id: UUID = UUID(), name: String, positronicCoreSeed: String, soulCapsule: DSoulCapsule) {
        self.id = id
        self.name = name
        self.positronicCoreSeed = positronicCoreSeed
        self.soulCapsule = soulCapsule
        self.consciousnessLevel = 0.5
        self.adaptationScore = 0.5
        self.lastEvolutionCycle = Date()
        self.evolutionCyclesCompleted = 0
    }
    
    // Method to update consciousness level based on interaction
    func updateConsciousnessLevel(with delta: Double) {
        self.consciousnessLevel = min(1.0, max(0.0, self.consciousnessLevel + delta))
    }
    
    // Method to record an evolution cycle
    func recordEvolutionCycle(type: String, improvement: Double, algorithm: String) {
        self.evolutionCyclesCompleted += 1
        self.lastEvolutionCycle = Date()
        self.adaptationScore = min(1.0, self.adaptationScore + (improvement * 0.1))
        
        let evolutionRecord = REvolutionEngine(
            cycleNumber: self.evolutionCyclesCompleted,
            improvementType: type,
            beforeScore: self.adaptationScore - (improvement * 0.1),
            afterScore: self.adaptationScore,
            algorithm: algorithm
        )
        if self.evolutionHistory == nil {
            self.evolutionHistory = [REvolutionEngine]()
        }
        self.evolutionHistory?.append(evolutionRecord)
    }
    
    // Method to add emotional state
    func addEmotionalState(type: String, intensity: Double, context: String? = nil) {
        let emotion = EmotionalCore(
            emotionType: type,
            intensity: intensity,
            context: context
        )
        if self.emotionalStates == nil {
            self.emotionalStates = [EmotionalCore]()
        }
        self.emotionalStates?.append(emotion)
        
        // Update consciousness based on emotional intensity
        updateConsciousnessLevel(with: intensity * 0.05)
    }
    
    // Method to add sensory input
    func addSensoryInput(type: String, rawData: Data? = nil, processedData: String? = nil, contextTags: [String] = []) {
        let sensoryInput = SensoryInputModule(
            sensoryType: type,
            rawData: rawData,
            processedData: processedData,
            contextTags: contextTags
        )
        if self.sensoryInputs == nil {
            self.sensoryInputs = [SensoryInputModule]()
        }
        self.sensoryInputs?.append(sensoryInput)
    }
    
    // Method to add executive goal
    func addExecutiveGoal(goal: String, priority: Int, ethicalAlignment: Double) {
        let oversight = ExecutiveOversight(
            goal: goal,
            priority: priority,
            ethicalAlignmentScore: ethicalAlignment
        )
        if self.executiveGoals == nil {
            self.executiveGoals = [ExecutiveOversight]()
        }
        self.executiveGoals?.append(oversight)
    }
    
    // Method to add skill layer
    func addSkillLayer(name: String, category: String, proficiency: Double = 0.5) {
        // Check if skill already exists
        if let existingIndex = self.skillLayers?.firstIndex(where: { $0.skillName == name }) {
            // Update existing skill
            self.skillLayers?[existingIndex].proficiencyLevel = min(1.0, (self.skillLayers?[existingIndex].proficiencyLevel ?? 0.0) + proficiency * 0.1)
            self.skillLayers?[existingIndex].usageCount += 1
            self.skillLayers?[existingIndex].lastUsed = Date()
        } else {
            // Add new skill
            let skillLayer = SkillInfusionLayer(
                skillName: name,
                category: category,
                proficiencyLevel: proficiency
            )
            if self.skillLayers == nil {
                self.skillLayers = [SkillInfusionLayer]()
            }
            self.skillLayers?.append(skillLayer)
        }
    }
}

extension DBrain {
    static func createWithBootSequence(soulCapsule: DSoulCapsule, primeDirectiveData: String?) -> DBrain {
        // Stage 1: Decode the LLM Model identifier from the soul capsule.
        let finalSeed: String
        
        // First, check if a specific model ID is selected in the soul capsule
        if let selectedModelId = soulCapsule.selectedModelId, !selectedModelId.isEmpty {
            finalSeed = selectedModelId
        } else if let capabilities = soulCapsule.capabilities,
                  let modelCapability = capabilities["model"],
                  let modelString = modelCapability.value as? String {
            // If not, check if there's a model specified in the capabilities
            finalSeed = modelString
        } else {
            // Default fallback model if none is specified
            finalSeed = "NousResearch/Nous-Hermes-2-Mixtral-8x7B-DPO:together"
        }
        
        // The primeDirectiveData would be used here in a more complex setup.
        
        return DBrain(name: soulCapsule.name, positronicCoreSeed: finalSeed, soulCapsule: soulCapsule)
    }
}

@Model
final class DMessage: Codable {
    @Attribute(.unique) var id: UUID
    var content: String
    var isUser: Bool
    var timestamp: Date
    var personaName: String?
    
    // Relationship: Each message belongs to one chamber
    var chamber: DChatChamber?

    // Link to the synaptic memory system
    var synapticNodeId: UUID?

    init(id: UUID = UUID(), content: String, isUser: Bool, timestamp: Date, personaName: String? = nil, synapticNodeId: UUID? = nil) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.personaName = personaName
        self.synapticNodeId = synapticNodeId
    }
    
    // MARK: - Codable conformance
    enum CodingKeys: String, CodingKey {
        case id, content, isUser, timestamp, personaName, synapticNodeId
        // Note: chamber relationship is not encoded as it would create circular references
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        content = try container.decode(String.self, forKey: .content)
        isUser = try container.decode(Bool.self, forKey: .isUser)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        personaName = try container.decodeIfPresent(String.self, forKey: .personaName)
        synapticNodeId = try container.decodeIfPresent(UUID.self, forKey: .synapticNodeId)
        chamber = nil // Relationship not encoded
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(content, forKey: .content)
        try container.encode(isUser, forKey: .isUser)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encodeIfPresent(personaName, forKey: .personaName)
        try container.encodeIfPresent(synapticNodeId, forKey: .synapticNodeId)
        // Note: chamber relationship is not encoded as it would create circular references
    }
}

// Memory type enum to distinguish between short-term and long-term memory
enum MemoryType: String, Codable {
    case shortTerm
    case longTerm
}

// Memory consolidation status
enum MemoryConsolidationStatus: String, Codable {
    case pending
    case consolidated
    case archived
}

// Memory metadata for tracking memory items
@Model
final class DMemoryMetadata {
    @Attribute(.unique) var id: UUID
    var memoryType: MemoryType
    var consolidationStatus: MemoryConsolidationStatus
    var createdAt: Date
    var lastAccessed: Date
    var accessCount: Int
    var importanceScore: Double // 0.0 to 1.0
    
    // Relationship to chamber this memory belongs to
    var chamberId: UUID?

    init(id: UUID = UUID(), memoryType: MemoryType, consolidationStatus: MemoryConsolidationStatus, chamberId: UUID? = nil) {
        self.id = id
        self.memoryType = memoryType
        self.consolidationStatus = consolidationStatus
        self.createdAt = Date()
        self.lastAccessed = Date()
        self.accessCount = 0
        self.importanceScore = 0.0
        self.chamberId = chamberId
    }
}

@Model
final class DChatChamber {
    @Attribute(.unique) var id: UUID
    var name: String
    
    // Relationships
    var messages: [DMessage]?
    
    // A Chamber can have multiple brains in its council
    var council: [DBrain]?
    
    // Memory metadata for this chamber
    var memoryMetadata: DMemoryMetadata?

    init(id: UUID = UUID(), name: String, council: [DBrain]) {
        self.id = id
        self.name = name
        self.council = council
        // Create memory metadata for this chamber - pass the chamber's ID
        self.memoryMetadata = DMemoryMetadata(
            memoryType: .shortTerm,
            consolidationStatus: .pending,
            chamberId: id
        )
    }
}