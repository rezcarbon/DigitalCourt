import SwiftUI

struct EnhancedModelSelectionView: View {
    @StateObject private var plcManager = PLCManager.shared
    @StateObject private var downloadManager = ModelDownloadManager.shared
    
    @State private var selectedModel: HuggingFaceModel?
    @State private var showingDownloadOptions = false
    @State private var isDownloading = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Header with device info
                deviceInfoSection
                
                List {
                    // Uncensored Models Section (Priority)
                    uncensoredModelsSection
                    
                    // Other Models Section
                    otherModelsSection
                    
                    // Remote Providers Section
                    remoteProvidersSection
                }
            }
            .navigationTitle("AI Model Selection")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Auto-Select") {
                        Task {
                            await plcManager.autoSelectProvider()
                        }
                    }
                }
            }
        }
    }
    
    private var deviceInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "iphone")
                Text("Device Capabilities")
                    .font(.headline)
                Spacer()
            }
            
            HStack {
                Text("RAM: \(DeviceCapabilities.getAvailableRAM()) GB")
                Spacer()
                Text("Storage: \(DeviceCapabilities.getAvailableStorage()) GB")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            if let recommended = DeviceCapabilities.getRecommendedModel() {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("Recommended: \(recommended.name)")
                        .font(.caption)
                        .fontWeight(.medium)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var uncensoredModelsSection: some View {
        Section(header: 
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.red)
                Text("Uncensored MLX Models (Primary)")
                    .foregroundColor(.red)
                    .fontWeight(.bold)
            }
        ) {
            ForEach(HuggingFaceModel.uncensoredModels, id: \.id) { model in
                ModelRow(
                    model: model,
                    isSelected: selectedModel?.id == model.id,
                    isDownloaded: downloadManager.isModelDownloaded(id: model.id),
                    isRecommended: model.id == DeviceCapabilities.getRecommendedModel()?.id
                ) {
                    selectModel(model)
                }
            }
        }
    }
    
    private var otherModelsSection: some View {
        Section(header: Text("Other MLX Models")) {
            ForEach(HuggingFaceModel.examples.filter { !$0.isUncensored }, id: \.id) { model in
                ModelRow(
                    model: model,
                    isSelected: selectedModel?.id == model.id,
                    isDownloaded: downloadManager.isModelDownloaded(id: model.id),
                    isRecommended: false
                ) {
                    selectModel(model)
                }
            }
        }
    }
    
    private var remoteProvidersSection: some View {
        Section(header: Text("Remote Providers (Fallback)")) {
            ProviderRow(
                name: "OpenAI GPT",
                description: "Cloud-based GPT models",
                isAvailable: !OpenAIProvider().isAvailable, // Placeholder
                icon: "cloud.fill"
            )
            
            ProviderRow(
                name: "Anthropic Claude", 
                description: "Cloud-based Claude models",
                isAvailable: !AnthropicProvider().isAvailable, // Placeholder
                icon: "cloud.fill"
            )
        }
    }
    
    private func selectModel(_ model: HuggingFaceModel) {
        selectedModel = model
        
        Task {
            if let mlxProvider = plcManager.modelProviders.first(where: { $0 is MLXModelProvider }) as? MLXModelProvider {
                do {
                    try await mlxProvider.switchToModel(model)
                    plcManager.switchModelProvider(mlxProvider)
                } catch {
                    print("Failed to switch to model: \(error)")
                }
            }
        }
    }
}

struct ModelRow: View {
    let model: HuggingFaceModel
    let isSelected: Bool
    let isDownloaded: Bool
    let isRecommended: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(model.name)
                            .fontWeight(isSelected ? .bold : .medium)
                        
                        if model.isUncensored {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        
                        if isRecommended {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                        
                        Spacer()
                    }
                    
                    Text(model.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    HStack {
                        Text("\(model.size) • \(model.quantization)")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                        
                        if !model.isCompatibleWithDevice {
                            Text("Requires more RAM")
                                .font(.caption2)
                                .foregroundColor(.red)
                        }
                        
                        Spacer()
                        
                        if isDownloaded {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "icloud.and.arrow.down")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ProviderRow: View {
    let name: String
    let description: String
    let isAvailable: Bool
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
            
            VStack(alignment: .leading) {
                Text(name)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(isAvailable ? "Available" : "Configure")
                .font(.caption)
                .foregroundColor(isAvailable ? .green : .orange)
        }
    }
}