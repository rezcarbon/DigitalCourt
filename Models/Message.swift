import Foundation

/// Represents a chat message in the UI layer
struct Message: Identifiable, Equatable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    let personaName: String?
    
    // Attachment data - only used in UI, not persisted
    let attachedImageData: Data?
    let attachedDocument: AttachedDocument?
    
    init(
        id: UUID = UUID(),
        content: String,
        isUser: Bool,
        timestamp: Date,
        personaName: String? = nil,
        attachedImageData: Data? = nil,
        attachedDocument: AttachedDocument? = nil
    ) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.personaName = personaName
        self.attachedImageData = attachedImageData
        self.attachedDocument = attachedDocument
    }
    
    // Equatable conformance
    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id &&
        lhs.content == rhs.content &&
        lhs.isUser == rhs.isUser &&
        lhs.timestamp == rhs.timestamp &&
        lhs.personaName == rhs.personaName
        // Note: We don't compare attachment data for equality as it's not needed for UI updates
    }
}