import Foundation
import NaturalLanguage

/// Advanced contextual understanding engine for enhanced AI comprehension
@MainActor
class ContextualUnderstandingEngine {
    
    private let nlTagger = NLTagger(tagSchemes: [.lexicalClass, .language, .lemma, .nameType])
    private var contextHistory: [ContextualMemory] = []
    private let maxContextHistory = 100
    
    func generateResponse(understanding: FusedUnderstanding, context: String) async -> ContextualResponse {
        let contextualAnalysis = analyzeContext(context, understanding: understanding)
        let responseStrategy = determineResponseStrategy(analysis: contextualAnalysis)
        let generatedResponse = generateContextualResponse(strategy: responseStrategy, understanding: understanding)
        let suggestedActions = generateSuggestedActions(understanding: understanding, context: contextualAnalysis)
        let additionalContext = gatherAdditionalContext(understanding: understanding)
        
        let response = ContextualResponse(
            response: generatedResponse,
            responseType: responseStrategy.type,
            confidence: calculateResponseConfidence(understanding: understanding, context: contextualAnalysis),
            suggestedActions: suggestedActions,
            additionalContext: additionalContext,
            timestamp: Date()
        )
        
        // Store in context history
        addToContextHistory(understanding: understanding, response: response, context: context)
        
        return response
    }
    
    func enhanceWithContext(understanding: FusedUnderstanding, contextualClues: [String]) async -> EnhancedUnderstanding {
        let contextualEnhancements = processContextualClues(contextualClues, understanding: understanding)
        let refinedIntent = refineIntent(understanding.primaryIntent, with: contextualEnhancements)
        let enhancedConfidence = enhanceConfidence(understanding.confidence, with: contextualEnhancements)
        
        let enhanced = EnhancedUnderstanding(
            originalUnderstanding: understanding,
            contextualEnhancements: contextualEnhancements,
            refinedIntent: refinedIntent,
            enhancedConfidence: enhancedConfidence,
            timestamp: Date()
        )
        
        return enhanced
    }
    
    // MARK: - Context Analysis
    
    private func analyzeContext(_ context: String, understanding: FusedUnderstanding) -> ContextualAnalysis {
        let sentiment = analyzeSentiment(context)
        let entities = extractEntities(context)
        let topics = extractTopics(context)
        let urgency = assessUrgency(context)
        let complexity = assessComplexity(context, understanding: understanding)
        let temporalContext = extractTemporalContext(context)
        let spatialContext = extractSpatialContext(context)
        let userIntent = inferUserIntent(context, understanding: understanding)
        let emotionalState = analyzeEmotionalState(context)
        let domainContext = identifyDomain(context)
        
        return ContextualAnalysis(
            sentiment: sentiment,
            entities: entities,
            topics: topics,
            urgency: urgency,
            complexity: complexity,
            temporalContext: temporalContext,
            spatialContext: spatialContext,
            userIntent: userIntent,
            emotionalState: emotionalState,
            domainContext: domainContext,
            historicalRelevance: findHistoricalRelevance(context)
        )
    }
    
    private func analyzeSentiment(_ text: String) -> SentimentAnalysis {
        let positiveIndicators = ["good", "great", "excellent", "happy", "pleased", "satisfied", "wonderful", "amazing"]
        let negativeIndicators = ["bad", "terrible", "awful", "upset", "disappointed", "frustrated", "horrible", "annoying"]
        let urgentIndicators = ["urgent", "immediately", "asap", "emergency", "critical", "now", "quickly"]
        
        let lowercaseText = text.lowercased()
        
        let positiveCount = positiveIndicators.reduce(0) { count, word in
            count + (lowercaseText.contains(word) ? 1 : 0)
        }
        
        let negativeCount = negativeIndicators.reduce(0) { count, word in
            count + (lowercaseText.contains(word) ? 1 : 0)
        }
        
        let urgentCount = urgentIndicators.reduce(0) { count, word in
            count + (lowercaseText.contains(word) ? 1 : 0)
        }
        
        let polarity: String
        if positiveCount > negativeCount {
            polarity = "positive"
        } else if negativeCount > positiveCount {
            polarity = "negative"
        } else {
            polarity = "neutral"
        }
        
        let intensity = max(positiveCount, negativeCount) > 2 ? "high" : "moderate"
        let isUrgent = urgentCount > 0
        
        return SentimentAnalysis(polarity: polarity, intensity: intensity, urgency: isUrgent)
    }
    
    private func extractEntities(_ text: String) -> [ContextualEntity] {
        var entities: [ContextualEntity] = []
        
        nlTagger.string = text
        nlTagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType) { tag, range in
            if let tag = tag {
                let entity = String(text[range])
                let entityType = mapNLTagToEntityType(tag)
                entities.append(ContextualEntity(text: entity, type: entityType, confidence: 0.8))
            }
            return true
        }
        
        return entities
    }
    
    private func extractTopics(_ text: String) -> [Topic] {
        let topicKeywords: [String: [String]] = [
            "technology": ["computer", "software", "app", "digital", "tech", "AI", "algorithm"],
            "business": ["company", "market", "sales", "revenue", "profit", "strategy"],
            "health": ["medical", "doctor", "patient", "treatment", "symptom", "diagnosis"],
            "education": ["school", "student", "teacher", "learning", "education", "course"],
            "finance": ["money", "bank", "investment", "financial", "budget", "cost"],
            "science": ["research", "study", "experiment", "data", "analysis", "scientific"]
        ]
        
        let lowercaseText = text.lowercased()
        var topics: [Topic] = []
        
        for (topicName, keywords) in topicKeywords {
            let relevanceScore = keywords.reduce(0.0) { score, keyword in
                score + (lowercaseText.contains(keyword) ? 1.0 : 0.0)
            } / Double(keywords.count)
            
            if relevanceScore > 0.1 {
                topics.append(Topic(name: topicName, relevance: relevanceScore, keywords: keywords.filter { lowercaseText.contains($0) }))
            }
        }
        
        return topics.sorted { $0.relevance > $1.relevance }
    }
    
    private func assessUrgency(_ text: String) -> UrgencyLevel {
        let urgentKeywords = ["urgent", "emergency", "critical", "asap", "immediately", "now", "quickly", "rush"]
        let lowercaseText = text.lowercased()
        
        let urgencyCount = urgentKeywords.reduce(0) { count, keyword in
            count + (lowercaseText.contains(keyword) ? 1 : 0)
        }
        
        switch urgencyCount {
        case 3...:
            return .critical
        case 2:
            return .high
        case 1:
            return .medium
        default:
            return .low
        }
    }
    
    private func assessComplexity(_ text: String, understanding: FusedUnderstanding) -> ContextualComplexityLevel {
        var complexityScore = 0
        
        // Text-based complexity indicators
        let sentenceCount = text.components(separatedBy: .punctuationCharacters).count
        let wordCount = text.components(separatedBy: .whitespaces).count
        let avgWordsPerSentence = Double(wordCount) / Double(max(1, sentenceCount))
        
        if avgWordsPerSentence > 15 { complexityScore += 1 }
        if wordCount > 100 { complexityScore += 1 }
        
        // Understanding-based complexity
        if understanding.modalityContributions.count > 2 { complexityScore += 1 }
        if understanding.confidence < 0.7 { complexityScore += 1 }
        if understanding.actionableInsights.count > 3 { complexityScore += 1 }
        
        switch complexityScore {
        case 4...:
            return .high
        case 2...3:
            return .medium
        default:
            return .low
        }
    }
    
    private func extractTemporalContext(_ text: String) -> TemporalContext {
        let timeKeywords = [
            "past": ["yesterday", "last", "ago", "previously", "before", "earlier"],
            "present": ["now", "today", "currently", "at the moment", "right now"],
            "future": ["tomorrow", "next", "later", "will", "going to", "plan to"]
        ]
        
        let lowercaseText = text.lowercased()
        var timeframe = "present" // default
        var timeIndicators: [String] = []
        
        for (frame, keywords) in timeKeywords {
            let matches = keywords.filter { lowercaseText.contains($0) }
            if !matches.isEmpty {
                timeframe = frame
                timeIndicators.append(contentsOf: matches)
            }
        }
        
        return TemporalContext(timeframe: timeframe, indicators: timeIndicators)
    }
    
    private func extractSpatialContext(_ text: String) -> SpatialContext {
        let locationKeywords = ["here", "there", "location", "place", "where", "at", "in", "on"]
        let lowercaseText = text.lowercased()
        
        let spatialIndicators = locationKeywords.filter { lowercaseText.contains($0) }
        let hasSpatialContext = !spatialIndicators.isEmpty
        
        return SpatialContext(hasSpatialReference: hasSpatialContext, indicators: spatialIndicators)
    }
    
    private func inferUserIntent(_ context: String, understanding: FusedUnderstanding) -> UserIntent {
        let intentPatterns: [String: [String]] = [
            "question": ["what", "how", "why", "when", "where", "who", "?"],
            "request": ["please", "can you", "could you", "would you", "help me"],
            "command": ["do", "make", "create", "show", "tell", "explain"],
            "information": ["about", "regarding", "concerning", "info", "details"],
            "problem": ["problem", "issue", "error", "bug", "wrong", "not working"]
        ]
        
        let lowercaseContext = context.lowercased()
        var intentScores: [String: Int] = [:]
        
        for (intent, patterns) in intentPatterns {
            intentScores[intent] = patterns.reduce(0) { count, pattern in
                count + (lowercaseContext.contains(pattern) ? 1 : 0)
            }
        }
        
        let primaryIntent = intentScores.max { $0.1 < $1.1 }?.0 ?? "general"
        let confidence = Double(intentScores[primaryIntent] ?? 0) / 5.0 // Normalize
        
        return UserIntent(type: primaryIntent, confidence: min(1.0, confidence), indicators: intentPatterns[primaryIntent] ?? [])
    }
    
    private func analyzeEmotionalState(_ text: String) -> EmotionalState {
        let emotionKeywords: [String: [String]] = [
            "joy": ["happy", "excited", "thrilled", "delighted", "pleased"],
            "anger": ["angry", "furious", "annoyed", "frustrated", "mad"],
            "sadness": ["sad", "disappointed", "upset", "depressed", "down"],
            "fear": ["scared", "worried", "anxious", "nervous", "afraid"],
            "surprise": ["surprised", "amazed", "shocked", "astonished"],
            "calm": ["calm", "peaceful", "relaxed", "serene", "content"]
        ]
        
        let lowercaseText = text.lowercased()
        var emotionScores: [String: Int] = [:]
        
        for (emotion, keywords) in emotionKeywords {
            emotionScores[emotion] = keywords.reduce(0) { count, keyword in
                count + (lowercaseText.contains(keyword) ? 1 : 0)
            }
        }
        
        let primaryEmotion = emotionScores.max { $0.1 < $1.1 }?.0 ?? "neutral"
        let intensity = (emotionScores[primaryEmotion] ?? 0) > 1 ? "high" : "moderate"
        
        return EmotionalState(primaryEmotion: primaryEmotion, intensity: intensity, indicators: emotionKeywords[primaryEmotion] ?? [])
    }
    
    private func identifyDomain(_ text: String) -> String {
        let domainKeywords: [String: [String]] = [
            "technical": ["code", "programming", "software", "bug", "system", "computer"],
            "medical": ["health", "doctor", "medical", "symptom", "treatment", "patient"],
            "business": ["company", "business", "market", "sales", "customer", "strategy"],
            "educational": ["learn", "study", "education", "school", "student", "teacher"],
            "personal": ["family", "friend", "personal", "life", "home", "relationship"]
        ]
        
        let lowercaseText = text.lowercased()
        var domainScores: [String: Int] = [:]
        
        for (domain, keywords) in domainKeywords {
            domainScores[domain] = keywords.reduce(0) { count, keyword in
                count + (lowercaseText.contains(keyword) ? 1 : 0)
            }
        }
        
        return domainScores.max { $0.1 < $1.1 }?.0 ?? "general"
    }
    
    private func findHistoricalRelevance(_ context: String) -> Double {
        // Check context history for similar topics or entities
        let currentTopics = extractTopics(context).map { $0.name }
        let currentEntities = extractEntities(context).map { $0.text.lowercased() }
        
        var relevanceScore = 0.0
        let recentHistory = contextHistory.suffix(10) // Check last 10 interactions
        
        for memory in recentHistory {
            let memoryTopics = memory.topics
            let memoryEntities = memory.entities.map { $0.lowercased() }
            
            let topicOverlap = Set(currentTopics).intersection(Set(memoryTopics)).count
            let entityOverlap = Set(currentEntities).intersection(Set(memoryEntities)).count
            
            relevanceScore += Double(topicOverlap + entityOverlap) * 0.1
        }
        
        return min(1.0, relevanceScore)
    }
    
    // MARK: - Response Generation
    
    private func determineResponseStrategy(analysis: ContextualAnalysis) -> ResponseStrategy {
        var strategy = ResponseStrategy(type: "informative", approach: "direct", tone: "neutral")
        
        // Adjust based on urgency
        switch analysis.urgency {
        case .critical:
            strategy.type = "immediate_action"
            strategy.approach = "urgent"
            strategy.tone = "serious"
        case .high:
            strategy.type = "priority_response"
            strategy.approach = "expedited"
            strategy.tone = "focused"
        case .medium:
            strategy.type = "standard_response"
            strategy.approach = "thorough"
            strategy.tone = "professional"
        case .low:
            strategy.type = "informative"
            strategy.approach = "casual"
            strategy.tone = "friendly"
        }
        
        // Adjust based on emotional state
        switch analysis.emotionalState.primaryEmotion {
        case "anger", "frustration":
            strategy.tone = "empathetic"
            strategy.approach = "calming"
        case "sadness", "disappointment":
            strategy.tone = "supportive"
            strategy.approach = "encouraging"
        case "joy", "excitement":
            strategy.tone = "enthusiastic"
            strategy.approach = "celebratory"
        default:
            break
        }
        
        // Adjust based on complexity
        switch analysis.complexity {
        case .high:
            strategy.approach = "step_by_step"
            strategy.type = "detailed_explanation"
        case .medium:
            strategy.approach = "structured"
        case .low:
            strategy.approach = "concise"
        }
        
        return strategy
    }
    
    private func generateContextualResponse(strategy: ResponseStrategy, understanding: FusedUnderstanding) -> String {
        var response = ""
        
        // Opening based on strategy
        switch strategy.tone {
        case "empathetic":
            response += "I understand this situation is frustrating. "
        case "supportive":
            response += "I'm here to help you through this. "
        case "enthusiastic":
            response += "That's wonderful! "
        case "serious":
            response += "I recognize the urgency of this matter. "
        default:
            response += "Based on the information provided, "
        }
        
        // Main content based on understanding
        response += "I can see that "
        if understanding.confidence > 0.8 {
            response += "there's a clear "
        } else {
            response += "there appears to be a "
        }
        
        response += understanding.primaryIntent.lowercased()
        
        // Add modality-specific insights
        if understanding.modalityContributions.count > 1 {
            response += " supported by multiple sources of information"
        }
        
        // Closing based on strategy
        switch strategy.type {
        case "immediate_action":
            response += ". Let me address this immediately."
        case "detailed_explanation":
            response += ". Let me break this down step by step."
        case "informative":
            response += ". Here's what I can tell you."
        default:
            response += ". How can I best assist you with this?"
        }
        
        return response
    }
    
    private func generateSuggestedActions(understanding: FusedUnderstanding, context: ContextualAnalysis) -> [String] {
        var actions: [String] = []
        
        // Actions based on user intent
        switch context.userIntent.type {
        case "question":
            actions.append("Provide detailed explanation")
            actions.append("Offer related resources")
        case "request":
            actions.append("Fulfill the request")
            actions.append("Confirm completion")
        case "problem":
            actions.append("Diagnose the issue")
            actions.append("Provide solution steps")
            actions.append("Offer preventive measures")
        case "command":
            actions.append("Execute the command")
            actions.append("Provide status update")
        default:
            actions.append("Provide relevant information")
        }
        
        // Actions based on urgency
        switch context.urgency {
        case .critical:
            actions.append("Take immediate action")
            actions.append("Escalate if necessary")
        case .high:
            actions.append("Prioritize response")
        default:
            break
        }
        
        // Actions based on emotional state
        if context.emotionalState.primaryEmotion == "anger" {
            actions.append("Acknowledge frustration")
            actions.append("Offer immediate resolution")
        }
        
        return actions
    }
    
    private func gatherAdditionalContext(understanding: FusedUnderstanding) -> [String: String] {
        var additionalContext: [String: String] = [:]
        
        additionalContext["confidence_level"] = String(format: "%.1f%%", understanding.confidence * 100)
        additionalContext["modality_count"] = String(understanding.modalityContributions.count)
        additionalContext["primary_modality"] = understanding.modalityContributions.max { $0.1 < $1.1 }?.0 ?? "unknown"
        additionalContext["actionable_insights_count"] = String(understanding.actionableInsights.count)
        additionalContext["processing_timestamp"] = understanding.timestamp.ISO8601Format()
        
        return additionalContext
    }
    
    private func calculateResponseConfidence(understanding: FusedUnderstanding, context: ContextualAnalysis) -> Double {
        var confidence = understanding.confidence
        
        // Boost confidence for clear user intent
        if context.userIntent.confidence > 0.8 {
            confidence += 0.1
        }
        
        // Reduce confidence for high complexity
        switch context.complexity {
        case .high:
            confidence -= 0.1
        case .medium:
            confidence -= 0.05
        default:
            break
        }
        
        // Boost confidence for historical relevance
        if context.historicalRelevance > 0.5 {
            confidence += 0.05
        }
        
        return min(1.0, max(0.0, confidence))
    }
    
    // MARK: - Context Enhancement
    
    private func processContextualClues(_ clues: [String], understanding: FusedUnderstanding) -> [String] {
        var enhancements: [String] = []
        
        for clue in clues {
            let clueAnalysis = analyzeContext(clue, understanding: understanding)
            
            if clueAnalysis.urgency == .high || clueAnalysis.urgency == .critical {
                enhancements.append("High urgency context detected")
            }
            
            if !clueAnalysis.entities.isEmpty {
                enhancements.append("Additional entities identified: \(clueAnalysis.entities.map { $0.text }.joined(separator: ", "))")
            }
            
            if clueAnalysis.emotionalState.primaryEmotion != "neutral" {
                enhancements.append("Emotional context: \(clueAnalysis.emotionalState.primaryEmotion)")
            }
            
            if !clueAnalysis.topics.isEmpty {
                enhancements.append("Topic context: \(clueAnalysis.topics.first?.name ?? "unknown")")
            }
        }
        
        return enhancements
    }
    
    private func refineIntent(_ originalIntent: String, with enhancements: [String]) -> String {
        var refinedIntent = originalIntent
        
        // Refine based on enhancements
        if enhancements.contains(where: { $0.contains("High urgency") }) {
            refinedIntent = "urgent_" + refinedIntent
        }
        
        if enhancements.contains(where: { $0.contains("Emotional context") }) {
            refinedIntent = "emotional_" + refinedIntent
        }
        
        return refinedIntent
    }
    
    private func enhanceConfidence(_ originalConfidence: Double, with enhancements: [String]) -> Double {
        var enhancedConfidence = originalConfidence
        
        // Each enhancement slightly boosts confidence
        enhancedConfidence += Double(enhancements.count) * 0.02
        
        // Cap at 1.0
        return min(1.0, enhancedConfidence)
    }
    
    // MARK: - Context Memory Management
    
    private func addToContextHistory(understanding: FusedUnderstanding, response: ContextualResponse, context: String) {
        let memory = ContextualMemory(
            understanding: understanding,
            response: response,
            context: context,
            topics: extractTopics(context).map { $0.name },
            entities: extractEntities(context).map { $0.text },
            timestamp: Date()
        )
        
        contextHistory.append(memory)
        
        // Maintain size limit
        if contextHistory.count > maxContextHistory {
            contextHistory.removeFirst(contextHistory.count - maxContextHistory)
        }
    }
    
    // MARK: - Helper Methods
    
    private func mapNLTagToEntityType(_ tag: NLTag) -> String {
        switch tag {
        case .personalName:
            return "person"
        case .placeName:
            return "location"
        case .organizationName:
            return "organization"
        default:
            return "entity"
        }
    }
}

// MARK: - Supporting Models

struct ContextualAnalysis {
    let sentiment: SentimentAnalysis
    let entities: [ContextualEntity]
    let topics: [Topic]
    let urgency: UrgencyLevel
    let complexity: ContextualComplexityLevel
    let temporalContext: TemporalContext
    let spatialContext: SpatialContext
    let userIntent: UserIntent
    let emotionalState: EmotionalState
    let domainContext: String
    let historicalRelevance: Double
}

struct SentimentAnalysis {
    let polarity: String
    let intensity: String
    let urgency: Bool
}

struct ContextualEntity {
    let text: String
    let type: String
    let confidence: Double
}

struct Topic {
    let name: String
    let relevance: Double
    let keywords: [String]
}

enum UrgencyLevel: String, CaseIterable {
    case low, medium, high, critical
}

enum ContextualComplexityLevel: String, CaseIterable {
    case low, medium, high
}

struct TemporalContext {
    let timeframe: String
    let indicators: [String]
}

struct SpatialContext {
    let hasSpatialReference: Bool
    let indicators: [String]
}

struct UserIntent {
    let type: String
    let confidence: Double
    let indicators: [String]
}

struct EmotionalState {
    let primaryEmotion: String
    let intensity: String
    let indicators: [String]
}

struct ResponseStrategy {
    var type: String
    var approach: String
    var tone: String
}

struct ContextualMemory {
    let understanding: FusedUnderstanding
    let response: ContextualResponse
    let context: String
    let topics: [String]
    let entities: [String]
    let timestamp: Date
}