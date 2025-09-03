import Foundation

/// Represents the top-level structure of the comprehensive skills JSON file.
struct ComprehensiveSkillSet: Codable {
    let metadata: SkillMetadata
    let skills: [ComprehensiveSkillCategory]

    enum CodingKeys: String, CodingKey {
        case metadata = "Skill_Metadata"
        case skills
    }
}

/// Represents the metadata for the skill set.
struct SkillMetadata: Codable {
    let name: String
    let version: String
    let author: String
    let purpose: String
    let domain: String
}

/// Represents a category of skills from the comprehensive JSON file, containing a list of individual skill names.
struct ComprehensiveSkillCategory: Codable {
    let category: String
    let skills: [String]
}

/// A simple representation of a skill for the BrainLoader.
struct LoadedSkill: Identifiable, Codable {
    var id = UUID()
    let fileName: String
    let displayName: String
    let version: String
    let category: String
}