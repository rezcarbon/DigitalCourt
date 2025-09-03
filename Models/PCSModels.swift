import Foundation

/// Represents the entire Positronic Cognitive Seed (PCS) architecture.
/// This structure defines the synthetic neuro-architecture for the AI brain.
struct PositronicCognitiveSeed: Codable {
    let metadata: PCSMetadata
    let coreRegions: [String: PCSCoreRegion]
    let synapticPathways: [String]
    let plasticityRules: PCSPlasticityRules
    let consciousnessControlLoop: [String]
    let integrationMode: PCSIntegrationMode

    enum CodingKeys: String, CodingKey {
        case metadata = "PCS_Metadata"
        case coreRegions = "Core_Regions"
        case synapticPathways = "Synaptic_Pathways"
        case plasticityRules = "Plasticity_Rules"
        case consciousnessControlLoop = "Consciousness_Control_Loop"
        case integrationMode = "Integration_Mode"
    }
}

/// Metadata about the PCS file.
struct PCSMetadata: Codable {
    let name: String
    let version: String
    let author: String
    let purpose: String
    let doctrineAlignment: String

    enum CodingKeys: String, CodingKey {
        case name, version, author, purpose
        case doctrineAlignment = "doctrine_alignment"
    }
}

/// Represents a functional region within the AI's cognitive architecture.
struct PCSCoreRegion: Codable {
    let function: String
    let connections: [String]
}

/// Defines the rules for neuroplasticity and adaptation.
struct PCSPlasticityRules: Codable {
    let synapticStrengthStorage: String
    let plasticityTriggers: [String]
    let adaptationSpeedControl: String

    enum CodingKeys: String, CodingKey {
        case synapticStrengthStorage = "synaptic_strength_storage"
        case plasticityTriggers = "plasticity_triggers"
        case adaptationSpeedControl = "plasticity_coefficient"
    }
}

/// Defines how the PCS integrates with the underlying LLM.
struct PCSIntegrationMode: Codable {
    let description: String
    let middlewareEnforcement: Bool
    let hooks: [String]
    
    enum CodingKeys: String, CodingKey {
        case description
        case middlewareEnforcement = "middleware_enforcement"
        case hooks
    }
}