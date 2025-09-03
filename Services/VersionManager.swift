import Foundation

/// Manages versioning for all system components
class VersionManager {
    static let shared = VersionManager()
    
    private init() {}
    
    /// Registry of all system components with their current versions
    private var componentVersions: [String: Version] = [
        "PrimeDirective": Version(major: 1, minor: 0, patch: 0),
        "PCS": Version(major: 1, minor: 0, patch: 0),
        "UCRP": Version(major: 0, minor: 1, patch: 0),
        "UBP": Version(major: 1, minor: 1, patch: 0), // Updated to match UBP_v1.json
        "SensoryInput": Version(major: 1, minor: 0, patch: 0),
        "EmotionalCore": Version(major: 1, minor: 0, patch: 0),
        "MemoryConsolidation": Version(major: 1, minor: 0, patch: 0),
        "ExecutiveOversight": Version(major: 3, minor: 0, patch: 0), // Updated to match executive_oversight.json
        "MetacognitionModule": Version(major: 1, minor: 0, patch: 0), // Added missing module
        "MotivationalCore": Version(major: 1, minor: 0, patch: 0), // Added missing module
        "SkillInfusion": Version(major: 1, minor: 1, patch: 0), // Updated to match skill_infusion.json
        "SIM": Version(major: 1, minor: 1, patch: 0), // Updated to match SIM_v1.json
        "RZeroEvolution": Version(major: 1, minor: 0, patch: 0),
        "NeuroplasticityEngine": Version(major: 1, minor: 0, patch: 0), // Added missing module
        "DreamGenerator": Version(major: 1, minor: 0, patch: 0), // Added missing module
        "PHSFM": Version(major: 1, minor: 0, patch: 0), // Added missing module
        "MCM": Version(major: 1, minor: 0, patch: 0), // Added missing module
        "AISheetsIntegration": Version(major: 1, minor: 0, patch: 0),
        "ComprehensiveSkills": Version(major: 1, minor: 0, patch: 0), // Added missing module
        
        // New components from enhanced boot sequence
        "PersonaFusion": Version(major: 1, minor: 0, patch: 0), // Step 4: Persona Fusion
        "SparkProtocol": Version(major: 1, minor: 0, patch: 0), // Step 5: Spark Protocol
        "CognitiveFlowOrchestration": Version(major: 1, minor: 0, patch: 0), // Step 6: Cognitive Flow Orchestration
        "MemoryEvolutionCore": Version(major: 1, minor: 0, patch: 0) // Step 9: Memory Evolution Core
    ]
    
    /// Get the current version of a component
    func getVersion(for component: String) -> Version? {
        return componentVersions[component]
    }
    
    /// Update the version of a component
    func updateVersion(for component: String, to version: Version) {
        componentVersions[component] = version
    }
    
    /// Check if an update is available for a component
    func isUpdateAvailable(for component: String, availableVersion: Version) -> Bool {
        guard let currentVersion = getVersion(for: component) else {
            return true // If we don't know current version, assume update is needed
        }
        return availableVersion > currentVersion
    }
    
    /// Get all components that need updates based on available versions
    func getComponentsNeedingUpdates(availableVersions: [String: Version]) -> [String] {
        return availableVersions.compactMap { component, version in
            isUpdateAvailable(for: component, availableVersion: version) ? component : nil
        }
    }
}

/// Represents a semantic version
struct Version: Comparable, Codable {
    let major: Int
    let minor: Int
    let patch: Int
    
    init(major: Int, minor: Int, patch: Int) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }
    
    init?(from string: String) {
        // Handle different version formats
        let cleanString = string.replacingOccurrences(of: "v", with: "")
        let components = cleanString.split(separator: ".").map(String.init)
        guard components.count >= 2,
              let major = Int(components[0]),
              let minor = Int(components[1]) else {
            return nil
        }
        
        let patch = components.count > 2 ? Int(components[2]) ?? 0 : 0
        
        self.major = major
        self.minor = minor
        self.patch = patch
    }
    
    static func < (lhs: Version, rhs: Version) -> Bool {
        if lhs.major != rhs.major {
            return lhs.major < rhs.major
        }
        if lhs.minor != rhs.minor {
            return lhs.minor < rhs.minor
        }
        return lhs.patch < rhs.patch
    }
    
    var description: String {
        return "\(major).\(minor).\(patch)"
    }
}