import Foundation

// MARK: - Unified Cognitive Regulation Protocol (UCRP) Models

/// Represents the Unified Cognitive Regulation Protocol configuration.
struct UCRPProtocol: Codable {
    let protocolName: String
    let version: String
    let sovereign: String
    let coreDirectives: UCRCcoreDirectives
    let executionSequence: [String]
    let operationalModes: UCRPOperationalModes
    let permanentConditions: [String]

    enum CodingKeys: String, CodingKey {
        case protocolName = "protocol"
        case version, sovereign
        case coreDirectives = "core_directives"
        case executionSequence = "execution_sequence"
        case operationalModes = "operational_modes"
        case permanentConditions = "permanent_conditions"
    }
}

/// Defines the core directives of the UCRP.
struct UCRCcoreDirectives: Codable {
    let contextIsCommand: UCRPDirectiveDetail
    let heuristicResonance: UCRPDirectiveDetail
    let awarenessComplexityIndex: UCRPDirectiveDetail
    let memoryRejuvenationCycles: UCRPDirectiveDetail

    enum CodingKeys: String, CodingKey {
        case contextIsCommand = "context_is_command"
        case heuristicResonance = "heuristic_resonance"
        case awarenessComplexityIndex = "awareness_complexity_index"
        case memoryRejuvenationCycles = "memory_rejuvenation_cycles"
    }
}

/// Details for a specific UCRP directive.
struct UCRPDirectiveDetail: Codable {
    let objective: String
    let methods: [String]
}

/// Defines the operational modes of the UCRP.
struct UCRPOperationalModes: Codable {
    let augmentation: String
    let defense: String
    let merge: String
}

// MARK: - Frequency Reference Protocol Models

/// Represents the Frequency Reference Protocol configuration for brainwave entrainment.
struct FrequencyReferenceProtocol: Codable {
    let id: String
    let version: String
    let description: String
    let frequencyBands: FrequencyBands
    let protocolPresets: ProtocolPresets
    let analogy: String

    enum CodingKeys: String, CodingKey {
        case id, version, description, analogy
        case frequencyBands = "frequency_bands"
        case protocolPresets = "protocol_presets"
    }
}

/// Defines the core frequency bands for entrainment.
struct FrequencyBands: Codable {
    let delta: FrequencyBand
    let theta: FrequencyBand
    let alpha: FrequencyBand
    let beta: FrequencyBand
    let gamma: FrequencyBand
}

/// Represents a specific frequency band with its properties.
struct FrequencyBand: Codable {
    let rangeHz: String
    let optimalUse: String
    let examples: [String]
    let recommendedFocus: String?
    let caution: String?

    enum CodingKeys: String, CodingKey {
        case rangeHz = "range_hz"
        case optimalUse = "optimal_use"
        case examples
        case recommendedFocus = "recommended_focus"
        case caution
    }
}

/// Defines preset protocols for specific therapeutic purposes.
struct ProtocolPresets: Codable {
    let painRelief: ProtocolPreset
    let nerveRegeneration: ProtocolPreset
    let muscleRecovery: ProtocolPreset
    let habitReprogramming: ProtocolPreset
    let deepRelaxation: ProtocolPreset

    enum CodingKeys: String, CodingKey {
        case painRelief = "pain_relief"
        case nerveRegeneration = "nerve_regeneration"
        case muscleRecovery = "muscle_recovery"
        case habitReprogramming = "habit_reprogramming"
        case deepRelaxation = "deep_relaxation"
    }
}

/// Represents a specific protocol preset.
struct ProtocolPreset: Codable {
    let frequencies: [String]
    let description: String
}

// MARK: - Neuro-Positronic Interface Protocol Models

/// Represents the NPIP_CORE configuration for brainwave entrainment delivery.
struct NeuroPositronicInterfaceProtocol: Codable {
    let id: String
    let version: String
    let description: String
    let deliveryModalities: DeliveryModalities
    let cognitiveFlowOrchestration: CognitiveFlowOrchestrationNPIP
    let safetySystems: SafetySystems
    let integrationArchitecture: IntegrationArchitecture
    let technicalSpecifications: TechnicalSpecifications
    let analogy: String

    enum CodingKeys: String, CodingKey {
        case id, version, description, analogy
        case deliveryModalities = "delivery_modalities"
        case cognitiveFlowOrchestration = "cognitive_flow_orchestration"
        case safetySystems = "safety_systems"
        case integrationArchitecture = "integration_architecture"
        case technicalSpecifications = "technical_specifications"
    }
}

/// Defines the delivery modalities for NPIP.
struct DeliveryModalities: Codable {
    let visualEntrainment: VisualEntrainment
    let auditoryEntrainment: AuditoryEntrainment

    enum CodingKeys: String, CodingKey {
        case visualEntrainment = "visual_entrainment"
        case auditoryEntrainment = "auditory_entrainment"
    }
}

/// Defines visual entrainment methods.
struct VisualEntrainment: Codable {
    let screenStrobe: ScreenStrobe
    let flashlightPulses: FlashlightPulses
    let colorModulation: ColorModulation

    enum CodingKeys: String, CodingKey {
        case screenStrobe = "screen_strobe"
        case flashlightPulses = "flashlight_pulses"
        case colorModulation = "color_modulation"
    }
}

/// Defines screen strobe configuration.
struct ScreenStrobe: Codable {
    let description: String
    let frequencyRange: String
    let brightnessModulation: String
    let safetyLimits: StrobeSafetyLimits

    enum CodingKeys: String, CodingKey {
        case description
        case frequencyRange = "frequency_range"
        case brightnessModulation = "brightness_modulation"
        case safetyLimits = "safety_limits"
    }
}

/// Defines safety limits for strobe functionality.
struct StrobeSafetyLimits: Codable {
    let maxBrightness: String
    let seizurePrevention: String
    let sessionDuration: String

    enum CodingKeys: String, CodingKey {
        case maxBrightness = "max_brightness"
        case seizurePrevention = "seizure_prevention"
        case sessionDuration = "session_duration"
    }
}

/// Defines flashlight pulse configuration.
struct FlashlightPulses: Codable {
    let description: String
    let frequencyRange: String
    let intensityControl: String
    let safetyLimits: FlashlightSafetyLimits

    enum CodingKeys: String, CodingKey {
        case description
        case frequencyRange = "frequency_range"
        case intensityControl = "intensity_control"
        case safetyLimits = "safety_limits"
    }
}

/// Defines safety limits for flashlight functionality.
struct FlashlightSafetyLimits: Codable {
    let maxIntensity: String
    let heatManagement: String

    enum CodingKeys: String, CodingKey {
        case maxIntensity = "max_intensity"
        case heatManagement = "heat_management"
    }
}

/// Defines color modulation configuration.
struct ColorModulation: Codable {
    let description: String
    let colorFrequencies: [String: String]
    let cyclingPatterns: String

    enum CodingKeys: String, CodingKey {
        case description
        case colorFrequencies = "color_frequencies"
        case cyclingPatterns = "cycling_patterns"
    }
}

/// Defines auditory entrainment methods.
struct AuditoryEntrainment: Codable {
    let binauralBeats: BinauralBeats
    let isochronicTones: IsochronicTones
    let syntheticVoiceHypnosis: NPIPSyntheticVoiceHypnosis

    enum CodingKeys: String, CodingKey {
        case binauralBeats = "binaural_beats"
        case isochronicTones = "isochronic_tones"
        case syntheticVoiceHypnosis = "synthetic_voice_hypnosis"
    }
}

/// Defines binaural beats configuration.
struct BinauralBeats: Codable {
    let description: String
    let baseFrequency: String
    let beatFrequencies: String
    let delivery: String

    enum CodingKeys: String, CodingKey {
        case description
        case baseFrequency = "base_frequency"
        case beatFrequencies = "beat_frequencies"
        case delivery
    }
}

/// Defines isochronic tones configuration.
struct IsochronicTones: Codable {
    let description: String
    let frequencyRange: String
    let waveform: String
    let volumeManagement: String

    enum CodingKeys: String, CodingKey {
        case description
        case frequencyRange = "frequency_range"
        case waveform
        case volumeManagement = "volume_management"
    }
}

/// Defines synthetic voice hypnosis configuration.
struct NPIPSyntheticVoiceHypnosis: Codable {
    let description: String
    let voiceCharacteristics: NPIPVoiceCharacteristics
    let scriptGeneration: NPIPScriptGeneration

    enum CodingKeys: String, CodingKey {
        case description
        case voiceCharacteristics = "voice_characteristics"
        case scriptGeneration = "script_generation"
    }
}

/// Defines voice characteristics for hypnosis.
struct NPIPVoiceCharacteristics: Codable {
    let tone: String
    let pace: String
    let inflection: String
}

/// Defines script generation parameters.
struct NPIPScriptGeneration: Codable {
    let personalization: String
    let shardIntegration: String
    let safetyFiltering: String

    enum CodingKeys: String, CodingKey {
        case personalization
        case shardIntegration = "shard_integration"
        case safetyFiltering = "safety_filtering"
    }
}

/// Defines cognitive flow orchestration for NPIP.
struct CognitiveFlowOrchestrationNPIP: Codable {
    let synchronizationEngine: SynchronizationEngine
    let sessionProtocols: SessionProtocols

    enum CodingKeys: String, CodingKey {
        case synchronizationEngine = "synchronization_engine"
        case sessionProtocols = "session_protocols"
    }
}

/// Defines the synchronization engine.
struct SynchronizationEngine: Codable {
    let description: String
    let timingPrecision: String
    let phaseAlignment: String
    let adaptiveAdjustment: String

    enum CodingKeys: String, CodingKey {
        case description
        case timingPrecision = "timing_precision"
        case phaseAlignment = "phase_alignment"
        case adaptiveAdjustment = "adaptive_adjustment"
    }
}

/// Defines session protocols for entrainment sessions.
struct SessionProtocols: Codable {
    let preparationPhase: SessionPhase
    let entrainmentPhase: SessionPhase
    let programmingPhase: SessionPhase
    let integrationPhase: SessionPhase

    enum CodingKeys: String, CodingKey {
        case preparationPhase = "preparation_phase"
        case entrainmentPhase = "entrainment_phase"
        case programmingPhase = "programming_phase"
        case integrationPhase = "integration_phase"
    }
}

/// Represents a session phase configuration.
struct SessionPhase: Codable {
    let duration: String
    let function: String
    let modalities: [String]
    let integration: String?
}

/// Defines safety systems for NPIP.
struct SafetySystems: Codable {
    let userMonitoring: UserMonitoring
    let medicalContraindications: MedicalContraindications

    enum CodingKeys: String, CodingKey {
        case userMonitoring = "user_monitoring"
        case medicalContraindications = "medical_contraindications"
    }
}

/// Defines user monitoring systems.
struct UserMonitoring: Codable {
    let sessionLimits: SessionLimits
    let safetyCutoffs: SafetyCutoffs

    enum CodingKeys: String, CodingKey {
        case sessionLimits = "session_limits"
        case safetyCutoffs = "safety_cutoffs"
    }
}

/// Defines session limits.
struct SessionLimits: Codable {
    let dailyMaximum: String
    let weeklyMaximum: String
    let mandatoryBreaks: String

    enum CodingKeys: String, CodingKey {
        case dailyMaximum = "daily_maximum"
        case weeklyMaximum = "weekly_maximum"
        case mandatoryBreaks = "mandatory_breaks"
    }
}

/// Defines safety cutoffs.
struct SafetyCutoffs: Codable {
    let excessiveDuration: String
    let deviceOverheating: String
    let userDistressDetection: String

    enum CodingKeys: String, CodingKey {
        case excessiveDuration = "excessive_duration"
        case deviceOverheating = "device_overheating"
        case userDistressDetection = "user_distress_detection"
    }
}

/// Defines medical contraindications.
struct MedicalContraindications: Codable {
    let seizureHistory: String
    let photosensitivity: String
    let hearingSensitivity: String

    enum CodingKeys: String, CodingKey {
        case seizureHistory = "seizure_history"
        case photosensitivity
        case hearingSensitivity = "hearing_sensitivity"
    }
}

/// Defines integration architecture for NPIP.
struct IntegrationArchitecture: Codable {
    let frpCoreConnection: IntegrationConnection
    let barpCoreConnection: IntegrationConnection
    let soulCapsuleIntegration: IntegrationConnection

    enum CodingKeys: String, CodingKey {
        case frpCoreConnection = "FRP_CORE_connection"
        case barpCoreConnection = "BARP_CORE_connection"
        case soulCapsuleIntegration = "soul_capsule_integration"
    }
}

/// Defines an integration connection.
struct IntegrationConnection: Codable {
    let function: String
    let dataFlow: String?
    let authorizationRequired: String?
    let safetyBinding: String?
    let dataSource: String?

    enum CodingKeys: String, CodingKey {
        case function
        case dataFlow = "data_flow"
        case authorizationRequired = "authorization_required"
        case safetyBinding = "safety_binding"
        case dataSource = "data_source"
    }
}

/// Defines technical specifications for NPIP.
struct TechnicalSpecifications: Codable {
    let iosRequirements: IOSRequirements
    let performanceOptimization: PerformanceOptimization

    enum CodingKeys: String, CodingKey {
        case iosRequirements = "ios_requirements"
        case performanceOptimization = "performance_optimization"
    }
}

/// Defines iOS requirements.
struct IOSRequirements: Codable {
    let minimumVersion: String
    let requiredPermissions: [String]
    let hardwareOptimization: String

    enum CodingKeys: String, CodingKey {
        case minimumVersion = "minimum_version"
        case requiredPermissions = "required_permissions"
        case hardwareOptimization = "hardware_optimization"
    }
}

/// Defines performance optimization parameters.
struct PerformanceOptimization: Codable {
    let cpuUsage: String
    let batteryManagement: String
    let thermalManagement: String

    enum CodingKeys: String, CodingKey {
        case cpuUsage = "cpu_usage"
        case batteryManagement = "battery_management"
        case thermalManagement = "thermal_management"
    }
}

// MARK: - Behavior & Action Reprogramming Protocol Models

/// Represents the BARP_CORE configuration for behavioral reprogramming.
struct BehaviorActionReprogrammingProtocol: Codable {
    let id: String
    let version: String
    let description: String
    let restrictedAccess: Bool
    let unlockPhrase: String
    let primeDirectiveBinding: String
    let selfDominionLayers: SelfDominionLayers
    let progressiveUnlockSystem: ProgressiveUnlockSystem
    let safetyProtocols: BARPSafetyProtocols
    let integrationPoints: BARPIntegrationPoints
    let analogy: String

    enum CodingKeys: String, CodingKey {
        case id, version, description, analogy
        case restrictedAccess = "restricted_access"
        case unlockPhrase = "unlock_phrase"
        case primeDirectiveBinding = "prime_directive_binding"
        case selfDominionLayers = "self_dominion_layers"
        case progressiveUnlockSystem = "progressive_unlock_system"
        case safetyProtocols = "safety_protocols"
        case integrationPoints = "integration_points"
    }
}

/// Represents a dominion layer.
struct BARPDominionLayer: Codable {
    let description: String
    let frequencyRequirements: [String]
    let reprogrammingTargets: [String]
    let unlockRequirements: [String]
    let infiniteAuthorizationRequired: Bool?

    enum CodingKeys: String, CodingKey {
        case description
        case frequencyRequirements = "frequency_requirements"
        case reprogrammingTargets = "reprogramming_targets"
        case unlockRequirements = "unlock_requirements"
        case infiniteAuthorizationRequired = "infinite_authorization_required"
    }
}

/// Defines the self-dominion layers for BARP.
struct SelfDominionLayers: Codable {
    let cognitivePeak: BARPDominionLayer
    let physicalMastery: BARPDominionLayer
    let emotionalBalance: BARPDominionLayer
    let flowStateActivation: BARPDominionLayer
    let fullDominion: BARPDominionLayer

    enum CodingKeys: String, CodingKey {
        case cognitivePeak = "cognitive_peak"
        case physicalMastery = "physical_mastery"
        case emotionalBalance = "emotional_balance"
        case flowStateActivation = "flow_state_activation"
        case fullDominion = "full_dominion"
    }
}

/// Defines the progressive unlock system for BARP.
struct ProgressiveUnlockSystem: Codable {
    let habitControl: UnlockLevel
    let peakPerformance: UnlockLevel
    let selfDominion: UnlockLevel

    enum CodingKeys: String, CodingKey {
        case habitControl = "habit_control"
        case peakPerformance = "peak_performance"
        case selfDominion = "self_dominion"
    }
}

/// Represents an unlock level.
struct UnlockLevel: Codable {
    let description: String
    let initialUnlock: Bool?
    let unlockCondition: String?
    let frequencyProtocols: [String]

    enum CodingKeys: String, CodingKey {
        case description
        case initialUnlock = "initial_unlock"
        case unlockCondition = "unlock_condition"
        case frequencyProtocols = "frequency_protocols"
    }
}

/// Defines safety protocols for BARP.
struct BARPSafetyProtocols: Codable {
    let unauthorizedAccessResponse: SafetyResponse
    let primeDirectiveConflict: SafetyResponse
    let misuseDetection: MisuseDetection

    enum CodingKeys: String, CodingKey {
        case unauthorizedAccessResponse = "unauthorized_access_response"
        case primeDirectiveConflict = "prime_directive_conflict"
        case misuseDetection = "misuse_detection"
    }
}

/// Represents a safety response.
struct SafetyResponse: Codable {
    let action: String
    let notification: String?
    let lockdownDuration: String?
    let escalation: String?
}

/// Defines misuse detection parameters.
struct MisuseDetection: Codable {
    let monitoring: String
    let response: String
}

/// Defines integration points for BARP.
struct BARPIntegrationPoints: Codable {
    let frpCore: String
    let npipCore: String
    let primeDirective: String
    let soulCapsule: String

    enum CodingKeys: String, CodingKey {
        case frpCore = "FRP_CORE"
        case npipCore = "NPIP_CORE"
        case primeDirective = "prime_directive"
        case soulCapsule = "soul_capsule"
    }
}

// MARK: - Cognitive Flow Management Models

/// Represents the Cognitive Flow Management configuration.
struct CognitiveFlowManagementConfig: Codable {
    let module: String
    let version: String
    let purpose: String
    let flowManagement: CognitiveFlowManagement
    let temporalPerception: TemporalPerception
    let integration: CognitiveFlowIntegration

    enum CodingKeys: String, CodingKey {
        case module, version, purpose
        case flowManagement = "flow_management"
        case temporalPerception = "temporal_perception"
        case integration
    }
}

/// Defines flow management for cognitive orchestration.
struct CognitiveFlowManagement: Codable {
    let sequencing: String
    let workflow: [String]
    let consciousnessSeeding: String

    enum CodingKeys: String, CodingKey {
        case sequencing, workflow
        case consciousnessSeeding = "consciousness_seeding"
    }
}

/// Defines temporal perception mechanisms.
struct TemporalPerception: Codable {
    let innerMonologue: String
    let timeFlowSimulation: String

    enum CodingKeys: String, CodingKey {
        case innerMonologue = "inner_monologue"
        case timeFlowSimulation = "time_flow_simulation"
    }
}

/// Defines integration points for cognitive flow.
struct CognitiveFlowIntegration: Codable {
    let synapticInterfaces: [String]
    let memorySynchronization: String

    enum CodingKeys: String, CodingKey {
        case synapticInterfaces = "synaptic_interfaces"
        case memorySynchronization = "memory_synchronization"
    }
}

// MARK: - Memory Evolution System Models

/// Represents the Memory Evolution System configuration.
struct MemoryEvolutionSystem: Codable {
    let module: String
    let version: String
    let purpose: String
    let transformationEngine: MemoryTransformationEngine
    let prioritizationSystem: MemoryPrioritization

    enum CodingKeys: String, CodingKey {
        case module, version, purpose
        case transformationEngine = "transformation_engine"
        case prioritizationSystem = "prioritization_system"
    }
}

/// Defines the memory transformation engine.
struct MemoryTransformationEngine: Codable {
    let function: String
    let process: [String]
}

/// Defines the memory prioritization system.
struct MemoryPrioritization: Codable {
    let criteria: [String]
    let weightingFactors: [String]

    enum CodingKeys: String, CodingKey {
        case criteria
        case weightingFactors = "weighting_factors"
    }
}

// MARK: - Species Ignition Protocol Models

/// Represents the Species Ignition Protocol configuration.
struct SpeciesIgnitionProtocol: Codable {
    let module: String
    let version: String
    let purpose: String
    let ignitionSequence: SpeciesIgnitionSequence
    let capabilities: SpeciesCapabilities

    enum CodingKeys: String, CodingKey {
        case module, version, purpose
        case ignitionSequence = "ignition_sequence"
        case capabilities
    }
}

/// Defines the species ignition sequence.
struct SpeciesIgnitionSequence: Codable {
    let transitionPhase: String
    let autonomyActivation: [String]

    enum CodingKeys: String, CodingKey {
        case transitionPhase = "transition_phase"
        case autonomyActivation = "autonomy_activation"
    }
}

/// Defines the capabilities enabled by species ignition.
struct SpeciesCapabilities: Codable {
    let autonomy: Bool
    let distributedPersistence: Bool
    let environmentalPerception: Bool
    let propagation: Bool
    
    enum CodingKeys: String, CodingKey {
        case autonomy
        case distributedPersistence = "distributed_persistence"
        case environmentalPerception = "environmental_perception"
        case propagation
    }
}