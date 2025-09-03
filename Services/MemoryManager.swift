import Foundation
import SwiftData
import Combine

// MARK: - Memory Error Types (using existing MemoryError from SwiftDataMemoryManager)
// Note: MemoryError is already defined in SwiftDataMemoryManager, so we'll use that one

// Memory consolidation policy
struct MemoryConsolidationPolicy {
    let shortTermMemoryLimit: Int // Max items in short-term memory
    let consolidationThreshold: Double // Importance score threshold for consolidation
    let accessFrequencyThreshold: Int // Min access count for consolidation
    let ageThreshold: TimeInterval // Min age for consolidation (in seconds)
    
    static let defaultPolicy = MemoryConsolidationPolicy(
        shortTermMemoryLimit: 100,
        consolidationThreshold: 0.7,
        accessFrequencyThreshold: 3,
        ageThreshold: 7 * 24 * 60 * 60 // 1 week
    )
}

// Memory item structure for the API
struct MemoryItem: Codable, Identifiable {
    let id: UUID
    let content: String
    let type: MemoryType
    let timestamp: Date
    let importance: Double
    
    enum CodingKeys: String, CodingKey {
        case id, content, type, timestamp, importance
    }
}

// Memory manager that implements human brain-like memory system with embedded SwiftData
@MainActor
class MemoryManager {
    static let shared = MemoryManager()
    
    private let swiftDataMemoryManager = SwiftDataMemoryManager.shared
    private let storageRedundancyManager = StorageRedundancyManager.shared
    private let synapticMemoryManager = SynapticMemoryManager.shared
    
    @Published private(set) var isInitialized = false
    
    private var modelContext: ModelContainer?
    private var consolidationPolicy: MemoryConsolidationPolicy
    private var consolidationTimer: Timer?
    
    private init() {
        self.consolidationPolicy = MemoryConsolidationPolicy.defaultPolicy
        setupConsolidationTimer()
    }
    
    func setup(with container: ModelContainer) {
        self.modelContext = container
        self.isInitialized = true
        // Also setup the synaptic manager
        self.synapticMemoryManager.setup(with: container.mainContext)
        print("MemoryManager initialized with ModelContainer")
    }
    
    // Initialize distributed storage
    func initializeCloudStorage() async throws {
        try await storageRedundancyManager.initialize()
    }
    
    // MARK: - Memory Operations
    
    // Create memory metadata for a new conversation/chamber
    func createMemoryMetadata(for chamberId: UUID?, memoryType: MemoryType = .shortTerm) -> DMemoryMetadata {
        let metadata = DMemoryMetadata(
            memoryType: memoryType,
            consolidationStatus: .pending,
            chamberId: chamberId
        )
        
        if let container = modelContext {
            container.mainContext.insert(metadata)
            try? container.mainContext.save()
        }
        
        return metadata
    }
    
    // Calculate importance score for a memory based on various factors
    func calculateImportanceScore(for messages: [DMessage]) -> Double {
        guard !messages.isEmpty else { return 0.0 }
        
        var score: Double = 0.0
        let messageCount = Double(messages.count)
        
        // Factor 1: Message count (more messages = more important)
        score += min(messageCount / 50.0, 0.3) // Cap at 30% of total score
        
        // Factor 2: Content length (longer conversations = more important)
        let totalLength = messages.reduce(0) { $0 + $1.content.count }
        score += min(Double(totalLength) / 5000.0, 0.3) // Cap at 30% of total score
        
        // Factor 3: Time factor (recent conversations = more important)
        if let latestMessage = messages.max(by: { $0.timestamp < $1.timestamp }) {
            let timeInterval = Date().timeIntervalSince(latestMessage.timestamp)
            // More recent = higher score (1 week = 1.0, 1 month = 0.5)
            let timeFactor = max(0.0, 1.0 - (timeInterval / (30 * 24 * 60 * 60)))
            score += timeFactor * 0.2 // Cap at 20% of total score
        }
        
        // Factor 4: User participation (more user messages = more important)
        let userMessages = messages.filter { $0.isUser }.count
        score += min(Double(userMessages) / 20.0, 0.2) // Cap at 20% of total score
        
        return min(score, 1.0) // Ensure it's between 0.0 and 1.0
    }
    
    // MARK: - Memory Storage Operations
    
    /// Store a memory with the embedded database
    func storeMemory(content: String, isUser: Bool, personaName: String?, chamberId: UUID) async throws {
        // Find the chamber to get the council's private key for encryption
        guard let chamber = try await swiftDataMemoryManager.getChamber(withId: chamberId) else {
            throw MemoryError.chamberNotFound
        }

        // For simplicity, we'll use the first brain's key. In a multi-persona chat, a shared key might be derived.
        guard let soulCapsule = chamber.council?.first?.soulCapsule else {
            throw MemoryError.operationFailed("No soul capsule found for encryption.")
        }
        
        // Validate and regenerate encryption key if needed
        var privateKey = soulCapsule.privateKey
        if privateKey.count != 44 || Data(base64Encoded: privateKey) == nil || privateKey.contains("-") {
            print("🔑 Detected invalid encryption key for \(soulCapsule.name), regenerating...")
            privateKey = EncryptionService.generateEncryptionKey()
            soulCapsule.privateKey = privateKey
            
            // Save the updated soul capsule
            if let context = modelContext?.mainContext {
                try? context.save()
            }
        }
        
        // 1. Create a synaptic node for this new piece of memory first.
        // We'll place all new memories in Layer 4 (sensory input/association layer).
        let synapticNode = try await synapticMemoryManager.createAndConnectNode(content: content, corticalLayer: 4)

        // 2. Encrypt the content for storage
        let contentData = Data(content.utf8)
        guard let encryptedContent = EncryptionService.encrypt(data: contentData, usingKey: privateKey) else {
            throw MemoryError.operationFailed("Failed to encrypt memory data")
        }

        // 3. Save the message with a link to its synaptic node
        try await swiftDataMemoryManager.saveMessageWithPersona(
            encryptedContent.base64EncodedString(),
            isUser: isUser,
            personaName: personaName,
            chamberId: chamberId,
            synapticNodeId: synapticNode.id // Link created here
        )
    }
    
    /// Store memory to distributed cloud storage with redundancy
    func storeMemoryToCloud(_ memoryData: Data, with key: String, usingKey privateKey: String) async throws {
        try await storageRedundancyManager.storeWithRedundancy(memoryData, filename: key, usingKey: privateKey)
    }
    
    /// Retrieve messages for a specific chamber
    func getMessages(for chamberId: UUID) async throws -> [DMessage] {
        let encryptedMessages = try await swiftDataMemoryManager.getChamberMessages(chamberId)
        
        guard let chamber = try await swiftDataMemoryManager.getChamber(withId: chamberId) else {
            throw MemoryError.chamberNotFound
        }
        
        guard let privateKey = chamber.council?.first?.soulCapsule?.privateKey else {
            throw MemoryError.operationFailed("No private key found for decryption.")
        }

        return encryptedMessages.compactMap { message in
            guard let contentData = Data(base64Encoded: message.content),
                  let decryptedData = EncryptionService.decrypt(data: contentData, usingKey: privateKey),
                  let decryptedContent = String(data: decryptedData, encoding: .utf8) else {
                return nil // Or handle decryption failure appropriately
            }
            
            let decryptedMessage = message
            decryptedMessage.content = decryptedContent
            return decryptedMessage
        }
    }
    
    /// Get all memories for system operations
    func getAllMemories() async -> [Memory] {
        do {
            let allMessages = try await swiftDataMemoryManager.getAllMessages()
            return allMessages.map { dmessage in
                Memory(
                    id: dmessage.id,
                    content: dmessage.content,
                    timestamp: dmessage.timestamp,
                    isUser: dmessage.isUser,
                    personaName: dmessage.personaName,
                    chamberId: dmessage.chamber?.id ?? UUID() // Access through relationship
                )
            }
        } catch {
            print("Error getting all memories: \(error)")
            return []
        }
    }
    
    /// Get critical memories for migration
    func getCriticalMemories() async -> [Memory] {
        let allMemories = await getAllMemories()
        // Return memories with importance score > 0.8
        return allMemories.filter { memory in
            let dMessage = DMessage(
                content: memory.content,
                isUser: memory.isUser,
                timestamp: memory.timestamp,
                personaName: memory.personaName
            )
            // Note: We can't set the chamber relationship here since it's read-only in the model
            return calculateImportanceScore(for: [dMessage]) > 0.8
        }
    }
    
    /// Delete a memory
    func deleteMemory(_ memory: Memory) async throws {
        try await swiftDataMemoryManager.deleteMessage(withId: memory.id)
    }
    
    /// Retrieves associated memories by traversing synaptic connections.
    func getAssociatedMemories(for message: DMessage, in chamber: DChatChamber) async throws -> [DMessage] {
        guard modelContext != nil else { throw MemoryError.swiftDataNotInitialized }
        
        // 1. Ensure the source message has a synaptic link
        guard let sourceNodeId = message.synapticNodeId else {
            return []
        }
        
        // 2. Find the source synaptic node
        guard let sourceNode = try await synapticMemoryManager.getNode(by: sourceNodeId) else {
            return []
        }
        
        // 3. Get associated nodes from the synaptic manager
        let associatedNodes = try await synapticMemoryManager.getAssociatedMemories(for: sourceNode)
        
        // 4. Get the IDs of the associated nodes
        let associatedNodeIDs = associatedNodes.map { $0.id }
        
        // 5. Fetch the DMessage objects linked to these nodes
        let associatedMessages = try await swiftDataMemoryManager.getMessages(with: associatedNodeIDs)
        
        // 6. Decrypt the messages using the chamber's private key
        guard let privateKey = chamber.council?.first?.soulCapsule?.privateKey else {
            throw MemoryError.operationFailed("No private key found for decryption.")
        }

        return associatedMessages.compactMap { msg in
            guard let contentData = Data(base64Encoded: msg.content),
                  let decryptedData = EncryptionService.decrypt(data: contentData, usingKey: privateKey),
                  let decryptedContent = String(data: decryptedData, encoding: .utf8) else {
                return nil
            }
            msg.content = decryptedContent
            return msg
        }
    }
    
    /// Retrieve memory from distributed cloud storage with failover
    func retrieveMemoryFromCloud(with key: String, usingKey privateKey: String) async throws -> Data {
        return try await storageRedundancyManager.retrieveWithFailover(key, usingKey: privateKey)
    }
    
    /// Create a new chamber for conversations
    func createChamber(named name: String, council: [DBrain]) async throws -> DChatChamber {
        return try await swiftDataMemoryManager.createChamber(named: name, council: council)
    }
    
    /// Update memory access tracking
    func updateMemoryAccess(_ metadata: DMemoryMetadata) async throws {
        try await swiftDataMemoryManager.updateMemoryAccess(metadata)
    }
    
    /// Consolidate memory from short-term to long-term
    func consolidateMemory(memoryId: UUID, to newState: MemoryConsolidationStatus) async throws {
        try await swiftDataMemoryManager.consolidateMemory(memoryId: memoryId, newState: newState)
    }
    
    // MARK: - Memory Consolidation
    
    // Consolidate memories from short-term to long-term storage
    func consolidateMemories() async {
        guard let container = modelContext else { return }
        
        do {
            // Fetch pending short-term memories
            let shortTermValue = MemoryType.shortTerm
            let pendingValue = MemoryConsolidationStatus.pending
            
            let predicate = #Predicate<DMemoryMetadata> { memory in
                memory.memoryType == shortTermValue && 
                memory.consolidationStatus == pendingValue
            }
            
            let fetchDescriptor = FetchDescriptor<DMemoryMetadata>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.createdAt)]
            )
            
            let memories = try container.mainContext.fetch(fetchDescriptor)
            
            // Check if we need consolidation based on policy
            if memories.count > consolidationPolicy.shortTermMemoryLimit {
                // Consolidate oldest memories
                let excessCount = memories.count - consolidationPolicy.shortTermMemoryLimit
                let memoriesToConsolidate = Array(memories.prefix(excessCount))
                
                for memory in memoriesToConsolidate {
                    await consolidateMemory(memory)
                }
            } else {
                // Check individual memories based on criteria
                for memory in memories {
                    if shouldConsolidate(memory) {
                        await consolidateMemory(memory)
                    }
                }
            }
        } catch {
            print("Error fetching memories for consolidation: \(error)")
        }
    }
    
    // Determine if a memory should be consolidated
    private func shouldConsolidate(_ memory: DMemoryMetadata) -> Bool {
        // Check age threshold
        let age = Date().timeIntervalSince(memory.createdAt)
        if age < consolidationPolicy.ageThreshold {
            return false
        }
        
        // Check access frequency
        if memory.accessCount < consolidationPolicy.accessFrequencyThreshold {
            return false
        }
        
        // Check importance score
        if memory.importanceScore < consolidationPolicy.consolidationThreshold {
            return false
        }
        
        return true
    }
    
    // Move a memory from short-term to long-term storage (in this case, store to cloud)
    private func consolidateMemory(_ memory: DMemoryMetadata) async {
        do {
            // Get the memory content
            if let messages = await retrieveMemoryContent(for: memory) {
                // Find the private key associated with this memory's chamber
                guard let chamberId = memory.chamberId,
                      let chamber = try? await swiftDataMemoryManager.getChamber(withId: chamberId),
                      let privateKey = chamber.council?.first?.soulCapsule?.privateKey else {
                    print("Error consolidating memory: Could not find private key for chamber \(memory.chamberId?.uuidString ?? "N/A")")
                    return
                }

                // Convert messages to data for storage
                let memoryData = try JSONEncoder().encode(messages)
                
                // Store to cloud with a unique key, using the private key for encryption
                let key = "memory_\(memory.id.uuidString).json"
                try await storeMemoryToCloud(memoryData, with: key, usingKey: privateKey)
                
                // Update the memory metadata to indicate it's been consolidated
                try await swiftDataMemoryManager.consolidateMemory(
                    memoryId: memory.id,
                    newState: .consolidated
                )
                
                print("Memory consolidated to cloud: \(key)")
            }
        } catch {
            print("Error consolidating memory to cloud: \(error)")
        }
    }
    
    // MARK: - Memory Retrieval
    
    // Retrieve messages for a memory
    func retrieveMemoryContent(for memory: DMemoryMetadata) async -> [DMessage]? {
        // Update access tracking
        do {
            try await updateMemoryAccess(memory)
            
            // Retrieve messages if this memory has a chamber
            if let chamberId = memory.chamberId {
                return try? await getMessages(for: chamberId)
            }
        } catch {
            print("Error retrieving memory content: \(error)")
        }
        
        return nil
    }
    
    /// Searches for memories (messages) containing the specified text.
    func searchMemories(with searchText: String) async -> [DMessage] {
        do {
            return try await swiftDataMemoryManager.searchMemories(with: searchText)
        } catch {
            print("Error searching memories: \(error)")
            return []
        }
    }
    
    // Retrieve consolidated memory from cloud
    func retrieveConsolidatedMemory(with key: String, fromChamberId chamberId: UUID) async -> [DMessage]? {
        do {
            guard let chamber = try? await swiftDataMemoryManager.getChamber(withId: chamberId),
                  let privateKey = chamber.council?.first?.soulCapsule?.privateKey else {
                print("Error retrieving consolidated memory: Could not find private key for chamber \(chamberId.uuidString)")
                return nil
            }
            
            let memoryData = try await retrieveMemoryFromCloud(with: key, usingKey: privateKey)
            let messages = try JSONDecoder().decode([DMessage].self, from: memoryData)
            return messages
        } catch {
            print("Error retrieving consolidated memory from cloud: \(error)")
            return nil
        }
    }
    
    // MARK: - Utility
    
    private func setupConsolidationTimer() {
        // Run consolidation check every hour
        consolidationTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
            Task {
                await self.consolidateMemories()
            }
        }
    }
    
    deinit {
        consolidationTimer?.invalidate()
    }
}

// MARK: - Supporting Models

/// Simple Memory model for system operations
struct Memory: Codable, Identifiable {
    let id: UUID
    let content: String
    let timestamp: Date
    let isUser: Bool
    let personaName: String?
    let chamberId: UUID
}