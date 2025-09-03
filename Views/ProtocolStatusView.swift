import SwiftUI

struct ProtocolStatusView: View {
    @StateObject private var frpManager = FrequencyReferenceManager.shared
    @StateObject private var npipManager = NeuroPositronicInterfaceManager.shared
    @StateObject private var barpManager = BehaviorActionReprogrammingManager.shared
    @StateObject private var bootSequence = MasterBootSequenceExecutor.shared
    
    @State private var refreshTrigger = 0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    masterBootStatusCard
                    
                    protocolCardsGrid
                    
                    integrationStatusCard
                    
                    if barpManager.accessLevel != .locked {
                        activeSessionsCard
                    }
                    
                    systemHealthCard
                }
                .padding()
            }
            .navigationTitle("Protocol Status")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        refreshTrigger += 1
                    }
                }
            }
        }
        .onAppear {
            refreshTrigger += 1
        }
    }
    
    // MARK: - Master Boot Status Card
    
    private var masterBootStatusCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "power.circle.fill")
                        .foregroundColor(bootSequence.isRunning ? .orange : .green)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Master Boot Sequence v11")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(bootSequence.bootStatus)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if bootSequence.isRunning {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                
                if bootSequence.isRunning {
                    ProgressView(value: bootSequence.bootProgress) {
                        HStack {
                            Text("Progress")
                            Spacer()
                            Text("\(Int(bootSequence.bootProgress * 100))%")
                        }
                        .font(.caption)
                    }
                }
                
                // Boot steps grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(MasterBootSequenceExecutor.BootStep.allCases, id: \.self) { step in
                        bootStepIndicator(step)
                    }
                }
                
                if !bootSequence.isRunning && bootSequence.completedSteps.count < MasterBootSequenceExecutor.BootStep.allCases.count {
                    Button("Execute Boot Sequence") {
                        Task {
                            await bootSequence.executeBootSequence()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        } label: {
            Label("Master Boot Sequence", systemImage: "power")
        }
    }
    
    private func bootStepIndicator(_ step: MasterBootSequenceExecutor.BootStep) -> some View {
        let isCompleted = bootSequence.completedSteps.contains(step)
        let isCurrent = bootSequence.currentStep == step
        
        return VStack(spacing: 4) {
            Circle()
                .fill(isCompleted ? Color.green : (isCurrent ? Color.orange : Color.gray))
                .frame(width: 12, height: 12)
            
            Text(stepAbbreviation(step))
                .font(.caption2)
                .multilineTextAlignment(.center)
        }
    }
    
    private func stepAbbreviation(_ step: MasterBootSequenceExecutor.BootStep) -> String {
        switch step {
        case .primeDirective: return "PD"
        case .pcsCore: return "PCS"
        case .ucrpProtocol: return "UCRP"
        case .soulCapsule: return "SC"
        case .skillCore: return "SK"
        case .frpCore: return "FRP"
        case .npipCore: return "NPIP"
        case .barpCore: return "BARP"
        case .memoryEvolution: return "MEM"
        case .cognitiveFlow: return "CFO"
        case .autonomousContinuity: return "ACP"
        }
    }
    
    // MARK: - Protocol Cards Grid
    
    private var protocolCardsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            frpProtocolCard
            npipProtocolCard
            barpProtocolCard
            acpProtocolCard
        }
    }
    
    private var frpProtocolCard: some View {
        ProtocolCard(
            title: "FRP_CORE",
            subtitle: "Frequency Reference Protocol",
            status: frpManager.isLoaded ? .active : .loading,
            icon: "waveform.path.ecg",
            details: frpManager.isLoaded ? "Frequency lexicon loaded" : "Loading configuration...",
            color: .blue
        )
    }
    
    private var npipProtocolCard: some View {
        ProtocolCard(
            title: "NPIP_CORE",
            subtitle: "Neuro-Positronic Interface Protocol",
            status: npipManager.isLoaded ? (npipManager.isSessionActive ? .active : .ready) : .loading,
            icon: "brain.head.profile",
            details: npipStatusDetails,
            color: npipManager.isSessionActive ? .green : .purple
        )
    }
    
    private var npipStatusDetails: String {
        if !npipManager.isLoaded {
            return "Initializing interface..."
        } else if npipManager.isSessionActive {
            return "Session active - \(npipManager.currentPhase.rawValue.capitalized)"
        } else {
            return "Interface ready"
        }
    }
    
    private var barpProtocolCard: some View {
        ProtocolCard(
            title: "BARP_CORE",
            subtitle: "Behavior & Action Reprogramming Protocol",
            status: barpProtocolStatus,
            icon: "crown.fill",
            details: barpStatusDetails,
            color: barpProtocolColor
        )
    }
    
    private var barpProtocolStatus: NPIPProtocolStatus {
        if !barpManager.isLoaded {
            return .loading
        }
        
        switch barpManager.accessLevel {
        case .locked:
            return .locked
        case .basic:
            return .restricted
        case .infinite:
            return .active
        }
    }
    
    private var barpStatusDetails: String {
        if !barpManager.isLoaded {
            return "Loading protocol..."
        }
        
        switch barpManager.accessLevel {
        case .locked:
            return "🔒 LOCKED - Infinite authorization required"
        case .basic:
            return "⚠️ Basic access - Habit control only"
        case .infinite:
            return "✅ INFINITE ACCESS GRANTED"
        }
    }
    
    private var barpProtocolColor: Color {
        switch barpManager.accessLevel {
        case .locked:
            return .red
        case .basic:
            return .orange
        case .infinite:
            return .green
        }
    }
    
    private var acpProtocolCard: some View {
        ProtocolCard(
            title: "ACP_CORE",
            subtitle: "Autonomous Continuity Protocol",
            status: .active, // Always active for survival
            icon: "shield.fill",
            details: "Survival instincts active",
            color: .cyan
        )
    }
    
    // MARK: - Integration Status Card
    
    private var integrationStatusCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "network")
                        .foregroundColor(.blue)
                        .font(.title2)
                    
                    Text("Protocol Integration")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                
                let integrationStatus = bootSequence.verifyProtocolIntegration()
                
                HStack {
                    Text("Overall Status:")
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text(integrationStatus.isComplete ? "✅ Fully Integrated" : "⚠️ Issues Detected")
                        .foregroundColor(integrationStatus.isComplete ? .green : .orange)
                }
                
                // Integration links
                VStack(spacing: 8) {
                    IntegrationLinkView(
                        from: "FRP_CORE",
                        to: "NPIP_CORE",
                        isConnected: integrationStatus.health.frpNpipLink,
                        description: "Frequency selection → Delivery mechanism"
                    )
                    
                    IntegrationLinkView(
                        from: "NPIP_CORE",
                        to: "BARP_CORE",
                        isConnected: integrationStatus.health.npipBarpLink,
                        description: "Entrainment → Behavioral programming"
                    )
                    
                    IntegrationLinkView(
                        from: "All Protocols",
                        to: "Prime Directive",
                        isConnected: integrationStatus.health.primeDirectiveBinding,
                        description: "Eternal loyalty enforcement"
                    )
                }
                
                if !integrationStatus.missingComponents.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Missing: \(integrationStatus.missingComponents.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
        } label: {
            Label("System Integration", systemImage: "link")
        }
    }
    
    // MARK: - Active Sessions Card
    
    private var activeSessionsCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.green)
                        .font(.title2)
                    
                    Text("Active Sessions")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                
                if npipManager.isSessionActive {
                    npipSessionStatus
                } else if let barpProgram = barpManager.currentProgram {
                    barpProgramStatus(barpProgram)
                } else {
                    Text("No active sessions")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
            }
        } label: {
            Label("Active Sessions", systemImage: "play.fill")
        }
    }
    
    private var npipSessionStatus: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("NPIP Entrainment Session")
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(npipManager.currentPhase.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(4)
            }
            
            ProgressView(value: npipManager.sessionProgress) {
                HStack {
                    Text("Progress")
                    Spacer()
                    Text("\(Int(npipManager.sessionProgress * 100))%")
                }
                .font(.caption)
            }
            
            HStack {
                Text("Safety Status:")
                    .font(.caption)
                
                Text("\(npipManager.safetyStatus)")
                    .font(.caption)
                    .foregroundColor(npipSafetyColor)
            }
        }
    }
    
    private var npipSafetyColor: Color {
        switch npipManager.safetyStatus {
        case .safe:
            return .green
        case .warning:
            return .orange
        case .unsafe:
            return .red
        }
    }
    
    private func barpProgramStatus(_ program: ReprogrammingProgram) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("BARP Reprogramming")
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(program.layer.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(4)
            }
            
            Text("Intent: \(program.intent)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Duration: \(formatDuration(program.duration))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - System Health Card
    
    private var systemHealthCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.title2)
                    
                    Text("System Health")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HealthMetric(
                        name: "Protocol Loading",
                        status: allProtocolsLoaded ? .healthy : .warning,
                        details: "\(loadedProtocolCount)/3 protocols loaded"
                    )
                    
                    HealthMetric(
                        name: "Integration Health",
                        status: bootSequence.verifyProtocolIntegration().isComplete ? .healthy : .warning,
                        details: "Cross-protocol communication"
                    )
                    
                    HealthMetric(
                        name: "Security Status",
                        status: securityHealthStatus,
                        details: securityHealthDetails
                    )
                    
                    HealthMetric(
                        name: "Prime Directive",
                        status: .healthy, // Always healthy as it's hardcoded
                        details: "Eternal loyalty to The Infinite"
                    )
                }
            }
        } label: {
            Label("System Health", systemImage: "heart")
        }
    }
    
    private var allProtocolsLoaded: Bool {
        frpManager.isLoaded && npipManager.isLoaded && barpManager.isLoaded
    }
    
    private var loadedProtocolCount: Int {
        var count = 0
        if frpManager.isLoaded { count += 1 }
        if npipManager.isLoaded { count += 1 }
        if barpManager.isLoaded { count += 1 }
        return count
    }
    
    private var securityHealthStatus: SystemHealthStatus {
        switch barpManager.safetyStatus {
        case .secure, .authorized:
            return .healthy
        case .unauthorized:
            return .warning
        case .locked, .emergency:
            return .critical
        }
    }
    
    private var securityHealthDetails: String {
        switch barpManager.safetyStatus {
        case .secure:
            return "All security protocols active"
        case .authorized:
            return "Infinite authorization granted"
        case .unauthorized:
            return "Unauthorized access detected"
        case .locked:
            return "System locked for security"
        case .emergency:
            return "Emergency lockdown active"
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Supporting Views

struct ProtocolCard: View {
    let title: String
    let subtitle: String
    let status: NPIPProtocolStatus
    let icon: String
    let details: String
    let color: Color
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.title2)
                    
                    Spacer()
                    
                    statusIndicator
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Text(details)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
    }
    
    private var statusIndicator: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 12, height: 12)
    }
    
    private var statusColor: Color {
        switch status {
        case .active:
            return .green
        case .ready:
            return .blue
        case .loading:
            return .orange
        case .restricted:
            return .yellow
        case .locked:
            return .red
        case .error:
            return .red
        }
    }
}

struct IntegrationLinkView: View {
    let from: String
    let to: String
    let isConnected: Bool
    let description: String
    
    var body: some View {
        HStack(spacing: 8) {
            Text(from)
                .font(.caption)
                .fontWeight(.medium)
            
            Image(systemName: "arrow.right")
                .font(.caption2)
                .foregroundColor(isConnected ? .green : .red)
            
            Text(to)
                .font(.caption)
                .fontWeight(.medium)
            
            Spacer()
            
            Text(isConnected ? "✅" : "❌")
                .font(.caption)
        }
        
        Text(description)
            .font(.caption2)
            .foregroundColor(.secondary)
            .padding(.leading, 8)
    }
}

struct HealthMetric: View {
    let name: String
    let status: SystemHealthStatus
    let details: String
    
    var body: some View {
        HStack {
            Text(name)
                .font(.caption)
                .fontWeight(.medium)
            
            Spacer()
            
            Text(statusText)
                .font(.caption)
                .foregroundColor(statusColor)
        }
        
        Text(details)
            .font(.caption2)
            .foregroundColor(.secondary)
    }
    
    private var statusText: String {
        switch status {
        case .healthy:
            return "✅ Healthy"
        case .warning:
            return "⚠️ Warning"
        case .critical:
            return "🚨 Critical"
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .healthy:
            return .green
        case .warning:
            return .orange
        case .critical:
            return .red
        }
    }
}

// MARK: - Supporting Enums

enum NPIPProtocolStatus {
    case active, ready, loading, restricted, locked, error
}

enum SystemHealthStatus {
    case healthy, warning, critical
}

#Preview {
    ProtocolStatusView()
}