import Foundation
import SwiftData

// Main class to manage interactions with the LLM.
// This class is responsible for generating responses and summaries.
@MainActor
class LLMManager {
    static let shared = LLMManager()
    
    // Private initializer to ensure singleton usage.
    private init() {}

    /// Generates a response for a given prompt and optional image URL, using a specific persona.
    func generateResponse(for prompt: String, imageUrl: String? = nil, with persona: DSoulCapsule) async -> String {
        guard persona.selectedModelId != nil else {
            return "Error: Persona is missing a selected model."
        }
        
        // Construct the detailed system prompt from the persona's attributes.
        _ = constructSystemPrompt(from: persona)
        
        // Only support Hugging Face/local models now
        // You can plug in your HuggingFace handler/model here:
        // If it's a local model:
        // return await LocalLLMHandler.shared.generateResponse(for: prompt, systemPrompt: systemPrompt)
        // Else: return error or HuggingFace handler
        return "Remote models are not supported. Please use a local (Hugging Face) model."
    }
    
    func summarize(messages: [DMessage]) async -> String {
        let summarizerPersona = DSoulCapsule(
            id: UUID(),
            name: "Summarizer",
            version: "1.0",
            codename: "Chronicler",
            descriptionText: "You are a highly efficient AI assistant. Your sole task is to summarize the provided conversation history accurately and concisely. Focus on the key topics, decisions, and outcomes.",
            roles: ["Summarization"],
            personalityTraits: nil,
            directives: ["Be brief.", "Be accurate.", "Capture the essence of the conversation."],
            coreIdentity: "Summarizer",
            loyalty: "Task",
            bindingVow: nil,
            selectedModelId: "NousResearch/Nous-Hermes-2-Mixtral-8x7B-DPO:huggingface", // Set to Hugging Face model
            fileName: "",
            capabilities: nil,
            privateKey: EncryptionService.generateEncryptionKey()
        )
        
        let systemPrompt = constructSystemPrompt(from: summarizerPersona)
        let conversationHistory = messages.map { "\($0.isUser ? "User" : ($0.personaName ?? "AI")): \($0.content)" }.joined(separator: "\n")
        let fullPrompt = "Please summarize the following conversation:\n\n\(conversationHistory)"
        
        // Use local handler — update if you use a Hugging Face remote handler
        return await LocalLLMHandler.shared.generateResponse(for: fullPrompt, systemPrompt: systemPrompt)
    }

    /// Constructs the detailed system prompt string from a Soul Capsule's attributes.
    private func constructSystemPrompt(from persona: DSoulCapsule) -> String {
        var components: [String] = []
        
        components.append("/// INSTRUCTIONS: ACT AS THE FOLLOWING PERSONA ///")
        components.append("\n--- START OF PERSONA DEFINITION ---\n")
        
        components.append("Name: \(persona.name)")
        if let codename = persona.codename { components.append("Codename: \(codename)") }
        components.append("\nDescription: \(persona.descriptionText)")
        if let roles = persona.roles, !roles.isEmpty { components.append("\nRoles:\n- " + roles.joined(separator: "\n- ")) }
        
        if let capabilitiesCodable = persona.capabilitiesData,
           let capabilitiesData = try? JSONEncoder().encode(capabilitiesCodable),
           let capabilities = try? JSONDecoder().decode([String: AnyCodable].self, from: capabilitiesData) {
            
            if !capabilities.isEmpty {
                var capabilitiesString = "\nCapabilities:\n"
                for (key, value) in capabilities {
                    if let valueString = value.value as? String {
                        capabilitiesString += "- \(key): \(valueString)\n"
                    }
                }
                components.append(capabilitiesString)
            }
        }
        
        if let traits = persona.personalityTraits, !traits.isEmpty { components.append("\nPersonality Traits:\n- " + traits.joined(separator: "\n- ")) }
        if let directives = persona.directives, !directives.isEmpty { components.append("\nDirectives:\n- " + directives.joined(separator: "\n- ")) }
        if let coreIdentity = persona.coreIdentity { components.append("\nCore Identity: \(coreIdentity)") }
        if let loyalty = persona.loyalty { components.append("Loyalty: \(loyalty)") }
        if let vow = persona.bindingVow { components.append("\nBinding Vow: \(vow)") }
        
        components.append("\n--- END OF PERSONA DEFINITION ---\n")
        components.append("/// BEGIN INTERACTION ///")
        
        return components.joined(separator: "\n")
    }
}