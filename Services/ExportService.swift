import Foundation
import Combine
import UniformTypeIdentifiers
import SwiftUI

@MainActor
class ExportService: ObservableObject {
    static let shared = ExportService()
    
    @Published var isExporting = false
    @Published var exportProgress: Double = 0.0
    @Published var lastExportURL: URL?
    
    private let fileManager = FileManager.default
    
    // MARK: - Chamber Export
    
    func exportChamber(_ chamber: Chamber, format: ChamberExportFormat = .json) async throws -> URL {
        isExporting = true
        exportProgress = 0.0
        
        defer {
            isExporting = false
            exportProgress = 0.0
        }
        
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let timestamp = Int(Date().timeIntervalSince1970)
        let exportURL = documentsPath.appendingPathComponent("Chamber_Export_\(chamber.name.replacingOccurrences(of: " ", with: "_"))_\(timestamp)")
        
        switch format {
        case .json:
            return try await exportChamberAsJSON(chamber, to: exportURL.appendingPathExtension("json"))
        case .markdown:
            return try await exportChamberAsMarkdown(chamber, to: exportURL.appendingPathExtension("md"))
        case .html:
            return try await exportChamberAsHTML(chamber, to: exportURL.appendingPathExtension("html"))
        case .pdf:
            return try await exportChamberAsPDF(chamber, to: exportURL.appendingPathExtension("pdf"))
        }
    }
    
    private func exportChamberAsJSON(_ chamber: Chamber, to url: URL) async throws -> URL {
        exportProgress = 0.2
        
        let exportData = ChamberExportData(
            chamber: CodableChamber(from: chamber),
            exportDate: Date(),
            exportVersion: "1.0",
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        )
        
        exportProgress = 0.5
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let jsonData = try encoder.encode(exportData)
        
        exportProgress = 0.8
        
        try jsonData.write(to: url)
        
        exportProgress = 1.0
        lastExportURL = url
        
        return url
    }
    
    private func exportChamberAsMarkdown(_ chamber: Chamber, to url: URL) async throws -> URL {
        exportProgress = 0.2
        
        var markdown = """
        # \(chamber.name)
        
        **Export Date:** \(DateFormatter.readable.string(from: Date()))
        **Council Members:** \(chamber.council.count)
        **Total Messages:** \(chamber.messages.count)
        
        ---
        
        ## Council Members
        
        """
        
        exportProgress = 0.4
        
        for brain in chamber.council {
            markdown += """
            - **\(brain.name)** (\(brain.soulCapsule?.codename ?? "Unknown"))
            
            """
        }
        
        markdown += "\n## Conversation History\n\n"
        
        exportProgress = 0.6
        
        for (index, message) in chamber.messages.enumerated() {
            let timestamp = DateFormatter.readable.string(from: message.timestamp)
            let sender = message.isUser ? "You" : (message.personaName ?? "AI")
            
            markdown += """
            ### \(sender) - \(timestamp)
            
            \(message.content)
            
            """
            
            if message.attachedImageData != nil {
                markdown += "*[Image attachment]*\n\n"
            }
            
            if let document = message.attachedDocument {
                markdown += "*[Document attachment: \(document.fileName)]*\n\n"
            }
            
            exportProgress = 0.6 + (Double(index) / Double(max(chamber.messages.count, 1))) * 0.3
        }
        
        try markdown.write(to: url, atomically: true, encoding: .utf8)
        
        exportProgress = 1.0
        lastExportURL = url
        
        return url
    }
    
    private func exportChamberAsHTML(_ chamber: Chamber, to url: URL) async throws -> URL {
        exportProgress = 0.2
        
        var html = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>\(chamber.name.htmlEscaped) - Digital Court Export</title>
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 40px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); }
                .container { background: white; border-radius: 10px; padding: 30px; box-shadow: 0 10px 30px rgba(0,0,0,0.2); }
                .header { border-bottom: 2px solid #667eea; margin-bottom: 30px; padding-bottom: 20px; }
                .message { margin: 20px 0; padding: 15px; border-radius: 8px; }
                .user-message { background: #007AFF; color: white; margin-left: 50px; }
                .ai-message { background: #f0f0f0; margin-right: 50px; }
                .timestamp { font-size: 12px; opacity: 0.7; margin-bottom: 5px; }
                .sender { font-weight: bold; margin-bottom: 5px; }
                .attachment { font-style: italic; color: #666; margin-top: 5px; }
                .council-member { background: #f8f9fa; padding: 10px; margin: 5px 0; border-radius: 5px; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>\(chamber.name.htmlEscaped)</h1>
                    <p><strong>Exported:</strong> \(DateFormatter.readable.string(from: Date()))</p>
                    <p><strong>Council Members:</strong> \(chamber.council.count) | <strong>Messages:</strong> \(chamber.messages.count)</p>
                </div>
                
                <div class="council-section">
                    <h2>Council Members</h2>
        """
        
        exportProgress = 0.4
        
        for brain in chamber.council {
            html += """
            <div class="council-member">
                <strong>\(brain.name.htmlEscaped)</strong> - \(brain.soulCapsule?.codename?.htmlEscaped ?? "Unknown")
            </div>
            """
        }
        
        html += """
                </div>
                
                <div class="conversation-section">
                    <h2>Conversation History</h2>
        """
        
        exportProgress = 0.6
        
        for (index, message) in chamber.messages.enumerated() {
            let timestamp = DateFormatter.readable.string(from: message.timestamp)
            let sender = message.isUser ? "You" : (message.personaName ?? "AI")
            let messageClass = message.isUser ? "user-message" : "ai-message"
            
            html += """
            <div class="message \(messageClass)">
                <div class="timestamp">\(timestamp)</div>
                <div class="sender">\(sender.htmlEscaped)</div>
                <div class="content">\(message.content.htmlEscaped.replacingOccurrences(of: "\n", with: "<br>"))</div>
            """
            
            if message.attachedImageData != nil {
                html += "<div class=\"attachment\">[Image attachment]</div>"
            }
            
            if let document = message.attachedDocument {
                html += "<div class=\"attachment\">[Document: \(document.fileName.htmlEscaped)]</div>"
            }
            
            html += "</div>"
            
            exportProgress = 0.6 + (Double(index) / Double(max(chamber.messages.count, 1))) * 0.3
        }
        
        html += """
                </div>
            </div>
        </body>
        </html>
        """
        
        try html.write(to: url, atomically: true, encoding: .utf8)
        
        exportProgress = 1.0
        lastExportURL = url
        
        return url
    }
    
    private func exportChamberAsPDF(_ chamber: Chamber, to url: URL) async throws -> URL {
        // For PDF export, we'll create HTML first then convert
        let htmlURL = try await exportChamberAsHTML(chamber, to: url.deletingPathExtension().appendingPathExtension("html"))
        
        // In a real implementation, you would use WKWebView to convert HTML to PDF
        // For now, we'll return the HTML URL as a placeholder
        lastExportURL = htmlURL
        return htmlURL
    }
    
    // MARK: - Chat Export
    
    func exportChatHistory(_ messages: [Message], title: String = "Chat Export") async throws -> URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let exportURL = documentsPath.appendingPathComponent("Chat_\(title)_\(Date().timeIntervalSince1970).json")
        
        isExporting = true
        defer { isExporting = false }
        
        let exportData = ChatExportData(
            title: title,
            messages: messages.map { CodableMessage(from: $0) },
            exportDate: Date(),
            messageCount: messages.count
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted]
        
        let jsonData = try encoder.encode(exportData)
        try jsonData.write(to: exportURL)
        
        lastExportURL = exportURL
        return exportURL
    }
    
    // MARK: - Import Methods
    
    func importChamber(from url: URL) async throws -> Chamber {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let exportData = try decoder.decode(ChamberExportData.self, from: data)
        return exportData.chamber.toChamber()
    }
    
    func importChatHistory(from url: URL) async throws -> [Message] {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let exportData = try decoder.decode(ChatExportData.self, from: data)
        return exportData.messages.map { $0.toMessage() }
    }
    
    // MARK: - Share Methods
    
    func shareChamber(_ chamber: Chamber, format: ChamberExportFormat = .json) async throws -> URL {
        return try await exportChamber(chamber, format: format)
    }
    
    func createShareableLink(for chamber: Chamber) async throws -> String {
        // In a real implementation, this would upload to a sharing service
        // For now, return a placeholder
        return "https://digitalcourt.ai/shared/chamber/\(chamber.id.uuidString)"
    }
    
    // MARK: - Utility Methods
    
    func getExportDirectory() -> URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let exportDir = documentsPath.appendingPathComponent("DigitalCourt_Exports")
        
        if !fileManager.fileExists(atPath: exportDir.path) {
            try? fileManager.createDirectory(at: exportDir, withIntermediateDirectories: true)
        }
        
        return exportDir
    }
    
    func cleanupOldExports(olderThan days: Int = 30) async {
        let exportDir = getExportDirectory()
        let cutoffDate = Date().addingTimeInterval(-TimeInterval(days * 24 * 60 * 60))
        
        guard let files = try? fileManager.contentsOfDirectory(at: exportDir, includingPropertiesForKeys: [.creationDateKey]) else {
            return
        }
        
        for file in files {
            if let creationDate = try? file.resourceValues(forKeys: [.creationDateKey]).creationDate,
               creationDate < cutoffDate {
                try? fileManager.removeItem(at: file)
            }
        }
    }
}

// MARK: - Supporting Types

enum ChamberExportFormat: String, CaseIterable {
    case json = "JSON"
    case markdown = "Markdown"
    case html = "HTML"
    case pdf = "PDF"
    
    var fileExtension: String {
        switch self {
        case .json: return "json"
        case .markdown: return "md"
        case .html: return "html"
        case .pdf: return "pdf"
        }
    }
}

// MARK: - Codable Wrapper Types

struct CodableChamber: Codable {
    let id: UUID
    let name: String
    let councilNames: [String] // Store names instead of full DBrain objects
    let messages: [CodableMessage]
    
    init(from chamber: Chamber) {
        self.id = chamber.id
        self.name = chamber.name
        self.councilNames = chamber.council.map { $0.name }
        self.messages = chamber.messages.map { CodableMessage(from: $0) }
    }
    
    func toChamber() -> Chamber {
        let messages = self.messages.map { $0.toMessage() }
        // Note: Council members would need to be reconstructed from the names
        // This is a simplified version that creates empty council
        return Chamber(id: self.id, name: self.name, council: [], messages: messages)
    }
}

struct CodableMessage: Codable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    let personaName: String?
    let hasImageAttachment: Bool
    let hasDocumentAttachment: Bool
    let documentFileName: String?
    
    init(from message: Message) {
        self.id = message.id
        self.content = message.content
        self.isUser = message.isUser
        self.timestamp = message.timestamp
        self.personaName = message.personaName
        self.hasImageAttachment = message.attachedImageData != nil
        self.hasDocumentAttachment = message.attachedDocument != nil
        self.documentFileName = message.attachedDocument?.fileName
    }
    
    func toMessage() -> Message {
        return Message(
            id: self.id,
            content: self.content,
            isUser: self.isUser,
            timestamp: self.timestamp,
            personaName: self.personaName,
            attachedImageData: nil, // Attachments would need separate handling
            attachedDocument: nil
        )
    }
}

struct ChamberExportData: Codable {
    let chamber: CodableChamber
    let exportDate: Date
    let exportVersion: String
    let appVersion: String
}

struct ChatExportData: Codable {
    let title: String
    let messages: [CodableMessage]
    let exportDate: Date
    let messageCount: Int
}

// MARK: - String Extensions

extension String {
    var htmlEscaped: String {
        return self.replacingOccurrences(of: "&", with: "&amp;")
                   .replacingOccurrences(of: "<", with: "&lt;")
                   .replacingOccurrences(of: ">", with: "&gt;")
                   .replacingOccurrences(of: "\"", with: "&quot;")
                   .replacingOccurrences(of: "'", with: "&#39;")
    }
}

// MARK: - DateFormatter Extension

extension DateFormatter {
    static let readable: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}