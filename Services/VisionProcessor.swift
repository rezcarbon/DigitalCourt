import Foundation
import Vision
import CoreImage
import UIKit
import Combine
import NaturalLanguage

@MainActor
class VisionProcessor: ObservableObject {
    static let shared = VisionProcessor()
    
    @Published var isProcessing = false
    @Published var lastProcessingResult: VisionResult?
    
    private init() {}
    
    // MARK: - Main Processing Method
    
    func processImage(_ imageData: Data, taskType: VisionTaskType) async -> VisionResult {
        isProcessing = true
        let startTime = Date()
        
        defer {
            isProcessing = false
        }
        
        guard let image = UIImage(data: imageData),
              let cgImage = image.cgImage else {
            let result = VisionResult(
                taskType: taskType.rawValue,
                success: false,
                confidence: 0.0,
                processingTime: Date().timeIntervalSince(startTime),
                results: [:],
                timestamp: Date()
            )
            lastProcessingResult = result
            return result
        }
        
        let result = await withCheckedContinuation { continuation in
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            var results: [String: Any] = [:]
            var success = false
            var confidence = 0.0
            
            do {
                switch taskType {
                case .objectDetection:
                    let request = VNDetectRectanglesRequest { request, error in
                        if let observations = request.results as? [VNRectangleObservation] {
                            let objects = observations.map { observation in
                                VisionDetectedObject(
                                    label: "Rectangle",
                                    confidence: Double(observation.confidence),
                                    boundingBox: observation.boundingBox,
                                    attributes: [:]
                                )
                            }
                            results["objects"] = objects
                            confidence = Double(observations.first?.confidence ?? 0.0)
                            success = true
                        } else if let error = error {
                            print("Object detection error: \(error)")
                        }
                    }
                    try handler.perform([request])
                    
                case .textRecognition:
                    let request = VNRecognizeTextRequest { request, error in
                        if let observations = request.results as? [VNRecognizedTextObservation] {
                            let textBlocks = observations.compactMap { observation -> TextBlock? in
                                guard let topCandidate = observation.topCandidates(1).first else { return nil }
                                return TextBlock(
                                    text: topCandidate.string,
                                    boundingBox: observation.boundingBox,
                                    confidence: Double(topCandidate.confidence)
                                )
                            }
                            let fullText = textBlocks.map { $0.text }.joined(separator: " ")
                            results["text"] = fullText
                            results["textBlocks"] = textBlocks
                            confidence = Double(observations.first?.topCandidates(1).first?.confidence ?? 0.0)
                            success = true
                        } else if let error = error {
                            print("Text recognition error: \(error)")
                        }
                    }
                    request.recognitionLevel = .accurate
                    try handler.perform([request])
                    
                case .faceDetection:
                    let request = VNDetectFaceRectanglesRequest { request, error in
                        if let observations = request.results as? [VNFaceObservation] {
                            let faces = observations.map { observation in
                                DetectedFace(
                                    boundingBox: observation.boundingBox,
                                    confidence: Double(observation.confidence),
                                    attributes: FaceAttributes(
                                        age: nil,
                                        gender: nil,
                                        emotion: nil,
                                        expressions: [:]
                                    )
                                )
                            }
                            results["faces"] = faces
                            confidence = Double(observations.first?.confidence ?? 0.0)
                            success = true
                        } else if let error = error {
                            print("Face detection error: \(error)")
                        }
                    }
                    try handler.perform([request])
                    
                case .sceneAnalysis:
                    let request = VNClassifyImageRequest { request, error in
                        if let observations = request.results as? [VNClassificationObservation],
                           let topObservation = observations.first {
                            results["scene"] = topObservation.identifier
                            results["allScenes"] = observations.prefix(5).map { 
                                ["identifier": $0.identifier, "confidence": $0.confidence] 
                            }
                            confidence = Double(topObservation.confidence)
                            success = true
                        } else if let error = error {
                            print("Scene analysis error: \(error)")
                        }
                    }
                    try handler.perform([request])
                    
                case .depthEstimation:
                    // Depth estimation would require specialized models or ARKit
                    results["depth"] = "Depth estimation not implemented"
                    results["message"] = "This feature requires specialized depth sensing hardware or models"
                    success = false
                }
            } catch {
                print("Vision processing error: \(error)")
                success = false
                results["error"] = error.localizedDescription
            }
            
            let finalResult = VisionResult(
                taskType: taskType.rawValue,
                success: success,
                confidence: confidence,
                processingTime: Date().timeIntervalSince(startTime),
                results: results,
                timestamp: Date()
            )
            
            continuation.resume(returning: finalResult)
        }
        
        lastProcessingResult = result
        return result
    }
    
    // MARK: - Specific Task Methods
    
    func recognizeText(_ imageData: Data) async -> TextRecognitionResult {
        let result = await processImage(imageData, taskType: .textRecognition)
        let text = result.results["text"] as? String ?? ""
        let textBlocks = result.results["textBlocks"] as? [TextBlock] ?? []
        
        return TextRecognitionResult(
            recognizedText: text,
            confidence: result.confidence,
            textBlocks: textBlocks,
            language: detectLanguage(text: text),
            timestamp: Date()
        )
    }
    
    func detectFaces(_ imageData: Data) async -> [DetectedFace] {
        let result = await processImage(imageData, taskType: .faceDetection)
        return result.results["faces"] as? [DetectedFace] ?? []
    }
    
    func analyzeScene(_ imageData: Data) async -> VisionSceneAnalysisResult? {
        let result = await processImage(imageData, taskType: .sceneAnalysis)
        
        guard result.success,
              let sceneType = result.results["scene"] as? String else {
            return nil
        }
        
        // Create mock objects for scene analysis - in a real implementation,
        // this would combine object detection with scene analysis
        let objects: [VisionDetectedObject] = []
        let lighting = analyzeLightingFromImage(imageData)
        let mood = analyzeMood(sceneType: sceneType)
        
        return VisionSceneAnalysisResult(
            sceneType: sceneType,
            objects: objects,
            lighting: lighting,
            mood: mood,
            confidence: result.confidence,
            timestamp: Date()
        )
    }
    
    func detectObjects(_ imageData: Data) async -> [VisionDetectedObject] {
        let result = await processImage(imageData, taskType: .objectDetection)
        return result.results["objects"] as? [VisionDetectedObject] ?? []
    }
    
    // MARK: - Helper Methods
    
    private func analyzeLightingFromImage(_ imageData: Data) -> String {
        guard let image = UIImage(data: imageData),
              let cgImage = image.cgImage else {
            return "Unknown"
        }
        return analyzeLighting(cgImage)
    }
    
    private func analyzeLighting(_ image: CGImage) -> String {
        // Simplified lighting analysis
        let context = CIContext()
        let ciImage = CIImage(cgImage: image)
        
        // Calculate average brightness
        let extent = ciImage.extent
        guard let averageFilter = CIFilter(name: "CIAreaAverage") else {
            return "Unknown"
        }
        
        averageFilter.setValue(ciImage, forKey: kCIInputImageKey)
        averageFilter.setValue(CIVector(cgRect: extent), forKey: kCIInputExtentKey)
        
        guard let outputImage = averageFilter.outputImage else { return "Unknown" }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(
            outputImage, 
            toBitmap: &bitmap, 
            rowBytes: 4, 
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1), 
            format: .RGBA8, 
            colorSpace: nil
        )
        
        let brightness = (Double(bitmap[0]) + Double(bitmap[1]) + Double(bitmap[2])) / (3.0 * 255.0)
        
        switch brightness {
        case 0.0..<0.3:
            return "Dark"
        case 0.3..<0.7:
            return "Medium"
        default:
            return "Bright"
        }
    }
    
    private func analyzeMood(sceneType: String) -> String {
        // Simple mood analysis based on scene type
        let moodMap: [String: String] = [
            "beach": "Relaxed",
            "forest": "Peaceful",
            "city": "Energetic",
            "mountain": "Majestic",
            "indoor": "Comfortable",
            "party": "Joyful",
            "office": "Professional",
            "sunset": "Romantic",
            "park": "Peaceful",
            "restaurant": "Social",
            "gym": "Energetic",
            "library": "Focused"
        ]
        
        let lowercaseScene = sceneType.lowercased()
        
        for (key, mood) in moodMap {
            if lowercaseScene.contains(key) {
                return mood
            }
        }
        
        return "Neutral"
    }
    
    private func detectLanguage(text: String) -> String? {
        guard !text.isEmpty else { return nil }
        
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        return recognizer.dominantLanguage?.rawValue
    }
    
    // MARK: - Batch Processing
    
    func processImages(_ imageDatas: [Data], taskType: VisionTaskType) async -> [VisionResult] {
        var results: [VisionResult] = []
        
        for imageData in imageDatas {
            let result = await processImage(imageData, taskType: taskType)
            results.append(result)
        }
        
        return results
    }
    
    // MARK: - Validation
    
    func validateImageData(_ imageData: Data) -> Bool {
        return UIImage(data: imageData) != nil
    }
    
    func getSupportedTaskTypes() -> [VisionTaskType] {
        return VisionTaskType.allCases.filter { taskType in
            // Filter out unsupported tasks
            taskType != .depthEstimation
        }
    }
}