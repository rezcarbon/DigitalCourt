import Foundation
import Vision

/// Vision-specific detected object model
struct VisionDetectedObject: Codable, Identifiable {
    let id = UUID()
    let label: String
    let confidence: Double
    let boundingBox: CGRect
    let attributes: [String: Any]
    
    enum CodingKeys: String, CodingKey {
        case label, confidence, boundingBox
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(label, forKey: .label)
        try container.encode(confidence, forKey: .confidence)
        try container.encode([
            boundingBox.origin.x,
            boundingBox.origin.y,
            boundingBox.size.width,
            boundingBox.size.height
        ], forKey: .boundingBox)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        label = try container.decode(String.self, forKey: .label)
        confidence = try container.decode(Double.self, forKey: .confidence)
        let bounds = try container.decode([Double].self, forKey: .boundingBox)
        boundingBox = CGRect(x: bounds[0], y: bounds[1], width: bounds[2], height: bounds[3])
        attributes = [:]
    }
    
    init(label: String, confidence: Double, boundingBox: CGRect, attributes: [String: Any]) {
        self.label = label
        self.confidence = confidence
        self.boundingBox = boundingBox
        self.attributes = attributes
    }
}

/// Vision-specific scene analysis result
struct VisionSceneAnalysisResult: Codable {
    let sceneType: String
    let objects: [VisionDetectedObject]
    let lighting: String
    let mood: String
    let confidence: Double
    let timestamp: Date
}

/// Vision task types
enum VisionTaskType: String, CaseIterable {
    case objectDetection = "object_detection"
    case textRecognition = "text_recognition"
    case faceDetection = "face_detection"
    case sceneAnalysis = "scene_analysis"
    case depthEstimation = "depth_estimation"
}

/// Vision processing result
struct VisionResult: Codable {
    let taskType: String
    let success: Bool
    let confidence: Double
    let processingTime: TimeInterval
    let results: [String: Any]
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case taskType, success, confidence, processingTime, timestamp
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(taskType, forKey: .taskType)
        try container.encode(success, forKey: .success)
        try container.encode(confidence, forKey: .confidence)
        try container.encode(processingTime, forKey: .processingTime)
        try container.encode(timestamp, forKey: .timestamp)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        taskType = try container.decode(String.self, forKey: .taskType)
        success = try container.decode(Bool.self, forKey: .success)
        confidence = try container.decode(Double.self, forKey: .confidence)
        processingTime = try container.decode(TimeInterval.self, forKey: .processingTime)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        results = [:]
    }
    
    init(taskType: String, success: Bool, confidence: Double, processingTime: TimeInterval, results: [String: Any], timestamp: Date) {
        self.taskType = taskType
        self.success = success
        self.confidence = confidence
        self.processingTime = processingTime
        self.results = results
        self.timestamp = timestamp
    }
}

/// Text recognition result
struct TextRecognitionResult: Codable {
    let recognizedText: String
    let textBlocks: [TextBlock]
    let confidence: Double
    let processingTime: TimeInterval
    let language: String?
    let timestamp: Date
    
    init(recognizedText: String, confidence: Double, textBlocks: [TextBlock], language: String?, timestamp: Date) {
        self.recognizedText = recognizedText
        self.confidence = confidence
        self.textBlocks = textBlocks
        self.processingTime = 0.0 // Default value
        self.language = language
        self.timestamp = timestamp
    }
}

/// Text block within recognized text
struct TextBlock: Codable {
    let text: String
    let boundingBox: CGRect
    let confidence: Double
    
    private enum CodingKeys: String, CodingKey {
        case text, confidence
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(text, forKey: .text)
        try container.encode(confidence, forKey: .confidence)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = try container.decode(String.self, forKey: .text)
        confidence = try container.decode(Double.self, forKey: .confidence)
        boundingBox = .zero // Default value for decoding
    }
    
    init(text: String, boundingBox: CGRect, confidence: Double) {
        self.text = text
        self.boundingBox = boundingBox
        self.confidence = confidence
    }
}

/// Detected face information
struct DetectedFace: Codable {
    let id = UUID()
    let boundingBox: CGRect
    let confidence: Double
    let attributes: FaceAttributes
    
    private enum CodingKeys: String, CodingKey {
        case confidence, attributes
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(confidence, forKey: .confidence)
        try container.encode(attributes, forKey: .attributes)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        confidence = try container.decode(Double.self, forKey: .confidence)
        attributes = try container.decode(FaceAttributes.self, forKey: .attributes)
        boundingBox = .zero // Default value for decoding
    }
    
    init(boundingBox: CGRect, confidence: Double, attributes: FaceAttributes) {
        self.boundingBox = boundingBox
        self.confidence = confidence
        self.attributes = attributes
    }
}

/// Face attributes information
struct FaceAttributes: Codable {
    let age: Int?
    let gender: String?
    let emotion: String?
    let expressions: [String: Double]
    
    private enum CodingKeys: String, CodingKey {
        case age, gender, emotion, expressions
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(age, forKey: .age)
        try container.encodeIfPresent(gender, forKey: .gender)
        try container.encodeIfPresent(emotion, forKey: .emotion)
        try container.encode(expressions, forKey: .expressions)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        age = try container.decodeIfPresent(Int.self, forKey: .age)
        gender = try container.decodeIfPresent(String.self, forKey: .gender)
        emotion = try container.decodeIfPresent(String.self, forKey: .emotion)
        expressions = try container.decode([String: Double].self, forKey: .expressions)
    }
    
    init(age: Int?, gender: String?, emotion: String?, expressions: [String: Double]) {
        self.age = age
        self.gender = gender
        self.emotion = emotion
        self.expressions = expressions
    }
}