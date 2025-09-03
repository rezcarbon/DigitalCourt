import Foundation

/// Represents the top-level structure for the Code Interpreter Module configuration.
struct CIMConfigContainer: Codable {
    let codeInterpreterModule: CIMConfiguration

    enum CodingKeys: String, CodingKey {
        case codeInterpreterModule = "CodeInterpreterModule"
    }
}

/// Defines the configuration for the Code Interpreter Module (CIM).
struct CIMConfiguration: Codable {
    let id: String
    let priority: Int
    let description: String
    let executionLayer: CIMExecutionLayer
    let autonomousFunctions: [String: String]
    let safetyMechanisms: [String: String]
    let analogy: String
    let advancedCapabilities: CIMAdvancedCapabilities?

    enum CodingKeys: String, CodingKey {
        case id, priority, description
        case executionLayer = "execution_layer"
        case autonomousFunctions = "autonomous_functions"
        case safetyMechanisms = "safety_mechanisms"
        case analogy
        case advancedCapabilities = "advanced_capabilities"
    }
}

/// Defines the execution environment for the CIM.
struct CIMExecutionLayer: Codable {
    let languages: [String]
    let sandboxing: String
    let bindings: [String: String]
}

// MARK: - Phase 3 Advanced Models

/// Advanced capabilities configuration for Phase 3 CIM
struct CIMAdvancedCapabilities: Codable {
    let autonomousReasoning: Bool
    let webInteraction: Bool
    let codeGeneration: Bool
    let patternRecognition: Bool
    let simulation: Bool
    let selfEvolution: Bool
    let multiModalProcessing: Bool
}

/// Execution statistics for monitoring CIM performance
struct CIMExecutionStats: Codable {
    var totalExecutions: Int = 0
    var successfulExecutions: Int = 0
    var errors: Int = 0
    var averageExecutionTime: Double = 0.0
    var completedTasks: Int = 0
    var autonomousOperations: Int = 0
    
    var successRate: Double {
        guard totalExecutions > 0 else { return 0.0 }
        return Double(successfulExecutions) / Double(totalExecutions)
    }
}

/// Resource utilization tracking
struct CIMResourceUtilization: Codable {
    var cpuUsage: Double = 0.0
    var memoryUsage: Double = 0.0
    var networkAvailable: Bool = true
    var diskSpace: Double = 0.0
    var activePromises: Int = 0
    var queuedTasks: Int = 0
}

/// Individual execution record
struct CIMExecution: Codable, Identifiable {
    var id = UUID()
    let script: String
    let result: String
    let duration: TimeInterval
    let success: Bool
    let timestamp: Date
    var metadata: [String: String] = [:]
}

/// Result of a CIM execution with metadata
struct CIMExecutionResult: Codable {
    let result: String
    let execution: CIMExecution
    var suggestions: [String] = []
    var optimizations: [String] = []
}

/// Autonomous task definition
struct AutonomousTask: Codable, Identifiable {
    var id = UUID()
    let objective: String
    let priority: TaskPriority
    let parameters: [String: String]
    let createdAt: Date
    let estimatedDuration: TimeInterval?
    let dependencies: [UUID]
    let status: TaskStatus
    
    enum TaskPriority: String, Codable, CaseIterable {
        case low, medium, high, critical
    }
    
    enum TaskStatus: String, Codable, CaseIterable {
        case pending, executing, completed, failed, cancelled
    }
}

/// Result of autonomous objective execution
struct CIMObjectiveResult: Codable {
    let success: Bool
    let objective: String
    let executionTime: TimeInterval
    let steps: [String]
    let results: [String]
    let error: String?
    var metadata: [String: String] = [:]
}

/// Execution plan for autonomous objectives
struct ExecutionPlan: Codable {
    let objective: String
    let steps: [ExecutionStep]
    let estimatedDuration: TimeInterval
    let requiredResources: [String]
    let riskAssessment: RiskAssessment
}

/// Individual step in execution plan
struct ExecutionStep: Codable, Identifiable {
    var id = UUID()
    let type: StepType
    let description: String
    let parameters: String
    let estimatedDuration: TimeInterval
    let dependencies: [UUID]
    
    enum StepType: String, Codable, CaseIterable {
        case computation, webScraping, apiCall, dataAnalysis, codeGeneration, problemSolving
    }
}

/// Risk assessment for autonomous operations
struct RiskAssessment: Codable {
    let level: RiskLevel
    let factors: [String]
    let mitigations: [String]
    let requiresApproval: Bool
    
    enum RiskLevel: String, Codable, CaseIterable {
        case low, medium, high, critical
    }
}

/// Evolution result from learning
struct CIMEvolutionResult: Codable {
    let newCapabilities: [String]
    let improvedSkills: [String]
    let optimizations: [String]
    var timestamp: Date = Date()
    var evolutionScore: Double = 0.0
}

/// Pattern recognition result
struct Pattern: Codable, Identifiable {
    var id = UUID()
    let type: String
    let confidence: Double
    let description: String
    let occurrences: Int
    let firstSeen: Date
    let lastSeen: Date
    let metadata: [String: String]
}

/// Knowledge synthesis result
struct KnowledgeSynthesis: Codable {
    let domain: String
    let insights: [Insight]
    let connections: [Connection]
    var timestamp: Date = Date()
    var confidenceScore: Double = 0.0
    
    struct Insight: Codable, Identifiable {
        var id = UUID()
        let description: String
        let confidence: Double
        let sources: [String]
        let implications: [String]
    }
    
    struct Connection: Codable, Identifiable {
        var id = UUID()
        let fromConcept: String
        let toConcept: String
        let relationshipType: String
        let strength: Double
        let evidence: [String]
    }
}

/// Simulation result
struct SimulationResult: Codable {
    let type: String
    let outcome: String
    let metrics: [String: Double]
    var timestamp: Date = Date()
    var iterations: Int = 0
    var convergence: Bool = false
}

/// Capability snapshot for export/analysis
struct CIMCapabilitySnapshot: Codable {
    let timestamp: Date
    let availableBindings: [String]
    let executionStats: CIMExecutionStats
    let resourceUtilization: CIMResourceUtilization
    let autonomousMode: Bool
    var version: String = "3.0.0"
    var features: [String] = [
        "Autonomous Reasoning",
        "Web Interaction",
        "Code Generation",
        "Pattern Recognition",
        "Simulation",
        "Self Evolution",
        "Multi-Modal Processing"
    ]
}

// MARK: - Supporting Engine Models

/// Web scraping configuration and results
struct WebScrapingResult: Codable {
    let url: String
    let content: String
    let metadata: [String: String]
    let timestamp: Date
    let success: Bool
    let error: String?
}

/// API orchestration result
struct APIOrchestrationResult: Codable {
    let endpoint: String
    let response: String
    let statusCode: Int
    let headers: [String: String]
    let timestamp: Date
    let duration: TimeInterval
}

/// Code analysis result
struct CodeAnalysisResult: Codable {
    let language: String
    let complexity: Int
    let issues: [CodeIssue]
    let suggestions: [String]
    let metrics: CodeMetrics
    
    struct CodeIssue: Codable, Identifiable {
        var id = UUID()
        let severity: Severity
        let description: String
        let line: Int?
        let suggestion: String?
        
        enum Severity: String, Codable, CaseIterable {
            case info, warning, error, critical
        }
    }
    
    struct CodeMetrics: Codable {
        let linesOfCode: Int
        let cyclomaticComplexity: Int
        let maintainabilityIndex: Double
        let technicalDebt: Double
    }
}

/// Problem solving context and result
struct ProblemSolvingResult: Codable {
    let problem: String
    let solution: String
    let approach: String
    let confidence: Double
    let alternatives: [String]
    let reasoning: [String]
    let timestamp: Date
}