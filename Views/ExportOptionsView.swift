import SwiftUI

struct ExportOptionsView: View {
    let chamber: Chamber
    @EnvironmentObject var exportService: ExportService
    
    @State private var selectedFormat: ChamberExportFormat = .json
    @State private var includeAttachments = true
    @State private var includeTimestamps = true
    @State private var isExporting = false
    @State private var exportedURL: URL?
    @State private var showingShareSheet = false
    @State private var exportError: String?
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Export Format")) {
                    Picker("Format", selection: $selectedFormat) {
                        ForEach(ChamberExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue)
                                .tag(format)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Export Options")) {
                    Toggle("Include Attachments", isOn: $includeAttachments)
                    Toggle("Include Timestamps", isOn: $includeTimestamps)
                    
                    HStack {
                        Text("Messages to Export")
                        Spacer()
                        Text("\(chamber.messages.count)")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Preview")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("File: \(chamber.name)_export.\(selectedFormat.fileExtension)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Estimated Size: \(estimatedFileSize())")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if selectedFormat == .html {
                            Text("Note: HTML export includes styling and formatting")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Section {
                    if isExporting {
                        HStack {
                            ProgressView()
                            Text("Exporting...")
                            Spacer()
                            Text("\(Int(exportService.exportProgress * 100))%")
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Button("Export Chamber") {
                            exportChamber()
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                    }
                    
                    if exportedURL != nil {
                        Button("Share Export") {
                            showingShareSheet = true
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("Export Chamber")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Dismiss
                    }
                }
            }
        }
        .alert("Export Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(exportError ?? "Unknown error occurred")
        }
        .sheet(isPresented: $showingShareSheet) {
            if exportedURL != nil {
                ShareSheet(items: [exportedURL!])
            }
        }
    }
    
    private func formatIcon(_ format: ChamberExportFormat) -> String {
        switch format {
        case .json: return "doc.badge.gearshape"
        case .markdown: return "doc.text"
        case .html: return "doc.richtext"
        case .pdf: return "doc.richtext.fill"
        }
    }
    
    private func estimatedFileSize() -> String {
        let baseSize = chamber.messages.reduce(0) { total, message in
            total + message.content.count
        }
        
        let attachmentSize = includeAttachments ? chamber.messages.reduce(0) { total, message in
            let imageSize = message.attachedImageData?.count ?? 0
            let docSize = message.attachedDocument?.data.count ?? 0
            return total + imageSize + docSize
        } : 0
        
        let totalBytes = baseSize + attachmentSize
        
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(totalBytes))
    }
    
    private func exportChamber() {
        isExporting = true
        
        Task {
            do {
                let url = try await exportService.exportChamber(chamber, format: selectedFormat)
                
                await MainActor.run {
                    self.exportedURL = url
                    self.isExporting = false
                }
            } catch {
                await MainActor.run {
                    self.exportError = error.localizedDescription
                    self.showingError = true
                    self.isExporting = false
                }
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
