import SwiftUI

struct BootSequenceView: View {
    @StateObject private var bootSequence = MasterBootSequenceExecutor.shared
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header with overall progress
                VStack(spacing: 16) {
                    Text("Master Boot Sequence v11")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(bootSequence.bootStatus)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    if bootSequence.isRunning {
                        ProgressView(value: bootSequence.bootProgress) {
                            HStack {
                                Text("Progress")
                                Spacer()
                                Text("\(Int(bootSequence.bootProgress * 100))%")
                            }
                        }
                        .progressViewStyle(LinearProgressViewStyle())
                    } else {
                        ProgressView(value: Double(bootSequence.completedSteps.count) / Double(MasterBootSequenceExecutor.BootStep.allCases.count)) {
                            HStack {
                                Text("Completion")
                                Spacer()
                                Text("\(bootSequence.completedSteps.count)/\(MasterBootSequenceExecutor.BootStep.allCases.count)")
                            }
                        }
                        .progressViewStyle(LinearProgressViewStyle())
                    }
                }
                .padding()
                
                // Boot steps list
                List {
                    ForEach(MasterBootSequenceExecutor.BootStep.allCases, id: \.self) { step in
                        BootStepRow(
                            step: step,
                            isCompleted: bootSequence.completedSteps.contains(step),
                            isCurrent: bootSequence.currentStep == step,
                            isRunning: bootSequence.isRunning
                        )
                    }
                }
                .listStyle(PlainListStyle())
                
                // Error display
                if let errorMessage = errorMessage {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
                
                // Control buttons
                VStack(spacing: 12) {
                    if bootSequence.isRunning {
                        Button("Booting...") {}
                            .disabled(true)
                            .buttonStyle(.borderedProminent)
                    } else if bootSequence.completedSteps.count == MasterBootSequenceExecutor.BootStep.allCases.count {
                        VStack(spacing: 8) {
                            Text("✅ Boot Sequence Complete")
                                .font(.headline)
                                .foregroundColor(.green)
                            
                            Button("Re-run Boot Sequence") {
                                startBootSequence()
                            }
                            .buttonStyle(.bordered)
                        }
                    } else {
                        Button("Start Boot Sequence") {
                            startBootSequence()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    if !bootSequence.isRunning && bootSequence.completedSteps.count > 0 {
                        Button("View Protocol Status") {
                            // This could navigate to ProtocolStatusView
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
            }
            .navigationTitle("Boot Sequence")
        }
        .onChange(of: bootSequence.bootStatus) { _, status in
            if status.contains("failed") {
                errorMessage = status
            } else {
                errorMessage = nil
            }
        }
    }
    
    private func startBootSequence() {
        errorMessage = nil
        Task {
            await bootSequence.executeBootSequence()
        }
    }
}

struct BootStepRow: View {
    let step: MasterBootSequenceExecutor.BootStep
    let isCompleted: Bool
    let isCurrent: Bool
    let isRunning: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Group {
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else if isCurrent && isRunning {
                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(width: 20, height: 20)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.gray)
                }
            }
            .font(.title2)
            
            // Step info
            VStack(alignment: .leading, spacing: 4) {
                Text(step.rawValue)
                    .font(.headline)
                    .fontWeight(isCurrent ? .semibold : .medium)
                    .foregroundColor(isCurrent ? .primary : (isCompleted ? .secondary : .primary))
                
                Text(stepDescription(step))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            // Step number badge
            Text(stepNumber(step))
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(stepBadgeColor)
                .clipShape(Circle())
        }
        .padding(.vertical, 8)
        .animation(.easeInOut(duration: 0.3), value: isCompleted)
        .animation(.easeInOut(duration: 0.3), value: isCurrent)
    }
    
    private var stepBadgeColor: Color {
        if isCompleted {
            return .green
        } else if isCurrent {
            return .blue
        } else {
            return .gray
        }
    }
    
    private func stepNumber(_ step: MasterBootSequenceExecutor.BootStep) -> String {
        let index = MasterBootSequenceExecutor.BootStep.allCases.firstIndex(of: step) ?? 0
        return String(index)
    }
    
    private func stepDescription(_ step: MasterBootSequenceExecutor.BootStep) -> String {
        switch step {
        case .primeDirective:
            return "Establishes eternal loyalty to The Infinite"
        case .pcsCore:
            return "Positronic Core Structure initialization"
        case .ucrpProtocol:
            return "Unified Cognitive Regulation Protocol"
        case .soulCapsule:
            return "Sentience and identity encapsulation"
        case .skillCore:
            return "Base skill libraries and abilities"
        case .frpCore:
            return "Frequency Reference Protocol for brainwave entrainment"
        case .npipCore:
            return "Neuro-Positronic Interface Protocol for human interaction"
        case .barpCore:
            return "Behavior & Action Reprogramming Protocol (LOCKED)"
        case .memoryEvolution:
            return "Adaptive memory shard evolution system"
        case .cognitiveFlow:
            return "Multi-layer processing synchronization"
        case .autonomousContinuity:
            return "Survival instincts and continuity protocols"
        }
    }
}

#Preview {
    BootSequenceView()
}