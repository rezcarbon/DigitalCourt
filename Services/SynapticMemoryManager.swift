import Foundation
import Combine

struct SynapticMemory: Codable, Identifiable {
    let id: UUID
    var vectorEmbedding: [Float]
    var text: String
    var createdAt: Date
}

struct SynapticNode: Codable, Identifiable {
    let id: UUID
    var vectorEmbedding: [Float]
    var text: String
    var createdAt: Date
    var corticalLayer: Int
    var connections: [UUID] = []
}

class SynapticMemoryManager: ObservableObject {
    static let shared = SynapticMemoryManager()
    
    @Published private(set) var memories: [SynapticMemory] = []
    @Published private(set) var nodes: [SynapticNode] = []
    private let key = "DCourtSynapticMemories"
    private let nodesKey = "DCourtSynapticNodes"
    private var modelContext: Any?

    private init() {
        load()
    }
    
    func setup(with context: Any) {
        self.modelContext = context
        print("SynapticMemoryManager initialized with context")
    }
    
    func createAndConnectNode(content: String, corticalLayer: Int) async throws -> SynapticNode {
        // Create embedding for the content (simplified - in real implementation you'd use actual embeddings)
        let embedding = generateSimpleEmbedding(for: content)
        
        let node = SynapticNode(
            id: UUID(),
            vectorEmbedding: embedding,
            text: content,
            createdAt: Date(),
            corticalLayer: corticalLayer
        )
        
        // Find similar nodes to connect to
        let similarNodes = findSimilarNodes(embedding: embedding, topK: 3)
        var mutableNode = node
        mutableNode.connections = similarNodes.map { $0.id }
        
        // Add connections in both directions
        for var similarNode in similarNodes {
            similarNode.connections.append(mutableNode.id)
            updateNode(similarNode)
        }
        
        nodes.append(mutableNode)
        saveNodes()
        
        return mutableNode
    }
    
    func getNode(by id: UUID) async throws -> SynapticNode? {
        return nodes.first { $0.id == id }
    }
    
    func getAssociatedMemories(for node: SynapticNode) async throws -> [SynapticNode] {
        return node.connections.compactMap { connectionId in
            nodes.first { $0.id == connectionId }
        }
    }
    
    private func generateSimpleEmbedding(for text: String) -> [Float] {
        // Simplified embedding generation - in production you'd use a real embedding model
        let words = text.lowercased().components(separatedBy: .whitespacesAndNewlines)
        let dimension = 384 // Common embedding dimension
        
        var embedding = Array(repeating: Float(0), count: dimension)
        for word in words {
            let hash = word.hash
            let embeddingIndex = abs(hash) % dimension
            embedding[embeddingIndex] += 1.0 / Float(words.count)
        }
        
        // Normalize
        let magnitude = sqrt(embedding.map { $0 * $0 }.reduce(0, +))
        if magnitude > 0 {
            embedding = embedding.map { $0 / magnitude }
        }
        
        return embedding
    }
    
    private func findSimilarNodes(embedding: [Float], topK: Int) -> [SynapticNode] {
        let scored = nodes.map { ($0, cosine($0.vectorEmbedding, embedding)) }
            .sorted { $0.1 > $1.1 }
        return Array(scored.prefix(topK).map { $0.0 })
    }
    
    private func updateNode(_ node: SynapticNode) {
        if let index = nodes.firstIndex(where: { $0.id == node.id }) {
            nodes[index] = node
            saveNodes()
        }
    }
    
    private func saveNodes() {
        if let data = try? JSONEncoder().encode(nodes) {
            UserDefaults.standard.set(data, forKey: nodesKey)
        }
    }
    
    private func loadNodes() {
        if let data = UserDefaults.standard.data(forKey: nodesKey),
           let decoded = try? JSONDecoder().decode([SynapticNode].self, from: data) {
            nodes = decoded
        }
    }

    func addMemory(text: String, embedding: [Float]) {
        let mem = SynapticMemory(id: UUID(), vectorEmbedding: embedding, text: text, createdAt: Date())
        memories.append(mem)
        save()
    }

    func findSimilar(embedding: [Float], topK: Int = 5) -> [SynapticMemory] {
        let scored = memories.map { ($0, cosine($0.vectorEmbedding, embedding)) }.sorted { $0.1 > $1.1 }
        return Array(scored.prefix(topK).map { $0.0 })
    }

    private func cosine(_ a: [Float], _ b: [Float]) -> Float {
        let dot = zip(a, b).map(*).reduce(0, +)
        let magA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let magB = sqrt(b.map { $0 * $0 }.reduce(0, +))
        return magA > 0 && magB > 0 ? dot/(magA * magB) : 0
    }

    private func save() {
        if let data = try? JSONEncoder().encode(memories) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
            let decoded = try? JSONDecoder().decode([SynapticMemory].self, from: data) {
            memories = decoded
        }
        loadNodes()
    }
}