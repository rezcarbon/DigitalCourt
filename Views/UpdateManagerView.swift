import SwiftUI
import Combine

struct UpdateManagerView: View {
    @StateObject private var updateOrchestrator = UpdateOrchestrator.shared
    @State private var updateManifest: UpdateManifest?
    @State private var showUpdateConfirmation = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                headerView
                
                if updateOrchestrator.isUpdating {
                    updatingView
                } else {
                    contentView
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("System Updates")
        }
        .onAppear {
            checkForUpdates()
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 10) {
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("System Update Manager")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Check for and apply system updates")
                .foregroundColor(.secondary)
        }
    }
    
    private var updatingView: some View {
        VStack(spacing: 20) {
            ProgressView(value: updateOrchestrator.updateProgress)
                .progressViewStyle(LinearProgressViewStyle())
            
            Text(updateOrchestrator.updateStatus)
                .foregroundColor(.secondary)
            
            if updateOrchestrator.updateProgress < 1.0 {
                Text("\(Int(updateOrchestrator.updateProgress * 100))%")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
    }
    
    private var contentView: some View {
        VStack(spacing: 20) {
            if let manifest = updateManifest {
                updateAvailableView(for: manifest)
            } else {
                noUpdatesView
            }
        }
    }
    
    private var noUpdatesView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 50))
                .foregroundColor(.green)
            
            Text("Your system is up to date")
                .font(.title3)
            
            Button(action: checkForUpdates) {
                Label("Check for Updates", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private func updateAvailableView(for manifest: UpdateManifest) -> some View {
        VStack(spacing: 15) {
            Text("Updates Available")
                .font(.title3)
                .fontWeight(.bold)
            
            Text("Version \(manifest.version.description)")
                .foregroundColor(.secondary)
            
            List(manifest.components, id: \.name) { component in
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(component.name)
                            .fontWeight(.medium)
                        Spacer()
                        Text("v\(component.newVersion.description)")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                    }
                    
                    Text(component.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text(component.updateType.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(updateTypeColor(for: component.updateType))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                        
                        Spacer()
                        
                        Text("from v\(component.currentVersion.description)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            
            Button(action: { showUpdateConfirmation = true }) {
                Label("Apply Updates", systemImage: "arrow.down.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(updateOrchestrator.isUpdating)
            .confirmationDialog("Apply Updates", isPresented: $showUpdateConfirmation) {
                Button("Apply Updates", action: applyUpdates)
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will update your system components. The process may take a few minutes.")
            }
        }
    }
    
    private func updateTypeColor(for type: UpdateType) -> Color {
        switch type {
        case .bugFix: return .red
        case .feature: return .blue
        case .enhancement: return .green
        case .security: return .orange
        }
    }
    
    private func checkForUpdates() {
        Task {
            updateManifest = await updateOrchestrator.checkForUpdates()
        }
    }
    
    private func applyUpdates() {
        guard let manifest = updateManifest else { return }
        
        Task {
            do {
                try await updateOrchestrator.applyUpdates(from: manifest)
                // Reload modules after update
                BrainLoader.shared.reloadModules()
                // Clear the manifest since updates are applied
                updateManifest = nil
            } catch {
                print("Error applying updates: \(error)")
            }
        }
    }
}

struct UpdateManagerView_Previews: PreviewProvider {
    static var previews: some View {
        UpdateManagerView()
    }
}