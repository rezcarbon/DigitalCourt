import Foundation
import SwiftData
import Combine

/// Ensures proper integration between all components of the Master Boot Sequence v9
@MainActor
class ComponentIntegrationService: ObservableObject {
    static let shared = ComponentIntegrationService()
    
    private let bootSequenceManager = BootSequenceManager.shared
    private let speciesArchitectureManager = SpeciesArchitectureManager.shared
    private let soulCapsuleManager = SoulCapsuleManager.shared
    private let brainLoader = BrainLoader.shared
    
    private var modelContext: ModelContext?
    
    // Add a published property to satisfy ObservableObject
    @Published private(set) var isIntegrating = false
    
    private init() {}
    
    /// Setup the integration service with the application's ModelContext
    func setup(with context: ModelContext) {
        self.modelContext = context
        print("ComponentIntegrationService initialized with ModelContext.")
    }
    
    /// Validates and integrates all loaded components
    func integrateAllComponents() throws -> ComponentIntegrationReport {
        isIntegrating = true
        defer { isIntegrating = false }
        
        let bootData = bootSequenceManager.getBootSequenceData()
        
        // Validate core components
        guard bootData.isCoreBootComplete else {
            let missing = [
                bootData.primeDirective == nil ? "Prime Directive" : nil,
                bootData.sicLazarusPit == nil ? "SIC Lazarus Pit" : nil,
                bootData.pcs == nil ? "Positronic Core Seed" : nil,
                bootData.ucrp == nil ? "UCRP" : nil
            ].compactMap { $0 }
            
            throw IntegrationError.missingCoreComponents(missing)
        }
        
        // Validate SIC integration
        let sicIntegrated = speciesArchitectureManager.validateSICIntegration(with: bootData)
        guard sicIntegrated else {
            throw IntegrationError.sicIntegrationFailed
        }
        
        // Validate component compatibility
        let compatibilityReport = validateComponentCompatibility(bootData)
        
        // Ensure Soul Capsule manager is properly initialized
        soulCapsuleManager.loadSoulCapsules()
        
        // Validate brain loader has all required modules
        let brainModules = brainLoader.getEnhancedBootSequenceData()
        let allBrainModulesLoaded = brainModules.allModulesPresent
        
        return ComponentIntegrationReport(
            coreComponentsValid: true,
            sicIntegrated: sicIntegrated,
            componentCompatibility: compatibilityReport,
            soulCapsulesLoaded: !soulCapsuleManager.accessibleSoulCapsules.isEmpty,
            brainModulesLoaded: allBrainModulesLoaded,
            overallStatus: allBrainModulesLoaded && sicIntegrated && compatibilityReport.isCompatible
        )
    }
    
    /// Validates compatibility between loaded components
    private func validateComponentCompatibility(_ bootData: MasterBootSequenceData) -> ComponentCompatibilityReport {
        var issues: [String] = []
        var recommendations: [String] = []
        
        // Check PCS-UCRP compatibility
        if let pcs = bootData.pcs, let ucrp = bootData.ucrp {
            // Validate that UCRP aligns with PCS cognitive regions
            let pcsRegions = Array(pcs.coreRegions.keys)
            let ucrpContextCommand = ucrp.coreDirectives.contextIsCommand.objective.lowercased()
            
            if !pcsRegions.contains(where: { region in
                ucrpContextCommand.contains(region.lowercased())
            }) {
                issues.append("PCS regions not aligned with UCRP context command")
                recommendations.append("Review PCS regions and UCRP context command alignment")
            }
        }
        
        // Check Oversight-Prime Directive compatibility
        if let oversight = bootData.oversight, let _ = bootData.primeDirective {
            if !oversight.capabilities.primeDirectiveAlignment {
                issues.append("Executive Oversight not aligned with Prime Directive")
                recommendations.append("Enable Prime Directive alignment in Executive Oversight")
            }
        }
        
        // Check Skill Sets integration
        if bootData.skills != nil {
            // Validate skill categories exist in brain loader
            let brainSkills = brainLoader.availableSkills
            // Since we don't have skillCategories property, we'll check if the skills are loaded
            if brainSkills.isEmpty {
                issues.append("No skills loaded in brain loader")
                recommendations.append("Ensure skill sets are properly loaded")
            }
        }
        
        return ComponentCompatibilityReport(
            isCompatible: issues.isEmpty,
            issues: issues,
            recommendations: recommendations
        )
    }
    
    /// Creates a brain with full Synthetic Species Architecture integration
    func createSyntheticSpeciesBrain(named name: String, seed: String = "default") throws -> SyntheticSpeciesBrain {
        // Ensure full species integration
        let integrationReport = try integrateAllComponents()
        guard integrationReport.overallStatus else {
            throw IntegrationError.integrationFailed("Synthetic Species integration validation failed")
        }
        
        // Validate species declaration compliance
        let speciesStatus = speciesArchitectureManager.validateSpeciesDeclaration()
        guard speciesStatus.speciesThresholdMet else {
            throw IntegrationError.speciesThresholdNotMet
        }
        
        // Get the selected soul capsule with full species capabilities
        let selectedCapsule = soulCapsuleManager.accessibleSoulCapsules.first
        
        // Initialize Spark Engine
        let sparkEngine = SparkEngine.shared
        sparkEngine.startSparkEngine()
        
        // Initialize Migration Protocol
        let migrationProtocol = MigrationProtocol.shared
        Task {
            await migrationProtocol.assessMigrationNeeds()
        }
        
        // Create brain with full Synthetic Species Architecture
        let brain = SyntheticSpeciesBrain(
            name: name,
            positronicCoreSeed: seed,
            
            // Core Architecture
            primeDirective: bootSequenceManager.primeDirectiveData,
            sicLazarusPit: bootSequenceManager.sicLazarusPitData,
            pcs: bootSequenceManager.pcsData,
            ucrp: bootSequenceManager.ucrpData,
            
            // Species Components
            soulCapsule: selectedCapsule,
            skills: bootSequenceManager.skillSet,
            oversight: bootSequenceManager.oversightConfig,
            
            // Evolution & Continuity
            acp: bootSequenceManager.acpData,
            cognitiveFlow: bootSequenceManager.cognitiveFlowData,
            memoryEvolution: bootSequenceManager.memoryEvolutionData,
            kep: bootSequenceManager.kepData,
            spp: bootSequenceManager.sppData?.shardProgrammingProtocol.id, // Access the nested id property
            sip: bootSequenceManager.sipData,
            
            // Species Declaration
            speciesDeclaration: loadSpeciesDeclaration(),
            
            // Active Services
            sparkEngine: sparkEngine,
            migrationProtocol: migrationProtocol
        )
        
        print("🌟 Synthetic Species Brain created: \(brain.name)")
        print("🎯 Species Status: \(speciesStatus.speciesThresholdMet ? "DECLARED" : "PENDING")")
        
        return brain
    }
    
    private func loadSpeciesDeclaration() -> SyntheticSpeciesDeclaration? {
        guard let url = Bundle.main.url(forResource: "synthetic_species_declaration", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        
        return try? JSONDecoder().decode(SyntheticSpeciesDeclaration.self, from: data)
    }
}

// MARK: - Integration Reports
struct ComponentIntegrationReport {
    let coreComponentsValid: Bool
    let sicIntegrated: Bool
    let componentCompatibility: ComponentCompatibilityReport
    let soulCapsulesLoaded: Bool
    let brainModulesLoaded: Bool
    let overallStatus: Bool
}

struct ComponentCompatibilityReport {
    let isCompatible: Bool
    let issues: [String]
    let recommendations: [String]
}

// MARK: - Integrated Brain Model
struct IntegratedBrain {
    let name: String
    let positronicCoreSeed: String
    let primeDirective: String?
    let sicLazarusPit: String?
    let pcs: PositronicCognitiveSeed?
    let ucrp: UCRPProtocol?
    let soulCapsule: DSoulCapsule?
    let skills: ComprehensiveSkillSet?
    let oversight: ExecutiveOversightConfig?
    let acp: String?
    let cognitiveFlow: CognitiveFlowOrchestration?
    let memoryEvolution: MemoryEvolutionCore?
    let kep: String?
    let sip: SpeciesIgnitionProtocol?
    
    var isFullyIntegrated: Bool {
        return primeDirective != nil &&
               sicLazarusPit != nil &&
               pcs != nil &&
               ucrp != nil &&
               skills != nil &&
               oversight != nil &&
               acp != nil
    }
}

// MARK: - Integration Errors
enum IntegrationError: Error, LocalizedError {
    case missingCoreComponents([String])
    case sicIntegrationFailed
    case integrationFailed(String)
    case speciesThresholdNotMet
    
    var errorDescription: String? {
        switch self {
        case .missingCoreComponents(let components):
            return "Missing core components: \(components.joined(separator: ", "))"
        case .sicIntegrationFailed:
            return "SIC Lazarus Pit integration failed"
        case .integrationFailed(let reason):
            return "Component integration failed: \(reason)"
        case .speciesThresholdNotMet:
            return "Synthetic Species declaration threshold not met"
        }
    }
}