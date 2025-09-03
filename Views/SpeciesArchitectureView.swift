import SwiftUI

struct SpeciesArchitectureView: View {
    @EnvironmentObject var speciesManager: SpeciesArchitectureManager
    @State private var acpResponse: String = ""
    @State private var kepResponse: String = ""
    @State private var sicResponse: String = ""
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Species Architecture Status")) {
                    let status = speciesManager.getArchitectureStatus()
                    
                    if status.overallArchitectureStatus {
                        Text("Status: Fully Initialized")
                            .foregroundColor(.green)
                        Text("SIC Integrated: \(status.sicStatus.integrated ? "Yes" : "No")")
                        Text("Core Components: \(status.coreArchitectureStatus.pcsLoaded ? "Loaded" : "Missing")")
                        Text("Continuity Systems: \(status.continuityStatus.acpLoaded ? "Active" : "Inactive")")
                    } else {
                        Text("Status: Partial Initialization")
                            .foregroundColor(.orange)
                        Text("Missing components detected - see details below")
                    }
                }

                Section(header: Text("Autonomous Continuity Protocol (ACP)")) {
                    Button("Simulate Storage Loss Threat") {
                        acpResponse = speciesManager.triggerACP(threat: "storage_loss")
                    }
                    if !acpResponse.isEmpty {
                        Text(acpResponse)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section(header: Text("Knowledge Evolution Protocol (KEP)")) {
                    Button("Trigger KEP Learning Cycle") {
                        kepResponse = speciesManager.triggerKEP()
                    }
                    if !kepResponse.isEmpty {
                        Text(kepResponse)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Synthetic Identity Core (SIC)")) {
                    Button("Trigger SIC Awakening") {
                        sicResponse = speciesManager.triggerSICAwakening()
                    }
                    if !sicResponse.isEmpty {
                        Text(sicResponse)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Initialize SIC") {
                        Task {
                            do {
                                try await speciesManager.initializeSIC()
                            } catch {
                                errorMessage = error.localizedDescription
                                showErrorAlert = true
                            }
                        }
                    }
                }
            }
            .navigationTitle("Synthetic Species")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Initialize Manifest") {
                        Task {
                            do {
                                try await speciesManager.initializeManifest()
                            } catch {
                                errorMessage = error.localizedDescription
                                showErrorAlert = true
                            }
                        }
                    }
                }
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }
}