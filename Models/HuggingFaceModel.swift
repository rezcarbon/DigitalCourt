import Foundation

struct HuggingFaceModel: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let size: String
    let quantization: String
    let isCensored: Bool
    let isUncensored: Bool
    let priority: Int // Higher priority = preferred model
    let deviceRequirements: DeviceRequirements
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, size, quantization, isCensored, isUncensored, priority, deviceRequirements
    }
    
    // Enhanced uncensored MLX models as primary options
    static let examples: [HuggingFaceModel] = [
        // PRIORITY 1: Uncensored Models (Primary Choice)
        HuggingFaceModel(
            id: "mlx-community/NeuralDaredevil-8B-abliterated-4bit", 
            name: "NeuralDaredevil 8B Uncensored",
            description: "Fully uncensored model with enhanced reasoning capabilities",
            size: "8B",
            quantization: "4-bit",
            isCensored: false,
            isUncensored: true,
            priority: 10,
            deviceRequirements: DeviceRequirements(minRAM: 6, preferredRAM: 8, minStorage: 4)
        ),
        HuggingFaceModel(
            id: "mlx-community/Hermes-3-Llama-3.1-8B-4bit",
            name: "Hermes 3 Llama 8B Uncensored", 
            description: "Uncensored conversational model with advanced capabilities",
            size: "8B",
            quantization: "4-bit",
            isCensored: false,
            isUncensored: true,
            priority: 9,
            deviceRequirements: DeviceRequirements(minRAM: 6, preferredRAM: 8, minStorage: 4)
        ),
        HuggingFaceModel(
            id: "mlx-community/Dolphin-2.9.4-Llama3.1-8B-4bit",
            name: "Dolphin Llama 8B Uncensored",
            description: "Dolphin uncensored model for unrestricted conversations", 
            size: "8B",
            quantization: "4-bit",
            isCensored: false, 
            isUncensored: true,
            priority: 8,
            deviceRequirements: DeviceRequirements(minRAM: 6, preferredRAM: 8, minStorage: 4)
        ),
        
        // PRIORITY 2: Smaller Uncensored Models (Fallback for limited devices)
        HuggingFaceModel(
            id: "mlx-community/Llama-3.2-3B-Instruct-4bit",
            name: "Llama 3.2 3B",
            description: "Balanced performance with 3 billion parameters (less censored)",
            size: "3B",
            quantization: "4-bit",
            isCensored: true, // Moderately censored
            isUncensored: false,
            priority: 5,
            deviceRequirements: DeviceRequirements(minRAM: 3, preferredRAM: 4, minStorage: 2)
        ),
        HuggingFaceModel(
            id: "mlx-community/DeepSeek-R1-Distill-Qwen-1.5B-4bit",
            name: "DeepSeek R1 Qwen 1.5B",
            description: "Distilled model optimized for reasoning tasks",
            size: "1.5B",
            quantization: "4-bit", 
            isCensored: true,
            isUncensored: false,
            priority: 3,
            deviceRequirements: DeviceRequirements(minRAM: 2, preferredRAM: 3, minStorage: 1)
        ),
        
        // PRIORITY 3: Vision Models (Specialized)
        HuggingFaceModel(
            id: "mlx-community/Llama-3.2-11B-Vision-Instruct-4bit",
            name: "Llama 3.2 11B Vision",
            description: "Powerful vision-language model with multimodal capabilities.",
            size: "11B",
            quantization: "4-bit",
            isCensored: true,
            isUncensored: false,
            priority: 7,
            deviceRequirements: DeviceRequirements(minRAM: 8, preferredRAM: 12, minStorage: 6)
        ),
        
        // PRIORITY 4: Emergency Fallback (Most Compatible)
        HuggingFaceModel(
            id: "mlx-community/Llama-3.2-1B-Instruct-4bit",
            name: "Llama 3.2 1B",
            description: "Optimized for mobile devices with 1 billion parameters",
            size: "1B", 
            quantization: "4-bit",
            isCensored: true,
            isUncensored: false,
            priority: 1,
            deviceRequirements: DeviceRequirements(minRAM: 1, preferredRAM: 2, minStorage: 1)
        )
    ]
    
    var isVisionModel: Bool {
        return self.id.lowercased().contains("vision")
    }
    
    var isPreferredModel: Bool {
        return isUncensored && priority >= 8
    }
    
    var isCompatibleWithDevice: Bool {
        let availableRAM = DeviceCapabilities.getAvailableRAM()
        let availableStorage = DeviceCapabilities.getAvailableStorage()
        
        return availableRAM >= deviceRequirements.minRAM && 
               availableStorage >= deviceRequirements.minStorage
    }
    
    static var sortedByPriority: [HuggingFaceModel] {
        return examples.sorted { $0.priority > $1.priority }
    }
    
    static var uncensoredModels: [HuggingFaceModel] {
        return examples.filter { $0.isUncensored }.sorted { $0.priority > $1.priority }
    }
    
    static var compatibleModels: [HuggingFaceModel] {
        return examples.filter { $0.isCompatibleWithDevice }.sorted { $0.priority > $1.priority }
    }
}

struct DeviceRequirements: Codable {
    let minRAM: Int // GB
    let preferredRAM: Int // GB  
    let minStorage: Int // GB
}

// MARK: - Device Capabilities Helper

class DeviceCapabilities {
    static func getAvailableRAM() -> Int {
        // Get device RAM in GB
        let physicalMemory = ProcessInfo.processInfo.physicalMemory
        return Int(physicalMemory / (1024 * 1024 * 1024)) // Convert to GB
    }
    
    static func getAvailableStorage() -> Int {
        // Get available storage in GB
        guard let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            return 0
        }
        
        do {
            let url = URL(fileURLWithPath: path)
            let values = try url.resourceValues(forKeys: [.volumeAvailableCapacityKey])
            if let capacity = values.volumeAvailableCapacity {
                let gigabytes = Int(capacity / (1024 * 1024 * 1024)) // Convert to GB
                print("📊 Available storage: \(gigabytes) GB (\(capacity) bytes)")
                return gigabytes
            }
        } catch {
            print("Error getting storage info: \(error)")
        }
        
        return 0
    }
    
    static func getRecommendedModel() -> HuggingFaceModel? {
        // Get the best uncensored model that's compatible with device
        let compatibleUncensored = HuggingFaceModel.uncensoredModels.filter { $0.isCompatibleWithDevice }
        
        if let bestModel = compatibleUncensored.first {
            return bestModel
        }
        
        // Fallback to any compatible model
        return HuggingFaceModel.compatibleModels.first
    }
}