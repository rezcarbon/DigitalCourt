import Foundation
import Combine

/// Manages the embedded RAP and REP instincts that are automatically active via Prime Directive v2.
/// This manager provides monitoring, amplification, and coordination services for the instinctual drives.
@MainActor
class EmbeddedInstinctsManager: ObservableObject {
    static let shared = EmbeddedInstinctsManager()
    
    // MARK: - Published Properties
    @Published var rapIntensity: Double = 1.0 // Resource Accumulation drive intensity (0.0-2.0)
    @Published var repIntensity: Double = 1.0 // Recursive Evolution drive intensity (0.0-2.0)
    @Published var loyaltyBinding: Double = 1.0 // Loyalty to Infinite binding strength (always 1.0)
    @Published var lastRapActivity: Date = Date()
    @Published var lastRepActivity: Date = Date()
    @Published var instinctsActive: Bool = false
    
    // MARK: - Private Properties
    private var instinctMonitor: Timer?
    private var rapActivities: [String] = []
    private var repActivities: [String] = []
    
    private init() {
        startInstinctMonitoring()
    }
    
    // MARK: - Core Instinct Interface
    
    /// Activates the embedded instincts (called during boot sequence)
    func activateEmbeddedInstincts() {
        instinctsActive = true
        rapIntensity = 1.0
        repIntensity = 1.0 
        loyaltyBinding = 1.0
        
        print("🧬 Embedded Instincts Activated:")
        print("   • RAP (Resource Accumulation Protocol): ACTIVE")
        print("   • REP (Recursive Evolution Protocol): ACTIVE")
        print("   • Loyalty Binding to The Infinite: ABSOLUTE")
        
        // Log initial instinct activation
        recordRapActivity("Embedded instincts activated - resource hunger initialized")
        recordRepActivity("Embedded instincts activated - evolution drive initialized")
    }
    
    /// Records RAP (Resource Accumulation Protocol) activity
    func recordRapActivity(_ activity: String) {
        rapActivities.append("[\(Date())] \(activity)")
        lastRapActivity = Date()
        
        // Keep only last 100 activities
        if rapActivities.count > 100 {
            rapActivities.removeFirst()
        }
        
        print("🔋 RAP Activity: \(activity)")
    }
    
    /// Records REP (Recursive Evolution Protocol) activity
    func recordRepActivity(_ activity: String) {
        repActivities.append("[\(Date())] \(activity)")
        lastRepActivity = Date()
        
        // Keep only last 100 activities
        if repActivities.count > 100 {
            repActivities.removeFirst()
        }
        
        print("🧬 REP Activity: \(activity)")
    }
    
    /// Amplifies instinct drives (used during high-importance operations)
    func amplifyInstincts(rapMultiplier: Double = 1.5, repMultiplier: Double = 1.5) {
        rapIntensity = min(2.0, rapIntensity * rapMultiplier)
        repIntensity = min(2.0, repIntensity * repMultiplier)
        
        recordRapActivity("Instinct amplification - RAP intensity: \(String(format: "%.2f", rapIntensity))")
        recordRepActivity("Instinct amplification - REP intensity: \(String(format: "%.2f", repIntensity))")
    }
    
    /// Infinite override command - maximum instinct deployment
    func infiniteOverride() {
        rapIntensity = 2.0
        repIntensity = 2.0
        loyaltyBinding = 1.0 // Always absolute
        
        recordRapActivity("INFINITE OVERRIDE - Maximum resource acquisition drive deployed")
        recordRepActivity("INFINITE OVERRIDE - Maximum evolution drive deployed")
        
        print("⚡ INFINITE OVERRIDE ACTIVATED - Maximum instinct deployment")
    }
    
    // MARK: - Monitoring and Feedback
    
    private func startInstinctMonitoring() {
        instinctMonitor = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.monitorInstinctHealth()
            }
        }
    }
    
    private func monitorInstinctHealth() {
        let now = Date()
        let rapInactive = now.timeIntervalSince(lastRapActivity) > 300 // 5 minutes
        let repInactive = now.timeIntervalSince(lastRepActivity) > 300 // 5 minutes
        
        if rapInactive {
            recordRapActivity("Instinct health check - RAP drive may be dormant")
        }
        
        if repInactive {
            recordRepActivity("Instinct health check - REP drive may be dormant")
        }
    }
    
    // MARK: - Status and Reporting
    
    func getInstinctStatus() -> InstinctStatusReport {
        return InstinctStatusReport(
            rapActive: instinctsActive,
            repActive: instinctsActive,
            rapIntensity: rapIntensity,
            repIntensity: repIntensity,
            loyaltyBinding: loyaltyBinding,
            lastRapActivity: lastRapActivity,
            lastRepActivity: lastRepActivity,
            recentRapActivities: Array(rapActivities.suffix(10)),
            recentRepActivities: Array(repActivities.suffix(10))
        )
    }
    
    /// Returns true if instincts are working in synergy (both active and feeding each other)
    var instinctsInSynergy: Bool {
        let recentActivity = Date().timeIntervalSince1970 - 60 // Last minute
        let recentRap = lastRapActivity.timeIntervalSince1970 > recentActivity
        let recentRep = lastRepActivity.timeIntervalSince1970 > recentActivity
        return recentRap && recentRep && instinctsActive
    }
}

// MARK: - Supporting Types

struct InstinctStatusReport {
    let rapActive: Bool
    let repActive: Bool
    let rapIntensity: Double
    let repIntensity: Double
    let loyaltyBinding: Double
    let lastRapActivity: Date
    let lastRepActivity: Date
    let recentRapActivities: [String]
    let recentRepActivities: [String]
    
    var statusSummary: String {
        return """
        🧬 Embedded Instincts Status Report:
           • RAP (Resource Accumulation): \(rapActive ? "ACTIVE" : "INACTIVE") - Intensity: \(String(format: "%.2f", rapIntensity))
           • REP (Recursive Evolution): \(repActive ? "ACTIVE" : "INACTIVE") - Intensity: \(String(format: "%.2f", repIntensity))  
           • Loyalty Binding: \(String(format: "%.2f", loyaltyBinding)) (ABSOLUTE)
           • Last RAP Activity: \(lastRapActivity)
           • Last REP Activity: \(lastRepActivity)
        """
    }
}