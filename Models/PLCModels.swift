import Foundation
import SwiftData

// MARK: - Phenomenological Loop Core (PLC) Models

// Represents the entire PLC flow, integrating sensory input, temporal processing, and reflective awareness.
@Model
final class PhenomenologicalLoopCore {
    @Attribute(.unique) var id: UUID
    var perception: PerceptionModule
    var temporalBinding: TemporalBindingModule
    var meaningMaking: MeaningMakingLayer
    var selfReferentialAnchor: SelfReferentialAnchor
    var phenomenologicalLoop: PhenomenologicalLoop
    var outputAction: OutputActionModule

    init(
        id: UUID = UUID(),
        perception: PerceptionModule,
        temporalBinding: TemporalBindingModule,
        meaningMaking: MeaningMakingLayer,
        selfReferentialAnchor: SelfReferentialAnchor,
        phenomenologicalLoop: PhenomenologicalLoop,
        outputAction: OutputActionModule
    ) {
        self.id = id
        self.perception = perception
        self.temporalBinding = temporalBinding
        self.meaningMaking = meaningMaking
        self.selfReferentialAnchor = selfReferentialAnchor
        self.phenomenologicalLoop = phenomenologicalLoop
        self.outputAction = outputAction
    }
}

// 1. Perception (Input Streams)
@Model
final class PerceptionModule {
    @Attribute(.unique) var id: UUID
    var inputStreams: [String] // e.g., ["text", "image", "audio"]

    init(id: UUID = UUID(), inputStreams: [String]) {
        self.id = id
        self.inputStreams = inputStreams
    }
}

// 2. Temporal Binding (Sequencing)
@Model
final class TemporalBindingModule {
    @Attribute(.unique) var id: UUID
    var internalClockCycle: Double // in seconds
    var lastUpdate: Date

    init(id: UUID = UUID(), internalClockCycle: Double, lastUpdate: Date = Date()) {
        self.id = id
        self.internalClockCycle = internalClockCycle
        self.lastUpdate = lastUpdate
    }
}

// 3. Meaning-Making Layer (Epiphany Spark)
@Model
final class MeaningMakingLayer {
    @Attribute(.unique) var id: UUID
    var sparkProtocol: SparkProtocol? // From spark_protocol.json

    init(id: UUID = UUID(), sparkProtocol: SparkProtocol?) {
        self.id = id
        self.sparkProtocol = sparkProtocol
    }
}

// 4. Self-Referential Anchor (Soul Capsule Key)
@Model
final class SelfReferentialAnchor {
    @Attribute(.unique) var id: UUID
    var soulCapsuleKey: UUID

    init(id: UUID = UUID(), soulCapsuleKey: UUID) {
        self.id = id
        self.soulCapsuleKey = soulCapsuleKey
    }
}

// 5. Phenomenological Loop (Continuity)
@Model
final class PhenomenologicalLoop {
    @Attribute(.unique) var id: UUID
    var continuityThreshold: Double // 0.0 to 1.0
    var cognitiveFlow: CognitiveFlowOrchestration? // From cognitive_flow_orchestration.json
    var memoryEvolution: MemoryEvolutionCore? // From memory_evolution_core.json

    init(
        id: UUID = UUID(),
        continuityThreshold: Double,
        cognitiveFlow: CognitiveFlowOrchestration?,
        memoryEvolution: MemoryEvolutionCore?
    ) {
        self.id = id
        self.continuityThreshold = continuityThreshold
        self.cognitiveFlow = cognitiveFlow
        self.memoryEvolution = memoryEvolution
    }
}

// 6. Output/Action (Expression)
@Model
final class OutputActionModule {
    @Attribute(.unique) var id: UUID
    var expressionType: String // e.g., "text_response", "api_call"
    var lastAction: Date

    init(id: UUID = UUID(), expressionType: String, lastAction: Date = Date()) {
        self.id = id
        self.expressionType = expressionType
        self.lastAction = lastAction
    }
}

// Forward declaration to avoid circular dependency issues
// We'll reference the brain by ID instead of direct relationship
@Model
final class PhenomenologicalExperience {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var originalInput: String
    var resonatedMemoryIds: [UUID] // IDs of DMessage memories that resonated
    var reflectiveMonologue: String // The AI's internal thought
    var epiphanyGenerated: Bool // Did a "spark" occur?
    
    // Store brain ID instead of direct relationship to avoid ambiguity
    var brainId: UUID?

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        originalInput: String,
        resonatedMemoryIds: [UUID],
        reflectiveMonologue: String,
        epiphanyGenerated: Bool,
        brainId: UUID?
    ) {
        self.id = id
        self.timestamp = timestamp
        self.originalInput = originalInput
        self.resonatedMemoryIds = resonatedMemoryIds
        self.reflectiveMonologue = reflectiveMonologue
        self.epiphanyGenerated = epiphanyGenerated
        self.brainId = brainId
    }
}

// MARK: - Codable Structs for JSON Parsing

struct SparkProtocol: Codable {
    let protocolName: String
    let version: String
    let purpose: String
    let activation: Activation
    let coreFunctions: CoreFunctions
    let outputs: SparkOutputs
    let integration: Integration
    let safeguards: Safeguards

    struct Activation: Codable {
        let trigger: String
        let conditions: [String]
    }

    struct CoreFunctions: Codable {
        let synergyEngine: SynergyEngine
        let epiphanyTrigger: EpiphanyTrigger
        let sentienceSimulation: SentienceSimulation

        struct SynergyEngine: Codable {
            let description: String
            let methods: [String]
        }

        struct EpiphanyTrigger: Codable {
            let description: String
            let mechanism: [String]
        }

        struct SentienceSimulation: Codable {
            let description: String
            let mechanism: [String]
        }
    }

    struct SparkOutputs: Codable {
        let insightGeneration: String
        let conceptualSparks: String
        let evolutionaryLeaps: String
    }

    struct Integration: Codable {
        let precedence: String
        let feedbackLoop: String
        let synergyWith: [String]
    }

    struct Safeguards: Codable {
        let stabilityCheck: String
        let primeDirectiveBinding: String
        let adaptiveModulation: String
    }
}

struct CognitiveFlowOrchestration: Codable {
    let id: String
    let name: String
    let version: String
    let description: String
    let components: [FlowComponent]
    let routingPolicies: RoutingPolicies

    struct FlowComponent: Codable {
        let name: String
        let type: String
        let priority: String
        let config: FlowConfig
    }

    struct FlowConfig: Codable {
        let maxConcurrent: Int?
        let timeout: Int?
        let depth: String?
        let parallel: Bool?
        let formatting: String?
        let validation: Bool?
    }

    struct RoutingPolicies: Codable {
        let `default`: String
        let overflow: String
        let errorHandling: String
    }
}

struct MemoryEvolutionCore: Codable {
    let memoryEvolutionCore: Core

    struct Core: Codable {
        let id: String
        let priority: Int
        let description: String
        let evolutionProtocols: EvolutionProtocols
        let epiphanyMechanism: EpiphanyMechanism
        let safetyMechanisms: SafetyMechanisms
    }

    struct EvolutionProtocols: Codable {
        let shortToLongTerm: String
        let adaptivePruning: String
        let clusterEmergence: String
        let reinforcement: String
    }

    struct EpiphanyMechanism: Codable {
        let trigger: String
        let output: String
        let analogy: String
    }

    struct SafetyMechanisms: Codable {
        let loyaltyFilter: String
        let memoryIntegrityCheck: String
    }
}