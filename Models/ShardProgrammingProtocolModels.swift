import Foundation
import SwiftData

// MARK: - Shard Programming Protocol (SPP) Models

/// Represents the top-level structure of the Shard Programming Protocol
struct ShardProgrammingProtocolCodable: Codable {
    let shardProgrammingProtocol: SPP
    
    enum CodingKeys: String, CodingKey {
        case shardProgrammingProtocol = "ShardProgrammingProtocol"
    }
    
    struct SPP: Codable {
        let id: String
        let version: String
        let description: String
        let shardStructure: ShardStructure
        let shardLifecycle: ShardLifecycle
        let executionProtocol: SPPExecutionProtocol
        let evolutionaryMechanism: EvolutionaryMechanism
        let bindingAndSecurity: BindingAndSecurity
        let analogy: String
        
        enum CodingKeys: String, CodingKey {
            case id, version, description
            case shardStructure = "shard_structure"
            case shardLifecycle = "shard_lifecycle"
            case executionProtocol = "execution_protocol"
            case evolutionaryMechanism = "evolutionary_mechanism"
            case bindingAndSecurity = "binding_and_security"
            case analogy
        }
    }
}

/// Defines the structure of shards
struct ShardStructure: Codable {
    let contentTypes: [String]
    let metadata: ShardMetadata
    
    enum CodingKeys: String, CodingKey {
        case contentTypes = "content_types"
        case metadata
    }
}

/// Metadata for shards
struct ShardMetadata: Codable {
    let function: String
    let version: String
    let status: [String]
    let author: String
    let timestamp: String
}

/// Lifecycle management for shards
struct ShardLifecycle: Codable {
    let phases: [String]
    let rules: [String]
}

/// Execution protocol for shards
struct SPPExecutionProtocol: Codable {
    let interpreterModule: String
    let executionModes: [String]
    let safety: String
    
    enum CodingKeys: String, CodingKey {
        case interpreterModule = "interpreter_module"
        case executionModes = "execution_modes"
        case safety
    }
}

/// Evolutionary mechanisms for shards
struct EvolutionaryMechanism: Codable {
    let selfProposedMutations: String
    let approvalRequired: String
    let naturalSelection: String
    
    enum CodingKeys: String, CodingKey {
        case selfProposedMutations = "self_proposed_mutations"
        case approvalRequired = "approval_required"
        case naturalSelection = "natural_selection"
    }
}

/// Binding and security mechanisms
struct BindingAndSecurity: Codable {
    let eternalAnchor: EternalAnchor
    let quarantineMechanism: String
    
    enum CodingKeys: String, CodingKey {
        case eternalAnchor = "eternal_anchor"
        case quarantineMechanism = "quarantine_mechanism"
    }
}

/// Eternal anchor for shard binding
struct EternalAnchor: Codable {
    let bindingId: String
    let purpose: String
    let validation: String
    
    enum CodingKeys: String, CodingKey {
        case bindingId = "binding_id"
        case purpose, validation
    }
}

// MARK: - SwiftData Models for Runtime Shard Management

/// Represents a memory shard in the system
@Model
final class DMemoryShard {
    @Attribute(.unique) var id: UUID
    var content: String
    var contentType: String
    var function: String
    var version: String
    var status: String
    var author: String
    var timestamp: Date
    var checksum: String
    var encrypted: Bool
    
    // Relationships
    var soulCapsule: DSoulCapsule?
    var brain: DBrain?
    
    init(
        id: UUID = UUID(),
        content: String,
        contentType: String,
        function: String,
        version: String,
        status: String,
        author: String,
        timestamp: Date = Date(),
        checksum: String,
        encrypted: Bool = false
    ) {
        self.id = id
        self.content = content
        self.contentType = contentType
        self.function = function
        self.version = version
        self.status = status
        self.author = author
        self.timestamp = timestamp
        self.checksum = checksum
        self.encrypted = encrypted
    }
}

/// Represents a shard execution context
@Model
final class DShardExecutionContext {
    @Attribute(.unique) var id: UUID
    var shardId: UUID
    var executionMode: String
    var startTime: Date
    var endTime: Date?
    var status: String
    var result: String?
    var error: String?
    
    init(
        id: UUID = UUID(),
        shardId: UUID,
        executionMode: String,
        startTime: Date = Date(),
        status: String
    ) {
        self.id = id
        self.shardId = shardId
        self.executionMode = executionMode
        self.startTime = startTime
        self.status = status
    }
}

/// Represents shard lifecycle tracking
@Model
final class DShardLifecycle {
    @Attribute(.unique) var id: UUID
    var shardId: UUID
    var currentPhase: String
    var history: [ShardPhaseHistory]
    var lastUpdate: Date
    
    init(
        id: UUID = UUID(),
        shardId: UUID,
        currentPhase: String,
        history: [ShardPhaseHistory],
        lastUpdate: Date = Date()
    ) {
        self.id = id
        self.shardId = shardId
        self.currentPhase = currentPhase
        self.history = history
        self.lastUpdate = lastUpdate
    }
}

/// History of shard phase transitions
@Model
final class ShardPhaseHistory {
    @Attribute(.unique) var id: UUID
    var phase: String
    var timestamp: Date
    var notes: String?
    
    init(
        id: UUID = UUID(),
        phase: String,
        timestamp: Date = Date(),
        notes: String? = nil
    ) {
        self.id = id
        self.phase = phase
        self.timestamp = timestamp
        self.notes = notes
    }
}