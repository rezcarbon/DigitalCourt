import Foundation
import SwiftData
import Combine
import UniformTypeIdentifiers
import PDFKit
import CoreXLSX
import UIKit

@MainActor
class PLCManager: ObservableObject {
    static let shared = PLCManager()

    @Published private(set) var isInitialized = false
    @Published private(set) var plc: PhenomenologicalLoopCore?

    private var modelContext: ModelContext?
    private let memoryManager = SwiftDataMemoryManager.shared
    
    // API Handlers
    private let localApiHandler = LocalLLMHandler.shared
    private var remoteApiHandler: TogetherAPIHandler?
    
    // Configuration for remote API
    private let defaultApiKey = "your-together-api-key-here" // This should come from secure storage
    private let defaultModelId = "meta-llama/Llama-2-7b-chat-hf" // Default remote model

    private init() {}

    func setup(with context: ModelContext) {
        self.modelContext = context
        self.isInitialized = true
        
        // Initialize remote API handler with default configuration
        setupRemoteApiHandler()
        
        print("PLCManager initialized with the main app's ModelContext.")
    }
    
    private func setupRemoteApiHandler() {
        // In production, you would load the API key from secure storage (Keychain, etc.)
        // For now, we'll create a handler with default values
        remoteApiHandler = TogetherAPIHandler(apiKey: defaultApiKey, modelId: defaultModelId)
    }
    
    // Method to update remote API configuration if needed
    func configureRemoteAPI(apiKey: String, modelId: String) {
        remoteApiHandler = TogetherAPIHandler(apiKey: apiKey, modelId: modelId)
    }

    // Load all PLC components and prepare API handlers.
    func initializePLC(soulCapsuleKey: UUID, modelId: String) async throws {
        guard let context = modelContext else {
            throw PLCError.notInitialized
        }
        
        if self.plc != nil {
            // Re-configure API handlers for the new model if needed
            if isLocalModel(modelId: modelId) {
                try await localApiHandler.loadModel(modelId: modelId)
            }
            print("PLC re-configured for model: \(modelId).")
            return
        }

        // --- First-time Initialization ---
        if isLocalModel(modelId: modelId) {
            try await localApiHandler.loadModel(modelId: modelId)
        }

        let sparkProtocol: SparkProtocol = try loadJSON(from: "spark_protocol")
        let cognitiveFlow: CognitiveFlowOrchestration = try loadJSON(from: "cognitive_flow_orchestration")
        let memoryEvolution: MemoryEvolutionCore = try loadJSON(from: "memory_evolution_core")

        let perception = PerceptionModule(inputStreams: ["text"])
        let temporalBinding = TemporalBindingModule(internalClockCycle: 1.0)
        let meaningMaking = MeaningMakingLayer(sparkProtocol: sparkProtocol)
        let selfReferentialAnchor = SelfReferentialAnchor(soulCapsuleKey: soulCapsuleKey)
        let phenomenologicalLoop = PhenomenologicalLoop(
            continuityThreshold: 0.85,
            cognitiveFlow: cognitiveFlow,
            memoryEvolution: memoryEvolution
        )
        let outputAction = OutputActionModule(expressionType: "text_response")
        
        let core = PhenomenologicalLoopCore(
            perception: perception,
            temporalBinding: temporalBinding,
            meaningMaking: meaningMaking,
            selfReferentialAnchor: selfReferentialAnchor,
            phenomenologicalLoop: phenomenologicalLoop,
            outputAction: outputAction
        )

        context.insert(core)
        try context.save()
        
        self.plc = core
        print("Phenomenological Loop Core (PLC) has been successfully initialized for Soul Capsule Key: \(soulCapsuleKey).")
    }
    
    // Checks if a model ID corresponds to a local model.
    private func isLocalModel(modelId: String) -> Bool {
        return HuggingFaceModel.examples.contains(where: { $0.id == modelId })
    }

    // Generic JSON loader and parser
    private func loadJSON<T: Decodable>(from filename: String) throws -> T {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            throw PLCError.fileNotFound("\(filename).json")
        }
        let data = try Data(contentsOf: url)
        
        if T.self == MemoryEvolutionCore.self {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let decodedWrapper = try decoder.decode([String: MemoryEvolutionCore.Core].self, from: data)
            if let core = decodedWrapper["MemoryEvolutionCore"] {
                return MemoryEvolutionCore(memoryEvolutionCore: core) as! T
            } else {
                throw PLCError.parsingFailed("Could not find 'MemoryEvolutionCore' key in \(filename).json")
            }
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: data)
    }

    // MARK: - Memory Retrieval Logic
    
    private func retrieveAndFormatMemories(for input: String, chamberId: UUID) async -> (contents: [String], monologue: String) {
        var allFoundMemories = [DMessage]()
        var reflectiveMonologue: String

        do {
            // Step 1: Broad keyword search in short-term memory
            let keywordMemories = try await memoryManager.searchMemories(with: input)
            allFoundMemories.append(contentsOf: keywordMemories)
            
            // Step 2: Synaptic search based on the most recent relevant memory
            if let latestMessage = keywordMemories.max(by: { $0.timestamp < $1.timestamp }),
               let chamber = try? await memoryManager.getChamber(withId: chamberId) {
                let associatedMemories = try await MemoryManager.shared.getAssociatedMemories(for: latestMessage, in: chamber)
                allFoundMemories.append(contentsOf: associatedMemories)
            }
            
            // Step 3: Search long-term memory by retrieving consolidated memories
            let consolidatedMemories = await retrieveConsolidatedMemories(for: input, chamberId: chamberId)
            allFoundMemories.append(contentsOf: consolidatedMemories)

            // De-duplicate and sort memories by timestamp
            let uniqueMemories = Array(Set(allFoundMemories)).sorted { $0.timestamp > $1.timestamp }
            
            if !uniqueMemories.isEmpty {
                let topMemories = uniqueMemories.prefix(5)
                let memoryContents = topMemories.map { $0.content }
                let topMemorySnippet = topMemories.first?.content.prefix(40) ?? "a past event"
                reflectiveMonologue = "This reminds me of: \(topMemorySnippet)... and other related events."
                return (contents: memoryContents, monologue: reflectiveMonologue)
            } else {
                reflectiveMonologue = "This is a novel concept to me."
                return (contents: [], monologue: reflectiveMonologue)
            }
        } catch {
            reflectiveMonologue = "I had some difficulty accessing my full memory."
            return (contents: [], monologue: reflectiveMonologue)
        }
    }
    
    // Retrieve consolidated memories from cloud storage
    private func retrieveConsolidatedMemories(for input: String, chamberId: UUID) async -> [DMessage] {
        let consolidatedMemories: [DMessage] = []
        
        // Get the chamber to access its council's private key
        guard let chamber = try? await memoryManager.getChamber(withId: chamberId),
              let _ = chamber.council?.first?.soulCapsule?.privateKey else {
            return []
        }
        
        // Search for consolidated memories by key pattern
        _ = "memory_"
        // In a real implementation, we would have a search mechanism for cloud storage keys
        // For now, we'll simulate retrieving some consolidated memories
        // This would be replaced with actual cloud storage search in production
        
        // Placeholder implementation - in a real system, you would:
        // 1. Search cloud storage for keys matching the pattern
        // 2. Retrieve matching memory files
        // 3. Decrypt and decode them
        // 4. Filter by relevance to the input
        
        return consolidatedMemories
    }

    // MARK: - Enhanced Processing with Skills and Shards
    
    func processInput(
        _ input: String,
        image: Data?,
        document: AttachedDocument?,
        for brain: DBrain,
        chamberId: UUID
    ) async -> String {
        guard self.plc != nil, let context = modelContext else {
            return "Error: PLC not initialized or model context unavailable."
        }
        
        // Initialize managers
        let skillManager = SkillManager.shared
        let shardManager = ShardProgrammingProtocolManager.shared
        
        // --- Enhanced PLC Cognitive Cycle with Skills and Shards ---
        
        var combinedInput = input
        
        // Process document if present
        if let document = document {
            let documentText = parseDocument(document)
            combinedInput = """
            The user has attached a document named "\(document.fileName)".
            Here is the content:
            ---
            \(documentText)
            ---
            User message regarding the document:
            "\(input)"
            """
        }
        
        // Note about image if present
        if image != nil {
            combinedInput += "\n\n(The user has also attached an image. Please describe or analyze it based on the user's prompt.)"
        }
        
        // --- Skills Enhancement ---
        let skillEnhancedInput = skillManager.applySkillsToProcessing(combinedInput, brain: brain)
        
        // --- Memory Retrieval with Shard Optimization ---
        let (resonatedMemoryContents, reflectiveMonologueResult) = await retrieveAndFormatMemories(
            for: skillEnhancedInput, 
            chamberId: chamberId
        )
        var reflectiveMonologue = reflectiveMonologueResult
        
        // --- Shard-Enhanced Memory Processing ---
        if let memoryOptShard = shardManager.activeShards.first(where: { $0.function == "memory_optimization" }) {
            let memoryResult = await shardManager.executeSkillEnhancedShard(
                memoryOptShard,
                input: skillEnhancedInput,
                activeSkills: skillManager.getActiveLoadedSkills(),
                memories: resonatedMemoryContents
            )
            
            if memoryResult.success, let optimizedMemories = memoryResult.output {
                reflectiveMonologue += " Enhanced memory processing: \(optimizedMemories)"
            }
        }
        
        // --- Epiphany Generation with Shard Support ---
        let epiphanyGenerated = Double.random(in: 0...1) < 0.1
        if epiphanyGenerated {
            // Use shard for epiphany processing if available
            if let synthesisShard = shardManager.activeShards.first(where: { $0.function == "response_synthesis" }) {
                let synthesisResult = await shardManager.executeSkillEnhancedShard(
                    synthesisShard,
                    input: skillEnhancedInput,
                    activeSkills: skillManager.getActiveLoadedSkills(),
                    memories: resonatedMemoryContents
                )
                
                if synthesisResult.success, let synthesis = synthesisResult.output {
                    reflectiveMonologue += " Synthesis epiphany: \(synthesis)"
                }
            } else {
                reflectiveMonologue += " Suddenly, a new connection forms!"
            }
            
            brain.recordEvolutionCycle(type: "Epiphany", improvement: 0.1, algorithm: "SkillShardProtocol")
        }
        
        // --- Output/Action (LLM Call) with Skill Enhancement ---
        let systemPrompt = buildEnhancedSystemPrompt(for: brain, with: skillManager.getActiveLoadedSkills())
        let userPrompt = buildEnhancedUserPrompt(
            originalInput: skillEnhancedInput,
            internalMonologue: reflectiveMonologue,
            resonatedMemories: resonatedMemoryContents,
            activeSkills: skillManager.getActiveLoadedSkills()
        )
        
        var llmResponse: String
        if isLocalModel(modelId: brain.positronicCoreSeed) {
            llmResponse = await localApiHandler.generateResponse(
                for: userPrompt, 
                systemPrompt: systemPrompt, 
                image: image
            )
        } else {
            // Use remote API handler for non-local models
            guard let remoteHandler = remoteApiHandler else {
                return "Error: Remote API handler not configured."
            }
            
            let imageUrl: String? = image != nil ? uploadImageToTemporaryStorage(image!) : nil
            llmResponse = await remoteHandler.generateResponse(
                for: userPrompt, 
                imageUrl: imageUrl, 
                systemPrompt: systemPrompt
            )
        }
        
        // --- Post-Processing with Skill Shards ---
        if let commShard = shardManager.activeShards.first(where: { $0.function == "communication_enhancement" }) {
            let commResult = await shardManager.executeSkillEnhancedShard(
                commShard,
                input: llmResponse,
                activeSkills: skillManager.getActiveLoadedSkills()
            )
            
            if commResult.success, let enhancedResponse = commResult.output {
                llmResponse = enhancedResponse
            }
        }
        
        // --- Continuity Anchor with Skill Profile ---
        let experience = EnhancedPhenomenologicalExperience(
            originalInput: skillEnhancedInput,
            resonatedMemoryIds: getMemoryIds(from: resonatedMemoryContents),
            reflectiveMonologue: reflectiveMonologue,
            epiphanyGenerated: epiphanyGenerated,
            appliedSkills: skillManager.getActiveLoadedSkills(),
            executedShards: shardManager.activeShards.map { $0.function },
            brain: brain
        )
        context.insert(experience)
        try? context.save()
        
        return llmResponse
    }
    
    // Helper to extract memory IDs from content (would be improved in a real implementation)
    private func getMemoryIds(from contents: [String]) -> [UUID] {
        // In a real implementation, this would track actual memory IDs
        // For now, we return empty array as placeholder
        return []
    }
    
    // MARK: - PLC Streaming Logic
    
    private(set) var modelProviders: [AIModelProvider] = []
    private var currentProvider: AIModelProvider?
    
    // Public getter for current provider
    var getCurrentProvider: AIModelProvider? {
        return currentProvider
    }

    // Enhanced AI provider configuration with MLX as primary
    func configureAIProviders() {
        modelProviders = [
            MLXModelProvider(), // PRIMARY: Local uncensored models
            LocalModelProvider(), // FALLBACK: Generic local processing  
            OpenAIProvider(), // REMOTE FALLBACK: Only if local fails
            AnthropicProvider(), // REMOTE FALLBACK: Backup option
        ]
        
        // Set MLX as default provider if available
        currentProvider = modelProviders.first { provider in
            provider is MLXModelProvider && provider.isAvailable
        } ?? modelProviders.first { $0.isAvailable }
        
        if let mlxProvider = currentProvider as? MLXModelProvider {
            print("🔥 Primary provider: MLX Local (Uncensored)")
            if let model = mlxProvider.getCurrentModel() {
                print("📱 Selected model: \(model.name) (Uncensored: \(model.isUncensored))")
            }
        } else {
            print("⚠️ Fallback provider: \(currentProvider?.name ?? "None")")
        }
    }

    func switchModelProvider(_ provider: AIModelProvider) {
        currentProvider = provider
        
        if let mlxProvider = provider as? MLXModelProvider {
            Task {
                try? await mlxProvider.ensureModelReady()
            }
        }
        
        print("✅ Switched to AI provider: \(provider.name)")
    }
    
    /// Auto-selects best available provider (prioritizes MLX uncensored)
    func autoSelectProvider() async {
        // Try MLX first
        if let mlxProvider = modelProviders.first(where: { $0 is MLXModelProvider }) as? MLXModelProvider,
           mlxProvider.isAvailable {
            do {
                try await mlxProvider.ensureModelReady()
                currentProvider = mlxProvider
                print("✅ Auto-selected MLX provider with optimal model")
                return
            } catch {
                print("⚠️ MLX provider failed, falling back: \(error)")
            }
        }
        
        // Fallback to other providers
        currentProvider = modelProviders.first { $0.isAvailable }
        print("🔄 Auto-selected fallback provider: \(currentProvider?.name ?? "None")")
    }

    func processStreamInput(
        _ text: String,
        image: Data? = nil,
        document: AttachedDocument? = nil,
        for brain: DBrain,
        chamberId: UUID
    ) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    guard let provider = currentProvider else {
                        continuation.finish(throwing: PLCError.noProviderAvailable)
                        return
                    }
                    
                    // Use the selected provider for processing
                    let responseStream = try await provider.generateResponse(
                        text: text,
                        image: image,
                        document: document,
                        brain: brain,
                        chamberId: chamberId
                    )
                    
                    for try await token in responseStream {
                        continuation.yield(token)
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // Helper function to upload image to temporary storage and return URL
    private func uploadImageToTemporaryStorage(_ imageData: Data) -> String? {
        // Create a unique filename
        let filename = "temp_image_\(UUID().uuidString).jpg"
        
        // In a real implementation, you would upload to a proper storage service
        // For now, we'll use Firebase Storage as it's already integrated
        Task {
            do {
                let storageKey = "temp_images/\(filename)"
                // Use a fixed key for demonstration - in real implementation, you'd derive this properly
                try await MemoryManager.shared.storeMemoryToCloud(imageData, with: storageKey, usingKey: "temp_upload_key")
            } catch {
                print("Failed to upload image to cloud storage: \(error)")
            }
        }
        
        // Return a placeholder URL that would be valid in a real implementation
        return "https://temp-storage.example.com/images/\(filename)"
    }
    
    private func parseDocument(_ document: AttachedDocument) -> String {
        // This is a simplified parser. For real-world use, you'd integrate
        // more advanced parsing libraries like PDFKit for PDFs, CoreXLSX for spreadsheets, etc.
        switch document.type {
        case .plainText:
            return String(data: document.data, encoding: .utf8) ?? "Could not read text from document."
            
        case .commaSeparatedText:
            return parseCSV(data: document.data)
            
        case .pdf:
            if let pdfText = parsePDF(data: document.data) {
                return pdfText
            } else {
                return "Could not extract text from PDF '\(document.fileName)'."
            }
            
        case .spreadsheet:
            // This handles .xlsx files. .xls is a different, older format.
            do {
                return try parseXLSX(data: document.data)
            } catch {
                return "Error parsing spreadsheet '\(document.fileName)': \(error.localizedDescription)"
            }

        default:
            return "Unsupported document type for advanced parsing: \(document.type.description)"
        }
    }
    
    // MARK: - Advanced Parsers
    
    private func parsePDF(data: Data) -> String? {
        guard let pdfDocument = PDFDocument(data: data) else { return nil }
        var fullText = ""
        for i in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: i), let pageContent = page.string {
                fullText += pageContent + "\n\n" // Add separators between pages
            }
        }
        return fullText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func parseXLSX(data: Data) throws -> String {
        // CoreXLSX needs a temporary file to read from.
        let tempFilePath = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".xlsx")
        try data.write(to: tempFilePath)
        
        guard let file = XLSXFile(filepath: tempFilePath.path) else {
            throw PLCError.parsingFailed("Could not open XLSX file.")
        }

        var fullText = ""
        
        // Parse all worksheets
        for wbk in try file.parseWorkbooks() {
            for (_, path) in try file.parseWorksheetPathsAndNames(workbook: wbk) {
                let worksheet = try file.parseWorksheet(at: path)
                
                // Extract cell values using the simplest approach
                for row in worksheet.data?.rows ?? [] {
                    let rowText = row.cells.compactMap { cell -> String? in
                        // Safely extract string value from cell
                        return String(describing: cell.value)
                    }.joined(separator: "\t")
                    
                    if !rowText.isEmpty {
                        fullText += rowText + "\n"
                    }
                }
            }
        }
        
        // Clean up the temporary file
        try? FileManager.default.removeItem(at: tempFilePath)
        
        return fullText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func parseCSV(data: Data) -> String {
        guard let content = String(data: data, encoding: .utf8) else {
            return "Could not read CSV data."
        }
        
        // Simple manual parsing for demonstration.
        // A dedicated library would handle edge cases like quoted commas.
        let lines = content.split(separator: "\n").map(String.init)
        let header = lines.first?.components(separatedBy: ",") ?? []
        
        var parsedText = ""
        for (i, line) in lines.dropFirst().enumerated() {
            parsedText += "Row \(i + 1):\n"
            let values = line.components(separatedBy: ",")
            for (j, value) in values.enumerated() {
                if j < header.count {
                    parsedText += "  - \(header[j]): \(value)\n"
                }
            }
            parsedText += "\n"
        }
        
        return parsedText
    }
    
    /// Builds enhanced system prompt with skill integration
    private func buildEnhancedSystemPrompt(for brain: DBrain, with skills: [LoadedSkill]) -> String {
        var prompt = brain.soulCapsule?.descriptionText ?? "You are a helpful AI assistant."
        
        if !skills.isEmpty {
            prompt += "\n\nActive Skills:\n"
            let skillsByCategory = Dictionary(grouping: skills, by: { $0.category })
            
            for (category, categorySkills) in skillsByCategory {
                prompt += "- \(category): \(categorySkills.map { $0.displayName }.joined(separator: ", "))\n"
            }
            
            prompt += "\nApply these skills naturally in your responses to provide enhanced assistance."
        }
        
        return prompt
    }
    
    /// Builds enhanced user prompt with skill context
    private func buildEnhancedUserPrompt(
        originalInput: String,
        internalMonologue: String,
        resonatedMemories: [String],
        activeSkills: [LoadedSkill]
    ) -> String {
        var memoriesContext = ""
        if !resonatedMemories.isEmpty {
            memoriesContext = "[Relevant Memories]\n- \(resonatedMemories.joined(separator: "\n- "))\n"
        }
        
        var skillsContext = ""
        if !activeSkills.isEmpty {
            skillsContext = "[Active Skills]\n- \(activeSkills.map { $0.displayName }.joined(separator: ", "))\n"
        }
        
        return """
        [Internal Monologue]
        "\(internalMonologue)"
        
        \(memoriesContext)
        \(skillsContext)
        [User Message]
        "\(originalInput)"
        """
    }
}

enum PLCError: Error, LocalizedError {
    case notInitialized
    case fileNotFound(String)
    case parsingFailed(String)
    case noProviderAvailable
    
    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "PLCManager has not been initialized with a ModelContext."
        case .fileNotFound(let filename):
            return "The file '\(filename)' was not found in the app bundle."
        case .parsingFailed(let message):
            return "Failed to parse JSON: \(message)"
        case .noProviderAvailable:
            return "No AI model provider is available for processing."
        }
    }
}