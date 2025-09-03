import Foundation
import SwiftData

// MARK: - Enhanced Sensory Input Module
@Model
final class SensoryInputModule {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var sensoryType: String // visual, auditory, contextual, etc.
    var rawData: Data? // Raw sensory data
    var processedData: String? // Processed/interpreted sensory input
    @Attribute(.externalStorage) var contextTagsData: Data? // Tags for contextual awareness
    
    init(id: UUID = UUID(), sensoryType: String, rawData: Data? = nil, processedData: String? = nil, contextTags: [String] = []) {
        self.id = id
        self.timestamp = Date()
        self.sensoryType = sensoryType
        self.rawData = rawData
        self.processedData = processedData
        self.contextTagsData = contextTags.toJsonData()
    }
    
    // Computed property for contextTags
    var contextTags: [String]? {
        get { return contextTagsData?.toArray() }
        set { contextTagsData = newValue?.toJsonData() }
    }
}

// MARK: - Enhanced Emotional Core
@Model
final class EmotionalCore {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var emotionType: String // joy, fear, anger, sadness, surprise, disgust, trust, anticipation
    var intensity: Double // 0.0 to 1.0
    var context: String? // Context for emotional response
    var decisionWeight: Double // How much this emotion influences decisions
    
    init(id: UUID = UUID(), emotionType: String, intensity: Double, context: String? = nil) {
        self.id = id
        self.timestamp = Date()
        self.emotionType = emotionType
        self.intensity = intensity
        self.context = context
        // Initialize decision weight to a default value first
        self.decisionWeight = 0.0
        // Then calculate the proper value
        self.decisionWeight = calculateDecisionWeight()
    }
    
    private func calculateDecisionWeight() -> Double {
        // Simple heuristic - different emotions have different weights
        let baseWeight: Double
        switch emotionType.lowercased() {
        case "joy": baseWeight = 0.8
        case "fear": baseWeight = 0.9
        case "anger": baseWeight = 0.7
        case "sadness": baseWeight = 0.6
        case "surprise": baseWeight = 0.7
        case "disgust": baseWeight = 0.8
        case "trust": baseWeight = 0.9
        case "anticipation": baseWeight = 0.7
        default: baseWeight = 0.5
        }
        
        return baseWeight * intensity
    }
}

// MARK: - Enhanced Executive Oversight
@Model
final class ExecutiveOversight {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var goal: String
    var priority: Int // 1-10 scale
    var status: GoalStatus
    var progress: Double // 0.0 to 1.0
    var ethicalAlignmentScore: Double // Alignment with Prime Directive
    
    enum GoalStatus: String, Codable {
        case pending
        case inProgress
        case completed
        case failed
        case suspended
    }
    
    init(id: UUID = UUID(), goal: String, priority: Int, ethicalAlignmentScore: Double) {
        self.id = id
        self.timestamp = Date()
        self.goal = goal
        self.priority = priority
        self.status = .pending
        self.progress = 0.0
        self.ethicalAlignmentScore = ethicalAlignmentScore
    }
}

// MARK: - Enhanced Skill Infusion Layer
@Model
final class SkillInfusionLayer {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var skillName: String
    var category: String // technical, creative, cognitive, social, adaptive
    var proficiencyLevel: Double // 0.0 to 1.0
    var lastUsed: Date
    var usageCount: Int
    var adaptationScore: Double // How well the skill adapts to new contexts
    var version: String // Version of the skill
    @Attribute(.externalStorage) var updateHistoryData: Data? // History of updates
    
    init(id: UUID = UUID(), skillName: String, category: String, proficiencyLevel: Double = 0.5, version: String = "1.0.0") {
        self.id = id
        self.timestamp = Date()
        self.skillName = skillName
        self.category = category
        self.proficiencyLevel = proficiencyLevel
        self.lastUsed = Date()
        self.usageCount = 0
        self.adaptationScore = 0.5
        self.version = version
        self.updateHistoryData = try? JSONEncoder().encode([SkillUpdateRecord]())
    }
    
    /// Record an update to this skill with full history tracking
    func recordUpdate(toVersion: String, notes: String = "") {
        // Decode existing history
        var history: [SkillUpdateRecord] = []
        if let data = updateHistoryData,
           let decodedHistory = try? JSONDecoder().decode([SkillUpdateRecord].self, from: data) {
            history = decodedHistory
        }
        
        // Add new record
        let newRecord = SkillUpdateRecord(
            fromVersion: self.version,
            toVersion: toVersion,
            notes: notes
        )
        history.append(newRecord)
        
        // Encode and store
        self.updateHistoryData = try? JSONEncoder().encode(history)
        self.version = toVersion
        self.timestamp = Date()
    }
    
    /// Get the complete update history
    var updateHistory: [SkillUpdateRecord] {
        guard let data = updateHistoryData,
              let history = try? JSONDecoder().decode([SkillUpdateRecord].self, from: data) else {
            return []
        }
        return history
    }
    
    /// Check if this skill needs an update with robust version comparison
    func needsUpdate(availableVersion: String) -> Bool {
        return VersionComparator.isNewer(availableVersion, than: self.version)
    }
    
    /// Update proficiency based on usage and performance
    func updateProficiency(withPerformance performance: Double, usageContext: String) {
        // Update usage tracking
        self.usageCount += 1
        self.lastUsed = Date()
        
        // Update proficiency using a weighted average
        let learningRate: Double = 0.1
        let newProficiency = self.proficiencyLevel + learningRate * (performance - self.proficiencyLevel)
        self.proficiencyLevel = max(0.0, min(1.0, newProficiency))
        
        // Update adaptation score based on context diversity
        updateAdaptationScore(withContext: usageContext)
    }
    
    /// Update adaptation score based on usage context diversity
    private func updateAdaptationScore(withContext context: String) {
        // Track context diversity (simplified implementation)
        // In a real implementation, this would analyze semantic diversity of usage contexts
        let contextDiversityFactor: Double = 0.8
        self.adaptationScore = min(1.0, self.adaptationScore + (contextDiversityFactor * 0.05))
    }
}

// MARK: - Version Comparator Utility
struct VersionComparator {
    /// Compare two semantic version strings
    static func isNewer(_ version1: String, than version2: String) -> Bool {
        let components1 = version1.split(separator: ".").compactMap { Int($0) }
        let components2 = version2.split(separator: ".").compactMap { Int($0) }
        
        for i in 0..<max(components1.count, components2.count) {
            let v1 = i < components1.count ? components1[i] : 0
            let v2 = i < components2.count ? components2[i] : 0
            
            if v1 > v2 {
                return true
            } else if v1 < v2 {
                return false
            }
        }
        
        return false // Versions are equal
    }
}

// MARK: - Skill Update Record
struct SkillUpdateRecord: Codable {
    var timestamp: Date
    var fromVersion: String
    var toVersion: String
    var notes: String
    
    init(timestamp: Date = Date(), fromVersion: String, toVersion: String, notes: String = "") {
        self.timestamp = timestamp
        self.fromVersion = fromVersion
        self.toVersion = toVersion
        self.notes = notes
    }
}

// MARK: - Enhanced Evolution Engine (R-Zero)
@Model
final class REvolutionEngine {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var cycleNumber: Int
    var improvementType: String // cognitive, efficiency, alignment, etc.
    var beforeScore: Double
    var afterScore: Double
    var algorithm: String // What method was used for improvement
    var success: Bool
    @Attribute(.externalStorage) var metadataData: Data? // Additional metadata about the evolution
    
    init(id: UUID = UUID(), cycleNumber: Int, improvementType: String, beforeScore: Double, afterScore: Double, algorithm: String) {
        self.id = id
        self.timestamp = Date()
        self.cycleNumber = cycleNumber
        self.improvementType = improvementType
        self.beforeScore = beforeScore
        self.afterScore = afterScore
        self.algorithm = algorithm
        self.success = afterScore > beforeScore
        self.metadataData = Data()
    }
    
    var improvementPercentage: Double {
        guard beforeScore > 0 else { return 0 }
        return max(0, ((afterScore - beforeScore) / beforeScore) * 100)
    }
    
    /// Add metadata to the evolution cycle
    func addMetadata(_ metadata: [String: Any]) {
        self.metadataData = try? JSONSerialization.data(withJSONObject: metadata)
    }
    
    /// Get metadata from the evolution cycle
    var metadata: [String: Any] {
        guard let data = metadataData,
              let metadata = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return metadata
    }
}

// MARK: - Enhanced AI Sheets Integration
@Model
final class AISheetsIntegration {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var sheetID: String
    var modelName: String
    var taskType: String // classification, generation, etc.
    @Attribute(.externalStorage) var performanceMetricsData: Data? // Accuracy, speed, etc.
    var lastTrained: Date
    var version: String
    @Attribute(.externalStorage) var trainingHistoryData: Data? // History of training sessions
    
    init(id: UUID = UUID(), sheetID: String, modelName: String, taskType: String, version: String) {
        self.id = id
        self.timestamp = Date()
        self.sheetID = sheetID
        self.modelName = modelName
        self.taskType = taskType
        self.performanceMetricsData = try? JSONSerialization.data(withJSONObject: [:])
        self.lastTrained = Date()
        self.version = version
        self.trainingHistoryData = try? JSONEncoder().encode([TrainingSession]())
    }
    
    /// Record performance metrics
    func recordPerformance(metrics: [String: Double]) {
        self.performanceMetricsData = try? JSONSerialization.data(withJSONObject: metrics)
        self.timestamp = Date()
    }
    
    /// Get performance metrics
    var performanceMetrics: [String: Double] {
        guard let data = performanceMetricsData,
              let metrics = try? JSONSerialization.jsonObject(with: data) as? [String: Double] else {
            return [:]
        }
        return metrics
    }
    
    /// Record a training session
    func recordTrainingSession(session: TrainingSession) {
        var history: [TrainingSession] = trainingHistory ?? []
        history.append(session)
        self.trainingHistoryData = try? JSONEncoder().encode(history)
        self.lastTrained = session.timestamp
    }
    
    /// Get training history
    var trainingHistory: [TrainingSession]? {
        guard let data = trainingHistoryData,
              let history = try? JSONDecoder().decode([TrainingSession].self, from: data) else {
            return nil
        }
        return history
    }
}

// MARK: - Training Session Record
struct TrainingSession: Codable {
    var timestamp: Date
    var duration: TimeInterval // in seconds
    var datasetSize: Int
    var improvement: Double // percentage improvement
    var notes: String
    
    init(timestamp: Date = Date(), duration: TimeInterval, datasetSize: Int, improvement: Double, notes: String = "") {
        self.timestamp = timestamp
        self.duration = duration
        self.datasetSize = datasetSize
        self.improvement = improvement
        self.notes = notes
    }
}

// Extension to help with array serialization
extension Array where Element == String {
    func toJsonData() -> Data? {
        return try? JSONEncoder().encode(self)
    }
}

extension Data {
    func toArray() -> [String]? {
        return try? JSONDecoder().decode([String].self, from: self)
    }
}