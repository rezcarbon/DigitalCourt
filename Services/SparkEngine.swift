import Foundation
import Combine
import NaturalLanguage
import SwiftData

@MainActor
class SparkEngine: ObservableObject {
    static let shared = SparkEngine()
    
    @Published private(set) var isActive = false
    @Published private(set) var lastEpiphany: EpiphanyEvent?
    @Published private(set) var sparkFrequency: Double = 0.3 // Moderate spark frequency
    @Published private(set) var totalEpiphanies: Int = 0
    @Published private(set) var epiphanyHistory: [EpiphanyEvent] = []
    
    private let memoryManager = SwiftDataMemoryManager.shared
    private let synapticMemoryManager = SynapticMemoryManager.shared
    private var sparkTimer: Timer?
    private let nlTagger = NLTagger(tagSchemes: [.lexicalClass, .nameType, .lemma])
    private let conceptExtractor = ConceptExtractor()
    private let fusionEngine = ConceptFusionEngine()
    
    private init() {
        loadEpiphanyHistory()
    }
    
    /// Activates the Spark Engine for epiphany generation
    func startSparkEngine() {
        isActive = true
        
        // Dynamic interval based on spark frequency
        let interval = 60.0 / sparkFrequency // More frequent = shorter interval
        
        sparkTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            Task { @MainActor in
                await self.generateSpark()
            }
        }
        
        print(" Spark Engine activated - Epiphany generation online (interval: \(interval)s)")
    }
    
    /// Generates synthetic epiphanies through advanced concept fusion
    func generateSpark() async {
        guard isActive else { return }
        
        // Gather diverse concept sources
        let recentConcepts = await getRecentConcepts(limit: 15)
        let semanticClusters = await getSemanticClusters(count: 5)
        let conversationPatterns = await extractConversationPatterns()
        let crossModalConcepts = await gatherCrossModalConcepts()
        
        // Multi-layered concept fusion
        if let fusedConcept = await fusionEngine.fuseMultiLayeredConcepts(
            concepts: recentConcepts,
            clusters: semanticClusters,
            patterns: conversationPatterns,
            crossModal: crossModalConcepts
        ) {
            let epiphany = EpiphanyEvent(
                concept: fusedConcept.insight,
                conceptType: fusedConcept.type,
                timestamp: Date(),
                importance: fusedConcept.importance,
                sourceMemories: fusedConcept.sourceMemoryIds,
                fusionMethod: fusedConcept.method,
                confidence: fusedConcept.confidence,
                novelty: fusedConcept.novelty
            )
            
            await processNewEpiphany(epiphany)
        }
    }
    
    /// Triggers immediate spark generation for specific context
    func triggerContextualSpark(for text: String) async -> String? {
        let relevantMemories = await getRelevantMemories(for: text, limit: 10)
        let contextualConcepts = conceptExtractor.extractAdvancedConcepts(from: text)
        let semanticNeighbors = await findSemanticNeighbors(for: text)
        
        if let contextualInsight = await fusionEngine.generateContextualInsight(
            text: text,
            concepts: contextualConcepts,
            memories: relevantMemories,
            neighbors: semanticNeighbors
        ) {
            let epiphany = EpiphanyEvent(
                concept: contextualInsight.insight,
                conceptType: .contextual,
                timestamp: Date(),
                importance: contextualInsight.importance,
                sourceMemories: contextualInsight.sourceMemoryIds,
                fusionMethod: contextualInsight.method,
                confidence: contextualInsight.confidence,
                novelty: contextualInsight.novelty
            )
            
            await processNewEpiphany(epiphany)
            
            print("Contextual Spark: \(contextualInsight.insight)")
            return contextualInsight.insight
        }
        
        return nil
    }
    
    // MARK: - Memory Integration Methods
    
    private func getAllAvailableMemories(limit: Int) async -> [DMessage] {
        do {
            let allMessages = try await memoryManager.getAllMessages()
            return Array(allMessages.prefix(limit))
        } catch {
            print("Error retrieving memories for SparkEngine: \(error)")
            return []
        }
    }
    
    private func getRecentConcepts(limit: Int) async -> [MemoryConcept] {
        let recentMessages = await getAllAvailableMemories(limit: limit)
        
        return recentMessages.compactMap { message in
            let concepts = conceptExtractor.extractAdvancedConcepts(from: message.content)
            guard let topConcept = concepts.first else { return nil }
            
            return MemoryConcept(
                id: message.id,
                content: topConcept.text,
                type: topConcept.type,
                importance: topConcept.importance,
                timestamp: message.timestamp
            )
        }
    }
    
    private func getSemanticClusters(count: Int) async -> [SemanticCluster] {
        let memories = await getAllAvailableMemories(limit: 100)
        
        // Create semantic clusters based on actual content analysis
        var clusters: [SemanticCluster] = []
        let keywordToMemories = createKeywordMappings(from: memories)
        
        // Extract top themes based on keyword frequency
        let sortedKeywords = keywordToMemories.sorted { $0.value.count > $1.value.count }
        
        for (keyword, memoryIds) in sortedKeywords.prefix(count) {
            let coherence = calculateClusterCoherence(for: memoryIds, in: memories)
            clusters.append(SemanticCluster(
                theme: keyword,
                memories: memoryIds,
                coherence: coherence
            ))
        }
        
        return clusters
    }
    
    /// Extract conversation patterns from recent interactions
    private func extractConversationPatterns() async -> [ConversationPattern] {
        let recentMessages = await getRecentConversations(limit: 50)
        var patterns: [ConversationPattern] = []
        
        // Analyze question-response patterns
        let questionResponsePairs = identifyQuestionResponsePairs(in: recentMessages)
        for pair in questionResponsePairs {
            patterns.append(ConversationPattern(
                type: .question_response,
                description: "Q: \(pair.question.prefix(50))... A: \(pair.response.prefix(50))...",
                frequency: 1.0,
                contextual_significance: calculateContextualSignificance(pair)
            ))
        }
        
        // Analyze topic transitions
        let topicTransitions = identifyTopicTransitions(in: recentMessages)
        for transition in topicTransitions {
            patterns.append(ConversationPattern(
                type: .topic_transition,
                description: "Topic shift: \(transition.from) → \(transition.to)",
                frequency: transition.frequency,
                contextual_significance: transition.significance
            ))
        }
        
        return patterns
    }
    
    /// Gather cross-modal concepts from different input types
    private func gatherCrossModalConcepts() async -> [CrossModalConcept] {
        var concepts: [CrossModalConcept] = []
        
        // Image-text correlations
        let imageTextPairs = await getImageTextCorrelations(limit: 10)
        for pair in imageTextPairs {
            concepts.append(CrossModalConcept(
                primaryModality: .vision,
                secondaryModality: .text,
                correlation: pair.correlation,
                description: pair.description,
                strength: pair.strength
            ))
        }
        
        // Document-conversation correlations
        let documentConversations = await getDocumentConversationCorrelations(limit: 10)
        for correlation in documentConversations {
            concepts.append(CrossModalConcept(
                primaryModality: .document,
                secondaryModality: .text,
                correlation: correlation.similarity,
                description: correlation.summary,
                strength: correlation.relevance
            ))
        }
        
        return concepts
    }
    
    private func getRecentConversations(limit: Int) async -> [DMessage] {
        return await getAllAvailableMemories(limit: limit)
    }
    
    private func getImageTextCorrelations(limit: Int) async -> [ImageTextCorrelation] {
        // Analyze messages that might contain image references or visual descriptions
        let messages = await getAllAvailableMemories(limit: 200)
        var correlations: [ImageTextCorrelation] = []
        
        let visualKeywords = ["image", "picture", "visual", "see", "look", "show", "display", "screenshot", "photo", "diagram", "chart", "graph"]
        
        for message in messages {
            let messageText = message.content.lowercased()
            let hasVisualContent = visualKeywords.contains { messageText.contains($0) }
            
            if hasVisualContent {
                let concepts = conceptExtractor.extractAdvancedConcepts(from: message.content)
                let topConcepts = concepts.prefix(2).map { $0.text }.joined(separator: " and ")
                
                correlations.append(ImageTextCorrelation(
                    correlation: "Visual reference to \(topConcepts)",
                    description: "Message contains visual elements correlated with textual concepts: \(topConcepts)",
                    strength: Double.random(in: 0.6...0.9)
                ))
                
                if correlations.count >= limit { break }
            }
        }
        
        return correlations
    }
    
    private func getDocumentConversationCorrelations(limit: Int) async -> [DocumentConversationCorrelation] {
        let messages = await getAllAvailableMemories(limit: 100)
        var correlations: [DocumentConversationCorrelation] = []
        
        // Group messages by similarity to find document-like patterns
        let documentPatterns = findDocumentPatterns(in: messages)
        
        for pattern in documentPatterns.prefix(limit) {
            correlations.append(DocumentConversationCorrelation(
                similarity: pattern.theme,
                summary: "Document-like content pattern found in conversations: \(pattern.description)",
                relevance: pattern.relevance
            ))
        }
        
        return correlations
    }
    
    private func getRelevantMemories(for text: String, limit: Int) async -> [DMessage] {
        do {
            // Use the search functionality from SwiftDataMemoryManager
            let searchResults = try await memoryManager.searchMemories(with: text)
            return Array(searchResults.prefix(limit))
        } catch {
            print("Error searching memories: \(error)")
            
            // Fallback: keyword-based search
            let allMemories = await getAllAvailableMemories(limit: 200)
            let keywords = extractKeywords(from: text)
            
            let relevantMemories = allMemories.filter { memory in
                keywords.contains { keyword in
                    memory.content.lowercased().contains(keyword.lowercased())
                }
            }
            
            return Array(relevantMemories.prefix(limit))
        }
    }
    
    private func findMemoriesContaining(keyword: String, limit: Int) async -> [DMessage] {
        return await getRelevantMemories(for: keyword, limit: limit)
    }
    
    private func storeEpiphany(_ epiphany: EpiphanyEvent) async {
        // Store epiphany as a special message in the system
        let epiphanyContent = " EPIPHANY (\(epiphany.conceptType.rawValue)): \(epiphany.concept)"
        
        do {
            // Create a synaptic node for this epiphany
            let synapticNode = try await synapticMemoryManager.createAndConnectNode(
                content: epiphanyContent,
                corticalLayer: 6 // Highest cortical layer for epiphanies
            )
            
            // Store in UserDefaults as backup
            let epiphanyData: [String: Any] = [
                "id": epiphany.id.uuidString,
                "content": epiphanyContent,
                "timestamp": epiphany.timestamp.timeIntervalSince1970,
                "importance": epiphany.importance,
                "confidence": epiphany.confidence,
                "novelty": epiphany.novelty,
                "synapticNodeId": synapticNode.id.uuidString
            ]
            
            var storedEpiphanies = UserDefaults.standard.array(forKey: "storedEpiphanies") as? [[String: Any]] ?? []
            storedEpiphanies.append(epiphanyData)
            
            // Keep only recent epiphanies
            if storedEpiphanies.count > 100 {
                storedEpiphanies = Array(storedEpiphanies.suffix(100))
            }
            
            UserDefaults.standard.set(storedEpiphanies, forKey: "storedEpiphanies")
            
            print("Epiphany stored successfully with synaptic connection")
        } catch {
            print("Error storing epiphany: \(error)")
            
            // Fallback storage in UserDefaults only
            let epiphanyData: [String: Any] = [
                "id": epiphany.id.uuidString,
                "content": epiphanyContent,
                "timestamp": epiphany.timestamp.timeIntervalSince1970,
                "importance": epiphany.importance,
                "confidence": epiphany.confidence,
                "novelty": epiphany.novelty
            ]
            
            var storedEpiphanies = UserDefaults.standard.array(forKey: "storedEpiphanies") as? [[String: Any]] ?? []
            storedEpiphanies.append(epiphanyData)
            UserDefaults.standard.set(storedEpiphanies, forKey: "storedEpiphanies")
        }
    }
    
    /// Process and store a new epiphany
    private func processNewEpiphany(_ epiphany: EpiphanyEvent) async {
        lastEpiphany = epiphany
        totalEpiphanies += 1
        epiphanyHistory.append(epiphany)
        
        // Keep only recent epiphanies in memory
        if epiphanyHistory.count > 100 {
            epiphanyHistory.removeFirst(epiphanyHistory.count - 100)
        }
        
        // Store epiphany as high-importance memory
        await storeEpiphany(epiphany)
        
        // Trigger follow-up processing for significant epiphanies
        if epiphany.importance > 0.8 {
            await triggerEpiphanyChain(from: epiphany)
        }
        
        // Save to persistent storage
        await saveEpiphanyHistory()
        
        print("Synthetic Epiphany Generated: \(epiphany.concept) (importance: \(epiphany.importance), novelty: \(epiphany.novelty))")
    }
    
    /// Trigger a chain of related epiphanies
    private func triggerEpiphanyChain(from epiphany: EpiphanyEvent) async {
        let chainConcepts = await fusionEngine.generateEpiphanyChain(
            seed: epiphany,
            depth: 3,
            branching: 2
        )
        
        for concept in chainConcepts {
            let chainEpiphany = EpiphanyEvent(
                concept: concept.insight,
                conceptType: .chain_reaction,
                timestamp: Date(),
                importance: concept.importance,
                sourceMemories: [epiphany.id],
                fusionMethod: .chain_synthesis,
                confidence: concept.confidence,
                novelty: concept.novelty
            )
            
            await processNewEpiphany(chainEpiphany)
        }
    }
    
    /// Advanced importance calculation
    private func calculateAdvancedImportance(_ fusedConcept: FusedConcept) -> Double {
        var importance = 0.0
        
        // Base importance from concept complexity
        let wordCount = fusedConcept.insight.split(separator: " ").count
        importance += min(Double(wordCount) / 30.0, 0.3)
        
        // Importance from source memory count
        importance += min(Double(fusedConcept.sourceMemoryIds.count) / 20.0, 0.2)
        
        // Importance from fusion method sophistication
        importance += fusedConcept.method.sophisticationScore
        
        // Importance from novelty
        importance += fusedConcept.novelty * 0.3
        
        // Importance from confidence
        importance += fusedConcept.confidence * 0.2
        
        return min(importance, 1.0)
    }
    
    /// Calculate novelty score for concepts
    private func calculateNovelty(_ concept: String) -> Double {
        let conceptWords = Set(concept.lowercased().split(separator: " ").map(String.init))
        
        // Compare against recent epiphanies
        let recentConcepts = epiphanyHistory.suffix(20).map { $0.concept }
        var maxSimilarity = 0.0
        
        for recentConcept in recentConcepts {
            let recentWords = Set(recentConcept.lowercased().split(separator: " ").map(String.init))
            let intersection = conceptWords.intersection(recentWords)
            let union = conceptWords.union(recentWords)
            let similarity = union.isEmpty ? 0.0 : Double(intersection.count) / Double(union.count)
            maxSimilarity = max(maxSimilarity, similarity)
        }
        
        return 1.0 - maxSimilarity // Higher novelty = less similarity
    }
    
    /// Find semantic neighbors for a given text
    private func findSemanticNeighbors(for text: String) async -> [SemanticNeighbor] {
        // This would use embeddings in a real implementation
        let keywords = extractKeywords(from: text)
        var neighbors: [SemanticNeighbor] = []
        
        for keyword in keywords {
            let relatedMemories = await findMemoriesContaining(keyword: keyword, limit: 5)
            for memory in relatedMemories {
                neighbors.append(SemanticNeighbor(
                    text: memory.content,
                    similarity: calculateTextSimilarity(text, memory.content),
                    sourceMemoryId: memory.id
                ))
            }
        }
        
        return neighbors.sorted { $0.similarity > $1.similarity }
    }
    
    // MARK: - Helper Methods
    
    private func createKeywordMappings(from messages: [DMessage]) -> [String: [UUID]] {
        var keywordToMemories: [String: [UUID]] = [:]
        
        for message in messages {
            let keywords = extractKeywords(from: message.content)
            for keyword in keywords {
                if keywordToMemories[keyword] == nil {
                    keywordToMemories[keyword] = []
                }
                keywordToMemories[keyword]?.append(message.id)
            }
        }
        
        return keywordToMemories
    }
    
    private func calculateClusterCoherence(for memoryIds: [UUID], in messages: [DMessage]) -> Double {
        guard memoryIds.count > 1 else { return 0.0 }
        
        let clusterMessages = messages.filter { memoryIds.contains($0.id) }
        guard clusterMessages.count > 1 else { return 0.0 }
        
        var totalSimilarity = 0.0
        var comparisons = 0
        
        for i in 0..<clusterMessages.count {
            for j in (i+1)..<clusterMessages.count {
                totalSimilarity += calculateTextSimilarity(
                    clusterMessages[i].content,
                    clusterMessages[j].content
                )
                comparisons += 1
            }
        }
        
        return comparisons > 0 ? totalSimilarity / Double(comparisons) : 0.0
    }
    
    private func findDocumentPatterns(in messages: [DMessage]) -> [DocumentPattern] {
        var patterns: [DocumentPattern] = []
        
        // Look for structured content patterns
        let structuredMessages = messages.filter { message in
            let content = message.content
            let hasStructure = content.contains("1.") || content.contains("•") || 
                             content.contains("-") || content.contains("##") ||
                             content.count > 500 // Longer messages might be document-like
            return hasStructure
        }
        
        // Group by content similarity
        var patternGroups: [String: [DMessage]] = [:]
        
        for message in structuredMessages {
            let primaryTopic = extractPrimaryTopic(from: message.content)
            if patternGroups[primaryTopic] == nil {
                patternGroups[primaryTopic] = []
            }
            patternGroups[primaryTopic]?.append(message)
        }
        
        for (topic, groupMessages) in patternGroups {
            if groupMessages.count >= 2 { // At least 2 messages to form a pattern
                let avgLength = groupMessages.map { $0.content.count }.reduce(0, +) / groupMessages.count
                let relevance = min(1.0, Double(avgLength) / 1000.0)
                
                patterns.append(DocumentPattern(
                    theme: topic,
                    description: "Structured content pattern with \(groupMessages.count) related messages",
                    relevance: relevance
                ))
            }
        }
        
        return patterns.sorted { $0.relevance > $1.relevance }
    }
    
    private func identifyQuestionResponsePairs(in messages: [DMessage]) -> [QuestionResponsePair] {
        var pairs: [QuestionResponsePair] = []
        
        for i in 0..<messages.count - 1 {
            let current = messages[i]
            let next = messages[i + 1]
            
            if current.isUser && current.content.contains("?") && !next.isUser {
                pairs.append(QuestionResponsePair(
                    question: current.content,
                    response: next.content,
                    timestamp: current.timestamp
                ))
            }
        }
        
        return pairs
    }
    
    private func identifyTopicTransitions(in messages: [DMessage]) -> [TopicTransition] {
        // Simplified topic transition detection
        var transitions: [TopicTransition] = []
        
        if messages.count >= 2 {
            let topics = messages.map { extractPrimaryTopic(from: $0.content) }
            
            for i in 0..<topics.count - 1 {
                if topics[i] != topics[i + 1] {
                    transitions.append(TopicTransition(
                        from: topics[i],
                        to: topics[i + 1],
                        frequency: 1.0,
                        significance: 0.7
                    ))
                }
            }
        }
        
        return transitions
    }
    
    private func extractPrimaryTopic(from text: String) -> String {
        let keywords = extractKeywords(from: text)
        return keywords.first ?? "general"
    }
    
    private func calculateContextualSignificance(_ pair: QuestionResponsePair) -> Double {
        let questionComplexity = Double(pair.question.split(separator: " ").count) / 20.0
        let responseComplexity = Double(pair.response.split(separator: " ").count) / 50.0
        return min(questionComplexity + responseComplexity, 1.0)
    }
    
    private func extractKeywords(from text: String) -> [String] {
        let words = text.lowercased().split(separator: " ").map(String.init)
        let stopWords = Set(["the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with", "by", "is", "are", "was", "were", "be", "been", "have", "has", "had", "do", "does", "did", "will", "would", "could", "should"])
        
        return words.filter { word in
            word.count > 3 && !stopWords.contains(word)
        }.prefix(5).map { $0 }
    }
    
    private func calculateTextSimilarity(_ text1: String, _ text2: String) -> Double {
        let words1 = Set(text1.lowercased().split(separator: " ").map(String.init))
        let words2 = Set(text2.lowercased().split(separator: " ").map(String.init))
        
        let intersection = words1.intersection(words2)
        let union = words1.union(words2)
        
        return union.isEmpty ? 0.0 : Double(intersection.count) / Double(union.count)
    }
    
    // MARK: - Persistence
    
    private func loadEpiphanyHistory() {
        // Load from UserDefaults or other persistent storage
        if let data = UserDefaults.standard.data(forKey: "epiphanyHistory"),
           let history = try? JSONDecoder().decode([EpiphanyEvent].self, from: data) {
            epiphanyHistory = history
            totalEpiphanies = history.count
        }
    }
    
    private func saveEpiphanyHistory() async {
        if let data = try? JSONEncoder().encode(epiphanyHistory) {
            UserDefaults.standard.set(data, forKey: "epiphanyHistory")
        }
    }
    
    // MARK: - Public Interface
    
    /// Adjusts spark frequency based on system load
    func adjustSparkFrequency(_ newFrequency: Double) {
        sparkFrequency = max(0.1, min(newFrequency, 1.0)) // Clamp between 0.1 and 1.0
        
        // Restart timer with new frequency
        if isActive {
            stopSparkEngine()
            startSparkEngine()
        }
        
        print("Spark frequency adjusted to: \(sparkFrequency)")
    }
    
    func getEpiphanyAnalytics() -> EpiphanyAnalytics {
        let recentEpiphanies = epiphanyHistory.suffix(20)
        guard !recentEpiphanies.isEmpty else {
            return EpiphanyAnalytics(
                totalEpiphanies: totalEpiphanies,
                averageImportance: 0.0,
                averageNovelty: 0.0,
                sparkFrequency: sparkFrequency,
                lastEpiphanyDate: lastEpiphany?.timestamp
            )
        }
        
        let averageImportance = recentEpiphanies.map { $0.importance }.reduce(0, +) / Double(recentEpiphanies.count)
        let averageNovelty = recentEpiphanies.map { $0.novelty }.reduce(0, +) / Double(recentEpiphanies.count)
        
        return EpiphanyAnalytics(
            totalEpiphanies: totalEpiphanies,
            averageImportance: averageImportance,
            averageNovelty: averageNovelty,
            sparkFrequency: sparkFrequency,
            lastEpiphanyDate: lastEpiphany?.timestamp
        )
    }
    
    func stopSparkEngine() {
        isActive = false
        sparkTimer?.invalidate()
        sparkTimer = nil
        print("Spark Engine deactivated")
    }
}

class ConceptFusionEngine {
    func fuseMultiLayeredConcepts(
        concepts: [MemoryConcept],
        clusters: [SemanticCluster],
        patterns: [ConversationPattern],
        crossModal: [CrossModalConcept]
    ) async -> FusedConcept? {
        guard !concepts.isEmpty else { return nil }
        
        let primaryConcepts = concepts.prefix(5)
        let conceptTexts = primaryConcepts.map { $0.content }
        
        // Analyze the relationships between concepts
        let relationships = analyzeConceptRelationships(conceptTexts)
        
        // Generate insight based on multi-layered analysis
        let insight = generateMultiLayeredInsight(
            concepts: conceptTexts,
            relationships: relationships,
            clusters: clusters,
            patterns: patterns,
            crossModal: crossModal
        )
        
        let confidence = calculateFusionConfidence(concepts, clusters, patterns, crossModal)
        let novelty = calculateConceptNovelty(insight, against: conceptTexts)
        let importance = calculateImportanceFromFusion(confidence: confidence, novelty: novelty, conceptCount: concepts.count)
        
        return FusedConcept(
            insight: insight,
            type: determineConceptType(from: conceptTexts),
            method: .multi_layered_fusion,
            confidence: confidence,
            novelty: novelty,
            importance: importance,
            sourceMemoryIds: concepts.map { $0.id }
        )
    }
    
    func generateContextualInsight(
        text: String,
        concepts: [ExtractedConcept],
        memories: [DMessage],
        neighbors: [SemanticNeighbor]
    ) async -> FusedConcept? {
        guard !concepts.isEmpty || !memories.isEmpty else { return nil }
        
        let topConcepts = concepts.prefix(3).map { $0.text }
        let memoryContexts = extractMemoryContexts(from: memories)
        
        let insight = synthesizeContextualInsight(
            inputText: text,
            extractedConcepts: topConcepts,
            memoryContexts: memoryContexts,
            semanticNeighbors: neighbors
        )
        
        let confidence = min(Double(memories.count) / 10.0 + Double(concepts.count) / 5.0, 1.0)
        let novelty = calculateContextualNovelty(insight, in: memories)
        let importance = calculateImportanceFromContext(confidence: confidence, novelty: novelty, memoryCount: memories.count)
        
        return FusedConcept(
            insight: insight,
            type: .contextual,
            method: .contextual_synthesis,
            confidence: confidence,
            novelty: novelty,
            importance: importance,
            sourceMemoryIds: memories.map { $0.id }
        )
    }
    
    func generateEpiphanyChain(seed: EpiphanyEvent, depth: Int, branching: Int) async -> [FusedConcept] {
        var chainConcepts: [FusedConcept] = []
        var currentConcept = seed.concept
        
        for i in 0..<depth {
            let branchConcepts = generateBranchingInsights(
                from: currentConcept,
                level: i,
                branches: branching,
                originalSeed: seed
            )
            
            chainConcepts.append(contentsOf: branchConcepts)
            
            // Use the most promising concept for the next level
            if let bestConcept = branchConcepts.max(by: { $0.importance < $1.importance }) {
                currentConcept = bestConcept.insight
            }
        }
        
        return chainConcepts
    }
    
    // MARK: - Helper Methods for Proper Implementation
    
    private func analyzeConceptRelationships(_ concepts: [String]) -> [ConceptRelationship] {
        var relationships: [ConceptRelationship] = []
        
        for i in 0..<concepts.count {
            for j in (i+1)..<concepts.count {
                let similarity = calculateConceptSimilarity(concepts[i], concepts[j])
                if similarity > 0.3 {
                    relationships.append(ConceptRelationship(
                        concept1: concepts[i],
                        concept2: concepts[j],
                        relationshipType: determineRelationshipType(similarity),
                        strength: similarity
                    ))
                }
            }
        }
        
        return relationships
    }
    
    private func generateMultiLayeredInsight(
        concepts: [String],
        relationships: [ConceptRelationship],
        clusters: [SemanticCluster],
        patterns: [ConversationPattern],
        crossModal: [CrossModalConcept]
    ) -> String {
        let conceptSummary = concepts.prefix(3).joined(separator: ", ")
        let relationshipTypes = relationships.map { $0.relationshipType }.joined(separator: " and ")
        let clusterThemes = clusters.map { $0.theme }.joined(separator: ", ")
        
        if relationships.isEmpty {
            return "Synthetic analysis reveals convergent patterns in \(conceptSummary) through \(clusters.count) semantic clusters and \(patterns.count) conversational patterns, suggesting emergent understanding across \(crossModal.count) modalities"
        } else {
            return "Multi-layered synthesis identifies \(relationshipTypes) relationships between \(conceptSummary), creating emergent insights through thematic resonance in \(clusterThemes) and cross-modal integration of \(crossModal.count) experiential dimensions"
        }
    }
    
    private func extractMemoryContexts(from memories: [DMessage]) -> [String] {
        return memories.map { message in
            let concepts = extractMainConcepts(from: message.content)
            return concepts.isEmpty ? message.content.prefix(100).description : concepts.joined(separator: " → ")
        }
    }
    
    private func synthesizeContextualInsight(
        inputText: String,
        extractedConcepts: [String],
        memoryContexts: [String],
        semanticNeighbors: [SemanticNeighbor]
    ) -> String {
        let inputSummary = inputText.prefix(50).description
        let conceptChain = extractedConcepts.joined(separator: " → ")
        let contextPattern = findCommonPattern(in: memoryContexts)
        let neighborCount = semanticNeighbors.count
        
        return "Contextual synthesis of '\(inputSummary)' reveals conceptual pathway: \(conceptChain), resonating with memory patterns '\(contextPattern)' across \(neighborCount) semantic associations, suggesting \(generateContextualConclusion(from: extractedConcepts))"
    }
    
    private func generateBranchingInsights(
        from concept: String,
        level: Int,
        branches: Int,
        originalSeed: EpiphanyEvent
    ) -> [FusedConcept] {
        var insights: [FusedConcept] = []
        
        let branchingStrategies = [
            "recursive deepening",
            "lateral exploration",
            "emergent synthesis",
            "pattern extrapolation",
            "meta-cognitive analysis"
        ]
        
        for branch in 0..<branches {
            let strategy = branchingStrategies[branch % branchingStrategies.count]
            let insight = "Chain extension \(level+1).\(branch+1): Through \(strategy) of '\(concept.prefix(30))', we discover \(generateChainExtension(level: level, branch: branch, strategy: strategy))"
            
            let confidence = max(0.2, originalSeed.confidence - Double(level) * 0.15)
            let novelty = max(0.3, originalSeed.novelty - Double(level) * 0.1)
            let importance = max(0.15, originalSeed.importance - Double(level) * 0.12)
            
            insights.append(FusedConcept(
                insight: insight,
                type: .chain_reaction,
                method: .chain_synthesis,
                confidence: confidence,
                novelty: novelty,
                importance: importance,
                sourceMemoryIds: [originalSeed.id]
            ))
        }
        
        return insights
    }
    
    private func calculateConceptSimilarity(_ concept1: String, _ concept2: String) -> Double {
        let words1 = Set(concept1.lowercased().components(separatedBy: .whitespacesAndNewlines))
        let words2 = Set(concept2.lowercased().components(separatedBy: .whitespacesAndNewlines))
        
        let intersection = words1.intersection(words2)
        let union = words1.union(words2)
        
        return union.isEmpty ? 0.0 : Double(intersection.count) / Double(union.count)
    }
    
    private func determineRelationshipType(_ similarity: Double) -> String {
        switch similarity {
        case 0.7...1.0: return "semantic convergence"
        case 0.5..<0.7: return "conceptual resonance"
        case 0.3..<0.5: return "thematic correlation"
        default: return "weak association"
        }
    }
    
    private func determineConceptType(from concepts: [String]) -> ConceptType {
        let allText = concepts.joined(separator: " ").lowercased()
        
        if allText.contains("person") || allText.contains("individual") {
            return .person
        } else if allText.contains("place") || allText.contains("location") {
            return .location
        } else if allText.contains("organization") || allText.contains("company") {
            return .organization
        } else {
            return .abstract_concept
        }
    }
    
    private func calculateConceptNovelty(_ concept: String, against existing: [String]) -> Double {
        let conceptWords = Set(concept.lowercased().components(separatedBy: .whitespacesAndNewlines))
        var maxSimilarity = 0.0
        
        for existingConcept in existing {
            let existingWords = Set(existingConcept.lowercased().components(separatedBy: .whitespacesAndNewlines))
            let similarity = Double(conceptWords.intersection(existingWords).count) / Double(conceptWords.union(existingWords).count)
            maxSimilarity = max(maxSimilarity, similarity)
        }
        
        return 1.0 - maxSimilarity
    }
    
    private func calculateContextualNovelty(_ insight: String, in memories: [DMessage]) -> Double {
        let insightWords = Set(insight.lowercased().components(separatedBy: .whitespacesAndNewlines))
        var maxSimilarity = 0.0
        
        for memory in memories.prefix(20) {
            let memoryWords = Set(memory.content.lowercased().components(separatedBy: .whitespacesAndNewlines))
            let similarity = Double(insightWords.intersection(memoryWords).count) / Double(insightWords.union(memoryWords).count)
            maxSimilarity = max(maxSimilarity, similarity)
        }
        
        return 1.0 - maxSimilarity
    }
    
    private func extractMainConcepts(from text: String) -> [String] {
        return text.components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.count > 4 }
            .prefix(3)
            .map { String($0) }
    }
    
    private func findCommonPattern(in contexts: [String]) -> String {
        guard !contexts.isEmpty else { return "general pattern" }
        
        let wordFrequency = contexts.flatMap { $0.components(separatedBy: .whitespacesAndNewlines) }
            .reduce(into: [String: Int]()) { counts, word in
                counts[word.lowercased(), default: 0] += 1
            }
        
        let mostCommon = wordFrequency.max { $0.value < $1.value }
        return mostCommon?.key ?? "contextual pattern"
    }
    
    private func generateContextualConclusion(from concepts: [String]) -> String {
        let conclusions = [
            "novel approaches to understanding",
            "deeper systemic connections",
            "emergent problem-solving strategies",
            "innovative conceptual frameworks",
            "enhanced cognitive pathways"
        ]
        
        return conclusions.randomElement() ?? "new perspectives"
    }
    
    private func generateChainExtension(level: Int, branch: Int, strategy: String) -> String {
        let extensions = [
            "fractal patterns emerging at deeper cognitive levels",
            "recursive loops revealing hidden system dynamics",
            "meta-patterns connecting previously isolated concepts",
            "emergent properties manifesting through iterative analysis",
            "higher-order relationships becoming apparent"
        ]
        
        return extensions.randomElement() ?? "deeper implications through continued exploration"
    }
    
    private func calculateFusionConfidence(
        _ concepts: [MemoryConcept],
        _ clusters: [SemanticCluster],
        _ patterns: [ConversationPattern],
        _ crossModal: [CrossModalConcept]
    ) -> Double {
        let conceptWeight = min(Double(concepts.count) / 10.0, 0.4)
        let clusterWeight = min(Double(clusters.count) / 5.0, 0.3)
        let patternWeight = min(Double(patterns.count) / 3.0, 0.2)
        let crossModalWeight = min(Double(crossModal.count) / 2.0, 0.1)
        
        return conceptWeight + clusterWeight + patternWeight + crossModalWeight
    }
    
    private func calculateImportanceFromFusion(confidence: Double, novelty: Double, conceptCount: Int) -> Double {
        let baseImportance = confidence * 0.4 + novelty * 0.4
        let complexityBonus = min(Double(conceptCount) / 20.0, 0.2)
        return min(baseImportance + complexityBonus, 1.0)
    }
    
    private func calculateImportanceFromContext(confidence: Double, novelty: Double, memoryCount: Int) -> Double {
        let baseImportance = confidence * 0.5 + novelty * 0.3
        let memoryBonus = min(Double(memoryCount) / 15.0, 0.2)
        return min(baseImportance + memoryBonus, 1.0)
    }
}

// MARK: - Concept Extractor

class ConceptExtractor {
    private let nlTagger = NLTagger(tagSchemes: [.lexicalClass, .nameType, .lemma, .language])
    
    func extractAdvancedConcepts(from text: String) -> [ExtractedConcept] {
        var concepts: [ExtractedConcept] = []
        
        nlTagger.string = text
        
        // Extract named entities with proper analysis
        concepts.append(contentsOf: extractNamedEntities(from: text))
        
        // Extract semantic concepts
        concepts.append(contentsOf: extractSemanticConcepts(from: text))
        
        // Extract compound concepts
        concepts.append(contentsOf: extractCompoundConcepts(from: text))
        
        return concepts.sorted { $0.importance > $1.importance }
    }
    
    private func extractNamedEntities(from text: String) -> [ExtractedConcept] {
        var entities: [ExtractedConcept] = []
        
        nlTagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType) { tag, range in
            if let tag = tag {
                let entity = String(text[range])
                let importance = calculateEntityImportance(entity, tag: tag, context: text)
                
                entities.append(ExtractedConcept(
                    text: entity,
                    type: mapNLTagToConceptType(tag),
                    importance: importance,
                    range: range
                ))
            }
            return true
        }
        
        return entities
    }
    
    private func extractSemanticConcepts(from text: String) -> [ExtractedConcept] {
        var concepts: [ExtractedConcept] = []
        
        nlTagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass) { tag, range in
            if let tag = tag, shouldExtractConcept(for: tag) {
                let word = String(text[range])
                if isSemanticallySignificant(word) {
                    concepts.append(ExtractedConcept(
                        text: word,
                        type: .abstract_concept,
                        importance: calculateSemanticImportance(word, in: text),
                        range: range
                    ))
                }
            }
            return true
        }
        
        return concepts
    }
    
    private func extractCompoundConcepts(from text: String) -> [ExtractedConcept] {
        var compounds: [ExtractedConcept] = []
        let sentences = text.components(separatedBy: .newlines)
        
        for sentence in sentences {
            let words = sentence.components(separatedBy: .whitespacesAndNewlines)
            
            // Look for meaningful multi-word phrases
            for i in 0..<(words.count - 1) {
                let phrase = "\(words[i]) \(words[i+1])"
                if isSignificantPhrase(phrase) {
                    let startIndex = sentence.range(of: phrase)?.lowerBound ?? sentence.startIndex
                    let endIndex = sentence.range(of: phrase)?.upperBound ?? sentence.endIndex
                    
                    compounds.append(ExtractedConcept(
                        text: phrase,
                        type: .abstract_concept,
                        importance: calculatePhraseImportance(phrase, in: text),
                        range: startIndex..<endIndex
                    ))
                }
            }
        }
        
        return compounds
    }
    
    private func calculateEntityImportance(_ entity: String, tag: NLTag, context: String) -> Double {
        var importance = 0.3
        
        // Boost for certain entity types
        switch tag {
        case .personalName: importance += 0.4
        case .organizationName: importance += 0.3
        case .placeName: importance += 0.2
        default: importance += 0.1
        }
        
        // Boost for frequency in context
        let occurrences = context.lowercased().components(separatedBy: entity.lowercased()).count - 1
        importance += min(Double(occurrences) * 0.1, 0.3)
        
        return min(importance, 1.0)
    }
    
    private func calculateSemanticImportance(_ word: String, in text: String) -> Double {
        let baseImportance = 0.4
        let frequency = text.lowercased().components(separatedBy: word.lowercased()).count - 1
        let lengthBonus = min(Double(word.count) / 15.0, 0.3)
        
        return min(baseImportance + Double(frequency) * 0.05 + lengthBonus, 1.0)
    }
    
    private func calculatePhraseImportance(_ phrase: String, in text: String) -> Double {
        let baseImportance = 0.5
        let uniqueness = phrase.components(separatedBy: .whitespacesAndNewlines).count > 1 ? 0.2 : 0.0
        let contextRelevance = text.lowercased().contains(phrase.lowercased()) ? 0.2 : 0.0
        
        return min(baseImportance + uniqueness + contextRelevance, 1.0)
    }
    
    private func shouldExtractConcept(for tag: NLTag) -> Bool {
        return [.noun, .verb, .adjective].contains(tag)
    }
    
    private func isSemanticallySignificant(_ word: String) -> Bool {
        let significantWords = ["analyze", "understand", "create", "develop", "system", "process", "strategy", "solution", "insight", "pattern", "relationship", "framework", "approach", "method", "technique", "innovation", "concept", "theory", "principle", "model"]
        return significantWords.contains(word.lowercased()) && word.count > 3
    }
    
    private func isSignificantPhrase(_ phrase: String) -> Bool {
        let words = phrase.components(separatedBy: .whitespacesAndNewlines)
        guard words.count == 2 else { return false }
        
        let significantPhrases = ["machine learning", "artificial intelligence", "data analysis", "problem solving", "decision making", "natural language", "deep learning", "neural network", "cognitive process", "system design"]
        return significantPhrases.contains(phrase.lowercased())
    }
    
    private func mapNLTagToConceptType(_ tag: NLTag) -> ConceptType {
        switch tag {
        case .personalName: return .person
        case .placeName: return .location
        case .organizationName: return .organization
        default: return .entity
        }
    }
}

// MARK: - Supporting Types

struct EpiphanyEvent: Codable, Identifiable {
    var id = UUID()
    let concept: String
    let conceptType: ConceptType
    let timestamp: Date
    let importance: Double
    let sourceMemories: [UUID]
    let fusionMethod: FusionMethod
    let confidence: Double
    let novelty: Double
}

enum ConceptType: String, Codable, CaseIterable {
    case abstract_concept, person, location, organization, entity, contextual, chain_reaction, cross_modal
}

enum FusionMethod: String, Codable, CaseIterable {
    case semantic_clustering, pattern_recognition, cross_modal_synthesis, contextual_synthesis, chain_synthesis, multi_layered_fusion
    
    var sophisticationScore: Double {
        switch self {
        case .semantic_clustering: return 0.3
        case .pattern_recognition: return 0.4
        case .cross_modal_synthesis: return 0.6
        case .contextual_synthesis: return 0.5
        case .chain_synthesis: return 0.7
        case .multi_layered_fusion: return 0.8
        }
    }
}

struct ExtractedConcept {
    let text: String
    let type: ConceptType
    let importance: Double
    let range: Range<String.Index>
}

struct ConversationPattern {
    let type: PatternType
    let description: String
    let frequency: Double
    let contextual_significance: Double
    
    enum PatternType: String, CaseIterable {
        case question_response, topic_transition, repetition, escalation
    }
}

struct CrossModalConcept {
    let primaryModality: ModalityType
    let secondaryModality: ModalityType
    let correlation: String
    let description: String
    let strength: Double
}

struct QuestionResponsePair {
    let question: String
    let response: String
    let timestamp: Date
}

struct TopicTransition {
    let from: String
    let to: String
    let frequency: Double
    let significance: Double
}

struct SemanticNeighbor {
    let text: String
    let similarity: Double
    let sourceMemoryId: UUID
}

struct FusedConcept {
    let insight: String
    let type: ConceptType
    let method: FusionMethod
    let confidence: Double
    let novelty: Double
    let importance: Double
    let sourceMemoryIds: [UUID]
}

struct EpiphanyAnalytics {
    let totalEpiphanies: Int
    let averageImportance: Double
    let averageNovelty: Double
    let sparkFrequency: Double
    let lastEpiphanyDate: Date?
}

struct MemoryConcept {
    let id: UUID
    let content: String
    let type: ConceptType
    let importance: Double
    let timestamp: Date
}

struct SemanticCluster {
    let theme: String
    let memories: [UUID]
    let coherence: Double
}

struct ImageTextCorrelation {
    let correlation: String
    let description: String
    let strength: Double
}

struct DocumentConversationCorrelation {
    let similarity: String
    let summary: String
    let relevance: Double
}

enum ModalityType: String, CaseIterable {
    case vision, text, audio, document, speech
}

struct ConceptRelationship {
    let concept1: String
    let concept2: String
    let relationshipType: String
    let strength: Double
}

struct DocumentPattern {
    let theme: String
    let description: String
    let relevance: Double
}
