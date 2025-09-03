import SwiftUI
import UniformTypeIdentifiers

struct EnhancedAttachmentPreviewView: View {
    @ObservedObject var viewModel: ChatChamberViewModel
    
    var body: some View {
        VStack(spacing: 8) {
            if let imageData = viewModel.attachedImageData, let uiImage = UIImage(data: imageData) {
                imageAttachmentView(uiImage)
            }
            
            if let document = viewModel.attachedDocument {
                documentAttachmentView(document)
            }
        }
    }
    
    private func imageAttachmentView(_ image: UIImage) -> some View {
        HStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(height: 60)
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Image Attachment")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("\(Int(image.size.width)) × \(Int(image.size.height))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(formatImageSize(image))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                Button(action: { viewModel.removeAttachment() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
                
                Button(action: { editImage() }) {
                    Image(systemName: "pencil.circle")
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func documentAttachmentView(_ document: AttachedDocument) -> some View {
        HStack {
            // Document icon
            Image(systemName: documentIcon(for: document.fileName))
                .font(.largeTitle)
                .foregroundColor(.blue)
                .frame(width: 60, height: 60)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(document.fileName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                Text(document.type.localizedDescription ?? "Document")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(formatFileSize(document.data.count))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                Button(action: { viewModel.removeAttachment() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
                
                Button(action: { previewDocument(document) }) {
                    Image(systemName: "eye.circle")
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func documentIcon(for fileName: String) -> String {
        let ext = (fileName as NSString).pathExtension.lowercased()
        switch ext {
        case "pdf": return "doc.richtext.fill"
        case "md": return "doc.text.fill"
        case "txt": return "doc.plaintext.fill"
        case "html": return "doc.richtext.fill"
        case "csv", "xls", "xlsx": return "tablecells.fill"
        case "json": return "doc.badge.gearshape.fill"
        case "zip", "tar", "gz": return "doc.zipper"
        default: return "doc.fill"
        }
    }
    
    private func formatImageSize(_ image: UIImage) -> String {
        let sizeInBytes = Int(image.pngData()?.count ?? 0)
        return formatFileSize(sizeInBytes)
    }
    
    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    private func editImage() {
        // Future: Implement image editing functionality
        print("Edit image functionality would be implemented here")
    }
    
    private func previewDocument(_ document: AttachedDocument) {
        // Create temporary file for preview
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(document.fileName)
        
        do {
            try document.data.write(to: tempURL)
            
            // Present document interaction controller
            let activityVC = UIActivityViewController(
                activityItems: [tempURL],
                applicationActivities: nil
            )
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.present(activityVC, animated: true)
            }
        } catch {
            print("Failed to preview document: \(error)")
        }
    }
}