import Foundation
import Combine

/// Enhanced Model Download Manager with Robust Persistence
/// Handles automatic downloading, verification, and management of MLX models from HuggingFace Hub
@MainActor
class ModelDownloadManager: ObservableObject {
    static let shared = ModelDownloadManager()
    
    @Published private(set) var downloadProgress: [String: DownloadProgress] = [:]
    @Published private(set) var downloadedModels: Set<String> = []
    @Published private(set) var verifiedModels: Set<String> = []
    @Published private(set) var isDownloading = false
    @Published private(set) var availableSpace: Int64 = 0
    
    // Make these public so they can be accessed from views
    public let modelsDirectory: URL
    private let metadataDirectory: URL
    private let hubBaseURL = "https://huggingface.co"
    private var downloadTasks: [String: URLSessionDownloadTask] = [:]
    private var urlSession: URLSession
    
    // Enhanced persistence tracking
    private let userDefaults = UserDefaults.standard
    private let downloadedModelsKey = "DCourt_DownloadedModels"
    private let verifiedModelsKey = "DCourt_VerifiedModels"
    
    private init() {
        // Create models directory
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        modelsDirectory = documentsURL.appendingPathComponent("Models", isDirectory: true)
        metadataDirectory = modelsDirectory.appendingPathComponent(".metadata", isDirectory: true)
        
        // Create directories if they don't exist
        try? FileManager.default.createDirectory(at: modelsDirectory, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: metadataDirectory, withIntermediateDirectories: true)
        
        // Configure URL session for large downloads
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 3600 // 1 hour for large models
        config.allowsCellularAccess = true
        config.waitsForConnectivity = true
        urlSession = URLSession(configuration: config)
        
        // Load existing models with verification
        Task {
            await loadAndVerifyModels()
            updateAvailableSpace()
        }
    }
    
    // MARK: - Enhanced Persistence System
    
    /// Loads and verifies all existing models on startup - make public
    public func loadAndVerifyModels() async {
        print("🔍 Loading and verifying existing models...")
        
        // Load from UserDefaults first
        if let savedDownloaded = userDefaults.array(forKey: downloadedModelsKey) as? [String] {
            downloadedModels = Set(savedDownloaded)
        }
        if let savedVerified = userDefaults.array(forKey: verifiedModelsKey) as? [String] {
            verifiedModels = Set(savedVerified)
        }
        
        // Scan file system and verify integrity
        guard FileManager.default.fileExists(atPath: modelsDirectory.path) else {
            print("📁 Models directory doesn't exist yet")
            return
        }
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: modelsDirectory.path)
            let modelFolders = contents.filter { !$0.hasPrefix(".") }
            
            var actuallyDownloaded: Set<String> = []
            var actuallyVerified: Set<String> = []
            
            for modelId in modelFolders {
                // Check if model directory exists and has content
                if await isModelCompletelyDownloaded(id: modelId) {
                    actuallyDownloaded.insert(modelId)
                    
                    // Verify model integrity
                    if await verifyModelSilently(id: modelId) {
                        actuallyVerified.insert(modelId)
                        print("✅ Verified existing model: \(modelId)")
                    } else {
                        print("⚠️  Model exists but failed verification: \(modelId)")
                    }
                } else {
                    print("🧹 Cleaning up incomplete model: \(modelId)")
                    await cleanupIncompleteModel(id: modelId)
                }
            }
            
            // Update state with verified models
            downloadedModels = actuallyDownloaded
            verifiedModels = actuallyVerified
            
            // Persist to UserDefaults
            await savePersistentState()
            
            print("📦 Loaded \(downloadedModels.count) downloaded models, \(verifiedModels.count) verified")
            
        } catch {
            print("❌ Error loading models: \(error)")
        }
    }
    
    /// Saves current state to UserDefaults for persistence
    private func savePersistentState() async {
        userDefaults.set(Array(downloadedModels), forKey: downloadedModelsKey)
        userDefaults.set(Array(verifiedModels), forKey: verifiedModelsKey)
        userDefaults.synchronize()
    }
    
    /// Checks if a model is completely downloaded
    private func isModelCompletelyDownloaded(id: String) async -> Bool {
        let modelPath = modelsDirectory.appendingPathComponent(id, isDirectory: true)
        let metadataPath = metadataDirectory.appendingPathComponent("\(id).json")
        
        // Check if model directory exists
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: modelPath.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            return false
        }
        
        // Check if completion marker exists
        if FileManager.default.fileExists(atPath: metadataPath.path) {
            do {
                let data = try Data(contentsOf: metadataPath)
                let metadata = try JSONDecoder().decode(ModelMetadata.self, from: data)
                return metadata.isComplete
            } catch {
                print("⚠️  Failed to read metadata for \(id): \(error)")
            }
        }
        
        // Fallback: check for essential files
        let configPath = modelPath.appendingPathComponent("config.json")
        return FileManager.default.fileExists(atPath: configPath.path)
    }
    
    /// Silently verifies a model without throwing errors
    private func verifyModelSilently(id: String) async -> Bool {
        do {
            guard let model = HuggingFaceModel.examples.first(where: { $0.id == id }) else {
                return false
            }
            try await verifyModelIntegrity(model)
            return true
        } catch {
            return false
        }
    }
    
    /// Creates completion metadata for a model
    private func createModelMetadata(for model: HuggingFaceModel) async throws {
        let metadata = ModelMetadata(
            modelId: model.id,
            modelName: model.name,
            downloadDate: Date(),
            isComplete: true,
            version: "1.0"
        )
        
        let metadataPath = metadataDirectory.appendingPathComponent("\(model.id).json")
        let data = try JSONEncoder().encode(metadata)
        try data.write(to: metadataPath)
    }
    
    /// Cleans up incomplete model downloads
    private func cleanupIncompleteModel(id: String) async {
        let modelPath = modelsDirectory.appendingPathComponent(id, isDirectory: true)
        let metadataPath = metadataDirectory.appendingPathComponent("\(id).json")
        
        try? FileManager.default.removeItem(at: modelPath)
        try? FileManager.default.removeItem(at: metadataPath)
        
        downloadedModels.remove(id)
        verifiedModels.remove(id)
        await savePersistentState()
    }
    
    // MARK: - Public Interface (Enhanced)
    
    /// Gets the models directory URL
    var modelsDirectoryURL: URL {
        return modelsDirectory
    }
    
    /// Downloads a model from HuggingFace Hub with robust persistence
    func downloadModel(_ model: HuggingFaceModel) async throws {
        guard !isModelVerified(id: model.id) else {
            print("✅ Model \(model.name) already downloaded and verified")
            return
        }
        
        guard hasEnoughSpace(for: model) else {
            throw ModelDownloadError.insufficientStorage
        }
        
        print("📥 Starting download of \(model.name)...")
        
        // Clean up any partial download first
        await cleanupIncompleteModel(id: model.id)
        
        // Create progress tracking
        let progress = DownloadProgress(
            modelId: model.id,
            modelName: model.name,
            status: .downloading,
            progress: 0.0,
            totalSize: estimateModelSize(model),
            downloadedSize: 0,
            speed: 0,
            remainingTime: 0
        )
        
        downloadProgress[model.id] = progress
        isDownloading = true
        
        do {
            // Download model files
            try await downloadModelFiles(model)
            
            // Verify download
            try await verifyModelIntegrity(model)
            
            // Create completion metadata
            try await createModelMetadata(for: model)
            
            // Update tracking
            downloadedModels.insert(model.id)
            verifiedModels.insert(model.id)
            downloadProgress[model.id]?.status = .completed
            
            // Persist state
            await savePersistentState()
            
            print("✅ Successfully downloaded and verified \(model.name)")
            
        } catch {
            downloadProgress[model.id]?.status = .failed
            downloadProgress[model.id]?.error = error.localizedDescription
            
            // Clean up failed download
            await cleanupIncompleteModel(id: model.id)
            
            throw error
        }
        
        // Check if any downloads are still active
        if downloadProgress.values.allSatisfy({ $0.status != .downloading }) {
            isDownloading = false
        }
        
        updateAvailableSpace()
    }
    
    /// Downloads multiple models with priority ordering and persistence
    func downloadModels(_ models: [HuggingFaceModel]) async {
        // Sort by priority and compatibility
        let sortedModels = models
            .filter { $0.isCompatibleWithDevice }
            .filter { !isModelVerified(id: $0.id) } // Skip already verified models
            .sorted { $0.priority > $1.priority }
        
        guard !sortedModels.isEmpty else {
            print("✅ All requested models are already downloaded")
            return
        }
        
        for model in sortedModels {
            do {
                try await downloadModel(model)
            } catch {
                print("❌ Failed to download \(model.name): \(error)")
                continue
            }
        }
    }
    
    /// Downloads the best available model for the device
    func downloadOptimalModel() async throws {
        // For iPhone 15 Pro Max, try the best uncensored model first
        let deviceRAM = DeviceCapabilities.getAvailableRAM()
        let deviceStorage = DeviceCapabilities.getAvailableStorage()
        
        print("📱 Device specs - RAM: \(deviceRAM)GB, Storage: \(deviceStorage)GB")
        
        // iPhone 15 Pro Max specific optimization
        var recommendedModel: HuggingFaceModel?
        
        if deviceRAM >= 8 && deviceStorage >= 6 {
            // Try premium uncensored models first
            recommendedModel = HuggingFaceModel.examples.first(where: { 
                $0.id == "mlx-community/NeuralDaredevil-8B-abliterated-4bit" 
            })
        } else if deviceRAM >= 6 && deviceStorage >= 4 {
            // Fallback to Hermes
            recommendedModel = HuggingFaceModel.examples.first(where: { 
                $0.id == "mlx-community/Hermes-3-Llama-3.1-8B-4bit" 
            })
        } else {
            // Use smaller model
            recommendedModel = HuggingFaceModel.examples.first(where: { 
                $0.id == "mlx-community/Llama-3.2-3B-Instruct-4bit" 
            })
        }
        
        guard let model = recommendedModel else {
            throw ModelDownloadError.noCompatibleModel
        }
        
        print("🎯 Downloading optimal model for device: \(model.name)")
        try await downloadModel(model)
    }
    
    /// Checks if a model is downloaded and verified
    func isModelDownloaded(id: String) -> Bool {
        return downloadedModels.contains(id) && modelDirectoryExists(id: id)
    }
    
    /// Checks if a model is verified and ready to use
    func isModelVerified(id: String) -> Bool {
        return verifiedModels.contains(id) && isModelDownloaded(id: id)
    }
    
    /// Gets the local path for a downloaded model
    func getModelPath(id: String) -> URL? {
        guard isModelVerified(id: id) else { return nil }
        return modelsDirectory.appendingPathComponent(id, isDirectory: true)
    }
    
    /// Deletes a downloaded model to free space
    func deleteModel(id: String) async throws {
        let modelPath = modelsDirectory.appendingPathComponent(id, isDirectory: true)
        let metadataPath = metadataDirectory.appendingPathComponent("\(id).json")
        
        guard FileManager.default.fileExists(atPath: modelPath.path) else {
            throw ModelDownloadError.modelNotFound
        }
        
        try FileManager.default.removeItem(at: modelPath)
        try? FileManager.default.removeItem(at: metadataPath)
        
        downloadedModels.remove(id)
        verifiedModels.remove(id)
        downloadProgress.removeValue(forKey: id)
        
        await savePersistentState()
        updateAvailableSpace()
        print("🗑️ Deleted model: \(id)")
    }
    
    /// Updates a model to the latest version
    func updateModel(_ model: HuggingFaceModel) async throws {
        // Delete old version
        if isModelDownloaded(id: model.id) {
            try await deleteModel(id: model.id)
        }
        
        // Download new version
        try await downloadModel(model)
    }
    
    /// Cancels an ongoing download
    func cancelDownload(modelId: String) {
        downloadTasks[modelId]?.cancel()
        downloadTasks.removeValue(forKey: modelId)
        downloadProgress[modelId]?.status = .cancelled
        
        Task {
            await cleanupIncompleteModel(id: modelId)
        }
    }
    
    /// Re-verifies all downloaded models
    func reVerifyAllModels() async {
        print("🔍 Re-verifying all models...")
        
        var newVerified: Set<String> = []
        
        for modelId in downloadedModels {
            if await verifyModelSilently(id: modelId) {
                newVerified.insert(modelId)
            } else {
                print("⚠️  Model failed re-verification: \(modelId)")
                await cleanupIncompleteModel(id: modelId)
            }
        }
        
        verifiedModels = newVerified
        await savePersistentState()
        
        print("✅ Re-verification complete: \(verifiedModels.count) models verified")
    }
    
    // MARK: - HuggingFace Hub Integration (Enhanced)
    
    private func downloadModelFiles(_ model: HuggingFaceModel) async throws {
        let modelDirectory = modelsDirectory.appendingPathComponent(model.id, isDirectory: true)
        try FileManager.default.createDirectory(at: modelDirectory, withIntermediateDirectories: true)
        
        // Get list of files to download using the correct API
        let filesToDownload = try await getModelFileList(model)
        let totalFiles = filesToDownload.count
        var completedFiles = 0
        
        guard !filesToDownload.isEmpty else {
            throw ModelDownloadError.noFilesToDownload
        }
        
        print("📄 Downloading \(totalFiles) files for \(model.name)...")
        
        // Download files with better error handling
        for file in filesToDownload {
            do {
                try await downloadFile(
                    model: model,
                    filename: file.filename,
                    url: file.downloadURL,
                    destinationDirectory: modelDirectory
                )
                
                completedFiles += 1
                let progress = Double(completedFiles) / Double(totalFiles)
                downloadProgress[model.id]?.progress = progress
                
                print("📄 Downloaded \(completedFiles)/\(totalFiles): \(file.filename)")
                
            } catch {
                print("❌ Failed to download \(file.filename): \(error)")
                throw error
            }
        }
        
        print("✅ All files downloaded for \(model.name)")
    }
    
    private func getModelFileList(_ model: HuggingFaceModel) async throws -> [ModelFile] {
        // Use the correct HuggingFace API endpoint
        let apiURL = "https://huggingface.co/api/models/\(model.id)"
        
        guard let url = URL(string: apiURL) else {
            throw ModelDownloadError.invalidURL
        }
        
        print("🔍 Fetching file list from: \(apiURL)")
        
        let (data, response) = try await urlSession.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ModelDownloadError.hubAPIError
        }
        
        if httpResponse.statusCode == 404 {
            throw ModelDownloadError.modelNotFound
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ HTTP Status: \(httpResponse.statusCode)")
            throw ModelDownloadError.hubAPIError
        }
        
        // Parse the model info response
        do {
            let modelInfo = try JSONDecoder().decode(HuggingFaceModelInfo.self, from: data)
            
            // Extract files from the model info
            let essentialFiles = modelInfo.siblings?.compactMap { sibling -> ModelFile? in
                let filename = sibling.rfilename
                
                // Filter essential files for MLX models
                if filename.hasSuffix(".safetensors") ||
                   filename == "config.json" ||
                   filename == "tokenizer.json" ||
                   filename == "tokenizer_config.json" ||
                   filename == "special_tokens_map.json" ||
                   filename == "tokenizer.model" ||
                   filename.contains("generation") ||
                   filename.hasSuffix(".txt") {
                    
                    return ModelFile(
                        filename: filename,
                        downloadURL: "https://huggingface.co/\(model.id)/resolve/main/\(filename)",
                        size: sibling.size ?? 0
                    )
                }
                return nil
            } ?? []
            
            guard !essentialFiles.isEmpty else {
                throw ModelDownloadError.noEssentialFiles
            }
            
            print("📋 Found \(essentialFiles.count) essential files to download")
            return essentialFiles
            
        } catch DecodingError.keyNotFound(let key, let context) {
            print("❌ JSON Parsing Error - Missing key: \(key), Context: \(context)")
            throw ModelDownloadError.hubAPIError
        } catch DecodingError.typeMismatch(let type, let context) {
            print("❌ JSON Parsing Error - Type mismatch for \(type), Context: \(context)")
            throw ModelDownloadError.hubAPIError
        } catch {
            print("❌ Failed to parse model info: \(error)")
            throw ModelDownloadError.hubAPIError
        }
    }
    
    private func downloadFile(model: HuggingFaceModel, filename: String, url: String, destinationDirectory: URL) async throws {
        guard let downloadURL = URL(string: url) else {
            throw ModelDownloadError.invalidURL
        }
        
        let destinationURL = destinationDirectory.appendingPathComponent(filename)
        
        // Skip if file already exists and has content
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: destinationURL.path)
                if let size = attributes[.size] as? Int64, size > 0 {
                    print("📄 Skipping existing file: \(filename)")
                    return
                }
            } catch {
                // Continue with download if we can't check size
            }
        }
        
        // Create intermediate directories if needed
        let parentDirectory = destinationURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: parentDirectory, withIntermediateDirectories: true)
        
        print("📥 Downloading \(filename) from \(url)")
        
        do {
            // Create a custom URLRequest with proper headers
            var request = URLRequest(url: downloadURL)
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("MLXDigitalCourt/1.0", forHTTPHeaderField: "User-Agent")
            request.timeoutInterval = 300 // 5 minutes timeout per file
            
            // Use the correct async download method
            let (tempURL, response) = try await urlSession.download(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response for \(filename)")
                throw ModelDownloadError.downloadFailed
            }
            
            print("📊 HTTP Status for \(filename): \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 404 {
                print("❌ File not found on server: \(filename)")
                throw ModelDownloadError.modelNotFound
            }
            
            guard httpResponse.statusCode == 200 else {
                print("❌ HTTP error \(httpResponse.statusCode) for \(filename)")
                if let data = try? Data(contentsOf: tempURL),
                   let errorMessage = String(data: data, encoding: .utf8) {
                    print("❌ Server error message: \(errorMessage)")
                }
                throw ModelDownloadError.downloadFailed
            }
            
            // Check file size
            let attributes = try FileManager.default.attributesOfItem(atPath: tempURL.path)
            if let size = attributes[.size] as? Int64 {
                print("📊 Downloaded file size: \(size) bytes for \(filename)")
                if size < 10 {
                    print("❌ Downloaded file too small: \(filename)")
                    throw ModelDownloadError.downloadFailed
                }
            }
            
            // Move file to final destination
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            try FileManager.default.moveItem(at: tempURL, to: destinationURL)
            print("✅ Successfully downloaded: \(filename)")
            
        } catch let error as ModelDownloadError {
            throw error
        } catch {
            print("❌ Download failed for \(filename): \(error)")
            throw ModelDownloadError.downloadFailed
        }
    }
    
    // MARK: - Model Verification
    
    private func verifyModelIntegrity(_ model: HuggingFaceModel) async throws {
        let modelDirectory = modelsDirectory.appendingPathComponent(model.id, isDirectory: true)
        let modelFiles = try FileManager.default.contentsOfDirectory(atPath: modelDirectory.path)

        // Accept a model if it has at least one MLX-supported weights file
        let hasSupportedWeights = modelFiles.contains { fn in
            let lower = fn.lowercased()
            return lower.hasSuffix(".gguf") || lower.hasSuffix(".safetensors") || lower.hasSuffix(".bin")
        }

        guard hasSupportedWeights else {
            throw ModelDownloadError.incompleteDownload
        }

        print("✅ [MLX PATCH] Verified model folder '\(model.id)' as valid LLM (weights: \(modelFiles.filter{ $0.hasSuffix(".gguf") || $0.hasSuffix(".safetensors") || $0.hasSuffix(".bin") }))")
    }
    
    // MARK: - Storage Management
    
    private func hasEnoughSpace(for model: HuggingFaceModel) -> Bool {
        let requiredSpace = estimateModelSize(model)
        return availableSpace > requiredSpace
    }
    
    private func estimateModelSize(_ model: HuggingFaceModel) -> Int64 {
        // Estimate based on model size and quantization
        let baseSize: Int64
        
        switch model.size {
        case "1B": baseSize = 1_000_000_000
        case "1.5B": baseSize = 1_500_000_000
        case "3B": baseSize = 3_000_000_000
        case "8B": baseSize = 8_000_000_000
        case "11B": baseSize = 11_000_000_000
        default: baseSize = 2_000_000_000
        }
        
        // Apply quantization factor
        let quantizationFactor: Double
        switch model.quantization {
        case "4-bit": quantizationFactor = 0.5
        case "8-bit": quantizationFactor = 0.75
        case "16-bit": quantizationFactor = 1.0
        default: quantizationFactor = 0.5
        }
        
        return Int64(Double(baseSize) * quantizationFactor)
    }
    
    private func updateAvailableSpace() {
        let spaceInGB = DeviceCapabilities.getAvailableStorage()
        availableSpace = Int64(spaceInGB) * 1_000_000_000 // Convert GB to bytes
        print("📊 Updated available space: \(spaceInGB) GB (\(availableSpace) bytes)")
    }
    
    private func modelDirectoryExists(id: String) -> Bool {
        let modelPath = modelsDirectory.appendingPathComponent(id, isDirectory: true)
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: modelPath.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }
}

// MARK: - Supporting Models

struct HuggingFaceModelInfo: Codable {
    let id: String?
    let modelId: String?
    let author: String?
    let sha: String?
    let siblings: [HuggingFaceFile]?
    
    enum CodingKeys: String, CodingKey {
        case id, modelId, author, sha, siblings
    }
}

struct HuggingFaceFile: Codable {
    let rfilename: String
    let size: Int64?
    
    enum CodingKeys: String, CodingKey {
        case rfilename, size
    }
}

struct ModelMetadata: Codable {
    let modelId: String
    let modelName: String
    let downloadDate: Date
    let isComplete: Bool
    let version: String
}

struct DownloadProgress {
    let modelId: String
    let modelName: String
    var status: DownloadStatus
    var progress: Double // 0.0 to 1.0
    var totalSize: Int64
    var downloadedSize: Int64
    var speed: Double // bytes per second
    var remainingTime: TimeInterval // seconds
    var error: String?
}

enum DownloadStatus {
    case pending
    case downloading
    case completed
    case failed
    case cancelled
}

struct ModelFile {
    let filename: String
    let downloadURL: String
    let size: Int64
}

// MARK: - Download Errors

enum ModelDownloadError: Error, LocalizedError {
    case insufficientStorage
    case noCompatibleModel
    case modelNotFound
    case invalidURL
    case hubAPIError
    case downloadFailed
    case incompleteDownload
    case verificationFailed
    case networkError
    case noFilesToDownload
    case noEssentialFiles
    
    var errorDescription: String? {
        switch self {
        case .insufficientStorage:
            return "Insufficient storage space for model download"
        case .noCompatibleModel:
            return "No compatible model found for this device"
        case .modelNotFound:
            return "Model not found"
        case .invalidURL:
            return "Invalid download URL"
        case .hubAPIError:
            return "HuggingFace Hub API error"
        case .downloadFailed:
            return "Model download failed"
        case .incompleteDownload:
            return "Model download incomplete"
        case .verificationFailed:
            return "Model verification failed"
        case .networkError:
            return "Network error during download"
        case .noFilesToDownload:
            return "No files to download for this model"
        case .noEssentialFiles:
            return "No essential files found for this model"
        }
    }
}