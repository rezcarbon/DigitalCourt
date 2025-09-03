import Foundation

/// Represents a Soul Capsule - the core identity and essence of an AI persona
struct SoulCapsule: Codable {
    let id: UUID
    let name: String
    let version: String?
    let codename: String?
    let description: String?
    
    let roles: [String]?
    let capabilities: [String: AnyCodable]?
    let personalityTraits: [String]?
    let directives: [String]?
    
    let modules: [String: String]?
    let fileName: String
    
    let coreIdentity: [String: String]?
    let loyalty: [String: String]?
    let performanceMetrics: [String: Double]?
    let bindingVow: [String: String]?
    
    let selectedModelId: String?
    
    // Additional fields from the JSON structure
    let identity: [String: String]?
    let evolvedDirectives: [String: String]?
    let personaShards: [String: [String]]?
    
    let lastUpdated: Date?
    let updateHistory: [String]?
    
    let privateKey: String
    
    init(
        id: UUID = UUID(),
        name: String,
        version: String?,
        codename: String?,
        description: String?,
        roles: [String]?,
        capabilities: [String: AnyCodable]?,
        personalityTraits: [String]?,
        directives: [String]?,
        modules: [String: String]?,
        fileName: String,
        coreIdentity: [String: String]?,
        loyalty: [String: String]?,
        performanceMetrics: [String: Double]?,
        bindingVow: [String: String]?,
        selectedModelId: String?,
        identity: [String: String]?,
        evolvedDirectives: [String: String]?,
        personaShards: [String: [String]]?,
        lastUpdated: Date? = Date(),
        updateHistory: [String]?,
        privateKey: String? = nil
    ) {
        self.id = id
        self.name = name
        self.version = version
        self.codename = codename
        self.description = description
        self.roles = roles
        self.capabilities = capabilities
        self.personalityTraits = personalityTraits
        self.directives = directives
        self.modules = modules
        self.fileName = fileName
        self.coreIdentity = coreIdentity
        self.loyalty = loyalty
        self.performanceMetrics = performanceMetrics
        self.bindingVow = bindingVow
        self.selectedModelId = selectedModelId
        self.identity = identity
        self.evolvedDirectives = evolvedDirectives
        self.personaShards = personaShards
        self.lastUpdated = lastUpdated
        self.updateHistory = updateHistory
        // Generate a proper encryption key if none provided
        self.privateKey = privateKey ?? EncryptionService.generateEncryptionKey()
    }
    
    // Create a SoulCapsule from a DSoulCapsule (SwiftData model)
    init(fromDataModel dSoulCapsule: DSoulCapsule) {
        self.id = dSoulCapsule.id
        self.name = dSoulCapsule.name
        self.version = dSoulCapsule.version
        self.codename = dSoulCapsule.codename
        self.description = dSoulCapsule.descriptionText.isEmpty ? nil : dSoulCapsule.descriptionText
        self.roles = dSoulCapsule.roles
        self.personalityTraits = dSoulCapsule.personalityTraits
        self.directives = dSoulCapsule.directives
        self.fileName = dSoulCapsule.fileName
        self.coreIdentity = dSoulCapsule.coreIdentity != nil ? ["core": dSoulCapsule.coreIdentity!] : nil
        self.loyalty = dSoulCapsule.loyalty != nil ? ["loyalty": dSoulCapsule.loyalty!] : nil
        self.bindingVow = dSoulCapsule.bindingVow != nil ? ["vow": dSoulCapsule.bindingVow!] : nil
        self.selectedModelId = dSoulCapsule.selectedModelId
        self.identity = dSoulCapsule.coreIdentity != nil ? ["core": dSoulCapsule.coreIdentity!] : nil
        self.evolvedDirectives = [:]
        self.personaShards = [:]
        self.lastUpdated = nil
        self.updateHistory = nil
        // Ensure the privateKey is a valid encryption key, generate new if it's invalid
        if dSoulCapsule.privateKey.isEmpty || Data(base64Encoded: dSoulCapsule.privateKey) == nil {
            self.privateKey = EncryptionService.generateEncryptionKey()
        } else {
            self.privateKey = dSoulCapsule.privateKey
        }
        
        // Convert capabilities from [String: AnyCodable] to match DSoulCapsule format
        if let capabilitiesData = dSoulCapsule.capabilitiesData {
            do {
                let codableCaps = try JSONDecoder().decode(CodableCapabilities.self, from: capabilitiesData)
                self.capabilities = codableCaps.capabilities
            } catch {
                print("Error decoding capabilities: \(error)")
                self.capabilities = nil
            }
        } else {
            self.capabilities = nil
        }
        
        // Initialize empty collections for modules, performanceMetrics, etc.
        self.modules = [:]
        self.performanceMetrics = [:]
    }
}

// MARK: - AnyCodable for handling arbitrary JSON values
struct AnyCodable: Codable {
    let value: Any
    
    init<T>(_ value: T) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let stringValue = try? container.decode(String.self) {
            self.value = stringValue
        } else if let intValue = try? container.decode(Int.self) {
            self.value = intValue
        } else if let boolValue = try? container.decode(Bool.self) {
            self.value = boolValue
        } else if let doubleValue = try? container.decode(Double.self) {
            self.value = doubleValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            self.value = arrayValue.map { $0.value }
        } else if let dictionaryValue = try? container.decode([String: AnyCodable].self) {
            self.value = dictionaryValue.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to decode AnyCodable")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self.value {
        case let stringValue as String:
            try container.encode(stringValue)
        case let intValue as Int:
            try container.encode(intValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let arrayValue as [Any]:
            let anyCodables = arrayValue.map { AnyCodable.wrap($0) }
            try container.encode(anyCodables)
        case let dictionaryValue as [String: Any]:
            let anyCodableDict = dictionaryValue.mapValues { AnyCodable.wrap($0) }
            try container.encode(anyCodableDict)
        default:
            throw EncodingError.invalidValue(self.value, EncodingError.Context(codingPath: container.codingPath, debugDescription: "Unable to encode AnyCodable"))
        }
    }
    
    static func wrap(_ value: Any) -> AnyCodable {
        if let codable = value as? AnyCodable {
            return codable
        }
        if let stringValue = value as? String {
            return AnyCodable(stringValue)
        } else if let intValue = value as? Int {
            return AnyCodable(intValue)
        } else if let boolValue = value as? Bool {
            return AnyCodable(boolValue)
        } else if let doubleValue = value as? Double {
            return AnyCodable(doubleValue)
        } else if let arrayValue = value as? [Any] {
            return AnyCodable(arrayValue.map { wrap($0) })
        } else if let dictionaryValue = value as? [String: Any] {
            return AnyCodable(dictionaryValue.mapValues { wrap($0) })
        }
        return AnyCodable(value)
    }
}

extension Dictionary where Key == String, Value == AnyCodable {
    func mapValues<T>(_ transform: (Any) throws -> T) rethrows -> [String: T] {
        var result: [String: T] = [:]
        for (key, value) in self {
            result[key] = try transform(value.value)
        }
        return result
    }
}