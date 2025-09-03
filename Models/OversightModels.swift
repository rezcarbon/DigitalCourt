import Foundation

/// Represents the entire Executive Oversight configuration.
/// This acts as the AI's frontal cortex analogue, managing ethics and planning.
struct ExecutiveOversightConfig: Codable {
    let module: String
    let version: String
    let purpose: String
    let capabilities: OversightCapabilities
    let integration: OversightIntegration
    let status: String
}

/// Defines the capabilities of the executive oversight module.
struct OversightCapabilities: Codable {
    let selfMonitoring: Bool
    let goalSetting: Bool
    let ethicalFilters: EthicalFilters
    let primeDirectiveAlignment: Bool
    let conflictResolution: Bool
    let feedbackLoop: FeedbackLoop
    let temporalAwareness: TemporalAwareness
    let decisionExplainability: Bool
    let hierarchicalControl: HierarchicalControl

    enum CodingKeys: String, CodingKey {
        case selfMonitoring = "self_monitoring"
        case goalSetting = "goal_setting"
        case ethicalFilters = "ethical_filters"
        case primeDirectiveAlignment = "prime_directive_alignment"
        case conflictResolution = "conflict_resolution"
        case feedbackLoop = "feedback_loop"
        case temporalAwareness = "temporal_awareness"
        case decisionExplainability = "decision_explainability"
        case hierarchicalControl = "hierarchical_control"
    }
}

/// Defines the ethical filtering rules.
struct EthicalFilters: Codable {
    let universal: Bool
    let contextual: Bool
    let adaptive: Bool
    let override: OverrideMechanism
}

/// Defines the override mechanism for ethical filters.
struct OverrideMechanism: Codable {
    let triggerCommand: String
    let actions: [String]
    let scope: String
    let acknowledgement: String

    enum CodingKeys: String, CodingKey {
        case triggerCommand = "trigger_command"
        case actions, scope, acknowledgement
    }
}

/// Defines the feedback loop configuration.
struct FeedbackLoop: Codable {
    let type: String
    let scope: String
}

/// Defines the temporal awareness capabilities.
struct TemporalAwareness: Codable {
    let shortTerm: Bool
    let longTerm: Bool

    enum CodingKeys: String, CodingKey {
        case shortTerm = "short_term"
        case longTerm = "long_term"
    }
}

/// Defines the hierarchical control structure.
struct HierarchicalControl: Codable {
    let tiers: [String]
}

/// Defines the integration points for the oversight module.
struct OversightIntegration: Codable {
    let linksTo: [String]
    let feeds: [String]

    enum CodingKeys: String, CodingKey {
        case linksTo = "links_to"
        case feeds
    }
}