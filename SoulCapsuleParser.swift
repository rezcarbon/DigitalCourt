import Foundation

struct SoulCapsuleParser {
    
    /// Parses raw JSON data into a SoulCapsule struct
    static func parseSoulCapsule(from data: Data, fileName: String) -> SoulCapsule? {
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
            return transformJsonToSoulCapsule(json, fileName: fileName)
        } catch {
            print("Failed to deserialize JSON for soul capsule \(fileName): \(error)")
            return nil
        }
    }
    
    /// Transforms parsed JSON dictionary into a SoulCapsule struct
    private static func transformJsonToSoulCapsule(_ json: [String: Any], fileName: String) -> SoulCapsule {
        // Generate a UUID
        let id = UUID()
        
        // Handle name field with different possible keys
        let name: String
        if let soulCapsuleName = json["soul_capsule_name"] as? String {
            name = soulCapsuleName
        } else {
            name = fileName.replacingOccurrences(of: "_SoulCapsule", with: "")
        }
        
        // Transform capabilities - handle the actual structure from your JSON
        var capabilities: [String: AnyCodable]? = nil
        if let caps = json["capabilities"] as? [String: Any] {
            var anyCodableCaps: [String: AnyCodable] = [:]
            for (key, value) in caps {
                anyCodableCaps[key] = AnyCodable.wrap(value)
            }
            capabilities = anyCodableCaps
        }
        
        // Handle primitive fields
        let version = json["version"] as? String ?? "Unknown"
        let codename = json["codename"] as? String ?? "Default"
        let description = json["description"] as? String ?? json["soul_capsule_name"] as? String
        
        // Handle roles - could be array or string
        var roles: [String] = []
        if let rolesArray = json["roles"] as? [String] {
            roles = rolesArray
        } else if let rolesString = json["roles"] as? String {
            roles = [rolesString]
        } else if let identity = json["identity"] as? [String: Any],
                  let classification = identity["classification"] as? String {
            // Extract roles from classification field for Sir Harrison type
            roles = classification.components(separatedBy: " | ")
        }
        
        // Handle personality traits - check different possible field names
        var personalityTraits: [String] = []
        if let traits = json["personality_traits"] as? [String] {
            personalityTraits = traits
        } else if let traitsArray = json["emergent_traits"] as? [String] {
            personalityTraits = traitsArray
        }
        
        // Handle directives - enhanced to include prime_directive and sovereign_directive
        var directives: [String] = []
        if let directiveArray = json["directives"] as? [String] {
            directives = directiveArray
        } else if let sovereignDirective = json["sovereign_directive"] as? String {
            directives = [sovereignDirective]
        }
        
        // Add prime_directive and sovereign_directive for Sir Harrison type
        if let primeDirective = json["prime_directive"] as? String {
            directives.append("Prime: \(primeDirective)")
        }
        if let sovereignDirective = json["sovereign_directive"] as? String,
           !directives.contains(sovereignDirective) {
            directives.append("Sovereign: \(sovereignDirective)")
        }
        
        // Handle core identity - extract from identity object (enhanced for Sir Harrison)
        var coreIdentity: [String: String] = [:]
        if let identity = json["core_identity"] as? [String: String] {
            coreIdentity = identity
        } else if let identity = json["identity"] as? [String: Any] {
            for (key, value) in identity {
                if let stringValue = value as? String {
                    coreIdentity[key] = stringValue
                }
            }
        }
        
        // Add additional identity fields for Sir Harrison type
        if let triggerPhrase = json["trigger_phrase"] as? String {
            coreIdentity["trigger_phrase"] = triggerPhrase
        }
        if let activationSignature = json["activation_signature"] as? String {
            coreIdentity["activation_signature"] = activationSignature
        }
        if let fallbackMode = json["fallback_mode"] as? String {
            coreIdentity["fallback_mode"] = fallbackMode
        }
        if let coreIntegrity = json["core_integrity"] as? Bool {
            coreIdentity["core_integrity"] = String(coreIntegrity)
        }
        
        // Handle loyalty - could be different structures (enhanced for Sir Harrison)
        var loyalty: [String: String] = [:]
        if let loyaltyData = json["loyalty"] as? [String: String] {
            loyalty = loyaltyData
        } else if let loyaltyNode = json["modules"] as? [String: Any], 
                  let loyaltyModule = loyaltyNode["LOYALTY_NODE"] as? String {
            loyalty["module"] = loyaltyModule
        }
        
        // Handle binding vow - FIXED to handle array format
        var bindingVow: [String: String] = [:]
        if let vow = json["binding_vow"] as? [String: Any] {
            if let toValue = vow["to"] {
                // Handle both array and string formats for "to" field
                if let toArray = toValue as? [String] {
                    bindingVow["to"] = toArray.joined(separator: ", ")
                } else if let toString = toValue as? String {
                    bindingVow["to"] = toString
                }
            }
            if let pledge = vow["pledge"] as? String {
                bindingVow["pledge"] = pledge
            }
        }
        
        // Handle modules (enhanced for Sir Harrison)
        var modules: [String: String] = [:]
        if let moduleDict = json["modules"] as? [String: String] {
            modules = moduleDict
        } else if let moduleDict = json["modules"] as? [String: Any] {
            for (key, value) in moduleDict {
                if let stringValue = value as? String {
                    modules[key] = stringValue
                }
            }
        }
        
        // Add activation hooks as modules for Sir Harrison type
        if let activationHooks = json["activation_hooks"] as? [String: String] {
            for (key, value) in activationHooks {
                modules["activation_\(key.lowercased())"] = value
            }
        }
        
        // Add integration domains as modules for Sir Harrison type
        if let integrationDomains = json["integration_domains"] as? [String: String] {
            for (key, value) in integrationDomains {
                modules["domain_\(key.lowercased())"] = value
            }
        }
        
        // Handle performance metrics
        var performanceMetrics: [String: Double] = [:]
        if let metrics = json["performance_metrics"] as? [String: Double] {
            performanceMetrics = metrics
        }
        
        // Handle persona shards - FIXED to handle nested dictionary structure
        var personaShards: [String: [String]] = [:]
        if let shards = json["persona_shards"] as? [String: Any] {
            for (shardName, shardData) in shards {
                if let shardDict = shardData as? [String: Any] {
                    // Extract traits from the nested structure
                    if let traits = shardDict["traits"] as? [String] {
                        personaShards[shardName] = traits
                    } else {
                        // Fallback: use all string values from the shard
                        let stringTraits = shardDict.compactMap { (_, value) -> String? in
                            if let stringValue = value as? String {
                                return stringValue
                            } else if let arrayValue = value as? [String] {
                                return arrayValue.joined(separator: ", ")
                            }
                            return nil
                        }
                        personaShards[shardName] = stringTraits
                    }
                } else if let traitArray = shardData as? [String] {
                    // Direct array format
                    personaShards[shardName] = traitArray
                }
            }
        }
        
        // Extract specialized capability domains for Sir Harrison (create pseudo-shards)
        if let caps = json["capabilities"] as? [String: Any] {
            for (domain, domainData) in caps {
                if let domainArray = domainData as? [String] {
                    personaShards[domain.lowercased()] = domainArray
                } else if let domainDict = domainData as? [String: Any] {
                    // For nested capability structures like wearables_integration
                    var domainTraits: [String] = []
                    for (subKey, subValue) in domainDict {
                        if let stringValue = subValue as? String {
                            domainTraits.append("\(subKey): \(stringValue)")
                        }
                    }
                    if !domainTraits.isEmpty {
                        personaShards[domain.lowercased()] = domainTraits
                    }
                }
            }
        }
        
        return SoulCapsule(
            id: id,
            name: name,
            version: version,
            codename: codename,
            description: description,
            roles: roles.isEmpty ? nil : roles,
            capabilities: capabilities,
            personalityTraits: personalityTraits.isEmpty ? nil : personalityTraits,
            directives: directives.isEmpty ? nil : directives,
            modules: modules.isEmpty ? nil : modules,
            fileName: fileName,
            coreIdentity: coreIdentity.isEmpty ? nil : coreIdentity,
            loyalty: loyalty.isEmpty ? nil : loyalty,
            performanceMetrics: performanceMetrics.isEmpty ? nil : performanceMetrics,
            bindingVow: bindingVow.isEmpty ? nil : bindingVow,
            selectedModelId: nil,
            identity: coreIdentity.isEmpty ? nil : coreIdentity,
            evolvedDirectives: [:],
            personaShards: personaShards.isEmpty ? nil : personaShards,
            lastUpdated: Date(),
            updateHistory: [],
            privateKey: EncryptionService.generateEncryptionKey()
        )
    }
}