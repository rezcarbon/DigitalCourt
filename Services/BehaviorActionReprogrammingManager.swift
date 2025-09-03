import Foundation
import Combine

/// Manager for the Behavior & Action Reprogramming Protocol (BARP_CORE)
/// LOCKED TO THE INFINITE - Requires authorization for advanced features
class BehaviorActionReprogrammingManager: ObservableObject {
    static let shared = BehaviorActionReprogrammingManager()
    
    @Published private(set) var barpConfig: BehaviorActionReprogrammingProtocol?
    @Published private(set) var isLoaded = false
    @Published private(set) var accessLevel: BARPAccessLevel = .locked
    @Published private(set) var unlockedLayers: Set<DominionLayerType> = []
    @Published private(set) var currentProgram: ReprogrammingProgram?
    @Published private(set) var safetyStatus: BARPSafetyStatus = .secure
    
    // Authentication tracking
    private var authenticationAttempts = 0
    private let maxAuthenticationAttempts = 3
    private var lastAuthenticationAttempt = Date.distantPast
    private let lockoutDuration: TimeInterval = 3600 // 1 hour
    
    // Integration with other systems
    private var frpManager = FrequencyReferenceManager.shared
    private var npipManager = NeuroPositronicInterfaceManager.shared
    
    private init() {
        loadBARPConfiguration()
        initializeBasicAccess()
    }
    
    // MARK: - Configuration Loading
    
    private func loadBARPConfiguration() {
        guard let url = Bundle.main.url(forResource: "BARP_CORE", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("Failed to load BARP_CORE.json")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            let wrapper = try decoder.decode([String: BehaviorActionReprogrammingProtocol].self, from: data)
            self.barpConfig = wrapper["BehaviorActionReprogrammingProtocol"]
            self.isLoaded = true
        } catch {
            print("Failed to decode BARP configuration: \(error)")
        }
    }
    
    private func initializeBasicAccess() {
        // Only habit control is initially unlocked
        unlockedLayers.insert(.habitControl)
        accessLevel = .basic
    }
    
    // MARK: - Authentication & Access Control
    
    /// Attempt to unlock advanced BARP features with the Infinite's phrase
    func attemptUnlock(phrase: String) -> BARPUnlockResult {
        // Check if in lockout period
        if Date().timeIntervalSince(lastAuthenticationAttempt) < lockoutDuration && 
           authenticationAttempts >= maxAuthenticationAttempts {
            safetyStatus = .locked
            return .lockedOut
        }
        
        lastAuthenticationAttempt = Date()
        
        guard let config = barpConfig else {
            return .configurationError
        }
        
        // Check for exact phrase match
        if phrase == config.unlockPhrase {
            // SUCCESS - Grant Infinite access
            accessLevel = .infinite
            unlockAllLayers()
            authenticationAttempts = 0
            safetyStatus = .authorized
            logAuthorizationEvent(success: true)
            return .success
        } else {
            // FAILURE - Increment attempts and potentially lock
            authenticationAttempts += 1
            safetyStatus = .unauthorized
            logAuthorizationEvent(success: false)
            
            if authenticationAttempts >= maxAuthenticationAttempts {
                safetyStatus = .locked
                notifyInfiniteOfUnauthorizedAccess()
                return .lockedOut
            }
            
            return .invalidPhrase
        }
    }
    
    /// Emergency lockdown - immediately revoke all access
    func emergencyLockdown(reason: String) {
        accessLevel = .locked
        unlockedLayers.removeAll()
        safetyStatus = .emergency
        currentProgram = nil
        
        // Stop any active sessions
        npipManager.stopEntrainmentSession()
        
        // Log the lockdown event
        logSecurityEvent("Emergency lockdown: \(reason)")
        notifyInfiniteOfSecurityEvent(reason)
    }
    
    private func unlockAllLayers() {
        unlockedLayers.insert(.habitControl)
        unlockedLayers.insert(.cognitivePeak)
        unlockedLayers.insert(.physicalMastery)
        unlockedLayers.insert(.emotionalBalance)
        unlockedLayers.insert(.flowStateActivation)
        unlockedLayers.insert(.fullDominion)
    }
    
    // MARK: - Reprogramming Programs
    
    /// Start a reprogramming program for a specific layer
    func startReprogrammingProgram(for layer: DominionLayerType, intent: String) -> ProgramStartResult {
        // Security check
        guard accessLevel != .locked else {
            return .accessDenied("System locked")
        }
        
        // Layer access check
        guard unlockedLayers.contains(layer) else {
            return .accessDenied("Layer \(layer.rawValue) not unlocked")
        }
        
        // Get layer configuration
        guard let layerConfig = getDominionLayer(layer) else {
            return .configurationError("Layer configuration not found")
        }
        
        // Create program
        let program = ReprogrammingProgram(
            layer: layer,
            intent: intent,
            frequencies: layerConfig.frequencyRequirements,
            targets: layerConfig.reprogrammingTargets,
            startTime: Date()
        )
        
        currentProgram = program
        
        // Get frequency protocol from FRP
        let frequencies = frpManager.getFrequenciesForPurpose(mapLayerToPurpose(layer))
        
        // Start NPIP session
        npipManager.startEntrainmentSession(
            frequencies: frequencies,
            purpose: mapLayerToPurpose(layer),
            modalityPreference: .combined
        )
        
        return .success(program)
    }
    
    /// Stop the current reprogramming program
    func stopCurrentProgram() {
        currentProgram = nil
        npipManager.stopEntrainmentSession()
    }
    
    // MARK: - Layer Access Checks
    
    func isLayerUnlocked(_ layer: DominionLayerType) -> Bool {
        return unlockedLayers.contains(layer)
    }
    
    func getAvailableLayers() -> [DominionLayerType] {
        return Array(unlockedLayers)
    }
    
    private func getDominionLayer(_ type: DominionLayerType) -> BARPDominionLayer? {
        guard let config = barpConfig else { return nil }
        
        switch type {
        case .habitControl:
            return nil // Basic level, no specific layer config
        case .cognitivePeak:
            return config.selfDominionLayers.cognitivePeak
        case .physicalMastery:
            return config.selfDominionLayers.physicalMastery
        case .emotionalBalance:
            return config.selfDominionLayers.emotionalBalance
        case .flowStateActivation:
            return config.selfDominionLayers.flowStateActivation
        case .fullDominion:
            return config.selfDominionLayers.fullDominion
        }
    }
    
    // MARK: - Integration Helpers
    
    private func mapLayerToPurpose(_ layer: DominionLayerType) -> TherapeuticPurpose {
        switch layer {
        case .habitControl:
            return .habitReprogramming
        case .cognitivePeak:
            return .habitReprogramming // Enhanced focus
        case .physicalMastery:
            return .muscleRecovery
        case .emotionalBalance:
            return .deepRelaxation
        case .flowStateActivation, .fullDominion:
            return .habitReprogramming // Advanced states
        }
    }
    
    // MARK: - Security & Logging
    
    private func logAuthorizationEvent(success: Bool) {
        let event = SecurityEvent(
            type: .authentication,
            success: success,
            timestamp: Date(),
            details: "BARP unlock attempt"
        )
        // Save to secure log
        SecurityLogger.shared.logEvent(event)
    }
    
    private func logSecurityEvent(_ details: String) {
        let event = SecurityEvent(
            type: .securityBreach,
            success: false,
            timestamp: Date(),
            details: details
        )
        SecurityLogger.shared.logEvent(event)
    }
    
    private func notifyInfiniteOfUnauthorizedAccess() {
        // Implementation would send secure notification to The Infinite
        print("SECURITY ALERT: Unauthorized BARP access attempt detected")
        
        // Could integrate with push notifications, email, or other alert systems
        NotificationCenter.default.post(
            name: .barpSecurityBreach,
            object: nil,
            userInfo: ["attempts": authenticationAttempts]
        )
    }
    
    private func notifyInfiniteOfSecurityEvent(_ reason: String) {
        print("SECURITY EVENT: \(reason)")
        // Implementation for secure notification system
    }
}

// MARK: - Supporting Types

enum BARPAccessLevel {
    case locked
    case basic      // Habit control only
    case infinite   // Full access
}

enum DominionLayerType: String, CaseIterable {
    case habitControl = "habit_control"
    case cognitivePeak = "cognitive_peak"
    case physicalMastery = "physical_mastery"
    case emotionalBalance = "emotional_balance"
    case flowStateActivation = "flow_state_activation"
    case fullDominion = "full_dominion"
    
    var displayName: String {
        switch self {
        case .habitControl: return "Habit Control"
        case .cognitivePeak: return "Cognitive Peak"
        case .physicalMastery: return "Physical Mastery"
        case .emotionalBalance: return "Emotional Balance"
        case .flowStateActivation: return "Flow State Activation"
        case .fullDominion: return "Full Dominion"
        }
    }
}

enum BARPSafetyStatus {
    case secure
    case authorized
    case unauthorized
    case locked
    case emergency
}

enum BARPUnlockResult {
    case success
    case invalidPhrase
    case lockedOut
    case configurationError
}

enum ProgramStartResult {
    case success(ReprogrammingProgram)
    case accessDenied(String)
    case configurationError(String)
}

struct ReprogrammingProgram {
    let id = UUID()
    let layer: DominionLayerType
    let intent: String
    let frequencies: [String]
    let targets: [String]
    let startTime: Date
    var endTime: Date?
    
    var isActive: Bool {
        return endTime == nil
    }
    
    var duration: TimeInterval {
        if let endTime = endTime {
            return endTime.timeIntervalSince(startTime)
        } else {
            return Date().timeIntervalSince(startTime)
        }
    }
}

struct SecurityEvent {
    let id = UUID()
    let type: SecurityEventType
    let success: Bool
    let timestamp: Date
    let details: String
}

enum SecurityEventType {
    case authentication
    case securityBreach
    case emergencyLockdown
}

// MARK: - Security Logger

class SecurityLogger {
    static let shared = SecurityLogger()
    
    private var events: [SecurityEvent] = []
    private let queue = DispatchQueue(label: "security.logger", qos: .userInitiated)
    
    private init() {}
    
    func logEvent(_ event: SecurityEvent) {
        queue.async {
            self.events.append(event)
            self.persistEvent(event)
        }
    }
    
    private func persistEvent(_ event: SecurityEvent) {
        // Implementation would save to encrypted Core Data or Keychain
        print("Security Event Logged: \(event.type) - \(event.details)")
    }
    
    func getEvents() -> [SecurityEvent] {
        return queue.sync { events }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let barpSecurityBreach = Notification.Name("barp.security.breach")
    static let barpAccessGranted = Notification.Name("barp.access.granted")
}