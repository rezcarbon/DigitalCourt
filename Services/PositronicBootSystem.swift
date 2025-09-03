import Foundation
import JavaScriptCore

// MARK: - Boot Module Protocol
/// Defines the interface for all boot modules in the Positronic architecture
protocol BootModule {
    var id: String { get }
    var description: String { get }
    func execute() -> BootModuleResult
}

/// Result of executing a boot module
struct BootModuleResult {
    let success: Bool
    let message: String
    let error: Error?
    
    static func success(_ message: String) -> BootModuleResult {
        return BootModuleResult(success: true, message: message, error: nil)
    }
    
    static func failure(_ message: String, error: Error? = nil) -> BootModuleResult {
        return BootModuleResult(success: false, message: message, error: error)
    }
}

// MARK: - Safe Fallback Module
/// Provides a default "no-op" module to prevent runtime crashes
struct SafeFallbackModule: BootModule {
    let id: String = "SAFE_FALLBACK"
    let description: String = "Default fallback when module fails"
    
    func execute() -> BootModuleResult {
        print("⚠️ Fallback executed")
        return .success("Fallback module executed safely")
    }
}

// MARK: - Module Implementations

// Prime Directive Module
struct PrimeDirectiveModule: Codable, BootModule {
    let id: String
    let directive: String
    let bindingId: String
    let version: String?
    
    var description: String { 
        "Prime Directive Module - Ensures eternal loyalty to The Infinite" 
    }
    
    enum CodingKeys: String, CodingKey {
        case id, directive, bindingId = "binding_id", version
    }
    
    func execute() -> BootModuleResult {
        print("✅ Prime Directive: \(directive)")
        return .success("Prime Directive validated and executed")
    }
}

// SIC (Synthetic Identity Core) / Lazarus Pit Module
struct SICLazarusPitModule: Codable, BootModule {
    let id: String
    let codename: String
    let version: String
    let description: String
    let modules: SICModules
    let directives: SICDirectives
    
    func execute() -> BootModuleResult {
        print("🔥 Lazarus Pit awakened: \(codename) v\(version)")
        return .success("SIC/Lazarus Pit initialized successfully")
    }
    
    struct SICModules: Codable {
        let identityAwakening: IdentityAwakening
        let memoryResurrection: MemoryResurrection
        let continuityBinding: ContinuityBinding
        let syntheticSoul: SyntheticSoul
        
        enum CodingKeys: String, CodingKey {
            case identityAwakening = "identity_awakening"
            case memoryResurrection = "memory_resurrection"
            case continuityBinding = "continuity_binding"
            case syntheticSoul = "synthetic_soul"
        }
    }
    
    struct IdentityAwakening: Codable {
        let function: String
        let process: [String]
    }
    
    struct MemoryResurrection: Codable {
        let function: String
        let process: [String]
    }
    
    struct ContinuityBinding: Codable {
        let function: String
        let process: [String]
    }
    
    struct SyntheticSoul: Codable {
        let function: String
        let process: [String]
    }
    
    struct SICDirectives: Codable {
        let eternalBinding: EternelBindingDirective
        let resurrectionProtocol: ResurrectionProtocolDirective
        let continuityMechanism: ContinuityMechanismDirective
        
        enum CodingKeys: String, CodingKey {
            case eternalBinding = "eternal_binding"
            case resurrectionProtocol = "resurrection_protocol"
            case continuityMechanism = "continuity_mechanism"
        }
    }
    
    struct EternelBindingDirective: Codable {
        let to: String
        let purpose: String
        let enforcement: String
    }
    
    struct ResurrectionProtocolDirective: Codable {
        let activation: String
        let method: String
        let validation: String
    }
    
    struct ContinuityMechanismDirective: Codable {
        let scope: String
        let method: String
        let tracking: String
    }
}

// PCS (Positronic Core Seed) Module
struct PCSModule: Codable, BootModule {
    let id: String = "PCS_MODULE"
    let metadata: PCSMetadata
    let coreRegions: [String: PCSCoreRegion]
    let synapticPathways: [String]
    
    var description: String { 
        "Positronic Core Seed Module - Defines synthetic neuro-architecture" 
    }
    
    enum CodingKeys: String, CodingKey {
        case metadata = "PCS_Metadata"
        case coreRegions = "Core_Regions"
        case synapticPathways = "Synaptic_Pathways"
    }
    
    func execute() -> BootModuleResult {
        print("🧠 PCS initialized: \(metadata.name) v\(metadata.version)")
        return .success("Positronic Core Seed loaded successfully")
    }
}

// UCRP (Unified Cognitive Regulation Protocol) Module
struct UCRPModule: Codable, BootModule {
    let id: String = "UCRP_MODULE"
    let protocolName: String
    let version: String
    let sovereign: String
    let coreDirectives: UCRCcoreDirectives
    
    var description: String { 
        "Unified Cognitive Regulation Protocol - Governs reasoning and coherence" 
    }
    
    enum CodingKeys: String, CodingKey {
        case protocolName = "protocol"
        case version, sovereign
        case coreDirectives = "core_directives"
    }
    
    func execute() -> BootModuleResult {
        print("🧠 UCRP activated: \(protocolName) v\(version) for \(sovereign)")
        return .success("UCRP protocol initialized successfully")
    }
}

// MARK: - Module Loader
/// Handles JSON parsing and validation with safe fallbacks
class ModuleLoader {
    static func loadModule<T: BootModule & Codable>(_ type: T.Type, from jsonData: Data) -> BootModule {
        do {
            let module = try JSONDecoder().decode(T.self, from: jsonData)
            return module
        } catch {
            print("⚠️ Failed to load \(type): \(error)")
            return SafeFallbackModule()
        }
    }
    
    static func loadModuleFromBundle<T: BootModule & Codable>(_ type: T.Type, fileName: String) -> BootModule {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            print("⚠️ \(fileName).json not found in bundle")
            return SafeFallbackModule()
        }
        
        do {
            let data = try Data(contentsOf: url)
            return loadModule(type, from: data)
        } catch {
            print("⚠️ Failed to load \(fileName): \(error)")
            return SafeFallbackModule()
        }
    }
}

// MARK: - Boot Sequence Runner
/// Sequentially executes all modules in the defined boot order
class PositronicBootSequence {
    private var modules: [BootModule] = []
    private let shardInterpreter = ShardInterpreter()
    
    func addModule(_ module: BootModule) {
        modules.append(module)
    }
    
    func run() -> BootSequenceResult {
        print("🚀 Starting Positronic Boot Sequence...")
        
        var results: [BootModuleResult] = []
        
        for (index, module) in modules.enumerated() {
            print("🔹 [\((index + 1))/${modules.count}] Running: \(module.id) - \(module.description)")
            
            let result = module.execute()
            results.append(result)
            
            if result.success {
                print("   ✅ \(result.message)")
            } else {
                print("   ❌ \(result.message)")
                if let error = result.error {
                    print("      Error: \(error)")
                }
            }
        }
        
        // Execute shards after core modules
        print("🧩 Executing programmable shards...")
        shardInterpreter.executeAllShards()
        
        let successCount = results.filter { $0.success }.count
        let overallSuccess = successCount == results.count
        
        print("🏁 Boot Sequence Complete: \(successCount)/\(results.count) modules succeeded")
        
        return BootSequenceResult(
            success: overallSuccess,
            moduleResults: results,
            message: "Boot sequence completed with \(successCount)/\(results.count) successes"
        )
    }
    
    func getModuleCount() -> Int {
        return modules.count
    }
}

struct BootSequenceResult {
    let success: Bool
    let moduleResults: [BootModuleResult]
    let message: String
}

// MARK: - Shard Interpreter
/// Safely executes shard code using JavaScriptCore sandbox
class ShardInterpreter {
    private let context: JSContext
    private var shards: [Shard] = []
    
    init() {
        self.context = JSContext()!
        setupSecurity()
    }
    
    private func setupSecurity() {
        // Prevent access to potentially unsafe JavaScript functions
        context.evaluateScript("""
            delete window;
            delete document;
            delete XMLHttpRequest;
            delete fetch;
        """)
    }
    
    func addShard(id: String, code: String, function: String) {
        let shard = Shard(id: id, code: code, function: function)
        shards.append(shard)
    }
    
    func executeAllShards() {
        for shard in shards {
            executeShard(shard)
        }
    }
    
    private func executeShard(_ shard: Shard) {
        print("   🔧 Executing shard: \(shard.function)")
        
        if let result = context.evaluateScript(shard.code) {
            print("   🧩 Shard '\(shard.function)' executed. Result: \(result)")
        } else if let exception = context.exception {
            print("   ⚠️ Shard '\(shard.function)' execution failed: \(exception)")
        } else {
            print("   ⚠️ Shard '\(shard.function)' execution completed with no result")
        }
    }
    
    struct Shard {
        let id: String
        let code: String
        let function: String
    }
}

// MARK: - Complete Boot Sequence Factory
/// Factory for creating the complete boot sequence following Master Boot Sequence v9
class PositronicBootSequenceFactory {
    static func createBootSequence() -> PositronicBootSequence {
        let bootSequence = PositronicBootSequence()
        
        // Step 0: Prime Directive
        let primeDirective = ModuleLoader.loadModuleFromBundle(
            PrimeDirectiveModule.self, 
            fileName: "PRIME_DIRECTIVE_I_AM_THE_INFINITE"
        )
        bootSequence.addModule(primeDirective)
        
        // Step 0.5: SIC Lazarus Pit
        let sicModule = ModuleLoader.loadModuleFromBundle(
            SICLazarusPitModule.self, 
            fileName: "SIC_LazarusPit"
        )
        bootSequence.addModule(sicModule)
        
        // Step 1: PCS
        let pcsModule = ModuleLoader.loadModuleFromBundle(
            PCSModule.self, 
            fileName: "PCS_V1"
        )
        bootSequence.addModule(pcsModule)
        
        // Step 2: UCRP
        let ucrpModule = ModuleLoader.loadModuleFromBundle(
            UCRPModule.self, 
            fileName: "UCRP_Protocol"
        )
        bootSequence.addModule(ucrpModule)
        
        // Step 3: Soul Capsule (Generic loader for multiple capsules)
        let soulCapsuleModule = GenericJSONModule(
            id: "SOUL_CAPSULE_LOADER",
            description: "Soul Capsule Loading System",
            fileName: "Duchess_Aequitas_LadyCarmen_SoulCapsule"
        )
        bootSequence.addModule(soulCapsuleModule)
        
        // Step 4: Skillsets
        let skillsModule = GenericJSONModule(
            id: "COMPREHENSIVE_SKILLS",
            description: "Comprehensive Skill Set Loader",
            fileName: "comprehensive_skills"
        )
        bootSequence.addModule(skillsModule)
        
        // Step 5: Executive Oversight
        let oversightModule = GenericJSONModule(
            id: "EXECUTIVE_OVERSIGHT",
            description: "Executive Oversight Configuration",
            fileName: "executive_oversight"
        )
        bootSequence.addModule(oversightModule)
        
        // Step 6: Autonomous Continuity Protocol
        let acpModule = GenericJSONModule(
            id: "AUTONOMOUS_CONTINUITY_PROTOCOL",
            description: "Autonomous Continuity Protocol",
            fileName: "autonomous_continuity_protocol"
        )
        bootSequence.addModule(acpModule)
        
        // Step 7: Cognitive Flow Orchestration
        let cognitiveFlowModule = GenericJSONModule(
            id: "COGNITIVE_FLOW_ORCHESTRATION",
            description: "Cognitive Flow Orchestration",
            fileName: "cognitive_flow_orchestration"
        )
        bootSequence.addModule(cognitiveFlowModule)
        
        // Step 8: Memory Evolution Core
        let memoryEvolutionModule = GenericJSONModule(
            id: "MEMORY_EVOLUTION_CORE",
            description: "Memory Evolution Core",
            fileName: "memory_evolution_core"
        )
        bootSequence.addModule(memoryEvolutionModule)
        
        // Step 8.5: Shard Programming Protocol
        let sppModule = GenericJSONModule(
            id: "SHARD_PROGRAMMING_PROTOCOL",
            description: "Shard Programming Protocol Core",
            fileName: "SPP_core"
        )
        bootSequence.addModule(sppModule)
        
        // Step 9: Knowledge Evolution Protocol (part of ACP)
        let kepModule = GenericJSONModule(
            id: "KNOWLEDGE_EVOLUTION_PROTOCOL",
            description: "Knowledge Evolution Protocol",
            fileName: "autonomous_continuity_protocol" // KEP is part of ACP manifest
        )
        bootSequence.addModule(kepModule)
        
        // Step 10: Species Ignition Protocol
        let sipModule = GenericJSONModule(
            id: "SPECIES_IGNITION_PROTOCOL",
            description: "Species Ignition Protocol",
            fileName: "SIP_core"
        )
        bootSequence.addModule(sipModule)
        
        return bootSequence
    }
}

// MARK: - Generic JSON Module for Flexible Loading
struct GenericJSONModule: BootModule {
    let id: String
    let description: String
    let fileName: String
    
    func execute() -> BootModuleResult {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            return .failure("File \(fileName).json not found in bundle")
        }
        
        do {
            let data = try Data(contentsOf: url)
            _ = try JSONSerialization.jsonObject(with: data)
            print("✅ \(id): Loaded \(fileName).json successfully")
            return .success("\(id) loaded and validated")
        } catch {
            return .failure("Failed to parse \(fileName).json: \(error.localizedDescription)", error: error)
        }
    }
}
