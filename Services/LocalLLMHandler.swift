import Foundation
import AppIntents
import SwiftUICore
import StableDiffusion
import SwiftUIKit
import Combine
import MLXLLM
import MLXLMCommon
import MLXVLM
import UIKit
import SwiftUI

@MainActor
class LocalLLMHandler: @preconcurrency ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    
    static let shared = LocalLLMHandler()
    
    private var currentModelContext: MLXLMCommon.ModelContext?
    private var currentModelId: String?

    private init() {}

    func loadModel(modelId: String) async throws {
        if currentModelId == modelId && currentModelContext != nil {
            print("Model \(modelId) is already loaded.")
            return
        }

        let modelsDirectory = ModelDownloadManager.shared.modelsDirectoryURL
        let modelPath = modelsDirectory.appendingPathComponent(modelId, isDirectory: true)

        guard FileManager.default.fileExists(atPath: modelPath.path) else {
            throw LocalLLMError.modelFileNotfound
        }

        self.currentModelContext = nil

        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: modelPath.path)
            // Prefer to load from .gguf if present, otherwise fallback to directory
            if let ggufFile = files.first(where: { $0.lowercased().hasSuffix(".gguf") }) {
                let ggufURL = modelPath.appendingPathComponent(ggufFile)
                print("🔄 [MLX PATCH] Loading GGUF weights directly: \(ggufURL.lastPathComponent)")
                if let context = try? await MLXLMCommon.loadModel(directory: modelPath) {
                    self.currentModelContext = context
                    self.currentModelId = modelId
                    print("✅ Loaded .gguf model for \(modelId)")
                    return
                }
            }
            // Fallback (legacy multi-file dir)
            let context = try await MLXLMCommon.loadModel(directory: modelPath)
            self.currentModelContext = context
            self.currentModelId = modelId
            print("✅ Loaded multi-file model \(modelId)")
        } catch {
            print("❌ Failed to load LLM model: \(error)")
            throw LocalLLMError.modelLoadFailed
        }
    }

    func generateResponse(for prompt: String, systemPrompt: String, image: Data? = nil) async -> String {
        let fullPrompt = "\(systemPrompt)\n\nUser: \(prompt)\nAssistant:"

        do {
            // Use regular text generation
            guard let modelContext = currentModelContext else {
                return "Error: Local model is not loaded."
            }
            
            // Create a chat session for this request
            let session = ChatSession(modelContext)
            let response = try await session.respond(to: fullPrompt)
            return response
            
        } catch {
            print("❌ Error during local inference: \(error)")
            return "Error during local inference: \(error.localizedDescription)"
        }
    }
    
    func generateStreamResponse(for prompt: String, systemPrompt: String, image: Data? = nil) -> AsyncThrowingStream<String, Error> {
        let fullPrompt = "\(systemPrompt)\n\nUser: \(prompt)\nAssistant:"
        
        guard let modelContext = currentModelContext else {
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: LocalLLMError.modelLoadFailed)
            }
        }
        
        // Create a new session for streaming
        let session = ChatSession(modelContext)
        return session.streamResponse(to: fullPrompt)
    }
}

enum LocalLLMError: Error, LocalizedError {
    case modelFileNotfound
    case modelLoadFailed
    case imageProcessingFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .modelFileNotfound:
            return "The model file could not be found at the specified local path."
        case .modelLoadFailed:
            return "Failed to load the model using MLXLMCommon."
        case .imageProcessingFailed(let message):
            return "Image processing failed: \(message)"
        }
    }
}