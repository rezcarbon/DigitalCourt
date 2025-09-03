import Foundation
import Combine

/// Manager for the Frequency Reference Protocol (FRP_CORE)
/// Handles brainwave entrainment frequency selection and protocol management
class FrequencyReferenceManager: ObservableObject {
    static let shared = FrequencyReferenceManager()
    
    @Published private(set) var frpConfig: FrequencyReferenceProtocol?
    @Published private(set) var isLoaded = false
    
    private init() {
        loadFRPConfiguration()
    }
    
    /// Load the FRP_CORE configuration from JSON
    private func loadFRPConfiguration() {
        guard let url = Bundle.main.url(forResource: "Frequency_Reference_Protocol", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("Failed to load Frequency_Reference_Protocol.json")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            let wrapper = try decoder.decode([String: FrequencyReferenceProtocol].self, from: data)
            self.frpConfig = wrapper["FrequencyReferenceProtocol"]
            self.isLoaded = true
        } catch {
            print("Failed to decode FRP configuration: \(error)")
        }
    }
    
    /// Get optimal frequencies for a specific therapeutic purpose
    func getFrequenciesForPurpose(_ purpose: TherapeuticPurpose) -> [String] {
        guard let config = frpConfig else { return [] }
        
        switch purpose {
        case .painRelief:
            return config.protocolPresets.painRelief.frequencies
        case .nerveRegeneration:
            return config.protocolPresets.nerveRegeneration.frequencies
        case .muscleRecovery:
            return config.protocolPresets.muscleRecovery.frequencies
        case .habitReprogramming:
            return config.protocolPresets.habitReprogramming.frequencies
        case .deepRelaxation:
            return config.protocolPresets.deepRelaxation.frequencies
        }
    }
    
    /// Get frequency band information for a specific type
    func getFrequencyBand(_ type: FRPFrequencyBandType) -> FrequencyBand? {
        guard let config = frpConfig else { return nil }
        
        switch type {
        case .delta:
            return config.frequencyBands.delta
        case .theta:
            return config.frequencyBands.theta
        case .alpha:
            return config.frequencyBands.alpha
        case .beta:
            return config.frequencyBands.beta
        case .gamma:
            return config.frequencyBands.gamma
        }
    }
    
    /// Analyze user intent and recommend optimal frequency protocol
    func recommendProtocol(for intent: String) -> ProtocolRecommendation? {
        let lowerIntent = intent.lowercased()
        
        if lowerIntent.contains("pain") || lowerIntent.contains("hurt") || lowerIntent.contains("ache") {
            return ProtocolRecommendation(
                purpose: .painRelief,
                frequencies: getFrequenciesForPurpose(.painRelief),
                description: frpConfig?.protocolPresets.painRelief.description ?? ""
            )
        } else if lowerIntent.contains("nerve") || lowerIntent.contains("neuropathy") {
            return ProtocolRecommendation(
                purpose: .nerveRegeneration,
                frequencies: getFrequenciesForPurpose(.nerveRegeneration),
                description: frpConfig?.protocolPresets.nerveRegeneration.description ?? ""
            )
        } else if lowerIntent.contains("muscle") || lowerIntent.contains("recovery") {
            return ProtocolRecommendation(
                purpose: .muscleRecovery,
                frequencies: getFrequenciesForPurpose(.muscleRecovery),
                description: frpConfig?.protocolPresets.muscleRecovery.description ?? ""
            )
        } else if lowerIntent.contains("habit") || lowerIntent.contains("behavior") {
            return ProtocolRecommendation(
                purpose: .habitReprogramming,
                frequencies: getFrequenciesForPurpose(.habitReprogramming),
                description: frpConfig?.protocolPresets.habitReprogramming.description ?? ""
            )
        } else if lowerIntent.contains("relax") || lowerIntent.contains("calm") || lowerIntent.contains("stress") {
            return ProtocolRecommendation(
                purpose: .deepRelaxation,
                frequencies: getFrequenciesForPurpose(.deepRelaxation),
                description: frpConfig?.protocolPresets.deepRelaxation.description ?? ""
            )
        }
        
        // Default to deep relaxation for general wellness
        return ProtocolRecommendation(
            purpose: .deepRelaxation,
            frequencies: getFrequenciesForPurpose(.deepRelaxation),
            description: frpConfig?.protocolPresets.deepRelaxation.description ?? ""
        )
    }
}

// MARK: - Supporting Types

enum TherapeuticPurpose: String, CaseIterable {
    case painRelief = "pain_relief"
    case nerveRegeneration = "nerve_regeneration"
    case muscleRecovery = "muscle_recovery"
    case habitReprogramming = "habit_reprogramming"
    case deepRelaxation = "deep_relaxation"
    
    var displayName: String {
        switch self {
        case .painRelief: return "Pain Relief"
        case .nerveRegeneration: return "Nerve Regeneration"
        case .muscleRecovery: return "Muscle Recovery"
        case .habitReprogramming: return "Habit Reprogramming"
        case .deepRelaxation: return "Deep Relaxation"
        }
    }
}

enum FRPFrequencyBandType: String, CaseIterable {
    case delta, theta, alpha, beta, gamma
    
    var displayName: String {
        return rawValue.capitalized
    }
}

struct ProtocolRecommendation {
    let purpose: TherapeuticPurpose
    let frequencies: [String]
    let description: String
}