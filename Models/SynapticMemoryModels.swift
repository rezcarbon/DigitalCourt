import Foundation
import SwiftData

// MARK: - Synaptic Memory Node
@Model
final class SynapticMemoryNode {
    @Attribute(.unique) var id: UUID
    var content: String // The actual memory content (e.g., a message or a summary)
    var timestamp: Date
    var corticalLayer: Int // Layer 1 to 6
    
    // A vector representation of the content for similarity search.
    // Stored as Data to be database-friendly.
    @Attribute(.externalStorage) var vectorEmbeddingData: Data?
    
    // Relationships will be managed by a separate connections model
    
    init(id: UUID = UUID(), content: String, timestamp: Date = Date(), corticalLayer: Int, vectorEmbedding: [Float]) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
        self.corticalLayer = corticalLayer
        self.vectorEmbedding = vectorEmbedding
    }
    
    var vectorEmbedding: [Float]? {
        get {
            guard let data = vectorEmbeddingData else { return nil }
            return data.withUnsafeBytes { Array($0.bindMemory(to: Float.self)) }
        }
        set {
            guard let newValue = newValue else {
                vectorEmbeddingData = nil
                return
            }
            vectorEmbeddingData = Data(bytes: newValue, count: newValue.count * MemoryLayout<Float>.size)
        }
    }
}

// MARK: - Synaptic Connection
@Model
final class SynapticConnection {
    @Attribute(.unique) var id: UUID
    var sourceNodeID: UUID
    var targetNodeID: UUID
    var strength: Double // Represents the weight of the connection (0.0 to 1.0)
    var lastActivated: Date
    
    init(id: UUID = UUID(), sourceNodeID: UUID, targetNodeID: UUID, strength: Double) {
        self.id = id
        self.sourceNodeID = sourceNodeID
        self.targetNodeID = targetNodeID
        self.strength = strength
        self.lastActivated = Date()
    }
}