import Foundation
import UniformTypeIdentifiers
import Combine

@MainActor
class SkillsetImportExportService: ObservableObject {
    static let shared = SkillsetImportExportService()
    
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private let skillManager = SkillManager.shared
    
    private init() {}
    
    // MARK: - Import Operations
    
    /// Imports skillsets from multiple files
    func bulkImportSkillsets(from urls: [URL], completion: @escaping (BulkImportResult) -> Void) {
        var successCount = 0
        var failedImports: [String] = []
        var importedSkillsets: [ComprehensiveSkillSet] = []
        
        let group = DispatchGroup()
        
        for url in urls {
            group.enter()
            
            Task {
                do {
                    let data = try Data(contentsOf: url)
                    let skillset = try JSONDecoder().decode(ComprehensiveSkillSet.self, from: data)
                    
                    await MainActor.run {
                        importedSkillsets.append(skillset)
                        successCount += 1
                        group.leave()
                    }
                } catch {
                    await MainActor.run {
                        failedImports.append("\(url.lastPathComponent): \(error.localizedDescription)")
                        group.leave()
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            Task { @MainActor in
                // Merge all successfully imported skillsets
                for skillset in importedSkillsets {
                    self.skillManager.mergeSkillset(skillset)
                }
                
                let result = BulkImportResult(
                    totalFiles: urls.count,
                    successCount: successCount,
                    failedImports: failedImports,
                    importedSkillsets: importedSkillsets
                )
                
                completion(result)
            }
        }
    }
    
    /// Imports skillsets from a CSV file
    func importFromCSV(url: URL, completion: @escaping (Result<ComprehensiveSkillSet, Error>) -> Void) {
        Task {
            do {
                let content = try String(contentsOf: url, encoding: .utf8)
                let skillset = try await self.parseCSVToSkillset(content, fileName: url.lastPathComponent)
                
                await MainActor.run {
                    completion(.success(skillset))
                }
            } catch {
                await MainActor.run {
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Imports from a text file with structured format
    func importFromTextFile(url: URL, completion: @escaping (Result<ComprehensiveSkillSet, Error>) -> Void) {
        Task {
            do {
                let content = try String(contentsOf: url, encoding: .utf8)
                let skillset = try await self.parseTextToSkillset(content, fileName: url.lastPathComponent)
                
                await MainActor.run {
                    completion(.success(skillset))
                }
            } catch {
                await MainActor.run {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Export Operations
    
    /// Exports skillsets in various formats
    func exportSkillsets(format: ExportFormat, skillsets: [ComprehensiveSkillSet], completion: @escaping (Result<URL, Error>) -> Void) {
        Task {
            do {
                let timestamp = DateFormatter.fileNameFormatter.string(from: Date())
                let fileName: String
                let fileExtension: String
                let data: Data
                
                switch format {
                case .json:
                    fileName = "skillsets_export_\(timestamp)"
                    fileExtension = "json"
                    data = try await self.exportToJSON(skillsets: skillsets)
                    
                case .csv:
                    fileName = "skillsets_export_\(timestamp)"
                    fileExtension = "csv"
                    data = try await self.exportToCSV(skillsets: skillsets)
                    
                case .txt:
                    fileName = "skillsets_export_\(timestamp)"
                    fileExtension = "txt"
                    data = try await self.exportToText(skillsets: skillsets)
                    
                case .markdown:
                    fileName = "skillsets_export_\(timestamp)"
                    fileExtension = "md"
                    data = try await self.exportToMarkdown(skillsets: skillsets)
                }
                
                let url = self.documentsDirectory.appendingPathComponent("\(fileName).\(fileExtension)")
                try data.write(to: url)
                
                await MainActor.run {
                    completion(.success(url))
                }
            } catch {
                await MainActor.run {
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Creates a comprehensive backup of all skillsets
    func createFullBackup(completion: @escaping (Result<URL, Error>) -> Void) {
        Task { @MainActor in
            // Get current skillset from available categories
            let currentSkillCategories = skillManager.availableSkillCategories
            guard !currentSkillCategories.isEmpty else {
                completion(.failure(SkillsetError.noSkillsetLoaded))
                return
            }
            
            // Convert SkillCategory to ComprehensiveSkillCategory
            let comprehensiveSkillCategories = currentSkillCategories.map { category in
                ComprehensiveSkillCategory(
                    category: category.name,
                    skills: category.skills.map { $0.name }
                )
            }
            
            let currentSkillset = ComprehensiveSkillSet(
                metadata: SkillMetadata(
                    name: "Current Skillset Backup",
                    version: "1.0",
                    author: "Digital Court",
                    purpose: "Backup of current skills",
                    domain: "Backup"
                ),
                skills: comprehensiveSkillCategories
            )
            
            let backup = SkillsetBackup(
                timestamp: Date(),
                version: "1.0",
                skillset: currentSkillset,
                customSkills: getCustomSkillsDict(),
                activeSkills: skillManager.getActiveLoadedSkills()
            )
            
            Task {
                do {
                    let encoder = JSONEncoder()
                    encoder.outputFormatting = .prettyPrinted
                    encoder.dateEncodingStrategy = .iso8601
                    
                    let data = try encoder.encode(backup)
                    let timestamp = DateFormatter.fileNameFormatter.string(from: Date())
                    let fileName = "skillset_backup_\(timestamp).json"
                    let url = self.documentsDirectory.appendingPathComponent(fileName)
                    
                    try data.write(to: url)
                    
                    await MainActor.run {
                        completion(.success(url))
                    }
                } catch {
                    await MainActor.run {
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    /// Get custom skills as a dictionary
    private func getCustomSkillsDict() -> [String: [String]] {
        var customSkills: [String: [String]] = [:]
        
        for category in skillManager.availableSkillCategories {
            customSkills[category.name] = category.skills.map { $0.name }
        }
        
        return customSkills
    }
    
    /// Restores from a backup file
    func restoreFromBackup(url: URL, completion: @escaping (Result<SkillsetBackup, Error>) -> Void) {
        Task {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                let backup = try decoder.decode(SkillsetBackup.self, from: data)
                
                await MainActor.run {
                    // Apply the backup
                    self.skillManager.mergeSkillset(backup.skillset)
                    
                    // Restore custom skills
                    for (category, skills) in backup.customSkills {
                        for skill in skills {
                            _ = self.skillManager.addCustomSkill(skill, to: category)
                        }
                    }
                    
                    completion(.success(backup))
                }
            } catch {
                await MainActor.run {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Private Parsing Methods
    
    private func parseCSVToSkillset(_ csv: String, fileName: String) async throws -> ComprehensiveSkillSet {
        let lines = csv.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        guard !lines.isEmpty else {
            throw SkillsetError.invalidFormat("CSV file is empty")
        }
        
        var categories: [String: [String]] = [:]
        
        // Skip header if it exists
        let dataLines = lines.first?.contains("Category") == true ? Array(lines.dropFirst()) : lines
        
        for line in dataLines {
            let components = line.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            
            guard components.count >= 2 else { continue }
            
            let category = components[0]
            let skill = components[1]
            
            if categories[category] == nil {
                categories[category] = []
            }
            
            if !categories[category]!.contains(skill) {
                categories[category]!.append(skill)
            }
        }
        
        let skillCategories = categories.map { category, skills in
            ComprehensiveSkillCategory(category: category, skills: skills.sorted())
        }.sorted { $0.category < $1.category }
        
        return ComprehensiveSkillSet(
            metadata: SkillMetadata(
                name: "Imported from \(fileName)",
                version: "1.0",
                author: "CSV Import",
                purpose: "Imported skillset from CSV file",
                domain: "Imported"
            ),
            skills: skillCategories
        )
    }
    
    private func parseTextToSkillset(_ text: String, fileName: String) async throws -> ComprehensiveSkillSet {
        let lines = text.components(separatedBy: .newlines)
        var categories: [String: [String]] = [:]
        var currentCategory: String?
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmed.isEmpty { continue }
            
            // Check if it's a category header (starts with # or is in ALL CAPS)
            if trimmed.hasPrefix("#") || trimmed.uppercased() == trimmed {
                currentCategory = trimmed.replacingOccurrences(of: "#", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                if categories[currentCategory!] == nil {
                    categories[currentCategory!] = []
                }
            } else if let category = currentCategory {
                // It's a skill under the current category
                let skill = trimmed.hasPrefix("-") ? 
                    String(trimmed.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines) : 
                    trimmed
                
                if !categories[category]!.contains(skill) {
                    categories[category]!.append(skill)
                }
            }
        }
        
        let skillCategories = categories.map { category, skills in
            ComprehensiveSkillCategory(category: category, skills: skills.sorted())
        }.sorted { $0.category < $1.category }
        
        return ComprehensiveSkillSet(
            metadata: SkillMetadata(
                name: "Imported from \(fileName)",
                version: "1.0",
                author: "Text Import",
                purpose: "Imported skillset from text file",
                domain: "Imported"
            ),
            skills: skillCategories
        )
    }
    
    // MARK: - Private Export Methods
    
    private func exportToJSON(skillsets: [ComprehensiveSkillSet]) async throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        if skillsets.count == 1 {
            return try encoder.encode(skillsets.first!)
        } else {
            return try encoder.encode(skillsets)
        }
    }
    
    private func exportToCSV(skillsets: [ComprehensiveSkillSet]) async throws -> Data {
        var csv = "Category,Skill,Source\n"
        
        for skillset in skillsets {
            for category in skillset.skills {
                for skill in category.skills {
                    csv += "\(category.category),\(skill),\(skillset.metadata.name)\n"
                }
            }
        }
        
        guard let data = csv.data(using: .utf8) else {
            throw SkillsetError.exportFailed("Failed to encode CSV data")
        }
        
        return data
    }
    
    private func exportToText(skillsets: [ComprehensiveSkillSet]) async throws -> Data {
        var text = ""
        
        for skillset in skillsets {
            text += "# \(skillset.metadata.name)\n"
            text += "Version: \(skillset.metadata.version)\n"
            text += "Author: \(skillset.metadata.author)\n\n"
            
            for category in skillset.skills {
                text += "## \(category.category)\n"
                for skill in category.skills {
                    text += "- \(skill)\n"
                }
                text += "\n"
            }
            
            text += "---\n\n"
        }
        
        guard let data = text.data(using: .utf8) else {
            throw SkillsetError.exportFailed("Failed to encode text data")
        }
        
        return data
    }
    
    private func exportToMarkdown(skillsets: [ComprehensiveSkillSet]) async throws -> Data {
        var markdown = "# Skillset Export\n\n"
        
        for skillset in skillsets {
            markdown += "## \(skillset.metadata.name)\n\n"
            markdown += "- **Version:** \(skillset.metadata.version)\n"
            markdown += "- **Author:** \(skillset.metadata.author)\n"
            markdown += "- **Purpose:** \(skillset.metadata.purpose)\n\n"
            
            for category in skillset.skills {
                markdown += "### \(category.category)\n\n"
                for skill in category.skills {
                    markdown += "- [ ] \(skill)\n"
                }
                markdown += "\n"
            }
            
            markdown += "---\n\n"
        }
        
        guard let data = markdown.data(using: .utf8) else {
            throw SkillsetError.exportFailed("Failed to encode markdown data")
        }
        
        return data
    }
}

// MARK: - Supporting Types

struct BulkImportResult {
    let totalFiles: Int
    let successCount: Int
    let failedImports: [String]
    let importedSkillsets: [ComprehensiveSkillSet]
    
    var hasFailures: Bool {
        return !failedImports.isEmpty
    }
    
    var successRate: Double {
        guard totalFiles > 0 else { return 0.0 }
        return Double(successCount) / Double(totalFiles)
    }
}

struct SkillsetBackup: Codable {
    let timestamp: Date
    let version: String
    let skillset: ComprehensiveSkillSet
    let customSkills: [String: [String]]
    let activeSkills: [LoadedSkill]
}

enum ExportFormat: CaseIterable {
    case json
    case csv
    case txt
    case markdown
    
    var displayName: String {
        switch self {
        case .json: return "JSON"
        case .csv: return "CSV"
        case .txt: return "Text"
        case .markdown: return "Markdown"
        }
    }
    
    var fileExtension: String {
        switch self {
        case .json: return "json"
        case .csv: return "csv"
        case .txt: return "txt"
        case .markdown: return "md"
        }
    }
}

enum SkillsetError: LocalizedError {
    case noSkillsetLoaded
    case invalidFormat(String)
    case exportFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .noSkillsetLoaded:
            return "No skillset is currently loaded"
        case .invalidFormat(let message):
            return "Invalid file format: \(message)"
        case .exportFailed(let message):
            return "Export failed: \(message)"
        }
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let fileNameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
}