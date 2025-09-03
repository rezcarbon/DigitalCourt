import Foundation
import SwiftUI
import WidgetKit
import ActivityKit
import AuthenticationServices
import _StoreKit_SwiftUI
import _PhotosUI_SwiftUI
import SwiftData
import Combine
import PhotosUI
import UniformTypeIdentifiers

struct AttachedDocument: Equatable, Codable {
    let id: UUID
    let fileName: String
    let data: Data
    let typeIdentifier: String // Store type identifier instead of UTType for Codable compatibility

    init(id: UUID = UUID(), fileName: String, data: Data, type: UTType) {
        self.id = id
        self.fileName = fileName
        self.data = data
        self.typeIdentifier = type.identifier
    }
    
    // Computed property to get UTType from identifier
    var type: UTType {
        return UTType(typeIdentifier) ?? .data
    }
    
    // Codable conformance - custom implementation for UTType
    enum CodingKeys: String, CodingKey {
        case id, fileName, data, typeIdentifier
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        fileName = try container.decode(String.self, forKey: .fileName)
        data = try container.decode(Data.self, forKey: .data)
        typeIdentifier = try container.decode(String.self, forKey: .typeIdentifier)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(fileName, forKey: .fileName)
        try container.encode(data, forKey: .data)
        try container.encode(typeIdentifier, forKey: .typeIdentifier)
    }
}

@MainActor
class ChatChamberViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var inputText: String = ""
    @Published var imageUrlInput: String = "" // This seems unused now, consider removing
    @Published var isLoading: Bool = false
    @Published var loadingStatus: String = "Thinking..."
    
    // Properties for attachments
    @Published var selectedPhoto: PhotosPickerItem? {
        didSet {
            Task {
                await processSelectedPhoto()
            }
        }
    }
    @Published var attachedImageData: Data?
    @Published var attachedDocument: AttachedDocument?
    
    private var chamber: Chamber
    private let memoryManager = MemoryManager.shared
    private let plcManager = PLCManager.shared
    
    init(chamber: Chamber) {
        self.chamber = chamber
        loadMessages()
        
        // Initialize the PLC for this chamber's primary soul capsule
        Task {
            // Extract the first brain from the council
            if let primaryBrain = chamber.council.first {
                // Check if soulCapsule is optional and unwrap it
                let soulCapsule = primaryBrain.soulCapsule
                let positronicCoreSeed = primaryBrain.positronicCoreSeed
                
                // Use optional binding to safely access the id
                if let capsuleId = soulCapsule?.id {
                    try? await plcManager.initializePLC(soulCapsuleKey: capsuleId, modelId: positronicCoreSeed)
                }
            }
        }
    }
    
    private func loadMessages() {
        self.messages = chamber.messages
    }
    
    func sendMessage() async {
        guard !isSendButtonDisabled else { return }
        
        let userMessage = Message(
            id: UUID(),
            content: inputText,
            isUser: true,
            timestamp: Date(),
            personaName: "You",
            attachedImageData: attachedImageData,
            attachedDocument: attachedDocument
        )
        
        // Store message using MemoryManager
        do {
            try await memoryManager.storeMemory(
                content: inputText,
                isUser: true,
                personaName: "You",
                chamberId: chamber.id
            )
        } catch {
            print("Error storing user message: \(error)")
        }
        
        messages.append(userMessage)
        chamber.addMessage(userMessage)
        
        // Store attachments if any
        // Note: You may want to enhance MemoryManager to store Data blobs
        // For now, we are passing them directly to the AI response generation
        
        let textToSend = inputText
        let imageToSend = attachedImageData
        let documentToSend = attachedDocument
        
        // Clear input and attachments
        inputText = ""
        removeAttachment()
        
        // Generate AI response
        await generateAIResponse(with: textToSend, image: imageToSend, document: documentToSend)
    }
    
    private func generateAIResponse(with text: String, image: Data?, document: AttachedDocument?) async {
        isLoading = true
        loadingStatus = "Analyzing..."
        
        let aiPersonaName = chamber.council.first?.name ?? "AI"
        
        // --- Create a placeholder message for the streaming content ---
        let aiMessageId = UUID()
        let aiMessage = Message(
            id: aiMessageId,
            content: "", // Start with empty content
            isUser: false,
            timestamp: Date(),
            personaName: aiPersonaName
        )
        messages.append(aiMessage)
        
        var fullResponse = ""

        do {
            // Use the primary brain directly instead of converting it
            if let primaryBrain = chamber.council.first {
                let responseStream = plcManager.processStreamInput(
                    text,
                    image: image,
                    document: document,
                    for: primaryBrain, // Pass the DBrain directly
                    chamberId: chamber.id
                )
                
                for try await token in responseStream {
                    fullResponse += token
                    // Create a new message with updated content instead of modifying existing one
                    if let index = messages.firstIndex(where: { $0.id == aiMessageId }) {
                        let updatedMessage = Message(
                            id: aiMessageId,
                            content: fullResponse,
                            isUser: false,
                            timestamp: aiMessage.timestamp,
                            personaName: aiPersonaName
                        )
                        messages[index] = updatedMessage
                    }
                }
            }
        } catch {
            // Create a new message with error content instead of modifying existing one
            if let index = messages.firstIndex(where: { $0.id == aiMessageId }) {
                let errorMessage = Message(
                    id: aiMessageId,
                    content: "Error: \(error.localizedDescription)",
                    isUser: false,
                    timestamp: aiMessage.timestamp,
                    personaName: aiPersonaName
                )
                messages[index] = errorMessage
            }
        }
        
        isLoading = false

        // --- Finalize and store the complete message ---
        let finalMessage = Message(
            id: aiMessageId,
            content: fullResponse,
            isUser: false,
            timestamp: Date(),
            personaName: aiPersonaName
        )
        
        // Replace the placeholder with the final message
        if let index = messages.firstIndex(where: { $0.id == aiMessageId }) {
            messages[index] = finalMessage
        }
        
        chamber.addMessage(finalMessage)
        
        do {
            try await memoryManager.storeMemory(
                content: fullResponse,
                isUser: false,
                personaName: aiPersonaName,
                chamberId: chamber.id
            )
        } catch {
            print("Error storing final AI message: \(error)")
        }
    }
    
    // Refresh messages from storage
    func refreshMessages() async {
        do {
            // Get DMessages from memory manager and convert to Messages
            let dMessages = try await memoryManager.getMessages(for: chamber.id)
            self.messages = dMessages.map { dMessage in
                Message(
                    id: dMessage.id,
                    content: dMessage.content,
                    isUser: dMessage.isUser,
                    timestamp: dMessage.timestamp,
                    personaName: dMessage.personaName
                )
            }
        } catch {
            print("Error refreshing messages: \(error)")
        }
    }
    
    var name: String {
        chamber.name
    }
    
    // Get the actual chamber for saving
    func getChamber() -> Chamber {
        return chamber
    }
    
    // MARK: - Attachment Handling
    
    var isSendButtonDisabled: Bool {
        inputText.isEmpty && attachedImageData == nil && attachedDocument == nil
    }
    
    func attachDocument(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            do {
                // Start accessing the security-scoped resource
                let didStartAccessing = url.startAccessingSecurityScopedResource()
                defer {
                    if didStartAccessing {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                
                let data = try Data(contentsOf: url)
                let type = UTType(filenameExtension: url.pathExtension) ?? .data
                self.attachedDocument = AttachedDocument(fileName: url.lastPathComponent, data: data, type: type)
                self.attachedImageData = nil // Can't have both
            } catch {
                print("Error reading file data: \(error.localizedDescription)")
            }
        case .failure(let error):
            print("Error selecting file: \(error.localizedDescription)")
        }
    }
    
    private func processSelectedPhoto() async {
        if let item = selectedPhoto {
            do {
                if let data = try await item.loadTransferable(type: Data.self) {
                    self.attachedImageData = data
                    self.attachedDocument = nil // Can't have both
                }
            } catch {
                print("Error loading image data: \(error.localizedDescription)")
            }
        }
    }
    
    func removeAttachment() {
        selectedPhoto = nil
        attachedImageData = nil
        attachedDocument = nil
    }
}