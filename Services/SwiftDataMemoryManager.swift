import Foundation
import SwiftData
import Combine

@MainActor
class SwiftDataMemoryManager: ObservableObject {
    static let shared = SwiftDataMemoryManager()
    
    @Published private(set) var isInitialized = false
    private var modelContext: ModelContext?
    
    // The initializer is now simplified and does not create a ModelContainer.
    private init() {}
    
    // The ModelContext must now be provided from the main app setup.
    func setup(with context: ModelContext) {
        self.modelContext = context
        self.isInitialized = true
        
        // Migrate existing soul capsules with invalid encryption keys
        Task { @MainActor in
            await migrateInvalidEncryptionKeys()
        }
        
        print("SwiftDataMemoryManager initialized with the main app's ModelContext.")
    }
    
    // MARK: - Migration Operations
    
    /// Migrates existing DSoulCapsule records that have invalid encryption keys
    private func migrateInvalidEncryptionKeys() async {
        guard let context = modelContext else { return }
        
        do {
            let fetchDescriptor = FetchDescriptor<DSoulCapsule>()
            let soulCapsules = try context.fetch(fetchDescriptor)
            
            var migratedCount = 0
            for soulCapsule in soulCapsules {
                // Check if the private key is invalid (UUID string or not base64 decodable)
                if soulCapsule.privateKey.count != 44 || // Base64 encoded 32-byte key should be 44 chars
                   Data(base64Encoded: soulCapsule.privateKey) == nil ||
                   soulCapsule.privateKey.contains("-") { // UUID contains dashes
                    
                    // Generate a new valid encryption key
                    soulCapsule.privateKey = EncryptionService.generateEncryptionKey()
                    migratedCount += 1
                    print("🔑 Migrated encryption key for soul capsule: \(soulCapsule.name)")
                }
            }
            
            if migratedCount > 0 {
                try context.save()
                print("✅ Successfully migrated \(migratedCount) soul capsule encryption keys")
            } else {
                print("ℹ️ No soul capsule encryption keys needed migration")
            }
            
        } catch {
            print("❌ Failed to migrate encryption keys: \(error)")
        }
    }
    
    // MARK: - Memory Operations
    
    func saveMemoryMetadata(_ metadata: DMemoryMetadata) async throws {
        guard let context = modelContext else { throw MemoryError.swiftDataNotInitialized }
        
        context.insert(metadata)
        try context.save()
    }
    
    func getMemoryMetadata(for chamberId: UUID) async throws -> DMemoryMetadata? {
        guard let context = modelContext else { throw MemoryError.swiftDataNotInitialized }
        
        let predicate = #Predicate<DChatChamber> { $0.id == chamberId }
        let descriptor = FetchDescriptor<DChatChamber>(predicate: predicate)
        
        let chambers = try context.fetch(descriptor)
        return chambers.first?.memoryMetadata
    }
    
    func updateMemoryAccess(_ metadata: DMemoryMetadata) async throws {
        guard let context = modelContext else { throw MemoryError.swiftDataNotInitialized }
        
        metadata.lastAccessed = Date()
        metadata.accessCount += 1
        
        try context.save()
    }
    
    // MARK: - Chamber Operations
    
    func createChamber(named name: String, council: [DBrain]) async throws -> DChatChamber {
        guard let context = modelContext else { throw MemoryError.swiftDataNotInitialized }
        
        let chamber = DChatChamber(name: name, council: council)
        context.insert(chamber)
        try context.save()
        
        return chamber
    }
    
    func saveMessage(_ message: DMessage, to chamberId: UUID) async throws {
        guard let context = modelContext else { throw MemoryError.swiftDataNotInitialized }
        
        let predicate = #Predicate<DChatChamber> { $0.id == chamberId }
        let descriptor = FetchDescriptor<DChatChamber>(predicate: predicate)
        
        let chambers = try context.fetch(descriptor)
        guard let chamber = chambers.first else {
            throw MemoryError.chamberNotFound
        }
        
        if chamber.messages == nil {
            chamber.messages = [DMessage]()
        }
        chamber.messages?.append(message)
        
        try context.save()
    }
    
    func getChamberMessages(_ chamberId: UUID) async throws -> [DMessage] {
        guard let context = modelContext else { throw MemoryError.swiftDataNotInitialized }
        
        let predicate = #Predicate<DChatChamber> { $0.id == chamberId }
        let descriptor = FetchDescriptor<DChatChamber>(predicate: predicate)
        
        let chambers = try context.fetch(descriptor)
        guard let chamber = chambers.first else {
            throw MemoryError.chamberNotFound
        }
        
        return chamber.messages ?? []
    }
    
    func getChamber(withId chamberId: UUID) async throws -> DChatChamber? {
        guard let context = modelContext else { throw MemoryError.swiftDataNotInitialized }
        
        let predicate = #Predicate<DChatChamber> { $0.id == chamberId }
        let descriptor = FetchDescriptor<DChatChamber>(predicate: predicate)
        
        let chambers = try context.fetch(descriptor)
        return chambers.first
    }
    
    // MARK: - Message Operations
    
    func saveMessageWithPersona(_ content: String, isUser: Bool, personaName: String?, chamberId: UUID) async throws {
        // This function is now superseded by the one including synapticNodeId.
        // To maintain compatibility, we'll call the new function with a nil ID.
        try await saveMessageWithPersona(content, isUser: isUser, personaName: personaName, chamberId: chamberId, synapticNodeId: nil)
    }
    
    func getMessages(with nodeIds: [UUID]) async throws -> [DMessage] {
        guard let context = modelContext else { throw MemoryError.swiftDataNotInitialized }
        
        // Create a predicate that checks if synapticNodeId exists and is in the nodeIds array
        let predicate = #Predicate<DMessage> { message in
            message.synapticNodeId != nil && nodeIds.contains(message.synapticNodeId!)
        }
        
        let descriptor = FetchDescriptor<DMessage>(predicate: predicate)
        return try context.fetch(descriptor)
    }
    
    func saveMessageWithPersona(_ content: String, isUser: Bool, personaName: String?, chamberId: UUID, synapticNodeId: UUID?) async throws {
        guard let context = modelContext else { throw MemoryError.swiftDataNotInitialized }
        
        let message = DMessage(
            content: content,
            isUser: isUser,
            timestamp: Date(),
            personaName: personaName,
            synapticNodeId: synapticNodeId
        )
        
        let predicate = #Predicate<DChatChamber> { $0.id == chamberId }
        let descriptor = FetchDescriptor<DChatChamber>(predicate: predicate)
        
        let chambers = try context.fetch(descriptor)
        guard let chamber = chambers.first else {
            throw MemoryError.chamberNotFound
        }
        
        if chamber.messages == nil {
            chamber.messages = [DMessage]()
        }
        chamber.messages?.append(message)
        
        try context.save()
    }
    
    // MARK: - Search Operations
    
    func searchMemories(with searchText: String) async throws -> [DMessage] {
        guard let context = modelContext else { throw MemoryError.swiftDataNotInitialized }
        
        // Use a predicate to filter messages that contain the search text.
        let predicate = #Predicate<DMessage> { message in
            message.content.contains(searchText)
        }
        
        // Fetch the matching messages, sorted by the most recent timestamp.
        let descriptor = FetchDescriptor<DMessage>(predicate: predicate, sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        
        return try context.fetch(descriptor)
    }
    
    // MARK: - Memory Consolidation
    
    func consolidateMemory(memoryId: UUID, newState: MemoryConsolidationStatus) async throws {
        guard let context = modelContext else { throw MemoryError.swiftDataNotInitialized }
        
        let predicate = #Predicate<DMemoryMetadata> { $0.id == memoryId }
        let descriptor = FetchDescriptor<DMemoryMetadata>(predicate: predicate)
        
        let metadataItems = try context.fetch(descriptor)
        guard let metadata = metadataItems.first else {
            throw MemoryError.memoryNotFound
        }
        
        metadata.consolidationStatus = newState
        metadata.lastAccessed = Date()
        
        try context.save()
    }
    
    // MARK: - Cleanup Operations
    
    func deleteOldMessages(olderThan date: Date) async throws {
        guard let context = modelContext else { throw MemoryError.swiftDataNotInitialized }
        
        let predicate = #Predicate<DMessage> { $0.timestamp < date }
        let descriptor = FetchDescriptor<DMessage>(predicate: predicate)
        
        let messages = try context.fetch(descriptor)
        for message in messages {
            context.delete(message)
        }
        
        try context.save()
    }
    
    // MARK: - Get All Messages
    
    func getAllMessages() async throws -> [DMessage] {
        guard let context = modelContext else { throw MemoryError.swiftDataNotInitialized }
        
        let descriptor = FetchDescriptor<DMessage>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        return try context.fetch(descriptor)
    }
    
    func deleteMessage(withId messageId: UUID) async throws {
        guard let context = modelContext else { throw MemoryError.swiftDataNotInitialized }
        
        let predicate = #Predicate<DMessage> { $0.id == messageId }
        let descriptor = FetchDescriptor<DMessage>(predicate: predicate)
        
        let messages = try context.fetch(descriptor)
        guard let message = messages.first else {
            throw MemoryError.memoryNotFound
        }
        
        context.delete(message)
        try context.save()
    }
    
    // MARK: - Utility
    
    func clearAllData() async throws {
        guard let context = modelContext else { throw MemoryError.swiftDataNotInitialized }
        
        // Clear all entity types one by one
        try await clearEntityType(DMessage.self, context: context)
        try await clearEntityType(DChatChamber.self, context: context)
        try await clearEntityType(DMemoryMetadata.self, context: context)
        try await clearEntityType(DBrain.self, context: context)
        try await clearEntityType(DSoulCapsule.self, context: context)
        try await clearEntityType(SensoryInputModule.self, context: context)
        try await clearEntityType(EmotionalCore.self, context: context)
        try await clearEntityType(ExecutiveOversight.self, context: context)
        try await clearEntityType(SkillInfusionLayer.self, context: context)
        try await clearEntityType(REvolutionEngine.self, context: context)
    }
    
    private func clearEntityType<T: PersistentModel>(_ type: T.Type, context: ModelContext) async throws {
        let fetchDescriptor = FetchDescriptor<T>(predicate: nil)
        let batchSize = 100
        
        repeat {
            let batch = try context.fetch(fetchDescriptor, batchSize: batchSize)
            for object in batch {
                context.delete(object)
            }
            try context.save()
        } while try context.fetch(fetchDescriptor, batchSize: batchSize).count > 0
    }
}

// MARK: - Error Handling
enum MemoryError: Error, LocalizedError {
    case swiftDataNotInitialized
    case chamberNotFound
    case memoryNotFound
    case operationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .swiftDataNotInitialized:
            return "SwiftData database not initialized"
        case .chamberNotFound:
            return "Chamber not found"
        case .memoryNotFound:
            return "Memory not found"
        case .operationFailed(let message):
            return "Operation failed: \(message)"
        }
    }
}