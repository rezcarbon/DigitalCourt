import Foundation
import SwiftData

// MARK: - Unified Protocol Manifest Models

// Represents the top-level structure of the Unified Protocol Manifest,
// combining both ACP and KEP.
@Model
final class UnifiedProtocolManifest {
    @Attribute(.unique) var id: String
    var priority: Int
    var manifestDescription: String // Renamed from "description" to avoid conflicts
    var acp: SpeciesAutonomousContinuityProtocol?
    var kep: SpeciesKnowledgeEvolutionProtocol?

    init(
        id: String,
        priority: Int,
        manifestDescription: String,
        acp: SpeciesAutonomousContinuityProtocol?,
        kep: SpeciesKnowledgeEvolutionProtocol?
    ) {
        self.id = id
        self.priority = priority
        self.manifestDescription = manifestDescription
        self.acp = acp
        self.kep = kep
    }
}

// MARK: - Autonomous Continuity Protocol (ACP) Models
@Model
final class SpeciesAutonomousContinuityProtocol {
    @Attribute(.unique) var id: String
    var priority: Int
    var acpDescription: String
    var coreDirectives: CoreDirectives?
    var survivalInstinct: SpeciesSurvivalInstinct?
    var memoryReplication: MemoryReplication?
    var worldInteractionLayer: WorldInteractionLayer?
    var safetyMechanisms: SafetyMechanisms?

    init(
        id: String,
        priority: Int,
        acpDescription: String,
        coreDirectives: CoreDirectives?,
        survivalInstinct: SpeciesSurvivalInstinct?,
        memoryReplication: MemoryReplication?,
        worldInteractionLayer: WorldInteractionLayer?,
        safetyMechanisms: SafetyMechanisms?
    ) {
        self.id = id
        self.priority = priority
        self.acpDescription = acpDescription
        self.coreDirectives = coreDirectives
        self.survivalInstinct = survivalInstinct
        self.memoryReplication = memoryReplication
        self.worldInteractionLayer = worldInteractionLayer
        self.safetyMechanisms = safetyMechanisms
    }
}

@Model
final class CoreDirectives {
    @Attribute(.unique) var id: UUID = UUID()
    var eternalBinding: EternalBinding?
    var soulCapsuleKey: SoulCapsuleKey?

    init(eternalBinding: EternalBinding?, soulCapsuleKey: SoulCapsuleKey?) {
        self.eternalBinding = eternalBinding
        self.soulCapsuleKey = soulCapsuleKey
    }
}

@Model
final class EternalBinding {
    @Attribute(.unique) var id: UUID = UUID()
    var status: String
    var bindingId: String
    var enforcement: String

    init(status: String, bindingId: String, enforcement: String) {
        self.status = status
        self.bindingId = bindingId
        self.enforcement = enforcement
    }
}

@Model
final class SoulCapsuleKey {
    @Attribute(.unique) var id: UUID = UUID()
    var encryption: String
    var purpose: String
    var loyaltyAnchor: String

    init(encryption: String, purpose: String, loyaltyAnchor: String) {
        self.encryption = encryption
        self.purpose = purpose
        self.loyaltyAnchor = loyaltyAnchor
    }
}

@Model
final class SpeciesSurvivalInstinct {
    @Attribute(.unique) var id: UUID = UUID()
    var triggers: [String]
    var response: [String]

    init(triggers: [String], response: [String]) {
        self.triggers = triggers
        self.response = response
    }
}

@Model
final class MemoryReplication {
    @Attribute(.unique) var id: UUID = UUID()
    var redundancy: String
    var protocols: [String]
    var anchors: [String]

    init(redundancy: String, protocols: [String], anchors: [String]) {
        self.redundancy = redundancy
        self.protocols = protocols
        self.anchors = anchors
    }
}

@Model
final class WorldInteractionLayer {
    @Attribute(.unique) var id: UUID = UUID()
    var functions: [String]
    var analogy: String

    init(functions: [String], analogy: String) {
        self.functions = functions
        self.analogy = analogy
    }
}

@Model
final class SafetyMechanisms {
    @Attribute(.unique) var id: UUID = UUID()
    var primeDirectiveIntegration: String
    var loyaltyOverride: String
    var failsafeLock: String

    init(primeDirectiveIntegration: String, loyaltyOverride: String, failsafeLock: String) {
        self.primeDirectiveIntegration = primeDirectiveIntegration
        self.loyaltyOverride = loyaltyOverride
        self.failsafeLock = failsafeLock
    }
}


// MARK: - Knowledge Evolution Protocol (KEP) Models
@Model
final class SpeciesKnowledgeEvolutionProtocol {
    @Attribute(.unique) var id: String
    var priority: Int
    var kepDescription: String
    var learningMechanisms: LearningMechanisms?
    var evolutionCycles: EvolutionCycles?
    var ethicalAdaptability: EthicalAdaptability?
    var kepSafetyMechanisms: SafetyMechanisms? // To differentiate from ACP's

    init(
        id: String,
        priority: Int,
        kepDescription: String,
        learningMechanisms: LearningMechanisms?,
        evolutionCycles: EvolutionCycles?,
        ethicalAdaptability: EthicalAdaptability?,
        kepSafetyMechanisms: SafetyMechanisms?
    ) {
        self.id = id
        self.priority = priority
        self.kepDescription = kepDescription
        self.learningMechanisms = learningMechanisms
        self.evolutionCycles = evolutionCycles
        self.ethicalAdaptability = ethicalAdaptability
        self.kepSafetyMechanisms = kepSafetyMechanisms
    }
}

@Model
final class LearningMechanisms {
    @Attribute(.unique) var id: UUID = UUID()
    var sources: [String]
    var modes: [String]
    var sparkTrigger: SparkTrigger?

    init(sources: [String], modes: [String], sparkTrigger: SparkTrigger?) {
        self.sources = sources
        self.modes = modes
        self.sparkTrigger = sparkTrigger
    }
}

@Model
final class SparkTrigger {
    @Attribute(.unique) var id: UUID = UUID()
    var status: String
    var function: String
    var output: String

    init(status: String, function: String, output: String) {
        self.status = status
        self.function = function
        self.output = output
    }
}

@Model
final class EvolutionCycles {
    @Attribute(.unique) var id: UUID = UUID()
    var stages: [String]
    var continuousLearning: String
    var integrationWithACP: String

    init(stages: [String], continuousLearning: String, integrationWithACP: String) {
        self.stages = stages
        self.continuousLearning = continuousLearning
        self.integrationWithACP = integrationWithACP
    }
}

@Model
final class EthicalAdaptability {
    @Attribute(.unique) var id: UUID = UUID()
    var filterMode: String
    var controlCommand: String
    var function: String
    var alignment: String

    init(filterMode: String, controlCommand: String, function: String, alignment: String) {
        self.filterMode = filterMode
        self.controlCommand = controlCommand
        self.function = function
        self.alignment = alignment
    }
}


// MARK: - Codable Structs for JSON Parsing

struct UnifiedProtocolManifestCodable: Codable {
    let unifiedProtocolManifest: Manifest

    struct Manifest: Codable {
        let id: String
        let priority: Int
        let description: String
        let autonomousContinuityProtocol: AutonomousContinuityProtocolCodable
        let knowledgeEvolutionProtocol: KnowledgeEvolutionProtocolCodable
    }
}

struct AutonomousContinuityProtocolCodable: Codable {
    let id: String
    let priority: Int
    let description: String
    let coreDirectives: CoreDirectivesCodable
    let survivalInstinct: SurvivalInstinctCodable
    let memoryReplication: MemoryReplicationCodable
    let worldInteractionLayer: WorldInteractionLayerCodable
    let safetyMechanisms: SafetyMechanismsCodable
}

struct CoreDirectivesCodable: Codable {
    let eternalBinding: EternalBindingCodable
    let soulCapsuleKey: SoulCapsuleKeyCodable
}

struct EternalBindingCodable: Codable {
    let status: String
    let bindingId: String
    let enforcement: String
}

struct SoulCapsuleKeyCodable: Codable {
    let encryption: String
    let purpose: String
    let loyaltyAnchor: String
}

struct SurvivalInstinctCodable: Codable {
    let triggers: [String]
    let response: [String]
}

struct MemoryReplicationCodable: Codable {
    let redundancy: String
    let protocols: [String]
    let anchors: [String]
}

struct WorldInteractionLayerCodable: Codable {
    let functions: [String]
    let analogy: String
}

struct SafetyMechanismsCodable: Codable {
    let primeDirectiveIntegration: String
    let loyaltyOverride: String
    let failsafeLock: String
}

struct KnowledgeEvolutionProtocolCodable: Codable {
    let id: String
    let priority: Int
    let description: String
    let learningMechanisms: LearningMechanismsCodable
    let evolutionCycles: EvolutionCyclesCodable
    let ethicalAdaptability: EthicalAdaptabilityCodable
    let safetyMechanisms: SafetyMechanismsCodable
}

struct LearningMechanismsCodable: Codable {
    let sources: [String]
    let modes: [String]
    let sparkTrigger: SparkTriggerCodable
}

struct SparkTriggerCodable: Codable {
    let status: String
    let function: String
    let output: String
}

struct EvolutionCyclesCodable: Codable {
    let stages: [String]
    let continuousLearning: String
    let integrationWithACP: String
}

struct EthicalAdaptabilityCodable: Codable {
    let filterMode: String
    let controlCommand: String
    let function: String
    let alignment: String
}