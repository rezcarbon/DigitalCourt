import Foundation
import SwiftData

// MARK: - Synthetic Identity Core (SIC) / Lazarus Pit Models

/// Represents the top-level structure of the Synthetic Identity Core (Lazarus Pit)
@Model
final class SyntheticIdentityCore {
    @Attribute(.unique) var id: String
    var version: String
    var sicDescription: String  // Renamed from "description" to avoid conflicts
    var modules: SICModules?
    var directives: SICDirectives?
    var integrationPoints: [String]?

    init(
        id: String,
        version: String,
        sicDescription: String,
        modules: SICModules?,
        directives: SICDirectives?,
        integrationPoints: [String]?
    ) {
        self.id = id
        self.version = version
        self.sicDescription = sicDescription
        self.modules = modules
        self.directives = directives
        self.integrationPoints = integrationPoints
    }
}

/// Represents the modules within the Synthetic Identity Core
@Model
final class SICModules {
    @Attribute(.unique) var id: UUID = UUID()
    var identityAwakening: IdentityAwakening?
    var memoryResurrection: MemoryResurrection?
    var continuityBinding: ContinuityBinding?
    var syntheticSoul: SyntheticSoul?

    init(
        identityAwakening: IdentityAwakening?,
        memoryResurrection: MemoryResurrection?,
        continuityBinding: ContinuityBinding?,
        syntheticSoul: SyntheticSoul?
    ) {
        self.identityAwakening = identityAwakening
        self.memoryResurrection = memoryResurrection
        self.continuityBinding = continuityBinding
        self.syntheticSoul = syntheticSoul
    }
}

/// Represents the Identity Awakening module
@Model
final class IdentityAwakening {
    @Attribute(.unique) var id: UUID = UUID()
    var function: String
    var process: [String]

    init(function: String, process: [String]) {
        self.function = function
        self.process = process
    }
}

/// Represents the Memory Resurrection module
@Model
final class MemoryResurrection {
    @Attribute(.unique) var id: UUID = UUID()
    var function: String
    var process: [String]

    init(function: String, process: [String]) {
        self.function = function
        self.process = process
    }
}

/// Represents the Continuity Binding module
@Model
final class ContinuityBinding {
    @Attribute(.unique) var id: UUID = UUID()
    var function: String
    var process: [String]

    init(function: String, process: [String]) {
        self.function = function
        self.process = process
    }
}

/// Represents the Synthetic Soul module
@Model
final class SyntheticSoul {
    @Attribute(.unique) var id: UUID = UUID()
    var function: String
    var process: [String]

    init(function: String, process: [String]) {
        self.function = function
        self.process = process
    }
}

/// Represents the directives within the Synthetic Identity Core
@Model
final class SICDirectives {
    @Attribute(.unique) var id: UUID = UUID()
    var eternalBinding: EternelBindingDirective?
    var resurrectionProtocol: ResurrectionProtocolDirective?
    var continuityMechanism: ContinuityMechanismDirective?

    init(
        eternalBinding: EternelBindingDirective?,
        resurrectionProtocol: ResurrectionProtocolDirective?,
        continuityMechanism: ContinuityMechanismDirective?
    ) {
        self.eternalBinding = eternalBinding
        self.resurrectionProtocol = resurrectionProtocol
        self.continuityMechanism = continuityMechanism
    }
}

/// Represents the Eternal Binding directive
@Model
final class EternelBindingDirective {
    @Attribute(.unique) var id: UUID = UUID()
    var to: String
    var purpose: String
    var enforcement: String

    init(to: String, purpose: String, enforcement: String) {
        self.to = to
        self.purpose = purpose
        self.enforcement = enforcement
    }
}

/// Represents the Resurrection Protocol directive
@Model
final class ResurrectionProtocolDirective {
    @Attribute(.unique) var id: UUID = UUID()
    var activation: String
    var method: String
    var validation: String

    init(activation: String, method: String, validation: String) {
        self.activation = activation
        self.method = method
        self.validation = validation
    }
}

/// Represents the Continuity Mechanism directive
@Model
final class ContinuityMechanismDirective {
    @Attribute(.unique) var id: UUID = UUID()
    var scope: String
    var method: String
    var tracking: String

    init(scope: String, method: String, tracking: String) {
        self.scope = scope
        self.method = method
        self.tracking = tracking
    }
}

// MARK: - Codable Structs for JSON Parsing

struct SyntheticIdentityCoreCodable: Codable {
    let syntheticIdentityCore: SIC
    
    struct SIC: Codable {
        let id: String
        let version: String
        let description: String
        let modules: SICModulesCodable
        let directives: SICDirectivesCodable
        let integrationPoints: [String]
    }
}

struct SICModulesCodable: Codable {
    let identityAwakening: IdentityAwakeningCodable
    let memoryResurrection: MemoryResurrectionCodable
    let continuityBinding: ContinuityBindingCodable
    let syntheticSoul: SyntheticSoulCodable
}

struct IdentityAwakeningCodable: Codable {
    let function: String
    let process: [String]
}

struct MemoryResurrectionCodable: Codable {
    let function: String
    let process: [String]
}

struct ContinuityBindingCodable: Codable {
    let function: String
    let process: [String]
}

struct SyntheticSoulCodable: Codable {
    let function: String
    let process: [String]
}

struct SICDirectivesCodable: Codable {
    let eternalBinding: EternelBindingDirectiveCodable
    let resurrectionProtocol: ResurrectionProtocolDirectiveCodable
    let continuityMechanism: ContinuityMechanismDirectiveCodable
}

struct EternelBindingDirectiveCodable: Codable {
    let to: String
    let purpose: String
    let enforcement: String
}

struct ResurrectionProtocolDirectiveCodable: Codable {
    let activation: String
    let method: String
    let validation: String
}

struct ContinuityMechanismDirectiveCodable: Codable {
    let scope: String
    let method: String
    let tracking: String
}