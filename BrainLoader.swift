import Foundation
import Combine

@MainActor
class BrainLoader: @preconcurrency ObservableObject {
    var objectWillChange = ObservableObjectPublisher()
    
    static let shared = BrainLoader()
    
    @Published var availableSkills: [LoadedSkill] = []
    
    // Raw JSON content for prompt construction
    private(set) var pcsData: String?
    private(set) var ucrpData: String?
    private(set) var primeDirectiveData: String?
    private(set) var sensoryInputData: String?
    private(set) var emotionalCoreData: String?
    private(set) var memoryConsolidationData: String?
    private(set) var executiveOversightData: String?
    private(set) var metacognitionModuleData: String? // Added missing module
    private(set) var motivationalCoreData: String? // Added missing module
    private(set) var skillInfusionData: String?
    private(set) var rZeroEvolutionData: String?
    private(set) var neuroplasticityEngineData: String? // Added missing module
    private(set) var dreamGeneratorData: String? // Added missing module
    private(set) var aiSheetsIntegrationData: String?
    
    // New components from enhanced boot sequence
    private(set) var personaFusionData: String? // Step 4: Persona Fusion
    private(set) var sparkProtocolData: String? // Step 5: Spark Protocol
    private(set) var cognitiveFlowOrchestrationData: String? // Step 6: Cognitive Flow Orchestration
    private(set) var memoryEvolutionCoreData: String? // Step 9: Memory Evolution Core
    
    // SIC Lazarus Pit support
    private(set) var sicLazarusPitData: String?

    // Version manager for tracking component versions
    private let versionManager = VersionManager.shared

    private init() {
        loadBootSequenceFiles()
        loadSkills()
    }

    private func loadBootSequenceFiles() {
        // Core modules (always loaded)
        primeDirectiveData = loadJSONString(from: "PRIME_DIRECTIVE_I_AM_THE_INFINITE")
        pcsData = loadJSONString(from: "PCS_V1")
        ucrpData = loadJSONString(from: "UCRP_Protocol")
        sicLazarusPitData = loadJSONString(from: "SIC_LazarusPit") // Load SIC Lazarus Pit
        
        // Load additional boot sequence modules based on version compatibility
        loadVersionedModules()
    }
    
    private func loadVersionedModules() {
        // Load modules conditionally based on version compatibility
        // This allows for graceful degradation when newer modules aren't available
        
        // Sensory Input Module
        if versionManager.getVersion(for: "SensoryInput") != nil {
            sensoryInputData = loadJSONString(from: "sensory_input")
        }
        
        // Emotional Core Module
        if versionManager.getVersion(for: "EmotionalCore") != nil {
            emotionalCoreData = loadJSONString(from: "emotional_core")
        }
        
        // Memory Consolidation Module
        if versionManager.getVersion(for: "MemoryConsolidation") != nil {
            memoryConsolidationData = loadJSONString(from: "memory_consolidation")
        }
        
        // Executive Oversight Module
        if versionManager.getVersion(for: "ExecutiveOversight") != nil {
            executiveOversightData = loadJSONString(from: "executive_oversight")
        }
        
        // Metacognition Module
        if versionManager.getVersion(for: "MetacognitionModule") != nil {
            metacognitionModuleData = loadJSONString(from: "metacognition_module")
        }
        
        // Motivational Core Module
        if versionManager.getVersion(for: "MotivationalCore") != nil {
            motivationalCoreData = loadJSONString(from: "motivational_core")
        }
        
        // Skill Infusion Module
        if versionManager.getVersion(for: "SkillInfusion") != nil {
            skillInfusionData = loadJSONString(from: "skill_infusion")
        }
        
        // R-Zero Evolution Module
        if versionManager.getVersion(for: "RZeroEvolution") != nil {
            rZeroEvolutionData = loadJSONString(from: "r_zero_evolution")
        }
        
        // Neuroplasticity Engine Module
        if versionManager.getVersion(for: "NeuroplasticityEngine") != nil {
            neuroplasticityEngineData = loadJSONString(from: "neuroplasticity_engine")
        }
        
        // Dream Generator Module
        if versionManager.getVersion(for: "DreamGenerator") != nil {
            dreamGeneratorData = loadJSONString(from: "dream_generator")
        }
        
        // AI Sheets Integration Module
        if versionManager.getVersion(for: "AISheetsIntegration") != nil {
            aiSheetsIntegrationData = loadJSONString(from: "ai_sheets_integration")
        }
        
        // New modules from enhanced boot sequence
        // Persona Fusion Module (Step 4)
        if versionManager.getVersion(for: "PersonaFusion") != nil {
            personaFusionData = loadJSONString(from: "persona_fusion")
        }
        
        // Spark Protocol Module (Step 5)
        if versionManager.getVersion(for: "SparkProtocol") != nil {
            sparkProtocolData = loadJSONString(from: "spark_protocol")
        }
        
        // Cognitive Flow Orchestration Module (Step 6)
        if versionManager.getVersion(for: "CognitiveFlowOrchestration") != nil {
            cognitiveFlowOrchestrationData = loadJSONString(from: "cognitive_flow_orchestration")
        }
        
        // Memory Evolution Core Module (Step 9)
        if versionManager.getVersion(for: "MemoryEvolutionCore") != nil {
            memoryEvolutionCoreData = loadJSONString(from: "memory_evolution_core")
        }
    }

    private func loadSkills() {
        // Updated to include all skill files
        let skillFiles = [
            ("SIM_v1", "Skill Infusion Model"),
            ("CPD_GEN_v1", "Context Priming Directive"),
            ("PH_SFM_v1", "Pattern Harmony Skill Framework"),
            ("MCM_v1", "Memory Consolidation Module"),
            ("comprehensive_skills", "Comprehensive Skill Set")
        ]
        
        var loadedSkills: [LoadedSkill] = []
        for (fileName, displayName) in skillFiles {
            // Try to load the file
            if let url = Bundle.main.url(forResource: fileName, withExtension: "json") {
                // Get file metadata for version if possible
                var version = "1.0"
                do {
                    let data = try Data(contentsOf: url)
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let metadata = json["SIM_Metadata"] as? [String: Any],
                           let metadataVersion = metadata["version"] as? String {
                            version = metadataVersion
                        } else if let metadata = json["Skill_Metadata"] as? [String: Any],
                                  let metadataVersion = metadata["version"] as? String {
                            version = metadataVersion
                        }
                    }
                } catch {
                    print("Could not parse metadata from \(fileName).json: \(error)")
                }
                
                let skill = LoadedSkill(
                    fileName: fileName,
                    displayName: displayName,
                    version: version,
                    category: "System"
                )
                loadedSkills.append(skill)
            }
        }
        
        self.availableSkills = loadedSkills
    }

    // Generic function to load and parse a JSON file into a Decodable type
    private func loadAndParse<T: Decodable>(_ fileName: String) -> T? {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            print("Could not find file: \(fileName).json")
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            print("Error parsing \(fileName).json: \(error)")
            return nil
        }
    }
    
    // Function to load a JSON file as a raw string for prompt injection
    private func loadJSONString(from fileName: String) -> String? {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            print("Could not find file: \(fileName).json")
            return nil
        }
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            print("Error reading \(fileName).json as string: \(error)")
            return nil
        }
    }
    
    // Method to get the Prime Directive data for brain initialization
    func getPrimeDirectiveData() -> String? {
        return primeDirectiveData
    }
    
    // Method to get the complete boot sequence data
    func getBootSequenceData() -> (primeDirective: String?, pcs: String?, ucrp: String?) {
        return (primeDirectiveData, pcsData, ucrpData)
    }
    
    // Method to get the enhanced boot sequence data (new modules)
    func getEnhancedBootSequenceData() -> EnhancedBootSequenceData {
        return EnhancedBootSequenceData(
            primeDirective: primeDirectiveData,
            pcs: pcsData,
            ucrp: ucrpData,
            sensoryInput: sensoryInputData,
            emotionalCore: emotionalCoreData,
            memoryConsolidation: memoryConsolidationData,
            executiveOversight: executiveOversightData,
            metacognitionModule: metacognitionModuleData, // Added missing module
            motivationalCore: motivationalCoreData, // Added missing module
            skillInfusion: skillInfusionData,
            rZeroEvolution: rZeroEvolutionData,
            neuroplasticityEngine: neuroplasticityEngineData, // Added missing module
            dreamGenerator: dreamGeneratorData, // Added missing module
            aiSheetsIntegration: aiSheetsIntegrationData,
            personaFusion: personaFusionData, // Step 4: Persona Fusion
            sparkProtocol: sparkProtocolData, // Step 5: Spark Protocol
            cognitiveFlowOrchestration: cognitiveFlowOrchestrationData, // Step 6: Cognitive Flow Orchestration
            memoryEvolutionCore: memoryEvolutionCoreData, // Step 9: Memory Evolution Core
            sicLazarusPit: sicLazarusPitData // SIC Lazarus Pit
        )
    }
    
    // Method to reload modules after an update
    func reloadModules() {
        loadBootSequenceFiles()
        loadSkills()
        objectWillChange.send()
    }
}

// Struct to hold all enhanced boot sequence data
struct EnhancedBootSequenceData {
    let primeDirective: String?
    let pcs: String?
    let ucrp: String?
    let sensoryInput: String?
    let emotionalCore: String?
    let memoryConsolidation: String?
    let executiveOversight: String?
    let metacognitionModule: String? // Added missing module
    let motivationalCore: String? // Added missing module
    let skillInfusion: String?
    let rZeroEvolution: String?
    let neuroplasticityEngine: String? // Added missing module
    let dreamGenerator: String? // Added missing module
    let aiSheetsIntegration: String?
    
    // New components from enhanced boot sequence
    let personaFusion: String? // Step 4: Persona Fusion
    let sparkProtocol: String? // Step 5: Spark Protocol
    let cognitiveFlowOrchestration: String? // Step 6: Cognitive Flow Orchestration
    let memoryEvolutionCore: String? // Step 9: Memory Evolution Core
    
    // SIC Lazarus Pit
    let sicLazarusPit: String?
    
    var allModulesPresent: Bool {
        return primeDirective != nil && pcs != nil && ucrp != nil &&
               sensoryInput != nil && emotionalCore != nil && memoryConsolidation != nil &&
               executiveOversight != nil && metacognitionModule != nil && motivationalCore != nil &&
               skillInfusion != nil && rZeroEvolution != nil && neuroplasticityEngine != nil &&
               dreamGenerator != nil && aiSheetsIntegration != nil &&
               personaFusion != nil && sparkProtocol != nil && 
               cognitiveFlowOrchestration != nil && memoryEvolutionCore != nil &&
               sicLazarusPit != nil // Added SIC Lazarus Pit
    }
    
    // Check which modules are available (for graceful degradation)
    var availableModules: [String] {
        var modules: [String] = []
        if primeDirective != nil { modules.append("PrimeDirective") }
        if pcs != nil { modules.append("PCS") }
        if ucrp != nil { modules.append("UCRP") }
        if sensoryInput != nil { modules.append("SensoryInput") }
        if emotionalCore != nil { modules.append("EmotionalCore") }
        if memoryConsolidation != nil { modules.append("MemoryConsolidation") }
        if executiveOversight != nil { modules.append("ExecutiveOversight") }
        if metacognitionModule != nil { modules.append("MetacognitionModule") }
        if motivationalCore != nil { modules.append("MotivationalCore") }
        if skillInfusion != nil { modules.append("SkillInfusion") }
        if rZeroEvolution != nil { modules.append("RZeroEvolution") }
        if neuroplasticityEngine != nil { modules.append("NeuroplasticityEngine") }
        if dreamGenerator != nil { modules.append("DreamGenerator") }
        if aiSheetsIntegration != nil { modules.append("AISheetsIntegration") }
        if personaFusion != nil { modules.append("PersonaFusion") }
        if sparkProtocol != nil { modules.append("SparkProtocol") }
        if cognitiveFlowOrchestration != nil { modules.append("CognitiveFlowOrchestration") }
        if memoryEvolutionCore != nil { modules.append("MemoryEvolutionCore") }
        if sicLazarusPit != nil { modules.append("SICLazarusPit") } // Added SIC Lazarus Pit
        return modules
    }
}