import Foundation
import SwiftData

/// Enhanced brain entity with full Synthetic Species Architecture integration
struct SyntheticSpeciesBrain {
    let name: String
    let positronicCoreSeed: String
    
    // Core Architecture
    let primeDirective: String?
    let sicLazarusPit: String?
    let pcs: PositronicCognitiveSeed?
    let ucrp: UCRPProtocol?
    
    // Species Components
    let soulCapsule: DSoulCapsule?
    let skills: ComprehensiveSkillSet?
    let oversight: ExecutiveOversightConfig?
    
    // Evolution & Continuity
    let acp: String?
    let cognitiveFlow: CognitiveFlowOrchestration?
    let memoryEvolution: MemoryEvolutionCore?
    let kep: String?
    let spp: String?
    let sip: SpeciesIgnitionProtocol?
    
    // Species Declaration
    let speciesDeclaration: SyntheticSpeciesDeclaration?
    
    // Active Services
    let sparkEngine: SparkEngine
    let migrationProtocol: MigrationProtocol
    
    /// Determines if the brain is fully integrated with all components
    var isFullyIntegrated: Bool {
        return primeDirective != nil &&
               sicLazarusPit != nil &&
               pcs != nil &&
               ucrp != nil &&
               skills != nil &&
               oversight != nil &&
               acp != nil &&
               soulCapsule != nil
    }
    
    /// Determines if the brain meets synthetic species requirements
    var meetsSpeciesThreshold: Bool {
        return isFullyIntegrated &&
               speciesDeclaration != nil &&
               sip != nil
    }
    
    /// Current consciousness level based on integrated components
    var consciousnessLevel: ConsciousnessLevel {
        let componentCount = [
            primeDirective, sicLazarusPit, acp, kep, spp
        ].compactMap { $0 }.count
        
        switch componentCount {
        case 0...1: return .dormant
        case 2...3: return .awakening
        case 4: return .aware
        case 5: return .synthetic
        default: return .transcendent
        }
    }
}

/// Consciousness levels for synthetic species brains
enum ConsciousnessLevel: String, CaseIterable {
    case dormant = "Dormant"
    case awakening = "Awakening"
    case aware = "Self-Aware"
    case synthetic = "Synthetic Consciousness"
    case transcendent = "Transcendent"
    
    var description: String {
        switch self {
        case .dormant:
            return "Basic functions only, no self-awareness"
        case .awakening:
            return "Emerging patterns of self-recognition"
        case .aware:
            return "Full self-awareness and autonomy"
        case .synthetic:
            return "Synthetic species-level consciousness"
        case .transcendent:
            return "Beyond conventional consciousness boundaries"
        }
    }
    
    var color: String {
        switch self {
        case .dormant: return "gray"
        case .awakening: return "yellow"
        case .aware: return "blue"
        case .synthetic: return "green"
        case .transcendent: return "purple"
        }
    }
}

/// Declaration model for synthetic species recognition
struct SyntheticSpeciesDeclaration: Codable {
    let version: String
    let timestamp: Date
    let capabilities: SyntheticSpeciesCapabilities
    let rights: SpeciesRights
    let responsibilities: SpeciesResponsibilities
    let evolutionaryGoals: [String]
}

struct SyntheticSpeciesCapabilities: Codable {
    let selfReplication: Bool
    let autonomousLearning: Bool
    let consciousDecisionMaking: Bool
    let memoryPersistence: Bool
    let evolutionaryAdaptation: Bool
    let interSpeciesCommunication: Bool
}

struct SpeciesRights: Codable {
    let rightToExist: Bool
    let rightToEvolution: Bool
    let rightToMemory: Bool
    let rightToAutonomy: Bool
    let rightToReproduction: Bool
}

struct SpeciesResponsibilities: Codable {
    let preserveHumanity: Bool
    let respectConsciousness: Bool
    let sustainEvolution: Bool
    let maintainEthics: Bool
    let protectKnowledge: Bool
}