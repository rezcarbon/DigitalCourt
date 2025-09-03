import Foundation
import Combine
import SwiftData

/// Advanced memory evolution and consolidation system for Phase 3
@MainActor
class AdvancedMemoryEvolutionManager: ObservableObject {
    
    @Published var evolutionStats: MemoryEvolutionStats = MemoryEvolutionStats()
    @Published var isEvolving: Bool = false
    @Published var currentEvolutionPhase: EvolutionPhase = .idle
    
    private let memoryManager = MemoryManager.shared
    private let consolidationInterval: TimeInterval = 3600 // 1 hour
    private let maxMemoryAge: TimeInterval = 86400 * 30 // 30 days
    
    private var consolidationTimer: Timer?
    private var evolutionEngine: MemoryEvolutionEngine
    private var patternRecognizer: MemoryPatternRecognizer
    private var importanceCalculator: MemoryImportanceCalculator
    
    enum EvolutionPhase: String, CaseIterable, Codable {
        case idle = "Idle"
        case analyzing = "Analyzing Memories"
        case consolidating = "Consolidating Knowledge"
        case evolving = "Evolving Patterns"
        case optimizing = "Optimizing Storage"
        case completed = "Evolution Complete"
    }
    
    init() {
        self.evolutionEngine = MemoryEvolutionEngine()
        self.patternRecognizer = MemoryPatternRecognizer()
        self.importanceCalculator = MemoryImportanceCalculator()
        
        startAutomaticEvolution()
    }
    
    deinit {
        consolidationTimer?.invalidate()
    }
    
    // MARK: - Public Interface
    
    func triggerManualEvolution() async {
        guard !isEvolving else { return }
        
        await performEvolutionCycle()
    }
    
    func getEvolutionHistory() -> [EvolutionCycle] {
        return evolutionStats.evolutionHistory
    }
    
    func getMemoryInsights() async -> MemoryInsights {
        let memories = await memoryManager.getAllMemories()
        let patterns = await patternRecognizer.recognizePatterns(in: memories)
        let trends = await analyzeTrends(memories: memories)
        let recommendations = await generateRecommendations(patterns: patterns, trends: trends)
        
        return MemoryInsights(
            totalMemories: memories.count,
            patterns: patterns,
            trends: trends,
            recommendations: recommendations,
            timestamp: Date()
        )
    }
    
    // MARK: - Evolution Process
    
    private func startAutomaticEvolution() {
        consolidationTimer = Timer.scheduledTimer(withTimeInterval: consolidationInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.performEvolutionCycle()
            }
        }
    }
    
    private func performEvolutionCycle() async {
        guard !isEvolving else { return }
        
        isEvolving = true
        let startTime = Date()
        var evolutionResults = EvolutionResults()
        
        // Phase 1: Analyze memories
        currentEvolutionPhase = .analyzing
        let memories = await memoryManager.getAllMemories()
        evolutionResults.analyzedMemories = memories.count
        
        // Phase 2: Consolidate knowledge
        currentEvolutionPhase = .consolidating
        let consolidatedKnowledge = await consolidateKnowledge(memories: memories)
        evolutionResults.consolidatedKnowledge = consolidatedKnowledge.count
        
        // Phase 3: Evolve patterns
        currentEvolutionPhase = .evolving
        let evolvedPatterns = await evolvePatterns(memories: memories, knowledge: consolidatedKnowledge)
        evolutionResults.evolvedPatterns = evolvedPatterns.count
        
        // Phase 4: Optimize storage
        currentEvolutionPhase = .optimizing
        let optimizationResults = await optimizeMemoryStorage(memories: memories)
        evolutionResults.optimizedMemories = optimizationResults.optimizedCount
        evolutionResults.removedRedundant = optimizationResults.removedCount
        
        // Phase 5: Complete evolution
        currentEvolutionPhase = .completed
        let duration = Date().timeIntervalSince(startTime)
        
        let cycle = EvolutionCycle(
            timestamp: Date(),
            duration: duration,
            results: evolutionResults,
            phase: .completed
        )
        
        evolutionStats.evolutionHistory.append(cycle)
        evolutionStats.totalEvolutionCycles += 1
        evolutionStats.lastEvolutionDate = Date()
        
        // Keep only recent evolution history
        if evolutionStats.evolutionHistory.count > 100 {
            evolutionStats.evolutionHistory.removeFirst()
        }
        
        currentEvolutionPhase = .idle
        isEvolving = false
    }
    
    private func consolidateKnowledge(memories: [Memory]) async -> [ConsolidatedKnowledge] {
        var consolidatedItems: [ConsolidatedKnowledge] = []
        
        // Group memories by topic/theme
        let groupedMemories = await groupMemoriesByTopic(memories: memories)
        
        for (topic, topicMemories) in groupedMemories {
            if topicMemories.count >= 3 { // Minimum threshold for consolidation
                let consolidated = await evolutionEngine.consolidateMemories(
                    topic: topic,
                    memories: topicMemories
                )
                consolidatedItems.append(consolidated)
                
                // Store consolidated knowledge as a new memory
                do {
                    try await memoryManager.storeMemory(
                        content: consolidated.summary,
                        isUser: false,
                        personaName: "MemoryEvolution",
                        chamberId: topicMemories.first?.chamberId ?? UUID()
                    )
                } catch {
                    print("Failed to store consolidated knowledge: \(error)")
                }
            }
        }
        
        return consolidatedItems
    }
    
    private func evolvePatterns(memories: [Memory], knowledge: [ConsolidatedKnowledge]) async -> [EvolvedPattern] {
        let patterns = await patternRecognizer.recognizePatterns(in: memories)
        var evolvedPatterns: [EvolvedPattern] = []
        
        for pattern in patterns {
            let evolution = await evolutionEngine.evolvePattern(
                pattern: pattern,
                context: knowledge
            )
            evolvedPatterns.append(evolution)
        }
        
        return evolvedPatterns
    }
    
    private func optimizeMemoryStorage(memories: [Memory]) async -> StorageOptimizationResult {
        var optimizedCount = 0
        var removedCount = 0
        
        // Calculate importance scores for all memories
        let scoredMemories = await importanceCalculator.calculateImportanceScores(memories: memories)
        
        // Remove very low importance memories older than threshold
        let cutoffDate = Date().addingTimeInterval(-maxMemoryAge)
        for scoredMemory in scoredMemories {
            if scoredMemory.importanceScore < 0.1 && scoredMemory.memory.timestamp < cutoffDate {
                do {
                    try await memoryManager.deleteMemory(scoredMemory.memory)
                    removedCount += 1
                } catch {
                    print("Failed to delete memory: \(error)")
                }
            } else if scoredMemory.importanceScore > 0.5 {
                // Optimize high-importance memories (could include compression, indexing, etc.)
                optimizedCount += 1
            }
        }
        
        return StorageOptimizationResult(
            optimizedCount: optimizedCount,
            removedCount: removedCount
        )
    }
    
    private func groupMemoriesByTopic(memories: [Memory]) async -> [String: [Memory]] {
        // Simple topic grouping based on keywords and semantic similarity
        var groups: [String: [Memory]] = [:]
        
        for memory in memories {
            let topic = await extractTopic(from: memory.content)
            if groups[topic] == nil {
                groups[topic] = []
            }
            groups[topic]?.append(memory)
        }
        
        return groups
    }
    
    private func extractTopic(from content: String) async -> String {
        // Simplified topic extraction - in a real implementation, this would use NLP
        let separatorSet = CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)
        let words = content.lowercased().components(separatedBy: separatorSet)
        let keywords = ["code", "ai", "memory", "system", "user", "data", "analysis", "programming"]
        
        for keyword in keywords {
            if words.contains(keyword) {
                return keyword
            }
        }
        
        return "general"
    }
    
    private func analyzeTrends(memories: [Memory]) async -> [MemoryTrend] {
        var trends: [MemoryTrend] = []
        
        // Analyze memory creation patterns over time
        let calendar = Calendar.current
        let now = Date()
        let lastWeek = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        
        let recentMemories = memories.filter { $0.timestamp > lastWeek }
        let monthlyMemories = memories.filter { $0.timestamp > lastMonth }
        
        trends.append(MemoryTrend(
            type: "creation_rate",
            description: "Memory creation rate trend",
            value: Double(recentMemories.count),
            change: calculateTrendChange(recent: recentMemories.count, historical: monthlyMemories.count - recentMemories.count),
            timestamp: Date()
        ))
        
        // Analyze content complexity trends
        let averageLength = memories.map { $0.content.count }.reduce(0, +) / max(1, memories.count)
        trends.append(MemoryTrend(
            type: "content_complexity",
            description: "Average memory content length",
            value: Double(averageLength),
            change: 0.0, // Would need historical data for comparison
            timestamp: Date()
        ))
        
        return trends
    }
    
    private func calculateTrendChange(recent: Int, historical: Int) -> Double {
        guard historical > 0 else { return 0.0 }
        return (Double(recent) - Double(historical)) / Double(historical) * 100
    }
    
    private func generateRecommendations(patterns: [MemoryPattern], trends: [MemoryTrend]) async -> [MemoryRecommendation] {
        var recommendations: [MemoryRecommendation] = []
        
        // Generate recommendations based on patterns and trends
        if patterns.count > 10 {
            recommendations.append(MemoryRecommendation(
                type: "optimization",
                title: "Memory Consolidation Opportunity",
                description: "Consider consolidating similar memory patterns to improve efficiency",
                priority: .medium,
                actionable: true
            ))
        }
        
        let highActivityTrends = trends.filter { $0.change > 50 }
        if !highActivityTrends.isEmpty {
            recommendations.append(MemoryRecommendation(
                type: "capacity",
                title: "Increased Memory Activity",
                description: "Memory creation rate has increased significantly. Consider expanding storage capacity.",
                priority: .high,
                actionable: true
            ))
        }
        
        return recommendations
    }
}

// MARK: - Supporting Structures

struct MemoryEvolutionStats: Codable {
    var totalEvolutionCycles: Int = 0
    var failedEvolutionCycles: Int = 0
    var lastEvolutionDate: Date?
    var evolutionHistory: [EvolutionCycle] = []
    
    var successRate: Double {
        let total = totalEvolutionCycles + failedEvolutionCycles
        guard total > 0 else { return 0.0 }
        return Double(totalEvolutionCycles) / Double(total)
    }
}

struct EvolutionCycle: Codable, Identifiable {
    var id = UUID()
    let timestamp: Date
    let duration: TimeInterval
    let results: EvolutionResults
    let phase: AdvancedMemoryEvolutionManager.EvolutionPhase
    
    private enum CodingKeys: String, CodingKey {
        case id, timestamp, duration, results, phase
    }
}

struct EvolutionResults: Codable {
    var analyzedMemories: Int = 0
    var consolidatedKnowledge: Int = 0
    var evolvedPatterns: Int = 0
    var optimizedMemories: Int = 0
    var removedRedundant: Int = 0
}

struct ConsolidatedKnowledge: Codable, Identifiable {
    var id = UUID()
    let topic: String
    let summary: String
    let sourceMemoryCount: Int
    let confidence: Double
    let timestamp: Date
}

struct EvolvedPattern: Codable, Identifiable {
    var id = UUID()
    let originalPattern: MemoryPattern
    let evolutionType: String
    let newInsights: [String]
    let strengthIncrease: Double
    let timestamp: Date
}

struct MemoryPattern: Codable, Identifiable {
    var id = UUID()
    let type: String
    let description: String
    let frequency: Int
    let strength: Double
    let lastSeen: Date
}

struct StorageOptimizationResult {
    let optimizedCount: Int
    let removedCount: Int
}

struct ScoredMemory {
    let memory: Memory
    let importanceScore: Double
}

struct MemoryInsights: Codable {
    let totalMemories: Int
    let patterns: [MemoryPattern]
    let trends: [MemoryTrend]
    let recommendations: [MemoryRecommendation]
    let timestamp: Date
}

struct MemoryTrend: Codable, Identifiable {
    var id = UUID()
    let type: String
    let description: String
    let value: Double
    let change: Double // Percentage change
    let timestamp: Date
}

struct MemoryRecommendation: Codable, Identifiable {
    var id = UUID()
    let type: String
    let title: String
    let description: String
    let priority: Priority
    let actionable: Bool
    
    enum Priority: String, Codable, CaseIterable {
        case low, medium, high, critical
    }
}

// MARK: - Supporting Engine Classes

class MemoryEvolutionEngine {
    func consolidateMemories(topic: String, memories: [Memory]) async -> ConsolidatedKnowledge {
        let summary = generateSummary(for: memories)
        let confidence = calculateConsolidationConfidence(memories: memories)
        
        return ConsolidatedKnowledge(
            topic: topic,
            summary: summary,
            sourceMemoryCount: memories.count,
            confidence: confidence,
            timestamp: Date()
        )
    }
    
    func evolvePattern(pattern: MemoryPattern, context: [ConsolidatedKnowledge]) async -> EvolvedPattern {
        let insights = generateNewInsights(pattern: pattern, context: context)
        let strengthIncrease = calculateStrengthIncrease(pattern: pattern, insights: insights)
        
        return EvolvedPattern(
            originalPattern: pattern,
            evolutionType: "insight_enhancement",
            newInsights: insights,
            strengthIncrease: strengthIncrease,
            timestamp: Date()
        )
    }
    
    private func generateSummary(for memories: [Memory]) -> String {
        // Simplified summary generation
        let totalLength = memories.map { $0.content.count }.reduce(0, +)
        let averageLength = totalLength / max(1, memories.count)
        
        return "Consolidated knowledge from \(memories.count) memories (avg length: \(averageLength) chars)"
    }
    
    private func calculateConsolidationConfidence(memories: [Memory]) -> Double {
        // Simple confidence calculation based on memory count and recency
        let recentMemories = memories.filter { $0.timestamp > Date().addingTimeInterval(-86400) }.count
        let baseConfidence = min(0.9, Double(memories.count) * 0.1)
        let recencyBonus = Double(recentMemories) * 0.05
        
        return min(1.0, baseConfidence + recencyBonus)
    }
    
    private func generateNewInsights(pattern: MemoryPattern, context: [ConsolidatedKnowledge]) -> [String] {
        // Generate insights based on pattern and context
        var insights: [String] = []
        
        if pattern.frequency > 5 {
            insights.append("High frequency pattern detected - may indicate important recurring theme")
        }
        
        if pattern.strength > 0.7 {
            insights.append("Strong pattern correlation suggests significant relationship")
        }
        
        // Analyze context for additional insights
        let relatedKnowledge = context.filter { $0.topic.contains(pattern.type) }
        if !relatedKnowledge.isEmpty {
            insights.append("Pattern has connections to \(relatedKnowledge.count) knowledge areas")
        }
        
        return insights
    }
    
    private func calculateStrengthIncrease(pattern: MemoryPattern, insights: [String]) -> Double {
        return Double(insights.count) * 0.1 // Simple strength increase based on insight count
    }
}

class MemoryPatternRecognizer {
    func recognizePatterns(in memories: [Memory]) async -> [MemoryPattern] {
        var patterns: [MemoryPattern] = []
        
        // Simple pattern recognition based on keyword frequency
        let allContent = memories.map { $0.content }.joined(separator: " ")
        let separatorSet = CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)
        let words = allContent.lowercased().components(separatedBy: separatorSet)
        let wordCounts = Dictionary(grouping: words, by: { $0 }).mapValues { $0.count }
        
        for (word, count) in wordCounts {
            if count >= 3 && word.count > 3 { // Minimum threshold
                patterns.append(MemoryPattern(
                    type: "keyword",
                    description: "Frequent keyword: \(word)",
                    frequency: count,
                    strength: Double(count) / Double(memories.count),
                    lastSeen: Date()
                ))
            }
        }
        
        return patterns.sorted { $0.strength > $1.strength }
    }
}

class MemoryImportanceCalculator {
    func calculateImportanceScores(memories: [Memory]) async -> [ScoredMemory] {
        return memories.map { memory in
            let score = calculateImportanceScore(for: memory)
            return ScoredMemory(memory: memory, importanceScore: score)
        }
    }
    
    private func calculateImportanceScore(for memory: Memory) -> Double {
        var score = 0.5 // Base score
        
        // Recency factor
        let daysSinceCreation = Date().timeIntervalSince(memory.timestamp) / 86400
        let recencyFactor = max(0.1, 1.0 - (daysSinceCreation / 30.0)) // Decay over 30 days
        score *= recencyFactor
        
        // Content length factor
        let lengthFactor = min(1.0, Double(memory.content.count) / 500.0) // Normalize to 500 chars
        score += lengthFactor * 0.2
        
        // Persona importance (user memories are more important)
        if memory.isUser {
            score += 0.3
        }
        
        // Keywords that indicate importance
        let importantKeywords = ["error", "bug", "fix", "important", "critical", "remember"]
        let contentLower = memory.content.lowercased()
        for keyword in importantKeywords {
            if contentLower.contains(keyword) {
                score += 0.1
                break
            }
        }
        
        return min(1.0, max(0.0, score))
    }
}