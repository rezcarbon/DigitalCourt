import Foundation
import MLX
import MLXLMCommon
import MLXLLM
import Combine

/// Manages bundled MLX models that ship with the app
@MainActor
class BundledModelManager: ObservableObject {
    static let shared = BundledModelManager()
    
    @Published private(set) var bundledModels: [BundledModel] = []
    @Published private(set) var isLoadingBundledModel = false
    @Published private(set) var loadedModel: MLXLMCommon.ModelContext?
    @Published private(set) var currentModelPath: String?
    
    private init() {
        loadBundledModels()
    }
    
    private func loadBundledModels() {
        // Define the premium bundled model - NeuralDaredevil with GGUF support
        bundledModels = [
            BundledModel(
                id: "bundled-neuraldaredevil-8b",
                name: "NeuralDaredevil 8B (Bundled)",
                description: "Premium uncensored model with enhanced reasoning - Ready to use!",
                size: "8B",
                bundlePath: "NeuralDaredevil-8B-abliterated-4bit",
                modelFileName: "NeuralDaredevil-8B-abliterated-4bit.gguf",
                isAvailable: checkModelAvailability("NeuralDaredevil-8B-abliterated-4bit"),
                isPremium: true
            ),
            BundledModel(
                id: "bundled-phi3-mini",
                name: "Phi-3 Mini (Bundled)",
                description: "Microsoft Phi-3 Mini - 3.8B parameters, optimized for mobile",
                size: "3.8B",
                bundlePath: "phi3-mini-4k-mlx",
                modelFileName: "weights.safetensors",
                isAvailable: checkModelAvailability("phi3-mini-4k-mlx"),
                isPremium: false
            )
        ]
        
        let availableModels = bundledModels.filter(\.isAvailable)
        print("📦 Found \(availableModels.count) bundled models:")
        for model in availableModels {
            print("  ✅ \(model.name) (\(model.size))")
        }
        
        // Auto-load the best available model
        if let premiumModel = availableModels.first(where: \.isPremium) {
            print("🚀 Auto-loading premium bundled model: \(premiumModel.name)")
            Task {
                try? await loadBundledModel(premiumModel)
            }
        }
    }
    
    private func checkModelAvailability(_ modelPath: String) -> Bool {
        // Method 1: Check in main bundle directly
        if let modelURL = Bundle.main.url(forResource: modelPath, withExtension: nil) {
            print("✅ Found model directory in bundle: \(modelURL.path)")
            
            // Check for GGUF file specifically for NeuralDaredevil
            if modelPath.contains("NeuralDaredevil") {
                let ggufURL = modelURL.appendingPathComponent("NeuralDaredevil-8B-abliterated-4bit.gguf")
                let hasGGUF = FileManager.default.fileExists(atPath: ggufURL.path)
                print("📄 GGUF file exists: \(hasGGUF) at \(ggufURL.path)")
                return hasGGUF
            }
            
            // For other models, check for config.json
            let configURL = modelURL.appendingPathComponent("config.json")
            return FileManager.default.fileExists(atPath: configURL.path)
        }
        
        // Method 2: Check in BundledModels subdirectory
        guard let bundleURL = Bundle.main.url(forResource: "BundledModels", withExtension: nil) else {
            print("❌ BundledModels directory not found in bundle")
            return false
        }
        
        let modelURL = bundleURL.appendingPathComponent(modelPath)
        
        // For NeuralDaredevil, look for GGUF file
        if modelPath.contains("NeuralDaredevil") {
            let ggufURL = modelURL.appendingPathComponent("NeuralDaredevil-8B-abliterated-4bit.gguf")
            let hasGGUF = FileManager.default.fileExists(atPath: ggufURL.path)
            
            if hasGGUF {
                print("✅ Bundled GGUF model available: \(modelPath)")
                print("   📁 Path: \(ggufURL.path)")
                return true
            }
        }
        
        // For other models, check for config.json
        let configURL = modelURL.appendingPathComponent("config.json")
        let hasConfig = FileManager.default.fileExists(atPath: configURL.path)
        
        if hasConfig {
            print("✅ Bundled model available: \(modelPath)")
            print("   📁 Path: \(modelURL.path)")
            return true
        }
        
        print("❌ Bundled model not found: \(modelPath)")
        print("   📁 Searched: \(modelURL.path)")
        return false
    }
    
    /// Loads a bundled model for immediate use
    func loadBundledModel(_ model: BundledModel) async throws {
        guard model.isAvailable else {
            throw BundledModelError.modelNotFound
        }
        
        isLoadingBundledModel = true
        
        do {
            print("📱 Loading bundled model: \(model.name)")
            
            var modelURL: URL?
            
            // Try to find the model in the bundle
            if let directURL = Bundle.main.url(forResource: model.bundlePath, withExtension: nil) {
                modelURL = directURL
            } else if let bundleURL = Bundle.main.url(forResource: "BundledModels", withExtension: nil) {
                modelURL = bundleURL.appendingPathComponent(model.bundlePath)
            }
            
            guard let foundModelURL = modelURL else {
                throw BundledModelError.modelNotFound
            }
            
            guard FileManager.default.fileExists(atPath: foundModelURL.path) else {
                print("❌ Model directory not found: \(foundModelURL.path)")
                throw BundledModelError.modelNotFound
            }
            
            print("📂 Loading model from: \(foundModelURL.path)")
            
            // For GGUF models, we need to handle them differently
            if model.modelFileName?.hasSuffix(".gguf") == true {
                let ggufPath = foundModelURL.appendingPathComponent(model.modelFileName!)
                
                guard FileManager.default.fileExists(atPath: ggufPath.path) else {
                    print("❌ GGUF file not found: \(ggufPath.path)")
                    throw BundledModelError.modelNotFound
                }
                
                print("📄 Loading GGUF model: \(ggufPath.path)")
                
                // Load GGUF model using MLXLMCommon
                let loadedModel = try await MLXLMCommon.loadModel(directory: foundModelURL)
                
                await MainActor.run {
                    self.loadedModel = loadedModel
                    self.currentModelPath = ggufPath.path
                    self.isLoadingBundledModel = false
                }
            } else {
                // Load standard MLX model directory
                let loadedModel = try await MLXLMCommon.loadModel(directory: foundModelURL)
                
                await MainActor.run {
                    self.loadedModel = loadedModel
                    self.currentModelPath = foundModelURL.path
                    self.isLoadingBundledModel = false
                }
            }
            
            print("✅ Successfully loaded bundled model: \(model.name)")
            
            // Notify the app that a model is ready
            NotificationCenter.default.post(
                name: .modelDidLoad,
                object: model,
                userInfo: ["modelPath": currentModelPath ?? ""]
            )
            
        } catch {
            await MainActor.run {
                self.isLoadingBundledModel = false
            }
            print("❌ Failed to load bundled model: \(error)")
            throw error
        }
    }
    
    /// Gets the best available bundled model (prioritizes premium)
    func getBestBundledModel() -> BundledModel? {
        let availableModels = bundledModels.filter(\.isAvailable)
        
        // First try premium models
        if let premium = availableModels.first(where: \.isPremium) {
            return premium
        }
        
        // Fallback to any available model
        return availableModels.first
    }
    
    /// Gets the NeuralDaredevil model specifically
    func getNeuralDaredevilModel() -> BundledModel? {
        return bundledModels.first { $0.id == "bundled-neuraldaredevil-8b" && $0.isAvailable }
    }
    
    /// Checks if any bundled models are available
    var hasBundledModels: Bool {
        return bundledModels.contains(where: \.isAvailable)
    }
    
    /// Checks if the premium model (NeuralDaredevil) is available
    var hasPremiumModel: Bool {
        return bundledModels.contains { $0.isPremium && $0.isAvailable }
    }
    
    /// Gets the current model name if loaded
    var currentModelName: String? {
        guard let currentPath = currentModelPath else { return nil }
        
        // Find the model that matches the current path
        if let model = bundledModels.first(where: { model in
            currentPath.contains(model.bundlePath) || currentPath.contains(model.modelFileName ?? "")
        }) {
            return model.name
        }
        
        // Fallback to extracting name from path
        return URL(fileURLWithPath: currentPath).lastPathComponent
    }

    /// Auto-loads the best model on app start
    func autoLoadBestModel() async {
        guard loadedModel == nil else {
            print("📱 Model already loaded")
            return
        }
        
        if let bestModel = getBestBundledModel() {
            do {
                try await loadBundledModel(bestModel)
            } catch {
                print("❌ Failed to auto-load model: \(error)")
            }
        }
    }
    
    /// Debug method to list all files in bundle
    func debugBundleContents() {
        print("🔍 Debug: Checking bundle contents...")
        
        // Check main bundle resources
        if let bundlePath = Bundle.main.resourcePath {
            print("📁 Bundle path: \(bundlePath)")
            
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: bundlePath)
                print("📋 Bundle contents: \(contents.count) items")
                
                for item in contents {
                    if item.contains("Neural") || item.contains("Bundle") || item.contains("Model") {
                        print("  🔍 Found: \(item)")
                    }
                }
            } catch {
                print("❌ Error reading bundle: \(error)")
            }
        }
    }
}

// MARK: - Supporting Models

struct BundledModel: Identifiable {
    let id: String
    let name: String
    let description: String
    let size: String
    let bundlePath: String
    let modelFileName: String?
    let isAvailable: Bool
    let isPremium: Bool
    
    init(id: String, name: String, description: String, size: String, bundlePath: String, modelFileName: String? = nil, isAvailable: Bool, isPremium: Bool = false) {
        self.id = id
        self.name = name
        self.description = description
        self.size = size
        self.bundlePath = bundlePath
        self.modelFileName = modelFileName
        self.isAvailable = isAvailable
        self.isPremium = isPremium
    }
}

enum BundledModelError: Error, LocalizedError {
    case modelNotFound
    case loadingFailed
    case incompatibleModel
    
    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "Bundled model not found in app bundle"
        case .loadingFailed:
            return "Failed to load bundled model"
        case .incompatibleModel:
            return "Bundled model is not compatible with this device"
        }
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let modelDidLoad = Notification.Name("modelDidLoad")
    static let modelDidFailToLoad = Notification.Name("modelDidFailToLoad")
}