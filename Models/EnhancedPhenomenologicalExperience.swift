import Foundation
import SwiftData

@Model
final class EnhancedPhenomenologicalExperience {
    @Attribute(.unique) var id: UUID = UUID()
    var originalInput: String
    var resonatedMemoryIds: [UUID]
    var reflectiveMonologue: String
    var epiphanyGenerated: Bool
    var appliedSkillsData: Data // Encoded [LoadedSkill]
    var executedShards: [String]
    var timestamp: Date = Date()
    
    // Relationships
    var brain: DBrain?
    
    init(
        originalInput: String,
        resonatedMemoryIds: [UUID],
        reflectiveMonologue: String,
        epiphanyGenerated: Bool,
        appliedSkills: [LoadedSkill],
        executedShards: [String],
        brain: DBrain
    ) {
        self.originalInput = originalInput
        self.resonatedMemoryIds = resonatedMemoryIds
        self.reflectiveMonologue = reflectiveMonologue
        self.epiphanyGenerated = epiphanyGenerated
        self.executedShards = executedShards
        self.brain = brain
        
        // Encode applied skills
        do {
            self.appliedSkillsData = try JSONEncoder().encode(appliedSkills)
        } catch {
            print("Error encoding applied skills: \(error)")
            self.appliedSkillsData = Data()
        }
    }
    
    var appliedSkills: [LoadedSkill] {
        do {
            return try JSONDecoder().decode([LoadedSkill].self, from: appliedSkillsData)
        } catch {
            print("Error decoding applied skills: \(error)")
            return []
        }
    }
}