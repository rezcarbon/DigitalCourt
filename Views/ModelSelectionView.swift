import SwiftUI
import UniformTypeIdentifiers

struct ModelSelectionView: View {
    @ObservedObject var downloadManager = ModelDownloadManager.shared
    @State private var showImporter = false
    @State private var selectedFiles: [URL] = []
    @State private var manualModelID = ""
    @State private var showModelIDPrompt = false

    var body: some View {
        VStack {
            Button("Import LLM Model Files") {
                showModelIDPrompt = true
            }
            .padding()
            .sheet(isPresented: $showModelIDPrompt) {
                VStack {
                    Text("Enter new Model Folder Name (no spaces, e.g. 'myllama-custom')\n(All files will be imported into this folder)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                    TextField("Model ID/Folder", text: $manualModelID)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    Button("Pick Model Files") {
                        showImporter = true
                    }
                    .disabled(manualModelID.trimmingCharacters(in: .whitespaces).isEmpty)
                    .padding()
                    Button("Cancel") { showModelIDPrompt = false }
                        .foregroundColor(.red)
                }
                .padding()
            }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.data],
                allowsMultipleSelection: true
            ) { result in
                showModelIDPrompt = false
                switch result {
                case .success(let urls):
                    selectedFiles = urls
                    importModelFiles(files: selectedFiles, folderName: manualModelID.trimmingCharacters(in: .whitespaces))
                case .failure(let error):
                    print("Model import failed: \(error)")
                }
            }

            // ...existing model list code...
        }
    }

    private func importModelFiles(files: [URL], folderName: String) {
        guard !folderName.isEmpty else { return }
        let fileManager = FileManager.default
        let modelsDir = downloadManager.modelsDirectory
        let destDir = modelsDir.appendingPathComponent(folderName)

        do {
            if fileManager.fileExists(atPath: destDir.path) {
                try fileManager.removeItem(at: destDir)
            }
            try fileManager.createDirectory(at: destDir, withIntermediateDirectories: true)
            for fileURL in files {
                let destURL = destDir.appendingPathComponent(fileURL.lastPathComponent)
                if fileManager.fileExists(atPath: destURL.path) {
                    try fileManager.removeItem(at: destURL)
                }
                try fileManager.copyItem(at: fileURL, to: destURL)
            }
            Task {
                await downloadManager.loadAndVerifyModels()
            }
        } catch {
            print("Model manual import failed:", error)
        }
    }
}