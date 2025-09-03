//
//  Chamber.swift
//  DCourt
//

import Foundation
import SwiftData

// MARK: - Chamber Model
struct Chamber: Identifiable, Equatable {
    var id: UUID
    var name: String
    var council: [DBrain]  // SwiftData models can't be Codable
    var messages: [Message]

    // Default initializer
    init(id: UUID = UUID(), name: String, council: [DBrain], messages: [Message] = []) {
        self.id = id
        self.name = name
        self.council = council
        self.messages = messages
    }
    
    // Add a new message to the chamber
    mutating func addMessage(_ message: Message) {
        messages.append(message)
    }

    // Equatable conformance
    static func == (lhs: Chamber, rhs: Chamber) -> Bool {
        lhs.id == rhs.id
    }
    
    // MARK: - SwiftData Integration
    
    // Initialize a Chamber struct from a DChatChamber data model
    init(fromDataModel dataModel: DChatChamber) {
        self.id = dataModel.id
        self.name = dataModel.name
        
        // Use the existing DBrains directly
        self.council = dataModel.council ?? []
        
        // Convert DMessages to Messages
        self.messages = (dataModel.messages ?? []).map { dMessage in
            return Message(
                id: dMessage.id,
                content: dMessage.content,
                isUser: dMessage.isUser,
                timestamp: dMessage.timestamp,
                personaName: dMessage.personaName
            )
        }
    }
    
    // Save the Chamber struct to SwiftData by creating/updating a DChatChamber
    func saveToSwiftData(context: ModelContext) -> DChatChamber {
        // Create a new DChatChamber instance
        let dataChamber = DChatChamber(name: self.name, council: self.council)  // Pass council to initializer
        dataChamber.id = self.id
        
        // Convert Messages to DMessages and associate them with the chamber
        dataChamber.messages = self.messages.map { message in
            let dMessage = DMessage(
                content: message.content,
                isUser: message.isUser,
                timestamp: message.timestamp,
                personaName: message.personaName
            )
            dMessage.id = message.id
            dMessage.chamber = dataChamber // Set the relationship
            return dMessage
        }
        
        // Insert or update the chamber in the context
        context.insert(dataChamber)
        
        return dataChamber
    }
}