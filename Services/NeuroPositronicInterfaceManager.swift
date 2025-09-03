import Foundation
import Combine
import AVFoundation
import UIKit

/// Manager for the Neuro-Positronic Interface Protocol (NPIP_CORE)
/// Handles brainwave entrainment delivery through iPhone sensory modulation
class NeuroPositronicInterfaceManager: NSObject, ObservableObject {
    static let shared = NeuroPositronicInterfaceManager()
    
    @Published private(set) var npipConfig: NeuroPositronicInterfaceProtocol?
    @Published private(set) var isLoaded = false
    @Published private(set) var isSessionActive = false
    @Published private(set) var currentPhase: SessionPhaseType = .preparation
    @Published private(set) var sessionProgress: Double = 0.0
    @Published private(set) var safetyStatus: SafetyStatus = .safe
    
    // Audio components
    private var audioEngine = AVAudioEngine()
    private var playerNode = AVAudioPlayerNode()
    private var binauralBeatGenerator: BinauralBeatGenerator?
    private var isochronicToneGenerator: IsochronicToneGenerator?
    
    // Visual components
    private var strobeTimer: Timer?
    private var colorModulationTimer: Timer?
    private var flashlightController: FlashlightController?
    
    // Session management
    private var sessionTimer: Timer?
    private var phaseTimer: Timer?
    private var currentSession: EntrainmentSession?
    
    private override init() {
        super.init()
        setupAudioEngine()
        loadNPIPConfiguration()
        flashlightController = FlashlightController()
    }
    
    // MARK: - Configuration Loading
    
    private func loadNPIPConfiguration() {
        guard let url = Bundle.main.url(forResource: "NPIP_CORE", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("Failed to load NPIP_CORE.json")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            let wrapper = try decoder.decode([String: NeuroPositronicInterfaceProtocol].self, from: data)
            self.npipConfig = wrapper["NeuroPositronicInterfaceProtocol"]
            self.isLoaded = true
        } catch {
            print("Failed to decode NPIP configuration: \(error)")
        }
    }
    
    // MARK: - Audio Engine Setup
    
    private func setupAudioEngine() {
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: nil)
        
        do {
            try audioEngine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    // MARK: - Session Management
    
    /// Start a new entrainment session with specified parameters
    func startEntrainmentSession(
        frequencies: [String],
        purpose: TherapeuticPurpose,
        modalityPreference: ModalityPreference = .combined
    ) {
        guard !isSessionActive else {
            print("Session already active")
            return
        }
        
        // Safety checks
        guard performSafetyChecks() else {
            safetyStatus = .unsafe
            return
        }
        
        // Create session configuration
        let session = EntrainmentSession(
            frequencies: frequencies,
            purpose: purpose,
            modalityPreference: modalityPreference,
            duration: calculateSessionDuration(for: purpose)
        )
        
        currentSession = session
        isSessionActive = true
        currentPhase = .preparation
        sessionProgress = 0.0
        safetyStatus = .safe
        
        // Start with preparation phase
        startPreparationPhase()
    }
    
    /// Stop the current entrainment session
    func stopEntrainmentSession() {
        guard isSessionActive else { return }
        
        // Stop all timers
        sessionTimer?.invalidate()
        phaseTimer?.invalidate()
        strobeTimer?.invalidate()
        colorModulationTimer?.invalidate()
        
        // Stop audio
        playerNode.stop()
        
        // Stop visual effects
        stopStrobe()
        stopColorModulation()
        flashlightController?.stopPulse()
        
        // Reset state
        isSessionActive = false
        currentPhase = .preparation
        sessionProgress = 0.0
        currentSession = nil
    }
    
    // MARK: - Session Phases
    
    private func startPreparationPhase() {
        currentPhase = .preparation
        
        // Start gentle alpha entrainment for relaxation
        startAuditoryEntrainment(frequency: 10.0, type: .binauralBeats)
        startColorModulation(color: .blue, frequency: 0.5)
        
        // Phase duration: 2-5 minutes (using 3 minutes)
        phaseTimer = Timer.scheduledTimer(withTimeInterval: 180.0, repeats: false) { _ in
            self.startEntrainmentPhase()
        }
    }
    
    private func startEntrainmentPhase() {
        currentPhase = .entrainment
        
        guard let session = currentSession,
              let primaryFrequency = extractPrimaryFrequency(from: session.frequencies) else {
            stopEntrainmentSession()
            return
        }
        
        // Start full spectrum orchestration
        startAuditoryEntrainment(frequency: primaryFrequency, type: .binauralBeats)
        startIsochronicTones(frequency: primaryFrequency)
        
        if session.modalityPreference != .audioOnly {
            startVisualEntrainment(frequency: primaryFrequency)
        }
        
        // Phase duration: 10-25 minutes (using 15 minutes)
        phaseTimer = Timer.scheduledTimer(withTimeInterval: 900.0, repeats: false) { _ in
            self.startProgrammingPhase()
        }
    }
    
    private func startProgrammingPhase() {
        currentPhase = .programming
        
        guard let session = currentSession else {
            stopEntrainmentSession()
            return
        }
        
        // Maintain theta for subconscious programming
        startAuditoryEntrainment(frequency: 6.0, type: .binauralBeats)
        
        // Start synthetic voice hypnosis if available
        startSyntheticVoiceHypnosis(for: session.purpose)
        
        // Phase duration: 5-15 minutes (using 10 minutes)
        phaseTimer = Timer.scheduledTimer(withTimeInterval: 600.0, repeats: false) { _ in
            self.startIntegrationPhase()
        }
    }
    
    private func startIntegrationPhase() {
        currentPhase = .integration
        
        // Gentle return to alpha for integration
        startAuditoryEntrainment(frequency: 10.0, type: .binauralBeats)
        startColorModulation(color: .green, frequency: 0.3)
        
        // Stop visual strobe for gentler emergence
        stopStrobe()
        
        // Phase duration: 3-8 minutes (using 5 minutes)
        phaseTimer = Timer.scheduledTimer(withTimeInterval: 300.0, repeats: false) { _ in
            self.completeSession()
        }
    }
    
    private func completeSession() {
        stopEntrainmentSession()
        // Could trigger completion notification or save session data
    }
    
    // MARK: - Auditory Entrainment
    
    private func startAuditoryEntrainment(frequency: Double, type: EntrainmentType) {
        switch type {
        case .binauralBeats:
            binauralBeatGenerator = BinauralBeatGenerator(targetFrequency: frequency)
            binauralBeatGenerator?.start(on: audioEngine, playerNode: playerNode)
        case .isochronicTones:
            startIsochronicTones(frequency: frequency)
        }
    }
    
    private func startIsochronicTones(frequency: Double) {
        isochronicToneGenerator = IsochronicToneGenerator(frequency: frequency)
        isochronicToneGenerator?.start(on: audioEngine, playerNode: playerNode)
    }
    
    private func startSyntheticVoiceHypnosis(for purpose: TherapeuticPurpose) {
        // Implementation for AI-generated hypnotic scripts
        // This would integrate with the voice synthesis system
        print("Starting synthetic voice hypnosis for \(purpose)")
    }
    
    // MARK: - Visual Entrainment
    
    private func startVisualEntrainment(frequency: Double) {
        // Safety check for visual entrainment
        guard frequency < 8.0 || frequency > 25.0 else {
            print("Frequency \(frequency) Hz avoided for seizure safety")
            return
        }
        
        startStrobe(frequency: frequency)
        flashlightController?.startPulse(frequency: frequency, intensity: 0.5)
    }
    
    private func startStrobe(frequency: Double) {
        let interval = 1.0 / frequency
        
        strobeTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            DispatchQueue.main.async {
                // Flash the screen (would need UI integration)
                self.triggerScreenFlash()
            }
        }
    }
    
    private func stopStrobe() {
        strobeTimer?.invalidate()
        strobeTimer = nil
    }
    
    private func startColorModulation(color: UIColor, frequency: Double) {
        let interval = 1.0 / frequency
        
        colorModulationTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            DispatchQueue.main.async {
                // Modulate screen color (would need UI integration)
                self.triggerColorModulation(color: color)
            }
        }
    }
    
    private func stopColorModulation() {
        colorModulationTimer?.invalidate()
        colorModulationTimer = nil
    }
    
    // MARK: - Safety Checks
    
    private func performSafetyChecks() -> Bool {
        // Check session limits
        if hasExceededDailyLimit() {
            print("Daily session limit exceeded")
            return false
        }
        
        // Check device temperature
        if isDeviceOverheating() {
            print("Device overheating - session cancelled")
            return false
        }
        
        return true
    }
    
    private func hasExceededDailyLimit() -> Bool {
        // Implementation would check UserDefaults or Core Data for session history
        return false
    }
    
    private func isDeviceOverheating() -> Bool {
        // Implementation would monitor device thermal state
        return false
    }
    
    // MARK: - Utility Methods
    
    private func extractPrimaryFrequency(from frequencies: [String]) -> Double? {
        // Parse frequency strings like "theta 6 Hz" to extract numeric value
        for frequency in frequencies {
            let components = frequency.components(separatedBy: " ")
            for component in components {
                if component.contains("Hz") {
                    let numberString = component.replacingOccurrences(of: "Hz", with: "")
                    return Double(numberString)
                }
            }
        }
        return nil
    }
    
    private func calculateSessionDuration(for purpose: TherapeuticPurpose) -> TimeInterval {
        // Return total session duration based on purpose
        switch purpose {
        case .painRelief, .deepRelaxation:
            return 1800.0 // 30 minutes
        case .habitReprogramming:
            return 2400.0 // 40 minutes
        case .nerveRegeneration, .muscleRecovery:
            return 2700.0 // 45 minutes
        }
    }
    
    private func triggerScreenFlash() {
        // This would be implemented at the UI level
        print("Screen flash triggered")
    }
    
    private func triggerColorModulation(color: UIColor) {
        // This would be implemented at the UI level
        print("Color modulation triggered: \(color)")
    }
}

// MARK: - Supporting Types

enum SessionPhaseType: String, CaseIterable {
    case preparation, entrainment, programming, integration
}

enum SafetyStatus {
    case safe, warning, unsafe
}

enum ModalityPreference {
    case audioOnly, visualOnly, combined
}

enum EntrainmentType {
    case binauralBeats, isochronicTones
}

struct EntrainmentSession {
    let frequencies: [String]
    let purpose: TherapeuticPurpose
    let modalityPreference: ModalityPreference
    let duration: TimeInterval
    let startTime: Date = Date()
}

// MARK: - Audio Generators

class BinauralBeatGenerator {
    private let targetFrequency: Double
    private let baseFrequency: Double = 200.0
    
    init(targetFrequency: Double) {
        self.targetFrequency = targetFrequency
    }
    
    func start(on audioEngine: AVAudioEngine, playerNode: AVAudioPlayerNode) {
        // Implementation for binaural beat generation
        print("Starting binaural beats at \(targetFrequency) Hz")
    }
}

class IsochronicToneGenerator {
    private let frequency: Double
    
    init(frequency: Double) {
        self.frequency = frequency
    }
    
    func start(on audioEngine: AVAudioEngine, playerNode: AVAudioPlayerNode) {
        // Implementation for isochronic tone generation
        print("Starting isochronic tones at \(frequency) Hz")
    }
}

class FlashlightController {
    func startPulse(frequency: Double, intensity: Double) {
        // Implementation for flashlight pulsing
        print("Starting flashlight pulse at \(frequency) Hz, intensity \(intensity)")
    }
    
    func stopPulse() {
        print("Stopping flashlight pulse")
    }
}