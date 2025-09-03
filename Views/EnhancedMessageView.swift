import SwiftUI

struct EnhancedMessageView: View {
    let message: Message
    @ObservedObject var voiceService: VoiceService
    @Environment(\.colorScheme) var colorScheme
    
    @State private var isPlaying = false
    @State private var showingMessageOptions = false

    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                userMessageView
            } else {
                aiMessageView
                Spacer()
            }
        }
        .contextMenu {
            messageContextMenu
        }
    }
    
    private var userMessageView: some View {
        VStack(alignment: .trailing) {
            // Display attached image if present
            if let imageData = message.attachedImageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .cornerRadius(10)
                    .padding(.bottom, 4)
            }
            
            // Display attached document name if present
            if let doc = message.attachedDocument {
                DocumentAttachmentView(document: doc)
                    .padding(.bottom, 4)
            }

            HStack {
                Text(message.content)
                    .font(.token("06 Body.Default"))
                    .padding(10)
                    .background(Color.token("Accent Colors.8 Blue", for: colorScheme))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                
                VStack(spacing: 4) {
                    // Speak button for user messages
                    Button(action: { speakMessage() }) {
                        Image(systemName: isPlaying ? "speaker.wave.2.fill" : "speaker.wave.2")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    // More options button
                    Button(action: { showingMessageOptions = true }) {
                        Image(systemName: "ellipsis")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            HStack {
                Text(formatTimestamp(message.timestamp))
                    .font(.token("11 Caption2.Default"))
                    .foregroundColor(token: "Labels.3 Tertiary")
                
                Text("You")
                    .font(.token("11 Caption2.Default"))
                    .foregroundColor(token: "Labels.3 Tertiary")
            }
        }
        .frame(maxWidth: 300, alignment: .trailing)
    }
    
    private var aiMessageView: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(message.content)
                    .font(.token("06 Body.Default"))
                    .padding(10)
                    .background(Color.token("Grays.Gray 6", for: colorScheme))
                    .foregroundColor(token: "Labels.1 Primary")
                    .cornerRadius(10)
                
                VStack(spacing: 4) {
                    // Speak button for AI messages
                    Button(action: { speakMessage() }) {
                        Image(systemName: isPlaying ? "speaker.wave.2.fill" : "speaker.wave.2")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    // More options button
                    Button(action: { showingMessageOptions = true }) {
                        Image(systemName: "ellipsis")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            HStack {
                Text(message.personaName ?? "AI")
                    .font(.token("11 Caption2.Default"))
                    .foregroundColor(token: "Labels.2 Secondary")
                
                Text(formatTimestamp(message.timestamp))
                    .font(.token("11 Caption2.Default"))
                    .foregroundColor(token: "Labels.3 Tertiary")
            }
        }
        .frame(maxWidth: 300, alignment: .leading)
    }
    
    private var messageContextMenu: some View {
        Group {
            Button(action: { speakMessage() }) {
                Label(isPlaying ? "Stop Speaking" : "Speak Message", systemImage: "speaker.wave.2")
            }
            
            Button(action: { copyMessage() }) {
                Label("Copy", systemImage: "doc.on.doc")
            }
            
            if !message.isUser {
                Button(action: { regenerateResponse() }) {
                    Label("Regenerate", systemImage: "arrow.clockwise")
                }
            }
            
            Divider()
            
            Button(action: { shareMessage() }) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }
    }
    
    private func speakMessage() {
        if isPlaying {
            voiceService.stopSpeaking()
            isPlaying = false
        } else {
            Task {
                await voiceService.speak(message.content)
            }
            isPlaying = true
            
            // Stop playing after reasonable time
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(message.content.count) * 0.1) {
                isPlaying = false
            }
        }
    }
    
    private func copyMessage() {
        UIPasteboard.general.string = message.content
    }
    
    private func regenerateResponse() {
        // Implementation would depend on your chat system
        print("Regenerating response for message: \(message.id)")
    }
    
    private func shareMessage() {
        let activityVC = UIActivityViewController(
            activityItems: [message.content],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct DocumentAttachmentView: View {
    let document: AttachedDocument
    
    var body: some View {
        HStack {
            Image(systemName: documentIcon)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(document.fileName)
                    .font(.caption)
                    .lineLimit(1)
                
                Text(formatFileSize(document.data.count))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("View") {
                // Open document viewer
                openDocument()
            }
            .font(.caption)
            .buttonStyle(.borderedProminent)
            .controlSize(.mini)
        }
        .padding(8)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var documentIcon: String {
        let ext = (document.fileName as NSString).pathExtension.lowercased()
        switch ext {
        case "pdf": return "doc.richtext.fill"
        case "md": return "doc.text.fill"
        case "txt": return "doc.plaintext.fill"
        case "html": return "doc.richtext.fill"
        case "csv", "xls", "xlsx": return "tablecells.fill"
        default: return "doc.fill"
        }
    }
    
    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    private func openDocument() {
        // Create a temporary file and open it
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(document.fileName)
        
        do {
            try document.data.write(to: tempURL)
            
            let activityVC = UIActivityViewController(
                activityItems: [tempURL],
                applicationActivities: nil
            )
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.present(activityVC, animated: true)
            }
        } catch {
            print("Failed to open document: \(error)")
        }
    }
}