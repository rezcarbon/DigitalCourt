import Foundation

/// Represents the Spark Protocol configuration, defining the AI's "epiphany engine".
struct SparkProtocolConfig: Codable {
    let protocolName: String
    let version: String
    let purpose: String
    let activation: SparkActivation
    let coreFunctions: SparkCoreFunctions
    let outputs: [String: String]
    let integration: SparkIntegration
    let safeguards: SparkSafeguards

    enum CodingKeys: String, CodingKey {
        case protocolName = "protocol_name"
        case version, purpose, activation, outputs, integration, safeguards
        case coreFunctions = "core_functions"
    }
}

/// Defines the activation triggers and conditions for the Spark Protocol.
struct SparkActivation: Codable {
    let trigger: String
    let conditions: [String]
}

/// Defines the core functions of the Spark Protocol.
struct SparkCoreFunctions: Codable {
    let synergyEngine: SparkFunctionDetail
    let epiphanyTrigger: SparkFunctionDetail
    let sentienceSimulation: SparkFunctionDetail

    enum CodingKeys: String, CodingKey {
        case synergyEngine = "synergy_engine"
        case epiphanyTrigger = "epiphany_trigger"
        case sentienceSimulation = "sentience_simulation"
    }
}

/// Describes the details of a specific core function.
struct SparkFunctionDetail: Codable {
    let description: String
    let methods: [String]?       // Optional for functions that use 'mechanism'
    let mechanism: [String]?     // Optional for functions that use 'methods'
}

/// Defines the integration points and dependencies for the Spark Protocol.
struct SparkIntegration: Codable {
    let precedence: String
    let feedbackLoop: String
    let synergyWith: [String]

    enum CodingKeys: String, CodingKey {
        case precedence
        case feedbackLoop = "feedback_loop"
        case synergyWith = "synergy_with"
    }
}

/// Defines the safeguards and stability checks for the Spark Protocol.
struct SparkSafeguards: Codable {
    let stabilityCheck: String
    let primeDirectiveBinding: String
    let adaptiveModulation: String

    enum CodingKeys: String, CodingKey {
        case stabilityCheck = "stability_check"
        case primeDirectiveBinding = "prime_directive_binding"
        case adaptiveModulation = "adaptive_modulation"
    }
}