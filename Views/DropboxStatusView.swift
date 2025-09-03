import SwiftUI

struct DropboxStatusView: View {
    @StateObject private var dropboxService = DropboxService.shared
    @State private var showingFileList = false
    @State private var files: [DropboxFile] = []
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "cloud.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                Text("Dropbox Storage")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                connectionStatusIndicator
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // User Info
            if let user = dropboxService.currentUser {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Connected Account")
                        .font(.headline)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text(user.name)
                                .fontWeight(.medium)
                            Text(user.email)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("✅ Ready")
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .shadow(radius: 1)
            }
            
            // Actions
            VStack(spacing: 12) {
                Button(action: {
                    Task {
                        await dropboxService.testConnection()
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Test Connection")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                Button(action: {
                    showingFileList = true
                    loadFileList()
                }) {
                    HStack {
                        Image(systemName: "list.bullet")
                        Text("View Files")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(!dropboxService.isAuthenticated)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Dropbox Integration")
        .onAppear {
            if !dropboxService.isInitialized {
                Task {
                    await dropboxService.testConnection()
                }
            }
        }
        .sheet(isPresented: $showingFileList) {
            DropboxFileListView(files: files)
        }
    }
    
    @ViewBuilder
    private var connectionStatusIndicator: some View {
        switch dropboxService.connectionStatus {
        case .disconnected:
            HStack {
                Circle()
                    .fill(Color.gray)
                    .frame(width: 8, height: 8)
                Text("Disconnected")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        case .connecting:
            HStack {
                ProgressView()
                    .scaleEffect(0.6)
                Text("Connecting...")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        case .connected:
            HStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                Text("Connected")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        case .error(_):
            HStack {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                Text("Error")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
    
    private func loadFileList() {
        Task {
            do {
                // Use the method that returns [DropboxFile] instead of [String]
                let fileList = try await dropboxService.listDropboxFiles()
                await MainActor.run {
                    files = fileList
                }
            } catch {
                print("Failed to load files: \(error)")
                // Fallback: create DropboxFile objects from string list
                do {
                    let fileNames = try await dropboxService.listFiles()
                    await MainActor.run {
                        files = fileNames.map { filename in
                            DropboxFile(
                                id: UUID().uuidString,
                                name: filename,
                                size: 0,
                                modifiedTime: Date()
                            )
                        }
                    }
                } catch {
                    print("Failed to load file names: \(error)")
                }
            }
        }
    }
}

struct DropboxFileListView: View {
    let files: [DropboxFile]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(files) { file in
                VStack(alignment: .leading, spacing: 4) {
                    Text(file.name)
                        .fontWeight(.medium)
                    
                    HStack {
                        Text(ByteCountFormatter.string(fromByteCount: Int64(file.size), countStyle: .file))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(file.modifiedTime, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 2)
            }
            .navigationTitle("Dropbox Files")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    DropboxStatusView()
}