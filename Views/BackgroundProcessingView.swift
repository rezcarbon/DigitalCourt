import SwiftUI

struct BackgroundProcessingView: View {
    @StateObject private var backgroundManager = BackgroundProcessingManager.shared
    @State private var showingConfiguration = false
    @State private var config = BackgroundProcessingConfig()
    
    var body: some View {
        NavigationView {
            Form {
                // Current Status Section
                statusSection
                
                // Manual Processing Section
                manualProcessingSection
                
                // Configuration Section
                configurationSection
                
                // Statistics Section
                statisticsSection
            }
            .navigationTitle("Background Processing")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Configure") {
                        showingConfiguration = true
                    }
                }
            }
            .sheet(isPresented: $showingConfiguration) {
                BackgroundProcessingConfigView(config: $config) { newConfig in
                    backgroundManager.updateConfiguration(newConfig)
                }
            }
        }
    }
    
    private var statusSection: some View {
        Section(header: Text("Current Status")) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Processing Status")
                        .fontWeight(.medium)
                    
                    Text(backgroundManager.processingStatus.isEmpty ? "Idle" : backgroundManager.processingStatus)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if backgroundManager.isProcessing {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            
            HStack {
                Text("Background Tasks")
                Spacer()
                Text(backgroundManager.backgroundTasksEnabled ? "✅ Enabled" : "❌ Disabled")
                    .foregroundColor(backgroundManager.backgroundTasksEnabled ? .green : .red)
            }
            
            if let lastProcessing = backgroundManager.lastProcessingDate {
                HStack {
                    Text("Last Processing")
                    Spacer()
                    Text(lastProcessing, style: .relative)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var manualProcessingSection: some View {
        Section(header: Text("Manual Processing")) {
            Button("Consolidate Memories") {
                Task {
                    try? await backgroundManager.performManualMemoryConsolidation()
                }
            }
            .disabled(backgroundManager.isProcessing)
            
            Button("Optimize Models") {
                Task {
                    try? await backgroundManager.performManualModelOptimization()
                }
            }
            .disabled(backgroundManager.isProcessing)
            
            Button("System Maintenance") {
                Task {
                    try? await backgroundManager.performManualSystemMaintenance()
                }
            }
            .disabled(backgroundManager.isProcessing)
        }
    }
    
    private var configurationSection: some View {
        Section(header: Text("Quick Settings")) {
            Toggle("Enable Background Processing", isOn: .init(
                get: { config.enableBackgroundProcessing },
                set: { 
                    config.enableBackgroundProcessing = $0
                    backgroundManager.updateConfiguration(config)
                }
            ))
            
            Toggle("Memory Consolidation", isOn: .init(
                get: { config.enableMemoryConsolidation },
                set: { 
                    config.enableMemoryConsolidation = $0
                    backgroundManager.updateConfiguration(config)
                }
            ))
            
            Toggle("Model Optimization", isOn: .init(
                get: { config.enableModelOptimization },
                set: { 
                    config.enableModelOptimization = $0
                    backgroundManager.updateConfiguration(config)
                }
            ))
            
            Toggle("System Maintenance", isOn: .init(
                get: { config.enableSystemMaintenance },
                set: { 
                    config.enableSystemMaintenance = $0
                    backgroundManager.updateConfiguration(config)
                }
            ))
        }
    }
    
    private var statisticsSection: some View {
        Section(header: Text("Processing Information")) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Background Processing Benefits:")
                    .fontWeight(.medium)
                
                ProcessingBenefitRow(
                    icon: "memories",
                    title: "Memory Consolidation",
                    description: "Moves old memories to cloud storage automatically"
                )
                
                ProcessingBenefitRow(
                    icon: "cpu",
                    title: "Model Optimization",
                    description: "Cleans up unused models and optimizes performance"
                )
                
                ProcessingBenefitRow(
                    icon: "wrench.and.screwdriver",
                    title: "System Maintenance",
                    description: "Validates data integrity and performs cleanup"
                )
            }
            .padding(.vertical, 4)
        }
    }
}

struct ProcessingBenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 2)
    }
}

struct BackgroundProcessingConfigView: View {
    @Binding var config: BackgroundProcessingConfig
    let onSave: (BackgroundProcessingConfig) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("General Settings")) {
                    Toggle("Enable Background Processing", isOn: $config.enableBackgroundProcessing)
                }
                
                Section(header: Text("Processing Types")) {
                    Toggle("Memory Consolidation", isOn: $config.enableMemoryConsolidation)
                    Toggle("Model Optimization", isOn: $config.enableModelOptimization)
                    Toggle("System Maintenance", isOn: $config.enableSystemMaintenance)
                }
                
                Section(header: Text("Processing Intervals")) {
                    VStack(alignment: .leading) {
                        Text("Memory Consolidation: \(formatInterval(config.memoryConsolidationInterval))")
                        Slider(value: .init(
                            get: { config.memoryConsolidationInterval },
                            set: { config.memoryConsolidationInterval = $0 }
                        ), in: 1800...43200, step: 1800) // 30 min to 12 hours
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Model Optimization: \(formatInterval(config.modelOptimizationInterval))")
                        Slider(value: .init(
                            get: { config.modelOptimizationInterval },
                            set: { config.modelOptimizationInterval = $0 }
                        ), in: 3600...604800, step: 3600) // 1 hour to 1 week
                    }
                    
                    VStack(alignment: .leading) {
                        Text("System Maintenance: \(formatInterval(config.systemMaintenanceInterval))")
                        Slider(value: .init(
                            get: { config.systemMaintenanceInterval },
                            set: { config.systemMaintenanceInterval = $0 }
                        ), in: 86400...2592000, step: 86400) // 1 day to 30 days
                    }
                }
                
                Section(header: Text("Storage Management")) {
                    VStack(alignment: .leading) {
                        Text("Minimum Free Space: \(ByteCountFormatter.string(fromByteCount: config.minFreeSpaceThreshold, countStyle: .file))")
                        Slider(value: .init(
                            get: { Double(config.minFreeSpaceThreshold) },
                            set: { config.minFreeSpaceThreshold = Int64($0) }
                        ), in: 500_000_000...10_000_000_000, step: 500_000_000) // 500MB to 10GB
                    }
                    
                    Stepper("Max Models to Keep: \(config.maxModelsToKeep)", 
                           value: $config.maxModelsToKeep, 
                           in: 1...10)
                }
                
                Section(header: Text("Important Information")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("⚠️ Background processing helps maintain optimal performance but may use battery power.")
                            .font(.caption)
                            .foregroundColor(.orange)
                        
                        Text("💡 iOS limits background processing time. Critical tasks will complete during app usage.")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Text("🔋 Model optimization requires device to be plugged in.")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle("Background Config")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(config)
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct BackgroundProcessingView_Previews: PreviewProvider {
    static var previews: some View {
        BackgroundProcessingView()
    }
}