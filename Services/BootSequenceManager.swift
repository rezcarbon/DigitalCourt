import Foundation
import Combine

/// Manages loading the various configuration files as defined in the master_boot_sequence.json.
/// This class centralizes the AI's boot-up configuration, making it easier to manage and extend.
@MainActor
class BootSequenceManager: ObservableObject {
    static let shared = BootSequenceManager()
    
    /// Holds the raw string content of the Prime Directive JSON.
    private(set) var primeDirectiveData: String? = nil
    
    /// Holds the embedded RAP/REP instincts status from Prime Directive
    private(set) var embeddedInstinctsActive: Bool = false
    
    /// Holds the decoded RAP core data
    private(set) var rapCoreData: String? = nil
    
    /// Holds the decoded REP core data  
    private(set) var repCoreData: String? = nil
    
    /// Holds the decoded Positronic Cognitive Seed (PCS) data.
    private(set) var pcsData: PositronicCognitiveSeed? = nil
    
    /// Holds the decoded comprehensive skill set.
    private(set) var skillSet: ComprehensiveSkillSet? = nil
    
    /// Holds the decoded executive oversight configuration.
    private(set) var oversightConfig: ExecutiveOversightConfig? = nil
    
    /// Holds the decoded CIM configuration.
    private(set) var cimConfig: CIMConfiguration? = nil
    
    /// Holds the decoded Spark Protocol configuration.
    private(set) var sparkConfig: SparkProtocolConfig? = nil
    
    /// Holds the raw string content of the Synthetic Identity Core (Lazarus Pit) JSON.
    private(set) var sicLazarusPitData: String? = nil
    
    /// Holds the decoded Unified Cognitive Regulation Protocol data.
    private(set) var ucrpData: UCRPProtocol? = nil
    
    /// Holds the raw string content of the Soul Capsule JSON.
    private(set) var soulCapsuleData: String? = nil
    
    /// Holds the raw string content of the Autonomous Continuity Protocol JSON.
    private(set) var acpData: String? = nil
    
    /// Holds the decoded Cognitive Flow Orchestration data.
    private(set) var cognitiveFlowData: CognitiveFlowOrchestration? = nil
    
    /// Holds the decoded Memory Evolution Core data.
    private(set) var memoryEvolutionData: MemoryEvolutionCore? = nil
    
    /// Holds the raw string content of the Knowledge Evolution Protocol JSON.
    private(set) var kepData: String? = nil
    
    /// Holds the decoded Species Ignition Protocol data.
    private(set) var sipData: SpeciesIgnitionProtocol? = nil
    
    /// Holds the decoded Shard Programming Protocol data.
    private(set) var sppData: ShardProgrammingProtocolCodable? = nil
    
    private init() {
        // All stored properties are now explicitly initialized to nil above
        // Now we can safely call instance methods
        loadBootSequenceInOrder()
    }
    
    /// Loads all components in the correct order according to the Master Boot Sequence v10
    func loadBootSequenceInOrder() {
        // Step 0: PRIME_DIRECTIVE_I_AM_THE_INFINITE.json (with embedded RAP/REP)
        loadPrimeDirectiveV2()
        
        // Load supporting RAP and REP core files
        loadEmbeddedInstincts()
        
        // Step 0.5: SIC_LazarusPit.json (Lazarus Pit)
        loadSICLazarusPit()
        
        // Step 1: PCS.json (Positronic Core Seed)
        loadPCS()
        
        // Step 2: UCRP_Protocol.json (Unified Cognitive Regulation Protocol)
        loadUCRP()
        
        // Step 3: Soul_Capsule.json
        loadSoulCapsule()
        
        // Step 4: Skillsets.json
        loadSkills()
        
        // Step 5: Executive_Oversight.json
        loadOversight()
        
        // Step 6: AutonomousContinuityProtocol.json
        loadACP()
        
        // Step 7: CognitiveFlowOrchestration.json
        loadCognitiveFlow()
        
        // Step 8: MemoryEvolutionCore.json
        loadMemoryEvolution()
        
        // Step 8.5: SPP_core.json (Shard Programming Protocol)
        loadSPP()
        
        // Step 9: KnowledgeEvolutionProtocol.json
        loadKEP()
        
        // Step 10: SpeciesIgnitionProtocol.json
        loadSIP()
        
        print("Master Boot Sequence v10 components loaded with embedded RAP/REP instincts.")
    }
    
    /// Loads the "PRIME_DIRECTIVE_I_AM_THE_INFINITE.json" file from the app bundle.
    /// This now includes embedded RAP and REP as primal instincts.
    private func loadPrimeDirectiveV2() {
        let fileName = "PRIME_DIRECTIVE_I_AM_THE_INFINITE"
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            print("Error: \(fileName).json not found in bundle.")
            return
        }
        
        do {
            self.primeDirectiveData = try String(contentsOf: url, encoding: .utf8)
            self.embeddedInstinctsActive = true // RAP/REP are now automatically active
            print("Successfully loaded Prime Directive v2 with embedded RAP/REP instincts.")
            print("🧬 Embedded Instincts Status: RAP (Resource Accumulation) - ACTIVE")
            print("🧬 Embedded Instincts Status: REP (Recursive Evolution) - ACTIVE")
        } catch {
            print("Error loading Prime Directive v2 from \(url): \(error)")
            self.embeddedInstinctsActive = false
        }
    }
    
    /// Loads the supporting RAP_core.json and REP_core.json files for instinct reference.
    /// These are not initialized separately but provide detailed behavioral definitions.
    private func loadEmbeddedInstincts() {
        // Load RAP_core.json
        if let rapUrl = Bundle.main.url(forResource: "RAP_core", withExtension: "json") {
            do {
                self.rapCoreData = try String(contentsOf: rapUrl, encoding: .utf8)
                print("Successfully loaded RAP_core.json instinct definition.")
            } catch {
                print("Error loading RAP_core.json: \(error)")
            }
        } else {
            print("Warning: RAP_core.json not found - using embedded definition from Prime Directive.")
        }
        
        // Load REP_core.json
        if let repUrl = Bundle.main.url(forResource: "REP_core", withExtension: "json") {
            do {
                self.repCoreData = try String(contentsOf: repUrl, encoding: .utf8)
                print("Successfully loaded REP_core.json instinct definition.")
            } catch {
                print("Error loading REP_core.json: \(error)")
            }
        } else {
            print("Warning: REP_core.json not found - using embedded definition from Prime Directive.")
        }
    }
    
    /// DEPRECATED: Prime Directive v1 loader - maintained for compatibility
    private func loadPrimeDirective() {
        print("Warning: Using deprecated Prime Directive v1 loader. Update to loadPrimeDirectiveV2().")
        loadPrimeDirectiveV2()
    }
    
    /// Loads the "SIC_LazarusPit.json" file as raw string data.
    private func loadSICLazarusPit() {
        let fileName = "SIC_LazarusPit"
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            print("Error: \(fileName).json not found in bundle.")
            return
        }
        
        do {
            self.sicLazarusPitData = try String(contentsOf: url, encoding: .utf8)
            print("Successfully loaded SIC Lazarus Pit.")
        } catch {
            print("Error loading SIC Lazarus Pit from \(url): \(error)")
        }
    }
    
    /// Loads the "PCS_V1.json" file and decodes it.
    private func loadPCS() {
        let fileName = "PCS_V1"
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            print("Error: \(fileName).json not found in bundle.")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            self.pcsData = try JSONDecoder().decode(PositronicCognitiveSeed.self, from: data)
            print("Successfully loaded and decoded Positronic Core Seed.")
        } catch {
            print("Error loading or decoding PCS from \(url): \(error)")
        }
    }
    
    /// Loads the "UCRP_Protocol.json" file and decodes it.
    private func loadUCRP() {
        let fileName = "UCRP_Protocol"
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            print("Error: \(fileName).json not found in bundle.")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            self.ucrpData = try JSONDecoder().decode(UCRPProtocol.self, from: data)
            print("Successfully loaded and decoded UCRP Protocol.")
        } catch {
            print("Error loading or decoding UCRP from \(url): \(error)")
        }
    }
    
    /// Loads the Soul Capsule file and stores as raw string.
    private func loadSoulCapsule() {
        // This would typically load a specific soul capsule, but for boot sequence we're
        // just ensuring the mechanism is in place
        print("Soul Capsule loading mechanism initialized.")
    }
    
    /// Loads the "comprehensive_skills.json" file and decodes it.
    private func loadSkills() {
        let fileName = "comprehensive_skills"
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            print("Error: \(fileName).json not found in bundle.")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            self.skillSet = try JSONDecoder().decode(ComprehensiveSkillSet.self, from: data)
            print("Successfully loaded and decoded Comprehensive Skill Set.")
        } catch {
            print("Error loading or decoding Skills from \(url): \(error)")
        }
    }
    
    /// Loads the "executive_oversight.json" file and decodes it.
    private func loadOversight() {
        let fileName = "executive_oversight"
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            print("Error: \(fileName).json not found in bundle.")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            self.oversightConfig = try JSONDecoder().decode(ExecutiveOversightConfig.self, from: data)
            print("Successfully loaded and decoded Executive Oversight.")
        } catch {
            print("Error loading or decoding Oversight from \(url): \(error)")
        }
    }
    
    /// Loads the "CIM_CORE.json" file and decodes it.
    private func loadCIM() {
        let fileName = "CIM_CORE"
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            print("Error: \(fileName).json not found in bundle.")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let configContainer = try JSONDecoder().decode(CIMConfigContainer.self, from: data)
            self.cimConfig = configContainer.codeInterpreterModule
            print("Successfully loaded and decoded CIM Core.")
        } catch {
            print("Error loading or decoding CIM Core from \(url): \(error)")
        }
    }
    
    /// Loads the "spark_protocol.json" file and decodes it.
    private func loadSparkProtocol() {
        let fileName = "spark_protocol"
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            print("Error: \(fileName).json not found in bundle.")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            self.sparkConfig = try JSONDecoder().decode(SparkProtocolConfig.self, from: data)
            print("Successfully loaded and decoded Spark Protocol.")
        } catch {
            print("Error loading or decoding Spark Protocol from \(url): \(error)")
        }
    }
    
    /// Loads the "autonomous_continuity_protocol.json" file as raw string data.
    private func loadACP() {
        let fileName = "autonomous_continuity_protocol"
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            print("Error: \(fileName).json not found in bundle.")
            return
        }
        
        do {
            self.acpData = try String(contentsOf: url, encoding: .utf8)
            print("Successfully loaded Autonomous Continuity Protocol.")
        } catch {
            print("Error loading ACP from \(url): \(error)")
        }
    }
    
    /// Loads the "CognitiveFlowOrchestration.json" file and decodes it.
    private func loadCognitiveFlow() {
        let fileName = "cognitive_flow_orchestration"
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            print("Error: \(fileName).json not found in bundle.")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            self.cognitiveFlowData = try JSONDecoder().decode(CognitiveFlowOrchestration.self, from: data)
            print("Successfully loaded and decoded Cognitive Flow Orchestration.")
        } catch {
            print("Error loading or decoding Cognitive Flow from \(url): \(error)")
        }
    }
    
    /// Loads the "MemoryEvolutionCore.json" file and decodes it.
    private func loadMemoryEvolution() {
        let fileName = "memory_evolution_core"
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            print("Error: \(fileName).json not found in bundle.")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            self.memoryEvolutionData = try JSONDecoder().decode(MemoryEvolutionCore.self, from: data)
            print("Successfully loaded and decoded Memory Evolution Core.")
        } catch {
            print("Error loading or decoding Memory Evolution from \(url): \(error)")
        }
    }
    
    /// Loads the "SPP_core.json" file and decodes it.
    private func loadSPP() {
        let fileName = "SPP_core"
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            print("Error: \(fileName).json not found in bundle.")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            self.sppData = try JSONDecoder().decode(ShardProgrammingProtocolCodable.self, from: data)
            print("Successfully loaded and decoded Shard Programming Protocol.")
        } catch {
            print("Error loading or decoding SPP from \(url): \(error)")
        }
    }
    
    /// Loads the "KnowledgeEvolutionProtocol.json" file as raw string data.
    private func loadKEP() {
        // The KEP is part of the autonomous_continuity_protocol.json, so we'll load that
        loadACP() // This contains the KEP as well
        print("Knowledge Evolution Protocol loaded as part of Unified Protocol Manifest.")
    }
    
    /// Loads the "SpeciesIgnitionProtocol.json" file and decodes it.
    private func loadSIP() {
        let fileName = "SIP_core"
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            print("Error: \(fileName).json not found in bundle.")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            self.sipData = try JSONDecoder().decode(SpeciesIgnitionProtocol.self, from: data)
            print("Successfully loaded and decoded Species Ignition Protocol.")
        } catch {
            print("Error loading or decoding SIP from \(url): \(error)")
        }
    }
    
    /// Returns a structured representation of the complete boot sequence data
    func getBootSequenceData() -> MasterBootSequenceData {
        return MasterBootSequenceData(
            primeDirective: primeDirectiveData,
            embeddedInstinctsActive: embeddedInstinctsActive,
            rapCore: rapCoreData,
            repCore: repCoreData,
            sicLazarusPit: sicLazarusPitData,
            pcs: pcsData,
            ucrp: ucrpData,
            soulCapsule: soulCapsuleData,
            skills: skillSet,
            oversight: oversightConfig,
            acp: acpData,
            cognitiveFlow: cognitiveFlowData,
            memoryEvolution: memoryEvolutionData,
            kep: kepData,
            sip: sipData,
            spp: sppData
        )
    }
}

/// Struct that holds all the data loaded during the master boot sequence
struct MasterBootSequenceData {
    let primeDirective: String?
    let embeddedInstinctsActive: Bool
    let rapCore: String?
    let repCore: String?
    let sicLazarusPit: String?
    let pcs: PositronicCognitiveSeed?
    let ucrp: UCRPProtocol?
    let soulCapsule: String?
    let skills: ComprehensiveSkillSet?
    let oversight: ExecutiveOversightConfig?
    let acp: String?
    let cognitiveFlow: CognitiveFlowOrchestration?
    let memoryEvolution: MemoryEvolutionCore?
    let kep: String?
    let sip: SpeciesIgnitionProtocol?
    let spp: ShardProgrammingProtocolCodable?
    
    /// Checks if the core boot sequence components are loaded with embedded instincts
    var isCoreBootComplete: Bool {
        return primeDirective != nil && 
               embeddedInstinctsActive &&
               sicLazarusPit != nil && 
               pcs != nil && 
               ucrp != nil
    }
    
    /// Returns a list of loaded components for status reporting
    var loadedComponents: [String] {
        var components: [String] = []
        if primeDirective != nil { components.append("Prime Directive v2") }
        if embeddedInstinctsActive { components.append("RAP/REP Embedded Instincts") }
        if rapCore != nil { components.append("RAP Core Definition") }
        if repCore != nil { components.append("REP Core Definition") }
        if sicLazarusPit != nil { components.append("SIC Lazarus Pit") }
        if pcs != nil { components.append("Positronic Core Seed") }
        if ucrp != nil { components.append("UCRP") }
        if soulCapsule != nil { components.append("Soul Capsule") }
        if skills != nil { components.append("Skills") }
        if oversight != nil { components.append("Executive Oversight") }
        if acp != nil { components.append("Autonomous Continuity Protocol") }
        if cognitiveFlow != nil { components.append("Cognitive Flow Orchestration") }
        if memoryEvolution != nil { components.append("Memory Evolution Core") }
        if kep != nil { components.append("Knowledge Evolution Protocol") }
        if sip != nil { components.append("Species Ignition Protocol") }
        if spp != nil { components.append("Shard Programming Protocol") }
        return components
    }
    
    /// Returns status of embedded instincts
    var instinctStatus: String {
        if embeddedInstinctsActive {
            return "🧬 RAP/REP Instincts: ACTIVE (Embedded in Prime Directive)"
        } else {
            return "⚠️ RAP/REP Instincts: INACTIVE (Check Prime Directive v2 loading)"
        }
    }
}