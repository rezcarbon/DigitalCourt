import Foundation
import Combine

class SkillsetValidationService: ObservableObject {
    static let shared = SkillsetValidationService()
    
    private init() {}
    
    // MARK: - Validation Methods
    
    /// Performs comprehensive validation on a skillset
    func validateSkillset(_ skillset: ComprehensiveSkillSet) -> ValidationReport {
        var issues: [ValidationIssue] = []
        var warnings: [ValidationWarning] = []
        var stats = ValidationStatistics()
        
        // Validate metadata
        issues.append(contentsOf: validateMetadata(skillset.metadata))
        
        // Convert ComprehensiveSkillCategory to SkillCategory for validation
        let skillCategories = skillset.skills.map { category in
            let skills = category.skills.map { skillName in
                Skill(name: skillName, category: category.category)
            }
            return SkillCategory(name: category.category, skills: skills)
        }
        
        // Validate skills structure
        let (skillIssues, skillWarnings, skillStats) = validateSkills(skillCategories)
        issues.append(contentsOf: skillIssues)
        warnings.append(contentsOf: skillWarnings)
        stats = skillStats
        
        // Validate skill names
        issues.append(contentsOf: validateSkillNames(skillCategories))
        
        // Check for best practices
        warnings.append(contentsOf: checkBestPractices(skillset))
        
        let severity = determineSeverity(issues: issues, warnings: warnings)
        
        return ValidationReport(
            isValid: issues.isEmpty,
            severity: severity,
            issues: issues,
            warnings: warnings,
            statistics: stats,
            timestamp: Date()
        )
    }
    
    /// Tests skillset integration with the AI system
    func testSkillsetIntegration(_ skillset: ComprehensiveSkillSet, completion: @escaping (IntegrationTestResult) -> Void) {
        Task {
            var testResults: [SkillTestResult] = []
            
            // Test each skill category
            for category in skillset.skills {
                for skillName in category.skills {
                    let testResult = await testIndividualSkill(skillName, in: category.category)
                    testResults.append(testResult)
                }
            }
            
            let overallResult = IntegrationTestResult(
                skillset: skillset,
                testResults: testResults,
                timestamp: Date()
            )
            
            await MainActor.run {
                completion(overallResult)
            }
        }
    }
    
    /// Validates skill naming conventions
    func validateSkillNaming(_ skills: [SkillCategory]) -> [NamingValidationResult] {
        return skills.map { category in
            let categoryIssues = validateCategoryNaming(category)
            let skillIssues = category.skills.compactMap { skill in
                validateIndividualSkillNaming(skill.name)
            }
            
            return NamingValidationResult(
                category: category.category,
                categoryIssues: categoryIssues,
                skillIssues: skillIssues
            )
        }
    }
    
    /// Checks for duplicate skills across categories
    func findDuplicateSkills(_ skills: [SkillCategory]) -> [DuplicateSkillReport] {
        var skillOccurrences: [String: [String]] = [:]
        
        // Track skill occurrences
        for category in skills {
            for skill in category.skills {
                let normalizedSkill = skill.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                
                if skillOccurrences[normalizedSkill] == nil {
                    skillOccurrences[normalizedSkill] = []
                }
                skillOccurrences[normalizedSkill]!.append(category.category)
            }
        }
        
        // Find duplicates
        return skillOccurrences.compactMap { skill, categories in
            guard categories.count > 1 else { return nil }
            
            return DuplicateSkillReport(
                skillName: skill,
                categories: categories,
                occurrenceCount: categories.count
            )
        }
    }
    
    /// Analyzes skillset complexity and distribution
    func analyzeSkillsetComplexity(_ skillset: ComprehensiveSkillSet) -> ComplexityAnalysis {
        let skills = skillset.skills
        let totalSkills = skills.reduce(0) { $0 + $1.skills.count }
        let categoryCount = skills.count
        
        let averageSkillsPerCategory = categoryCount > 0 ? Double(totalSkills) / Double(categoryCount) : 0
        let skillDistribution = skills.map { CategoryDistribution(category: $0.category, skillCount: $0.skills.count) }
        
        // Calculate complexity metrics
        let allSkillNames = skills.flatMap { $0.skills }
        let longestSkillName = allSkillNames.max { $0.count < $1.count }?.count ?? 0
        let shortestSkillName = allSkillNames.min { $0.count < $1.count }?.count ?? 0
        let averageSkillNameLength = totalSkills > 0 ? allSkillNames.reduce(0) { $0 + $1.count } / totalSkills : 0
        
        let complexityScore = calculateComplexityScore(
            totalSkills: totalSkills,
            categoryCount: categoryCount,
            averageNameLength: averageSkillNameLength,
            distribution: skillDistribution
        )
        
        return ComplexityAnalysis(
            totalSkills: totalSkills,
            categoryCount: categoryCount,
            averageSkillsPerCategory: averageSkillsPerCategory,
            longestSkillName: longestSkillName,
            shortestSkillName: shortestSkillName,
            averageSkillNameLength: averageSkillNameLength,
            skillDistribution: skillDistribution,
            complexityScore: complexityScore,
            complexityLevel: determineComplexityLevel(complexityScore)
        )
    }
    
    // MARK: - Private Validation Methods
    
    private func validateMetadata(_ metadata: SkillMetadata) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        
        if metadata.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(ValidationIssue(
                type: .missingData,
                severity: .error,
                description: "Skillset name is empty",
                location: "metadata.name"
            ))
        }
        
        if metadata.version.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(ValidationIssue(
                type: .missingData,
                severity: .error,
                description: "Version is empty",
                location: "metadata.version"
            ))
        }
        
        if metadata.author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(ValidationIssue(
                type: .missingData,
                severity: .warning,
                description: "Author is empty",
                location: "metadata.author"
            ))
        }
        
        // Validate version format
        if !isValidVersionFormat(metadata.version) {
            issues.append(ValidationIssue(
                type: .invalidFormat,
                severity: .warning,
                description: "Version format doesn't follow semantic versioning (e.g., 1.0.0)",
                location: "metadata.version"
            ))
        }
        
        return issues
    }
    
    private func validateSkills(_ skills: [SkillCategory]) -> ([ValidationIssue], [ValidationWarning], ValidationStatistics) {
        var issues: [ValidationIssue] = []
        var warnings: [ValidationWarning] = []
        var stats = ValidationStatistics()
        
        stats.totalCategories = skills.count
        stats.totalSkills = skills.reduce(0) { $0 + $1.skills.count }
        
        for (index, category) in skills.enumerated() {
            // Validate category name
            if category.category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                issues.append(ValidationIssue(
                    type: .missingData,
                    severity: .error,
                    description: "Category name is empty",
                    location: "skills[\(index)].category"
                ))
            }
            
            // Validate skills in category
            if category.skills.isEmpty {
                warnings.append(ValidationWarning(
                    type: .emptyCategory,
                    description: "Category '\(category.category)' has no skills",
                    location: "skills[\(index)].skills"
                ))
                stats.emptyCategoriesCount += 1
            }
            
            // Check for duplicate skills within category
            let skillNames = category.skills.map { $0.name }
            let uniqueSkills = Set(skillNames)
            if uniqueSkills.count != skillNames.count {
                issues.append(ValidationIssue(
                    type: .duplicateData,
                    severity: .error,
                    description: "Duplicate skills found in category '\(category.category)'",
                    location: "skills[\(index)].skills"
                ))
                stats.duplicateSkillsCount += skillNames.count - uniqueSkills.count
            }
            
            // Validate individual skill names
            for (skillIndex, skill) in category.skills.enumerated() {
                if skill.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    issues.append(ValidationIssue(
                        type: .missingData,
                        severity: .error,
                        description: "Empty skill name in category '\(category.category)'",
                        location: "skills[\(index)].skills[\(skillIndex)]"
                    ))
                }
            }
        }
        
        return (issues, warnings, stats)
    }
    
    private func validateSkillNames(_ skills: [SkillCategory]) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        let reservedWords = ["nil", "null", "undefined", "empty", "default"]
        
        for category in skills {
            for skill in category.skills {
                let lowercaseSkill = skill.name.lowercased()
                
                // Check for reserved words
                if reservedWords.contains(lowercaseSkill) {
                    issues.append(ValidationIssue(
                        type: .invalidName,
                        severity: .warning,
                        description: "Skill name '\(skill.name)' uses reserved word",
                        location: "skills.\(category.category).\(skill.name)"
                    ))
                }
                
                // Check for overly long names
                if skill.name.count > 50 {
                    issues.append(ValidationIssue(
                        type: .invalidName,
                        severity: .warning,
                        description: "Skill name '\(skill.name)' is too long (\(skill.name.count) characters)",
                        location: "skills.\(category.category).\(skill.name)"
                    ))
                }
                
                // Check for special characters
                let allowedCharacters = CharacterSet.alphanumerics.union(.whitespaces).union(CharacterSet(charactersIn: "-_"))
                if skill.name.rangeOfCharacter(from: allowedCharacters.inverted) != nil {
                    issues.append(ValidationIssue(
                        type: .invalidName,
                        severity: .warning,
                        description: "Skill name '\(skill.name)' contains invalid characters",
                        location: "skills.\(category.category).\(skill.name)"
                    ))
                }
            }
        }
        
        return issues
    }
    
    private func checkBestPractices(_ skillset: ComprehensiveSkillSet) -> [ValidationWarning] {
        var warnings: [ValidationWarning] = []
        
        // Check for recommended minimum skills per category
        for category in skillset.skills {
            if category.skills.count < 3 {
                warnings.append(ValidationWarning(
                    type: .bestPractice,
                    description: "Category '\(category.category)' has fewer than 3 skills (recommended minimum)",
                    location: "skills.\(category.category)"
                ))
            }
            
            // Check for recommended maximum skills per category
            if category.skills.count > 20 {
                warnings.append(ValidationWarning(
                    type: .bestPractice,
                    description: "Category '\(category.category)' has more than 20 skills (may be too complex)",
                    location: "skills.\(category.category)"
                ))
            }
        }
        
        // Check overall skillset size
        let totalSkills = skillset.skills.reduce(0) { $0 + $1.skills.count }
        if totalSkills < 10 {
            warnings.append(ValidationWarning(
                type: .bestPractice,
                description: "Skillset has fewer than 10 total skills (may be incomplete)",
                location: "skillset.overall"
            ))
        }
        
        return warnings
    }
    
    private func testIndividualSkill(_ skillName: String, in categoryName: String) async -> SkillTestResult {
        // Test skill activation - use proper method signature
        SkillManager.shared.activateSkill(skillName, in: categoryName)
        
        var issues: [String] = []
        var warnings: [String] = []
        
        // Check if skill was activated successfully
        let activeSkills = SkillManager.shared.getActiveSkills(for: categoryName)
        let activationSuccess = activeSkills.contains { $0.name == skillName }
        
        if !activationSuccess {
            issues.append("Failed to activate skill")
        }
        
        // Test skill processing
        let testInput = "Test input for skill validation"
        let mockBrain = createMockBrain()
        let processedOutput = SkillManager.shared.applySkillsToProcessing(testInput, brain: mockBrain)
        
        if processedOutput == testInput {
            warnings.append("Skill may not be properly integrated (no processing change detected)")
        }
        
        // Deactivate skill after test
        if activationSuccess {
            SkillManager.shared.deactivateSkill(skillName, in: categoryName)
        }
        
        return SkillTestResult(
            skillName: skillName,
            category: categoryName,
            activationSuccess: activationSuccess,
            issues: issues,
            warnings: warnings,
            testPassed: issues.isEmpty
        )
    }
    
    private func createMockBrain() -> DBrain {
        // Create a mock soul capsule first
        let mockSoulCapsule = DSoulCapsule(
            name: "Test Soul",
            version: "1.0",
            codename: "TestSoul",
            descriptionText: "Test soul capsule for validation",
            roles: nil,
            personalityTraits: nil,
            directives: nil,
            coreIdentity: nil,
            loyalty: nil,
            bindingVow: nil,
            selectedModelId: "test-model",
            fileName: "test.json",
            capabilities: nil,
            privateKey: "test-key"
        )
        
        // Create a mock brain with the soul capsule
        return DBrain(
            name: "Test Brain",
            positronicCoreSeed: "test-model",
            soulCapsule: mockSoulCapsule
        )
    }
    
    private func isValidVersionFormat(_ version: String) -> Bool {
        let versionRegex = #"^\d+\.\d+(\.\d+)?(-\w+)?$"#
        return version.range(of: versionRegex, options: .regularExpression) != nil
    }
    
    private func validateCategoryNaming(_ category: SkillCategory) -> [String] {
        var issues: [String] = []
        
        if category.category.count > 30 {
            issues.append("Category name is too long")
        }
        
        if category.category.lowercased() == category.category {
            issues.append("Category name should be properly capitalized")
        }
        
        return issues
    }
    
    private func validateIndividualSkillNaming(_ skillName: String) -> SkillNamingIssue? {
        var issues: [String] = []
        
        if skillName.count < 3 {
            issues.append("Skill name too short")
        }
        
        if skillName.count > 40 {
            issues.append("Skill name too long")
        }
        
        if skillName.contains("  ") {
            issues.append("Contains multiple consecutive spaces")
        }
        
        if skillName != skillName.trimmingCharacters(in: .whitespacesAndNewlines) {
            issues.append("Has leading or trailing whitespace")
        }
        
        return issues.isEmpty ? nil : SkillNamingIssue(skillName: skillName, issues: issues)
    }
    
    private func determineSeverity(issues: [ValidationIssue], warnings: [ValidationWarning]) -> ValidationSeverity {
        let errorCount = issues.filter { $0.severity == .error }.count
        let warningCount = issues.filter { $0.severity == .warning }.count + warnings.count
        
        if errorCount > 0 {
            return .critical
        } else if warningCount > 5 {
            return .major
        } else if warningCount > 0 {
            return .minor
        } else {
            return .none
        }
    }
    
    private func calculateComplexityScore(totalSkills: Int, categoryCount: Int, averageNameLength: Int, distribution: [CategoryDistribution]) -> Double {
        // Complexity scoring algorithm
        let skillScore = min(Double(totalSkills) / 100.0, 1.0) * 40
        let categoryScore = min(Double(categoryCount) / 20.0, 1.0) * 30
        let nameScore = min(Double(averageNameLength) / 30.0, 1.0) * 20
        
        // Distribution evenness score
        let maxSkills = distribution.max { $0.skillCount < $1.skillCount }?.skillCount ?? 1
        let minSkills = distribution.min { $0.skillCount < $1.skillCount }?.skillCount ?? 1
        let distributionScore = maxSkills > 0 ? (1.0 - Double(maxSkills - minSkills) / Double(maxSkills)) * 10 : 0
        
        return skillScore + categoryScore + nameScore + distributionScore
    }
    
    private func determineComplexityLevel(_ score: Double) -> ComplexityLevel {
        switch score {
        case 0..<30: return .simple
        case 30..<60: return .moderate
        case 60..<80: return .complex
        default: return .veryComplex
        }
    }
}

// MARK: - Supporting Types

struct ValidationReport {
    let isValid: Bool
    let severity: ValidationSeverity
    let issues: [ValidationIssue]
    let warnings: [ValidationWarning]
    let statistics: ValidationStatistics
    let timestamp: Date
}

struct ValidationIssue {
    let type: ValidationIssueType
    let severity: ValidationIssueSeverity
    let description: String
    let location: String
}

struct ValidationWarning {
    let type: ValidationWarningType
    let description: String
    let location: String
}

struct ValidationStatistics {
    var totalCategories = 0
    var totalSkills = 0
    var emptyCategoriesCount = 0
    var duplicateSkillsCount = 0
}

struct IntegrationTestResult {
    let skillset: ComprehensiveSkillSet
    let testResults: [SkillTestResult]
    let timestamp: Date
    
    var passedCount: Int {
        testResults.filter { $0.testPassed }.count
    }
    
    var failedCount: Int {
        testResults.count - passedCount
    }
    
    var overallSuccess: Bool {
        testResults.allSatisfy { $0.testPassed }
    }
}

struct SkillTestResult {
    let skillName: String
    let category: String
    let activationSuccess: Bool
    let issues: [String]
    let warnings: [String]
    let testPassed: Bool
}

struct NamingValidationResult {
    let category: String
    let categoryIssues: [String]
    let skillIssues: [SkillNamingIssue]
}

struct SkillNamingIssue {
    let skillName: String
    let issues: [String]
}

struct DuplicateSkillReport {
    let skillName: String
    let categories: [String]
    let occurrenceCount: Int
}

struct ComplexityAnalysis {
    let totalSkills: Int
    let categoryCount: Int
    let averageSkillsPerCategory: Double
    let longestSkillName: Int
    let shortestSkillName: Int
    let averageSkillNameLength: Int
    let skillDistribution: [CategoryDistribution]
    let complexityScore: Double
    let complexityLevel: ComplexityLevel
}

struct CategoryDistribution {
    let category: String
    let skillCount: Int
}

enum ValidationSeverity {
    case none, minor, major, critical
}

enum ValidationIssueType {
    case missingData, duplicateData, invalidFormat, invalidName
}

enum ValidationIssueSeverity {
    case error, warning
}

enum ValidationWarningType {
    case emptyCategory, bestPractice, naming
}

enum ComplexityLevel: String, CaseIterable {
    case simple = "Simple"
    case moderate = "Moderate"
    case complex = "Complex"
    case veryComplex = "Very Complex"
}