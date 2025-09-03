import SwiftUI

struct DropboxStorageConfigView: View {
    @StateObject private var dropboxManager = DropboxStorageManager.shared
    @State private var authToken = ""
    @State private var isAuthenticating = false
    @State private var connectionStatus = "Not Connected"
    @State private var testResult: String?
    @State private var showingAuthInstructions = false
    
    var body: some View {
        List {
            Section(header: Text("Dropbox Configuration")) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "shippingbox.fill")
                            .foregroundColor(.blue)
                        Text("Dropbox Storage")
                            .font(.headline)
                    }
                    
                    Text("Connect your Dropbox account to get 2GB of free storage with automatic sync.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    HStack {
                        Text("Status:")
                        Spacer()
                        Text(connectionStatus)
                            .fontWeight(.medium)
                            .foregroundColor(connectionStatus == "✅ Connected" ? .green : .orange)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section(header: Text("Authentication")) {
                VStack(alignment: .leading, spacing: 12) {
                    if !isDropboxConnected {
                        Text("Enter your Dropbox Access Token:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        SecureField("Access Token", text: $authToken)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button(action: { showingAuthInstructions = true }) {
                            HStack {
                                Image(systemName: "questionmark.circle")
                                Text("How to get an access token?")
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.blue)
                        
                        Button(action: authenticateDropbox) {
                            HStack {
                                if isAuthenticating {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "link")
                                }
                                Text(isAuthenticating ? "Connecting..." : "Connect Dropbox")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(authToken.isEmpty || isAuthenticating)
                        
                    } else {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Dropbox connected successfully!")
                                .fontWeight(.medium)
                        }
                        
                        Button(action: disconnectDropbox) {
                            Text("Disconnect")
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.red)
                    }
                }
            }
            
            if isDropboxConnected {
                Section(header: Text("Test Connection")) {
                    Button(action: testDropboxConnection) {
                        HStack {
                            Image(systemName: "checkmark.circle")
                            Text("Test Upload & Download")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    
                    if let result = testResult {
                        Text(result)
                            .font(.caption)
                            .foregroundColor(result.hasPrefix("✅") ? .green : .red)
                    }
                }
            }
            
            Section(header: Text("Features")) {
                FeatureRow(icon: "cloud.fill", title: "Cloud Storage", description: "2GB free, 2TB paid plans")
                FeatureRow(icon: "arrow.clockwise", title: "Sync", description: "Real-time file synchronization")
                FeatureRow(icon: "person.2", title: "Sharing", description: "Easy file sharing and collaboration")
                FeatureRow(icon: "checkmark.shield", title: "Reliability", description: "99.9% uptime guarantee")
            }
        }
        .navigationTitle("Dropbox Storage")
        .onAppear {
            checkDropboxStatus()
        }
        .sheet(isPresented: $showingAuthInstructions) {
            DropboxAuthInstructionsView()
        }
    }
    
    private var isDropboxConnected: Bool {
        // Check if Dropbox is configured
        return !authToken.isEmpty && connectionStatus.contains("Connected")
    }
    
    private func checkDropboxStatus() {
        Task {
            let isConfigured = await dropboxManager.isConfigured()
            await MainActor.run {
                connectionStatus = isConfigured ? "✅ Connected" : "❌ Not Connected"
            }
        }
    }
    
    private func authenticateDropbox() {
        isAuthenticating = true
        
        Task {
            do {
                // Store the auth token securely
                // In production, you would validate this token with Dropbox API
                UserDefaults.standard.set(authToken, forKey: "DropboxAuthToken")
                
                // Test the connection
                try await dropboxManager.initialize()
                
                await MainActor.run {
                    connectionStatus = "✅ Connected"
                    isAuthenticating = false
                }
                
            } catch {
                await MainActor.run {
                    connectionStatus = "❌ Connection Failed"
                    testResult = "❌ Authentication failed: \(error.localizedDescription)"
                    isAuthenticating = false
                }
            }
        }
    }
    
    private func disconnectDropbox() {
        UserDefaults.standard.removeObject(forKey: "DropboxAuthToken")
        authToken = ""
        connectionStatus = "❌ Not Connected"
        testResult = nil
    }
    
    private func testDropboxConnection() {
        Task {
            do {
                let testData = "Dropbox test - \(Date())".data(using: .utf8)!
                let testFilename = "dropbox_test_\(Int(Date().timeIntervalSince1970)).txt"
                
                try await dropboxManager.storeData(testData, with: testFilename, usingKey: "test_key")
                _ = try await dropboxManager.retrieveData(with: testFilename, usingKey: "test_key")
                try await dropboxManager.deleteData(with: testFilename)
                
                await MainActor.run {
                    testResult = "✅ Test successful - Dropbox storage is working"
                }
                
            } catch {
                await MainActor.run {
                    testResult = "❌ Test failed: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct DropboxAuthInstructionsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Getting a Dropbox Access Token")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 12) {
                    InstructionStep(number: 1, text: "Go to https://www.dropbox.com/developers/apps")
                    InstructionStep(number: 2, text: "Click 'Create app'")
                    InstructionStep(number: 3, text: "Choose 'Scoped access' and 'Full Dropbox'")
                    InstructionStep(number: 4, text: "Enter an app name (e.g., 'Digital Court Storage')")
                    InstructionStep(number: 5, text: "Go to the 'Settings' tab")
                    InstructionStep(number: 6, text: "Generate an access token")
                    InstructionStep(number: 7, text: "Copy the token and paste it in the app")
                }
                
                Spacer()
                
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
            .padding()
            .navigationTitle("Instructions")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct InstructionStep: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text("\(number).")
                .fontWeight(.bold)
                .foregroundColor(.blue)
            Text(text)
            Spacer()
        }
    }
}
