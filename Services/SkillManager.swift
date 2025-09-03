import Foundation
import Combine

struct Skill: Codable, Equatable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var category: String
    var isActive: Bool
    var metadata: SkillMetadata?

    init(name: String, category: String, active: Bool = false, metadata: SkillMetadata? = nil) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.isActive = active
        self.metadata = metadata
    }
    
    // MARK: - Hashable Conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: - Equatable Conformance
    static func == (lhs: Skill, rhs: Skill) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.category == rhs.category &&
               lhs.isActive == rhs.isActive
    }
}

struct SkillCategory: Codable, Identifiable {
    let id: UUID
    var name: String
    var skills: [Skill]
    
    // For backward compatibility with SuperuserSkillsetManagementView
    var category: String { name }

    init(name: String, skills: [Skill] = []) {
        self.id = UUID()
        self.name = name
        self.skills = skills
    }
}

// MARK: - Export Types

enum ExportType {
    case all
    case activeOnly
    case customOnly
}

struct SkillsetValidation {
    let isValid: Bool
    let errors: [String]
}

// MARK: - Statistics and Default Skills

struct SkillStatistics {
    let totalAvailableSkills: Int
    let totalActiveSkills: Int
    let totalCategories: Int
    let categoryStatistics: [CategoryStatistic]
}

struct CategoryStatistic {
    let name: String
    let totalSkills: Int
    let activeSkills: Int
}

class SkillManager: ObservableObject {
    static let shared = SkillManager()

    @Published private(set) var categories: [SkillCategory] = []
    @Published private(set) var activeSkills: [Skill] = []
    private let skillKey = "DCourtSkillCategories"

    private init() {
        load()
        // Ensure we have default skills available for the boot sequence
        if getAllSkills().isEmpty {
            activateDefaultSkills()
        }
    }
    
    // MARK: - Computed Properties
    
    var availableSkillCategories: [SkillCategory] {
        return categories
    }
    
    // MARK: - CRUD Operations
    
    func addCategory(_ name: String) {
        guard !categories.contains(where: { $0.name.lowercased() == name.lowercased() }) else { return }
        categories.append(SkillCategory(name: name))
        save()
    }

    func removeCategory(_ name: String) {
        categories.removeAll { $0.name.lowercased() == name.lowercased() }
        save()
    }

    func addSkill(_ name: String, to category: String) {
        guard let cidx = categories.firstIndex(where: { $0.name.lowercased() == category.lowercased() }) else { return }
        let exists = categories[cidx].skills.contains { $0.name.lowercased() == name.lowercased() }
        guard !exists else { return }
        let skill = Skill(name: name, category: category)
        categories[cidx].skills.append(skill)
        save()
    }
    
    func removeSkill(_ name: String, from category: String) {
        guard let cidx = categories.firstIndex(where: { $0.name.lowercased() == category.lowercased() }) else { return }
        categories[cidx].skills.removeAll { $0.name.lowercased() == name.lowercased() }
        save()
    }

    func activateSkill(_ name: String, in category: String) {
        setSkill(name, in: category, active: true)
    }
    
    func deactivateSkill(_ name: String, in category: String) {
        setSkill(name, in: category, active: false)
    }
    
    private func setSkill(_ name: String, in category: String, active: Bool) {
        guard let cidx = categories.firstIndex(where: { $0.name.lowercased() == category.lowercased() }),
            let sidx = categories[cidx].skills.firstIndex(where: { $0.name.lowercased() == name.lowercased() })
        else { return }
        categories[cidx].skills[sidx].isActive = active
        updateActiveSkills()
        save()
    }
    
    private func updateActiveSkills() {
        activeSkills = categories.flatMap { $0.skills.filter { $0.isActive } }
    }

    func getSkills(for category: String) -> [Skill] {
        categories.first(where: { $0.name.lowercased() == category.lowercased() })?.skills ?? []
    }
    
    func getAllSkills() -> [Skill] {
        categories.flatMap{ $0.skills }
    }
    
    func getActiveSkills(for category: String) -> [Skill] {
        return getSkills(for: category).filter { $0.isActive }
    }
    
    // MARK: - Statistics and Default Skills Methods
    
    func activateDefaultSkills() {
        // Load default skillset if categories are empty or have no active skills
        if categories.isEmpty || activeSkills.isEmpty {
            loadDefaultSkillset()
        }
    }

    func getSkillStatistics() -> SkillStatistics {
        let categoryStats = categories.map { category in
            CategoryStatistic(
                name: category.name,
                totalSkills: category.skills.count,
                activeSkills: category.skills.filter { $0.isActive }.count
            )
        }
        
        return SkillStatistics(
            totalAvailableSkills: categories.flatMap { $0.skills }.count,
            totalActiveSkills: activeSkills.count,
            totalCategories: categories.count,
            categoryStatistics: categoryStats
        )
    }

    private func loadDefaultSkillset() {
        // Create default categories and skills if none exist
        let defaultCategories = [
            ("Analysis", ["Critical Thinking", "Data Analysis", "Pattern Recognition"]),
            ("Communication", ["Clear Writing", "Active Listening", "Presentation"]),
            ("Problem Solving", ["Root Cause Analysis", "Creative Solutions", "Decision Making"]),
            ("Technology", ["Digital Literacy", "Information Processing", "System Analysis"])
        ]
        
        for (categoryName, skillNames) in defaultCategories {
            // Add category if it doesn't exist
            if !categories.contains(where: { $0.name.lowercased() == categoryName.lowercased() }) {
                addCategory(categoryName)
            }
            
            // Add skills to the category
            for skillName in skillNames {
                addSkill(skillName, to: categoryName)
            }
        }
        
        save()
    }
    
    // MARK: - Processing Methods
    
    func applySkillsToProcessing(_ input: String, brain: DBrain) -> String {
        // Apply active skills to enhance the input processing
        let enhancedInput = activeSkills.reduce(input) { currentInput, skill in
            return applySkillToInput(currentInput, skill: skill, brain: brain)
        }
        return enhancedInput
    }
    
    private func applySkillToInput(_ input: String, skill: Skill, brain: DBrain) -> String {
        // Apply individual skill logic to the input
        // This is a simplified implementation - in a real system you'd have more sophisticated skill application
        
        switch skill.category.lowercased() {
        case "analysis":
            return "\(input)\n[Analysis Enhanced: \(skill.name)]"
        case "reasoning":
            return "\(input)\n[Reasoning Enhanced: \(skill.name)]"
        case "communication":
            return "\(input)\n[Communication Enhanced: \(skill.name)]"
        case "creativity":
            return "\(input)\n[Creativity Enhanced: \(skill.name)]"
        default:
            return "\(input)\n[Enhanced with: \(skill.name)]"
        }
    }
    
    // Convert Skills to LoadedSkills for compatibility
    func getActiveLoadedSkills() -> [LoadedSkill] {
        return activeSkills.map { skill in
            LoadedSkill(
                fileName: "\(skill.name.replacingOccurrences(of: " ", with: "_")).json",
                displayName: skill.name,
                version: "1.0.0",
                category: skill.category
            )
        }
    }
    
    // MARK: - Advanced Operations (for SuperuserSkillsetManagementView)
    
    func addCustomSkill(_ name: String, to category: String) -> Bool {
        // Check if category exists, create if not
        if !categories.contains(where: { $0.name.lowercased() == category.lowercased() }) {
            addCategory(category)
        }
        
        // Check if skill already exists
        guard let cidx = categories.firstIndex(where: { $0.name.lowercased() == category.lowercased() }),
              !categories[cidx].skills.contains(where: { $0.name.lowercased() == name.lowercased() }) else {
            return false
        }
        
        let skill = Skill(name: name, category: category, active: false)
        categories[cidx].skills.append(skill)
        save()
        return true
    }
    
    func mergeSkillset(_ skillset: ComprehensiveSkillSet) {
        for skillCategory in skillset.skills {
            // Create category if it doesn't exist
            if !categories.contains(where: { $0.name.lowercased() == skillCategory.category.lowercased() }) {
                addCategory(skillCategory.category)
            }
            
            // Add skills from the skillset
            for skillName in skillCategory.skills {
                _ = addCustomSkill(skillName, to: skillCategory.category)
            }
        }
        save()
    }
    
    func exportSkillsets(type: ExportType, completion: @escaping (Result<URL, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let skillsetsToExport: [SkillCategory]
                
                switch type {
                case .all:
                    skillsetsToExport = self.categories
                case .activeOnly:
                    skillsetsToExport = self.categories.compactMap { category in
                        let activeSkills = category.skills.filter { $0.isActive }
                        return activeSkills.isEmpty ? nil : SkillCategory(name: category.name, skills: activeSkills)
                    }
                case .customOnly:
                    // For now, treat all user-created skills as custom
                    skillsetsToExport = self.categories
                }
                
                let exportData = ExportSkillsetData(
                    categories: skillsetsToExport,
                    exportDate: Date(),
                    exportType: type
                )
                
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                encoder.outputFormatting = .prettyPrinted
                
                let jsonData = try encoder.encode(exportData)
                
                // Save to documents directory
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let timestamp = SkillManagerDateFormatter.fileNameFormatter.string(from: Date())
                let fileName = "DigitalCourt_Skills_\(type)_\(timestamp).json"
                let fileURL = documentsPath.appendingPathComponent(fileName)
                
                try jsonData.write(to: fileURL)
                
                Task { @MainActor in
                    completion(.success(fileURL))
                }
                
            } catch {
                Task { @MainActor in
                    completion(.failure(error))
                }
            }
        }
    }
    
    func validateSkillsets() -> SkillsetValidation {
        var errors: [String] = []
        
        // Check for empty categories
        let emptyCategories = categories.filter { $0.skills.isEmpty }
        if !emptyCategories.isEmpty {
            errors.append("Empty categories found: \(emptyCategories.map { $0.name }.joined(separator: ", "))")
        }
        
        // Check for duplicate skill names within categories
        for category in categories {
            let skillNames = category.skills.map { $0.name.lowercased() }
            let uniqueNames = Set(skillNames)
            if skillNames.count != uniqueNames.count {
                errors.append("Duplicate skills found in category '\(category.name)'")
            }
        }
        
        // Check for very long skill names
        for category in categories {
            let longNames = category.skills.filter { $0.name.count > 100 }
            if !longNames.isEmpty {
                errors.append("Overly long skill names found in category '\(category.name)'")
            }
        }
        
        return SkillsetValidation(isValid: errors.isEmpty, errors: errors)
    }
    
    func createSkillsetTemplate(completion: @escaping (Result<URL, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let templateSkillset = ComprehensiveSkillSet(
                    metadata: SkillMetadata(
                        name: "Custom Skillset Template",
                        version: "1.0.0",
                        author: "Digital Court User",
                        purpose: "Template for creating custom skillsets",
                        domain: "Custom"
                    ),
                    skills: [
                        ComprehensiveSkillCategory(
                            category: "Example Category",
                            skills: [
                                "Example Skill 1",
                                "Example Skill 2",
                                "Example Skill 3"
                            ]
                        )
                    ]
                )
                
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                encoder.outputFormatting = .prettyPrinted
                
                let jsonData = try encoder.encode(templateSkillset)
                
                // Save to documents directory
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let timestamp = SkillManagerDateFormatter.fileNameFormatter.string(from: Date())
                let fileName = "DigitalCourt_SkillsetTemplate_\(timestamp).json"
                let fileURL = documentsPath.appendingPathComponent(fileName)
                
                try jsonData.write(to: fileURL)
                
                Task { @MainActor in
                    completion(.success(fileURL))
                }
                
            } catch {
                Task { @MainActor in
                    completion(.failure(error))
                }
            }
        }
    }

    // MARK: - Persistence

    private func save() {
        updateActiveSkills()
        if let data = try? JSONEncoder().encode(categories) {
            UserDefaults.standard.set(data, forKey: skillKey)
        }
    }
    
    private func load() {
        if let data = UserDefaults.standard.data(forKey: skillKey),
           let decoded = try? JSONDecoder().decode([SkillCategory].self, from: data) {
            categories = decoded
            updateActiveSkills()
        } else {
            // Provide defaults
            categories = [SkillCategory(name: "General")]
            updateActiveSkills()
        }
    }
}

// MARK: - Supporting Types for Export

struct ExportSkillsetData: Codable {
    let categories: [SkillCategory]
    let exportDate: Date
    let exportType: ExportType
}

extension ExportType: Codable {
    enum CodingKeys: String, CodingKey {
        case all, activeOnly, customOnly
    }
}

// Use a dedicated struct to avoid conflicts
struct SkillManagerDateFormatter {
    static let fileNameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter
    }()
}