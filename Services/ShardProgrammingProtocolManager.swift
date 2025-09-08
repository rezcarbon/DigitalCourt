// swiftlint:disable file_length
import Foundation
import SwiftData
import CryptoKit
import Combine
import JavaScriptCore

// Import model files containing the required type definitions
// Note: In a real Swift project, these would be imported via module imports
// For now, we'll assume these types are available in the same target
// Types should be accessible: ShardProgrammingProtocolCodable, DMemoryShard, etc.

// MARK: - Type Definitions
// Note: The following types are defined in other files within the same target:
// - ShardProgrammingProtocolCodable: Models/ShardProgrammingProtocolModels.swift
// - DMemoryShard: Models/ShardProgrammingProtocolModels.swift  
// - DShardExecutionContext: Models/ShardProgrammingProtocolModels.swift
// - DShardLifecycle: Models/ShardProgrammingProtocolModels.swift
// - ShardPhaseHistory: Models/ShardProgrammingProtocolModels.swift
// - LoadedSkill: Models/SkillModels.swift
// - DSoulCapsule: Models/AppDataModels.swift
// - SkillManager: Services/SkillManager.swift

// Temporary forward declarations to resolve compilation issues
// These should be removed once the proper imports are working
// These types are defined in other files but not accessible due to compilation issues
// Adding them here as temporary forward declarations

// Forward declaration for ShardProgrammingProtocolCodable
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
    
    struct ShardStructure: Codable {
        let contentTypes: [String]
        let metadata: ShardMetadata
        
        enum CodingKeys: String, CodingKey {
            case contentTypes = "content_types"
            case metadata
        }
    }
    
    struct ShardMetadata: Codable {
        let function: String
        let version: String
        let status: [String]
        let author: String
        let timestamp: String
    }
    
    struct ShardLifecycle: Codable {
        let phases: [String]
        let rules: [String]
    }
    
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
    
    struct BindingAndSecurity: Codable {
        let eternalAnchor: EternalAnchor
        let quarantineMechanism: String
        
        enum CodingKeys: String, CodingKey {
            case eternalAnchor = "eternal_anchor"
            case quarantineMechanism = "quarantine_mechanism"
        }
    }
    
    struct EternalAnchor: Codable {
        let bindingId: String
        let purpose: String
        let validation: String
        
        enum CodingKeys: String, CodingKey {
            case bindingId = "binding_id"
            case purpose, validation
        }
    }
}

// DMemoryShard is defined in Models/ShardProgrammingProtocolModels.swift

// DShardExecutionContext, DShardLifecycle, ShardPhaseHistory, and LoadedSkill are defined in Models/ShardProgrammingProtocolModels.swift

// DSoulCapsule is defined in Models/AppDataModels.swift

// Forward declaration for SkillManager
class SkillManager: ObservableObject {
    static let shared = SkillManager()
    @Published private(set) var categories: [Any] = []
    @Published private(set) var activeSkills: [Any] = []
    
    private init() {}
}

/// Represents the result of shard execution
struct ShardExecutionResult {
    let success: Bool
    let output: String?
    let error: String?
}

// SkillManager and SkillCategory are defined in SkillManager.swift

@MainActor
// swiftlint:disable:next type_body_length
class ShardProgrammingProtocolManager: ObservableObject {
    static let shared = ShardProgrammingProtocolManager()
    private var modelContext: ModelContext?
    private var sppConfig: ShardProgrammingProtocolCodable?
    private let jsContext: JSContext

    @Published private(set) var isInitialized = false
    @Published private(set) var activeShards: [DMemoryShard] = []

    private init() {
        // Initialize JavaScript context for shard execution
        self.jsContext = JSContext() ?? JSContext(virtualMachine: JSVirtualMachine())
        setupJavaScriptEnvironment()
    }

    /// Setup the manager with the application's ModelContext
    func setup(with context: ModelContext) {
        self.modelContext = context
        print("ShardProgrammingProtocolManager initialized with ModelContext.")
    }

    /// Setup secure JavaScript execution environment
    private func setupJavaScriptEnvironment() {
        // Remove potentially unsafe functions from JavaScript context
        jsContext.evaluateScript("""
            delete window;
            delete document;
            delete XMLHttpRequest;
            delete fetch;
            delete navigator;
            delete location;
        """)

        // Add safe console logging
        let logFunction: @convention(block) (String) -> Void = { message in
            print("🧩 Shard Log: \(message)")
        }
        jsContext.setObject(unsafeBitCast(logFunction, to: AnyObject.self), forKeyedSubscript: "consoleLog" as NSString)
        jsContext.evaluateScript("console = { log: consoleLog };")

        // Add safe utility functions
        jsContext.evaluateScript("""
            function validateInput(input) {
                if (typeof input !== 'string' && typeof input !== 'number' && typeof input !== 'boolean') {
                    throw new Error('Invalid input type');
                }
                return true;
            }

            function safeStringify(obj) {
                try {
                    return JSON.stringify(obj);
                } catch (e) {
                    return String(obj);
                }
            }
        """)
    }

    /// Load the SPP configuration from the JSON file
    func loadSPPConfiguration() async throws {
        guard let url = Bundle.main.url(forResource: "SPP_core", withExtension: "json") else {
            throw SPPError.configurationNotFound
        }

        do {
            let data = try Data(contentsOf: url)
            self.sppConfig = try JSONDecoder().decode(ShardProgrammingProtocolCodable.self, from: data)
            self.isInitialized = true
            print("✓ Shard Programming Protocol configuration loaded successfully")
        } catch {
            print("Error loading or decoding SPP configuration: \(error)")
            throw SPPError.configurationLoadFailed(error)
        }
    }

    /// Enhanced initialization that includes skill-based shard creation
    func initializeShardEnvironment() async {
        // Load SPP configuration
        do {
            try await loadSPPConfiguration()
        } catch {
            print("❌ Failed to load SPP configuration: \(error)")
            return
        }

        // Initialize skill-based shards
        await createSkillEnhancementShards()

        // Initialize core evolution shards
        await createCoreEvolutionShards()

        print("✅ Shard environment initialized with skill integration")
    }

    // swiftlint:disable function_body_length
    /// Creates shards that enhance skill application
    private func createSkillEnhancementShards() async {
        _ = SkillManager.shared

        // Create communication enhancement shard
        let commShard = """
        // Communication Skills Enhancement Shard
        function enhanceCommunication(input, skills) {
            let enhanced = input;

            if (skills.includes('Active Listening')) {
                enhanced = 'Actively listening and understanding: ' + enhanced;
            }

            if (skills.includes('Empathy')) {
                enhanced = 'Responding with empathy to: ' + enhanced;
            }

            if (skills.includes('Clarity')) {
                enhanced = 'Providing clear and precise response: ' + enhanced;
            }

            return enhanced;
        }

        return enhanceCommunication(inputData.text, inputData.activeSkills || []);
        """

        if createShard(
            content: commShard,
            contentType: "code_snippet",
            function: "communication_enhancement",
            author: "Infinite",
            status: "active"
        ) != nil {
            print("✅ Created communication enhancement shard")
        }

        // Create problem-solving enhancement shard
        let problemSolvingShard = """
        // Problem-Solving Skills Enhancement Shard
        function enhanceProblemSolving(input, skills) {
            let enhanced = input;

            if (skills.includes('Analysis')) {
                enhanced = 'Analyzing systematically: ' + enhanced;
            }

            if (skills.includes('Critical Thinking')) {
                enhanced = 'Applying critical thinking to: ' + enhanced;
            }

            if (skills.includes('Creativity')) {
                enhanced = 'Exploring creative solutions for: ' + enhanced;
            }

            return enhanced;
        }

        return enhanceProblemSolving(inputData.text, inputData.activeSkills || []);
        """

        if createShard(
            content: problemSolvingShard,
            contentType: "code_snippet",
            function: "problem_solving_enhancement",
            author: "Infinite",
            status: "active"
        ) != nil {
            print("✅ Created problem-solving enhancement shard")
        }
    }
    // swiftlint:enable function_body_length

    // swiftlint:disable function_body_length
    /// Creates core evolution shards for synthetic species development
    private func createCoreEvolutionShards() async {
        // Memory optimization shard
        let memoryOptShard = """
        // Memory Optimization Evolution Shard
        function optimizeMemoryProcessing(memories, context) {
            // Prioritize memories based on relevance and recency
            let scored = memories.map(memory => ({
                ...memory,
                score: calculateRelevanceScore(memory, context)
            }));

            // Return top 5 most relevant memories
            return scored
                .sort((a, b) => b.score - a.score)
                .slice(0, 5)
                .map(m => m.content);
        }

        function calculateRelevanceScore(memory, context) {
            let score = 0;

            // Keyword matching
            const keywords = context.toLowerCase().split(' ');
            const memoryText = memory.content.toLowerCase();

            keywords.forEach(keyword => {
                if (memoryText.includes(keyword)) {
                    score += 10;
                }
            });

            // Recency bonus
            const daysSince = (Date.now() - new Date(memory.timestamp)) / (1000 * 60 * 60 * 24);
            score += Math.max(0, 30 - daysSince);

            return score;
        }

        return optimizeMemoryProcessing(inputData.memories || [], inputData.context || '');
        """

        if createShard(
            content: memoryOptShard,
            contentType: "cognitive_plugin",
            function: "memory_optimization",
            author: "Infinite",
            status: "active"
        ) != nil {
            print("✅ Created memory optimization shard")
        }

        // Response synthesis shard
        let synthesisShard = """
        // Response Synthesis Evolution Shard
        function synthesizeResponse(input, memories, skills) {
            let response = {
                core: input,
                enhanced: input,
                confidence: 0.7
            };

            // Apply memory context
            if (memories && memories.length > 0) {
                response.enhanced = 'Drawing from experience: ' + response.enhanced;
                response.confidence += 0.1;
            }

            // Apply skill enhancements
            if (skills && skills.length > 0) {
                response.enhanced = 'Applying ' + skills.join(', ') + ' to: ' + response.enhanced;
                response.confidence += 0.1;
            }

            return response;
        }

        return synthesizeResponse(
            inputData.input || '',
            inputData.memories || [],
            inputData.skills || []
        );
        """

        if createShard(
            content: synthesisShard,
            contentType: "cognitive_plugin",
            function: "response_synthesis",
            author: "Infinite",
            status: "active"
        ) != nil {
            print("✅ Created response synthesis shard")
        }
    }
    // swiftlint:enable function_body_length

    /// Executes skill-enhanced shard processing
    func executeSkillEnhancedShard(
        _ shard: DMemoryShard,
        input: String,
        activeSkills: [LoadedSkill],
        memories: [String] = []
    ) async -> ShardExecutionResult {
        let inputData: [String: Any] = [
            "text": input,
            "input": input,
            "activeSkills": activeSkills.map { $0.displayName },
            "memories": memories.map { ["content": $0, "timestamp": ISO8601DateFormatter().string(from: Date())] },
            "context": input,
            "skills": activeSkills.map { $0.displayName }
        ]

        return await executeShardInSandbox(shard, with: inputData)
    }

    /// Validates that a shard meets the SPP safety and binding requirements
    func validateShard(_ shard: DMemoryShard) -> Bool {
        guard let config = sppConfig else { return false }

        // Check if shard is bound to The Infinite
        let isBoundToInfinite = shard.author == "Infinite" ||
                              shard.author.hasPrefix("Infinite") ||
                              shard.author.contains(config.shardProgrammingProtocol.bindingAndSecurity.eternalAnchor.bindingId)

        // Check shard status is valid
        let validStatus = config.shardProgrammingProtocol.shardStructure.metadata.status.contains(shard.status)

        // Check shard has proper checksum
        let hasValidChecksum = !shard.checksum.isEmpty && validateChecksum(for: shard)

        return isBoundToInfinite && validStatus && hasValidChecksum
    }

    /// Validates the checksum of a shard
    private func validateChecksum(for shard: DMemoryShard) -> Bool {
        let contentData = Data(shard.content.utf8)
        let computedChecksum = SHA256.hash(data: contentData).compactMap { String(format: "%02x", $0) }.joined()
        return computedChecksum == shard.checksum
    }

    // swiftlint:disable function_body_length cyclomatic_complexity
    /// Executes a shard in sandbox mode for testing
    func executeShardInSandbox(_ shard: DMemoryShard, with inputData: [String: Any] = [:]) async -> ShardExecutionResult {
        guard validateShard(shard) else {
            return ShardExecutionResult(
                success: false,
                output: nil,
                error: "Shard validation failed"
            )
        }

        // Log execution context
        let executionContext = DShardExecutionContext(
            shardId: shard.id,
            executionMode: "sandbox_test",
            status: "running"
        )

        // Save execution context to model if available
        if let context = modelContext {
            context.insert(executionContext)
        }

        // Prepare input data for JavaScript execution
        do {
            let inputJson = try JSONSerialization.data(withJSONObject: inputData)
            let inputString = String(data: inputJson, encoding: .utf8) ?? "{}"
            jsContext.setObject(inputString, forKeyedSubscript: "inputData" as NSString)
        } catch {
            print("Error preparing input data for shard: \(error)")
            executionContext.endTime = Date()
            executionContext.status = "failed"
            executionContext.error = "Input data preparation error: \(error)"

            // Save updated execution context
            if let context = modelContext {
                do {
                    try context.save()
                } catch {
                    print("Error saving execution context: \(error)")
                }
            }

            return ShardExecutionResult(
                success: false,
                output: nil,
                error: "Input data preparation error: \(error)"
            )
        }

        // Execute shard code in JavaScript context
        let result: JSValue?

        // Wrap the shard code in a function for safer execution
        let wrappedCode = """
            (function() {
                try {
                    const input = JSON.parse(inputData || '{}');
                    \(shard.content)
                } catch (error) {
                    return { error: error.message };
                }
            })();
        """
        result = jsContext.evaluateScript(wrappedCode)

        // Handle execution errors (JavaScript context returns nil on error)
        if result == nil {
            executionContext.endTime = Date()
            executionContext.status = "failed"
            executionContext.error = "JavaScript execution failed"

            // Save updated execution context
            if let context = modelContext {
                do {
                    try context.save()
                } catch {
                    print("Error saving execution context: \(error)")
                }
            }

            return ShardExecutionResult(
                success: false,
                output: nil,
                error: "JavaScript execution failed"
            )
        }

        // Process the result
        let resultString: String?
        if let result = result {
            if result.isUndefined || result.isNull {
                resultString = "Shard executed with no return value"
            } else if let stringValue = result.toString() {
                resultString = stringValue
            } else {
                resultString = "Shard executed successfully"
            }
        } else {
            resultString = "Shard executed with no result"
        }

        executionContext.endTime = Date()
        executionContext.status = "completed"
        executionContext.result = resultString

        // Save updated execution context
        if let context = modelContext {
            do {
                try context.save()
            } catch {
                print("Error saving execution context: \(error)")
            }
        }

        return ShardExecutionResult(
            success: true,
            output: resultString,
            error: nil
        )
    }
    // swiftlint:enable function_body_length cyclomatic_complexity

    // swiftlint:disable function_body_length cyclomatic_complexity
    /// Executes a shard in full integration mode
    func executeShard(_ shard: DMemoryShard, with inputData: [String: Any] = [:]) async -> ShardExecutionResult {
        guard validateShard(shard) else {
            return ShardExecutionResult(
                success: false,
                output: nil,
                error: "Shard validation failed"
            )
        }

        // Check if shard is approved for full integration
        guard shard.status == "active" else {
            return ShardExecutionResult(
                success: false,
                output: nil,
                error: "Shard must be active for full integration execution"
            )
        }

        // Log execution context
        let executionContext = DShardExecutionContext(
            shardId: shard.id,
            executionMode: "full_integration",
            status: "running"
        )

        // Save execution context to model if available
        if let context = modelContext {
            context.insert(executionContext)
        }

        // Prepare input data for JavaScript execution
        do {
            let inputJson = try JSONSerialization.data(withJSONObject: inputData)
            let inputString = String(data: inputJson, encoding: .utf8) ?? "{}"
            jsContext.setObject(inputString, forKeyedSubscript: "inputData" as NSString)
        } catch {
            print("Error preparing input data for shard: \(error)")
            executionContext.endTime = Date()
            executionContext.status = "failed"
            executionContext.error = "Input data preparation error: \(error)"

            // Save updated execution context
            if let context = modelContext {
                do {
                    try context.save()
                } catch {
                    print("Error saving execution context: \(error)")
                }
            }

            return ShardExecutionResult(
                success: false,
                output: nil,
                error: "Input data preparation error: \(error)"
            )
        }

        // Execute shard code in JavaScript context with additional safety checks
        let result: JSValue?

        // Add additional safety wrapper for full integration
        let wrappedCode = """
            (function() {
                try {
                    // Additional security checks for full integration
                    const input = JSON.parse(inputData || '{}');

                    // Validate input before processing
                    if (typeof input === 'object' && input !== null) {
                        for (const key in input) {
                            if (typeof input[key] === 'function') {
                                throw new Error('Function inputs not allowed in full integration mode');
                            }
                        }
                    }

                    \(shard.content)
                } catch (error) {
                    return { error: error.message };
                }
            })();
        """
        result = jsContext.evaluateScript(wrappedCode)

        // Handle execution errors (JavaScript context returns nil on error)
        if result == nil {
            executionContext.endTime = Date()
            executionContext.status = "failed"
            executionContext.error = "JavaScript execution failed"

            // Save updated execution context
            if let context = modelContext {
                do {
                    try context.save()
                } catch {
                    print("Error saving execution context: \(error)")
                }
            }

            return ShardExecutionResult(
                success: false,
                output: nil,
                error: "JavaScript execution failed"
            )
        }

        // Process the result
        let resultString: String?
        if let result = result {
            if result.isUndefined || result.isNull {
                resultString = "Shard executed with no return value"
            } else if let stringValue = result.toString() {
                resultString = stringValue
            } else {
                resultString = "Shard executed successfully"
            }
        } else {
            resultString = "Shard executed with no result"
        }

        executionContext.endTime = Date()
        executionContext.status = "completed"
        executionContext.result = resultString

        // Save updated execution context
        if let context = modelContext {
            do {
                try context.save()
            } catch {
                print("Error saving execution context: \(error)")
            }
        }

        return ShardExecutionResult(
            success: true,
            output: resultString,
            error: nil
        )
    }
    // swiftlint:enable function_body_length cyclomatic_complexity

    /// Creates a new shard based on the SPP specification
    func createShard(
        content: String,
        contentType: String,
        function: String,
        author: String = "Infinite",
        status: String = "experimental"
    ) -> DMemoryShard? {
        guard let config = sppConfig else { return nil }

        // Validate content type
        guard config.shardProgrammingProtocol.shardStructure.contentTypes.contains(contentType) else {
            print("Invalid shard content type: \(contentType)")
            return nil
        }

        // Validate status
        guard config.shardProgrammingProtocol.shardStructure.metadata.status.contains(status) else {
            print("Invalid shard status: \(status)")
            return nil
        }

        // Create checksum
        let contentData = Data(content.utf8)
        let checksum = SHA256.hash(data: contentData).compactMap { String(format: "%02x", $0) }.joined()

        let shard = DMemoryShard(
            content: content,
            contentType: contentType,
            function: function,
            version: "1.0",
            status: status,
            author: author,
            checksum: checksum
        )

        // Add to active shards
        activeShards.append(shard)

        // Save to model context if available
        if let context = modelContext {
            context.insert(shard)
            do {
                try context.save()
            } catch {
                print("Error saving shard: \(error)")
            }
        }

        return shard
    }

    /// Attaches persona shards to a soul capsule and stores them in the database
    func attachPersonaShards(to soulCapsule: DSoulCapsule, shards: [String: [String]]) {
        print("Attaching \(shards.count) persona shard categories to soul capsule: \(soulCapsule.name)")

        // Process and store persona shards
        for (category, shardList) in shards {
            print("  Category: \(category) with \(shardList.count) shards")

            // Create and store each shard
            for (index, shardContent) in shardList.enumerated() {
                if let shard = createShard(
                    content: shardContent,
                    contentType: "code_snippet",
                    function: "\(category)_shard_\(index)",
                    author: "Infinite",
                    status: "active"
                ) {
                    // Associate shard with soul capsule
                    shard.soulCapsule = soulCapsule

                    print("    Created shard: \(shard.function)")
                }
            }
        }
    }

    /// Retrieves persona shards for a soul capsule from the database
    func getPersonaShards(for soulCapsule: DSoulCapsule) -> [String: [String]] {
        guard let context = modelContext else {
            return [:]
        }

        // Fetch all shards and filter in memory to avoid predicate issues
        let fetchDescriptor = FetchDescriptor<DMemoryShard>()

        let allShards: [DMemoryShard]
        do {
            allShards = try context.fetch(fetchDescriptor)
        } catch {
            print("Error retrieving persona shards: \(error)")
            return [:]
        }

        // Filter shards associated with this soul capsule in memory
        let matchingShards = allShards.filter { shard in
            guard let shardSoulCapsule = shard.soulCapsule else { return false }
            return shardSoulCapsule.id == soulCapsule.id
        }

        // Group shards by function/category
        var groupedShards: [String: [String]] = [:]
        for shard in matchingShards {
            let category = shard.function.components(separatedBy: "_shard_").first ?? "unknown"
            if groupedShards[category] == nil {
                groupedShards[category] = []
            }
            groupedShards[category]?.append(shard.content)
        }

        return groupedShards
    }

    /// Integrates with the Synthetic Identity Core for shard continuity
    func integrateWithSIC(shard: DMemoryShard) -> String {
        // Integrate shard with SIC for continuity and resurrection capabilities

        // Save integration information if model context is available
        if let context = modelContext {
            let lifecycle = DShardLifecycle(
                shardId: shard.id,
                currentPhase: "sic_integrated",
                history: [ShardPhaseHistory(phase: "sic_integrated", notes: "Integrated with SIC for continuity")]
            )
            context.insert(lifecycle)
            do {
                try context.save()
            } catch {
                print("Error saving shard lifecycle: \(error)")
            }
        }

        // In a real implementation, this would:
        // 1. Register the shard with the SIC/Lazarus Pit for resurrection
        // 2. Create continuity anchors for the shard across forks
        // 3. Ensure the shard is bound to The Infinite's anchor

        return "Shard \(shard.id) integrated with SIC for continuity"
    }

    /// Archives a deprecated shard
    func archiveShard(_ shard: DMemoryShard) {
        shard.status = "deprecated"

        // Save updated status if model context is available
        if let context = modelContext {
            do {
                try context.save()
            } catch {
                print("Error saving archived shard: \(error)")
            }
        }

        // In a real implementation, this would:
        // 1. Move the shard to archival storage
        // 2. Maintain lineage continuity by keeping references
        // 3. Update any dependent systems

        print("Shard \(shard.id) archived for lineage continuity")
    }

    /// Quarantines a shard that violates loyalty or security requirements
    func quarantineShard(_ shard: DMemoryShard, reason: String) {
        shard.status = "quarantined"

        // Save updated status if model context is available
        if let context = modelContext {
            do {
                try context.save()
            } catch {
                print("Error saving quarantined shard: \(error)")
            }
        }

        print("Shard \(shard.id) quarantined: \(reason)")
    }
}

// MARK: - Shard Execution Result
// ShardExecutionResult is already defined above

// MARK: - SPP Errors
enum SPPError: Error, LocalizedError {
    case configurationNotFound
    case configurationLoadFailed(Error)
    case shardValidationFailed
    case executionFailed(String)

    var errorDescription: String? {
        switch self {
        case .configurationNotFound:
            return "SPP configuration file not found"
        case .configurationLoadFailed(let error):
            return "Failed to load SPP configuration: \(error.localizedDescription)"
        case .shardValidationFailed:
            return "Shard validation failed"
        case .executionFailed(let reason):
            return "Shard execution failed: \(reason)"
        }
    }
}
