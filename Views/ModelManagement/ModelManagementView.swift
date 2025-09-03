import SwiftUI

struct ModelManagementView: View {
    @StateObject private var modelDownloadManager = ModelDownloadManager.shared
    @StateObject private var bundledModelManager = BundledModelManager.shared
    @State private var showingDownloadAlert = false
    @State private var selectedModelId: String?
    @State private var downloadError: String?
    
    var body: some View {
        NavigationView {
            List {
                // Premium Bundled Model Section (Highlight NeuralDaredevil)
                if bundledModelManager.hasPremiumModel {
                    Section(header: 
                        HStack {
                            Text("🏆 Premium Bundled Model")
                            Spacer()
                            Text("READY")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(4)
                        }
                    ) {
                        if let neuralModel = bundledModelManager.getNeuralDaredevilModel() {
                            PremiumModelRow(model: neuralModel)
                        }
                    }
                }
                
                // Other Bundled Models
                if bundledModelManager.bundledModels.filter({ $0.isAvailable && !$0.isPremium }).count > 0 {
                    Section(header: Text("📦 Additional Bundled Models")) {
                        ForEach(bundledModelManager.bundledModels.filter { $0.isAvailable && !$0.isPremium }) { model in
                            BundledModelRow(model: model)
                        }
                    }
                }
                
                // Model Status
                Section(header: Text("📊 Current Status")) {
                    VStack(alignment: .leading, spacing: 8) {
                        if r.loadedModel != nil { !=nil
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Model Loaded and Ready")
                                    .fontWeight(.medium)
                                Spacer()
                            }
                            
                            if let currentPath = bundledModelManager.currentModelPath {
                                Text("Path: \(currentPath)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.orange)
                                Text("No Model Loaded")
                                    .fontWeight(.medium)
                                Spacer()
                                
                                Button("Load Best Model") {
                                    Task {
                                        await bundledModelManager.autoLoadBestModel()
                                    }
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // Download Additional Models Section
                Section(header: Text("🔽 Download Additional Models")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("iPhone 15 Pro Max - Additional Options")
                            .font(.headline)
                        
                        Text("Download more models for variety (optional)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button(action: downloadOptimalModel) {
                            HStack {
                                if modelDownloadManager.isDownloading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "cloud.download.fill")
                                }
                                Text(modelDownloadManager.isDownloading ? "Downloading..." : "Download Alternative Model")
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(modelDownloadManager.isDownloading)
                    }
                    .padding(.vertical, 4)
                }
                
                // Available Models Section (Downloadable)
                Section(header: Text("🌐 Available for Download")) {
                    ForEach(HuggingFaceModel.sortedByPriority) { model in
                        DownloadableModelRow(model: model)
                    }
                }
                
                // Storage Info
                Section(header: Text("💾 Storage Info")) {
                    StorageInfoView()
                }
            }
            .navigationTitle("Model Management")
            .refreshable {
                await modelDownloadManager.loadAndVerifyModels()
            }
            .onAppear {
                // Debug bundle contents
                bundledModelManager.debugBundleContents()
                
                // Ensure model is loaded when view appears
                if bundledModelManager.loadedModel == nil {
                    Task {
                        await bundledModelManager.autoLoadBestModel()
                    }
                }
            }
            .alert("Download Error", isPresented: .constant(downloadError != nil)) {
                Button("OK") { downloadError = nil }
            } message: {
                if let error = downloadError {
                    Text(error)
                }
            }
        }
    }
    
    private func downloadOptimalModel() {
        Task {
            do {
                try await modelDownloadManager.downloadOptimalModel()
            } catch {
                await MainActor.run {
                    downloadError = error.localizedDescription
                }
            }
        }
    }
}

struct PremiumModelRow: View {
    let model: BundledModel
    @StateObject private var bundledManager = BundledModelManager.shared
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(model.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("PREMIUM")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange)
                        .cornerRadius(4)
                }
                
                Text(model.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Label(model.size, systemImage: "cpu.fill")
                        .foregroundColor(.blue)
                    Label("Uncensored", systemImage: "lock.open.fill")
                        .foregroundColor(.orange)
                    Label("Bundled", systemImage: "app.badge.checkmark.fill")
                        .foregroundColor(.green)
                }
                .font(.caption2)
            }
            
            Spacer()
            
            VStack {
                if bundledManager.loadedModel != nil && bundledManager.currentModelPath?.contains(model.bundlePath) == true {
                    VStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                        Text("Active")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                } else {
                    Button(action: {
                        Task {
                            try? await bundledManager.loadBundledModel(model)
                        }
                    }) {
                        VStack {
                            Image(systemName: bundledManager.isLoadingBundledModel ? "arrow.clockwise" : "play.circle.fill")
                                .font(.title2)
                            Text(bundledManager.isLoadingBundledModel ? "Loading" : "Load")
                                .font(.caption2)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(bundledManager.isLoadingBundledModel)
                }
            }
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.1))
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 4)
    }
}

struct BundledModelRow: View {
    let model: BundledModel
    @StateObject private var bundledManager = BundledModelManager.shared
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(model.name)
                    .font(.headline)
                
                Text(model.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Label(model.size, systemImage: "cpu")
                    Label("Bundled", systemImage: "app.badge.checkmark")
                        .foregroundColor(.green)
                }
                .font(.caption2)
            }
            
            Spacer()
            
            Button(action: {
                Task {
                    try? await bundledManager.loadBundledModel(model)
                }
            }) {
                if bundledManager.isLoadingBundledModel {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text("Load")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(bundledManager.isLoadingBundledModel)
        }
        .padding(.vertical, 4)
    }
}

struct DownloadableModelRow: View {
    let model: HuggingFaceModel
    @StateObject private var modelManager = ModelDownloadManager.shared
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(model.name)
                    .font(.headline)
                
                Text(model.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Label(model.size, systemImage: "cpu")
                    Label(model.quantization, systemImage: "arrow.down.circle")
                    
                    if model.isUncensored {
                        Label("Uncensored", systemImage: "lock.open")
                            .foregroundColor(.orange)
                    }
                    
                    if !model.isCompatibleWithDevice {
                        Label("Requires more RAM", systemImage: "exclamationmark.triangle")
                            .foregroundColor(.red)
                    }
                }
                .font(.caption2)
            }
            
            Spacer()
            
            VStack {
                if modelManager.isModelVerified(id: model.id) {
                    Label("Downloaded", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                } else if modelManager.downloadProgress[model.id]?.status == .downloading {
                    VStack {
                        ProgressView(value: modelManager.downloadProgress[model.id]?.progress ?? 0)
                        Text("\(Int((modelManager.downloadProgress[model.id]?.progress ?? 0) * 100))%")
                            .font(.caption2)
                    }
                } else {
                    Button(action: {
                        Task {
                            try? await modelManager.downloadModel(model)
                        }
                    }) {
                        Text("Download")
                    }
                    .buttonStyle(.bordered)
                    .disabled(!model.isCompatibleWithDevice)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct DownloadProgressRow: View {
    let progress: DownloadProgress
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(progress.modelName)
                .font(.headline)
            
            ProgressView(value: progress.progress) {
                Text("\(Int(progress.progress * 100))%")
            }
            
            if progress.status == .failed, let error = progress.error {
                Text("Error: \(error)")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
}

struct StorageInfoView: View {
    @StateObject private var modelManager = ModelDownloadManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Available Space:")
                Spacer()
                Text("\(modelManager.availableSpace / 1_000_000_000) GB")
                    .fontWeight(.medium)
            }
            
            HStack {
                Text("Downloaded Models:")
                Spacer()
                Text("\(modelManager.downloadedModels.count)")
                    .fontWeight(.medium)
            }
            
            HStack {
                Text("Verified Models:")
                Spacer()
                Text("\(modelManager.verifiedModels.count)")
                    .fontWeight(.medium)
            }
        }
    }
}

struct CurrentModelStatusView: View {
    @StateObject private var bundledManager = BundledModelManager.shared
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let modelName = bundledManager.currentModelName {
                    Text("✅ \(modelName)")
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    Text("Model is loaded and ready")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("No model loaded")
                        .font(.headline)
                        .foregroundColor(.orange)
                    
                    Text("Loading default model...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if bundledManager.isLoadingBundledModel {
                ProgressView()
                    .scaleEffect(0.8)
            } else if bundledManager.currentModelName != nil {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }
}
