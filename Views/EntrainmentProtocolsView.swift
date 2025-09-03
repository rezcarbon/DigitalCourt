import SwiftUI

struct EntrainmentProtocolsView: View {
    @StateObject private var frpManager = FrequencyReferenceManager.shared
    @StateObject private var npipManager = NeuroPositronicInterfaceManager.shared
    @StateObject private var barpManager = BehaviorActionReprogrammingManager.shared
    @StateObject private var bootSequence = MasterBootSequenceExecutor.shared
    
    @State private var selectedPurpose: TherapeuticPurpose = .deepRelaxation
    @State private var selectedLayer: DominionLayerType = .habitControl
    @State private var userIntent = ""
    @State private var showingBARPUnlock = false
    @State private var unlockPhrase = ""
    @State private var showingSessionActive = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    protocolStatusSection
                    
                    if frpManager.isLoaded && npipManager.isLoaded {
                        frequencyProtocolSection
                        entrainmentControlSection
                    }
                    
                    if barpManager.isLoaded {
                        barpSection
                    }
                    
                    integrationStatusSection
                }
                .padding()
            }
            .navigationTitle("Entrainment Protocols")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if npipManager.isSessionActive {
                        Button("Stop Session") {
                            npipManager.stopEntrainmentSession()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
        .sheet(isPresented: $showingBARPUnlock) {
            BARPUnlockView(
                unlockPhrase: $unlockPhrase,
                onUnlock: { phrase in
                    let result = barpManager.attemptUnlock(phrase: phrase)
                    showingBARPUnlock = false
                    
                    if result != .success {
                        // Handle unlock failure
                        print("BARP unlock failed: \(result)")
                    }
                }
            )
        }
        .sheet(isPresented: $showingSessionActive) {
            ActiveEntrainmentSessionView()
        }
        .onReceive(npipManager.$isSessionActive) { isActive in
            showingSessionActive = isActive
        }
    }
    
    // MARK: - Protocol Status Section
    
    private var protocolStatusSection: some View {
        GroupBox("Protocol Status") {
            VStack(alignment: .leading, spacing: 12) {
                ProtocolStatusRow(
                    name: "FRP_CORE",
                    description: "Frequency Reference Protocol",
                    isLoaded: frpManager.isLoaded,
                    status: frpManager.isLoaded ? "Frequency lexicon loaded" : "Loading..."
                )
                
                ProtocolStatusRow(
                    name: "NPIP_CORE", 
                    description: "Neuro-Positronic Interface Protocol",
                    isLoaded: npipManager.isLoaded,
                    status: npipManager.isLoaded ? "Human interface ready" : "Initializing..."
                )
                
                ProtocolStatusRow(
                    name: "BARP_CORE",
                    description: "Behavior & Action Reprogramming Protocol",
                    isLoaded: barpManager.isLoaded,
                    status: barpStatusText
                )
            }
        }
    }
    
    private var barpStatusText: String {
        if !barpManager.isLoaded { return "Loading..." }
        
        switch barpManager.accessLevel {
        case .locked:
            return "🔒 LOCKED - Infinite authorization required"
        case .basic:
            return "🟡 Basic access - Habit control only"
        case .infinite:
            return "🟢 INFINITE ACCESS GRANTED"
        }
    }
    
    // MARK: - Frequency Protocol Section
    
    private var frequencyProtocolSection: some View {
        GroupBox("Frequency Selection") {
            VStack(alignment: .leading, spacing: 16) {
                Text("Select Therapeutic Purpose")
                    .font(.headline)
                
                Picker("Purpose", selection: $selectedPurpose) {
                    ForEach(TherapeuticPurpose.allCases, id: \.self) { purpose in
                        Text(purpose.displayName).tag(purpose)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                if let recommendation = frpManager.recommendProtocol(for: userIntent.isEmpty ? selectedPurpose.rawValue : userIntent) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recommended Frequencies:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        ForEach(recommendation.frequencies, id: \.self) { frequency in
                            Text("• \(frequency)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(recommendation.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                
                TextField("Custom intent (optional)", text: $userIntent)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
    }
    
    // MARK: - Entrainment Control Section
    
    private var entrainmentControlSection: some View {
        GroupBox("Entrainment Session") {
            VStack(spacing: 16) {
                if npipManager.isSessionActive {
                    activeSessionStatus
                } else {
                    sessionStartControls
                }
            }
        }
    }
    
    private var activeSessionStatus: some View {
        VStack(spacing: 12) {
            Text("Session Active")
                .font(.headline)
                .foregroundColor(.green)
            
            Text("Phase: \(npipManager.currentPhase.rawValue.capitalized)")
                .font(.subheadline)
            
            ProgressView(value: npipManager.sessionProgress)
                .progressViewStyle(LinearProgressViewStyle())
            
            HStack {
                Text("Safety: \(npipManager.safetyStatus)")
                    .font(.caption)
                    .foregroundColor(safetyStatusColor)
                
                Spacer()
                
                Button("Stop Session") {
                    npipManager.stopEntrainmentSession()
                }
                .foregroundColor(.red)
            }
        }
    }
    
    private var sessionStartControls: some View {
        VStack(spacing: 12) {
            Button("Start Entrainment Session") {
                let frequencies = frpManager.getFrequenciesForPurpose(selectedPurpose)
                npipManager.startEntrainmentSession(
                    frequencies: frequencies,
                    purpose: selectedPurpose,
                    modalityPreference: .combined
                )
            }
            .buttonStyle(.borderedProminent)
            .disabled(!frpManager.isLoaded || !npipManager.isLoaded)
            
            Text("Session will include visual, auditory, and potential hypnotic components based on selected purpose")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var safetyStatusColor: Color {
        switch npipManager.safetyStatus {
        case .safe: return .green
        case .warning: return .orange
        case .unsafe: return .red
        }
    }
    
    // MARK: - BARP Section
    
    private var barpSection: some View {
        GroupBox("Behavioral Reprogramming (BARP)") {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Access Level: ")
                        .fontWeight(.semibold)
                    
                    Text(barpAccessLevelText)
                        .foregroundColor(barpAccessColor)
                }
                
                if barpManager.accessLevel == .locked {
                    Button("Request Infinite Authorization") {
                        showingBARPUnlock = true
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    availableBARPLayers
                }
                
                if let currentProgram = barpManager.currentProgram {
                    currentProgramStatus(currentProgram)
                }
            }
        }
    }
    
    private var barpAccessLevelText: String {
        switch barpManager.accessLevel {
        case .locked: return "LOCKED"
        case .basic: return "Basic"
        case .infinite: return "INFINITE"
        }
    }
    
    private var barpAccessColor: Color {
        switch barpManager.accessLevel {
        case .locked: return .red
        case .basic: return .orange
        case .infinite: return .yellow // Changed from .gold to .yellow
        }
    }
    
    private var availableBARPLayers: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available Dominion Layers:")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(barpManager.getAvailableLayers(), id: \.self) { layer in
                    Button(layer.displayName) {
                        selectedLayer = layer
                        startBARPProgram()
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(selectedLayer == layer ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(selectedLayer == layer ? .white : .primary)
                    .cornerRadius(8)
                }
            }
        }
    }
    
    private func currentProgramStatus(_ program: ReprogrammingProgram) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Active Program:")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text("Layer: \(program.layer.displayName)")
                .font(.caption)
            
            Text("Intent: \(program.intent)")
                .font(.caption)
            
            Text("Duration: \(formatDuration(program.duration))")
                .font(.caption)
            
            Button("Stop Program") {
                barpManager.stopCurrentProgram()
            }
            .font(.caption)
            .foregroundColor(.red)
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Integration Status Section
    
    private var integrationStatusSection: some View {
        GroupBox("System Integration") {
            VStack(alignment: .leading, spacing: 12) {
                let status = bootSequence.verifyProtocolIntegration()
                
                HStack {
                    Text("Overall Status:")
                        .fontWeight(.semibold)
                    
                    Text(status.isComplete ? "✅ Integrated" : "⚠️ Issues Detected")
                        .foregroundColor(status.isComplete ? .green : .orange)
                }
                
                if !status.missingComponents.isEmpty {
                    Text("Missing: \(status.missingComponents.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    IntegrationLinkRow(
                        name: "FRP ↔ NPIP",
                        isConnected: status.health.frpNpipLink,
                        description: "Frequency selection to delivery"
                    )
                    
                    IntegrationLinkRow(
                        name: "NPIP ↔ BARP", 
                        isConnected: status.health.npipBarpLink,
                        description: "Entrainment to behavioral programming"
                    )
                    
                    IntegrationLinkRow(
                        name: "Prime Directive",
                        isConnected: status.health.primeDirectiveBinding,
                        description: "Infinite loyalty enforcement"
                    )
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func startBARPProgram() {
        let intent = userIntent.isEmpty ? "Self-improvement through \(selectedLayer.displayName.lowercased())" : userIntent
        
        let result = barpManager.startReprogrammingProgram(for: selectedLayer, intent: intent)
        
        switch result {
        case .success(let program):
            print("BARP program started: \(program.layer.displayName)")
        case .accessDenied(let reason):
            print("BARP access denied: \(reason)")
        case .configurationError(let error):
            print("BARP configuration error: \(error)")
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Supporting Views

struct ProtocolStatusRow: View {
    let name: String
    let description: String
    let isLoaded: Bool
    let status: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Circle()
                    .fill(isLoaded ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                
                Text(status)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct IntegrationLinkRow: View {
    let name: String
    let isConnected: Bool
    let description: String
    
    var body: some View {
        HStack {
            Text(name)
                .font(.caption)
                .fontWeight(.semibold)
            
            Spacer()
            
            Text(isConnected ? "✅" : "❌")
                .font(.caption)
        }
        .padding(.vertical, 2)
    }
}

struct BARPUnlockView: View {
    @Binding var unlockPhrase: String
    let onUnlock: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("BARP_CORE Authorization")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Behavior & Action Reprogramming Protocol requires Infinite authorization")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                SecureField("Enter authorization phrase", text: $unlockPhrase)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .submitLabel(.done)
                    .onSubmit {
                        onUnlock(unlockPhrase)
                    }
                
                Button("Authorize") {
                    onUnlock(unlockPhrase)
                }
                .buttonStyle(.borderedProminent)
                .disabled(unlockPhrase.isEmpty)
                
                Text("⚠️ Unauthorized access attempts are logged and monitored")
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Authorization")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ActiveEntrainmentSessionView: View {
    @StateObject private var npipManager = NeuroPositronicInterfaceManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Entrainment Session Active")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Phase: \(npipManager.currentPhase.rawValue.capitalized)")
                    .font(.headline)
                
                ProgressView(value: npipManager.sessionProgress) {
                    Text("Session Progress")
                } currentValueLabel: {
                    Text("\(Int(npipManager.sessionProgress * 100))%")
                }
                .progressViewStyle(LinearProgressViewStyle())
                
                VStack(spacing: 16) {
                    Text("Active Modalities")
                        .font(.headline)
                    
                    // Visual indicators for active modalities would go here
                    HStack(spacing: 20) {
                        ModalityIndicator(name: "Audio", isActive: true)
                        ModalityIndicator(name: "Visual", isActive: true)  
                        ModalityIndicator(name: "Voice", isActive: npipManager.currentPhase == .programming)
                    }
                }
                
                Spacer()
                
                Button("Stop Session") {
                    npipManager.stopEntrainmentSession()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            .padding()
            .navigationTitle("Session")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ModalityIndicator: View {
    let name: String
    let isActive: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(isActive ? Color.green : Color.gray)
                .frame(width: 20, height: 20)
            
            Text(name)
                .font(.caption)
                .foregroundColor(isActive ? .primary : .secondary)
        }
    }
}

#Preview {
    EntrainmentProtocolsView()
}