import SwiftUI

struct IPFSStorageConfigView: View {
    @StateObject private var ipfsManager = IPFSStorageManager.shared
    @State private var gatewayURL = "https://ipfs.infura.io:5001"
    @State private var projectId = ""
    @State private var projectSecret = ""
    @State private var connectionStatus = "Not Connected"
    @State private var testResult: String?
    @State private var isTestingConnection = false
    @State private var showingInfuraInstructions = false
    
    var body: some View {
        List {
            Section(header: Text("IPFS Configuration")) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "network")
                            .foregroundColor(.purple)
                        Text("IPFS Distributed Storage")
                            .font(.headline)
                    }
                    
                    Text("InterPlanetary File System - Decentralized storage network with content-addressed data.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    HStack {
                        Text("Status:")
                        Spacer()
                        Text(connectionStatus)
                            .fontWeight(.medium)
                            .foregroundColor(connectionStatus.contains("✅") ? .green : .orange)
                    }
                    
                    if ipfsManager.connectionStatus == .connected {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("IPFS Gateway Connected")
                                .fontWeight(.medium)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section(header: Text("Gateway Configuration")) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("IPFS Gateway URL:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextField("Gateway URL", text: $gatewayURL)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    Text("For better reliability, use Infura IPFS:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        TextField("Project ID", text: $projectId)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        SecureField("Secret", text: $projectSecret)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    HStack {
                        Button(action: { showingInfuraInstructions = true }) {
                            HStack {
                                Image(systemName: "questionmark.circle")
                                Text("Get Infura credentials")
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.blue)
                        
                        Spacer()
                        
                        Button(action: saveConfiguration) {
                            Text("Save Config")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            
            Section(header: Text("Features")) {
                FeatureRow(icon: "globe", title: "Decentralized", description: "No central authority or servers")
                FeatureRow(icon: "link", title: "Content Addressing", description: "Files identified by cryptographic hash")
                FeatureRow(icon: "infinity", title: "Unlimited Storage", description: "No storage limits (requires pinning)")
                FeatureRow(icon: "speedometer", title: "Performance", description: "Fast retrieval from global network")
            }
            
            Section(header: Text("Test Connection")) {
                VStack(alignment: .leading, spacing: 12) {
                    Button(action: testIPFSConnection) {
                        HStack {
                            if isTestingConnection {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "checkmark.circle")
                            }
                            Text(isTestingConnection ? "Testing..." : "Test Upload & Download")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isTestingConnection)
                    
                    if let result = testResult {
                        Text(result)
                            .font(.caption)
                            .foregroundColor(result.hasPrefix("✅") ? .green : .red)
                            .padding(.top, 4)
                    }
                    
                    Text("Note: Files uploaded to IPFS are public. The app encrypts data before upload.")
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .italic()
                }
            }
            
            Section(header: Text("Setup Status")) {
                ConfigStep(number: 1, title: "Gateway", description: "IPFS gateway configured", isCompleted: !gatewayURL.isEmpty)
                ConfigStep(number: 2, title: "Connection", description: "Successfully connected to network", isCompleted: ipfsManager.connectionStatus == .connected)
                ConfigStep(number: 3, title: "Pinning Service", description: "Optional: Ensure data persistence", isCompleted: false)
            }
            
            Section(header: Text("Recommended Pinning Services")) {
                VStack(alignment: .leading, spacing: 8) {
                    PinningServiceRow(name: "Pinata", cost: "1GB free", url: "https://pinata.cloud")
                    PinningServiceRow(name: "Infura IPFS", cost: "5GB free", url: "https://infura.io")
                    PinningServiceRow(name: "Fleek", cost: "Storage + hosting", url: "https://fleek.co")
                    
                    Text("Pinning services ensure your data remains available on IPFS even when your node is offline.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .italic()
                        .padding(.top, 8)
                }
            }
        }
        .navigationTitle("IPFS Storage")
        .onAppear {
            checkIPFSStatus()
            loadSavedConfiguration()
        }
        .sheet(isPresented: $showingInfuraInstructions) {
            InfuraInstructionsView()
        }
    }
    
    private func checkIPFSStatus() {
        Task {
            let isConfigured = await ipfsManager.isConfigured()
            await MainActor.run {
                connectionStatus = isConfigured ? "✅ Connected" : "❌ Not Connected"
            }
        }
    }
    
    private func loadSavedConfiguration() {
        if let savedGateway = UserDefaults.standard.string(forKey: "IPFSGatewayURL") {
            gatewayURL = savedGateway
        }
        if let savedProjectId = UserDefaults.standard.string(forKey: "IPFSProjectId") {
            projectId = savedProjectId
        }
        if let savedSecret = UserDefaults.standard.string(forKey: "IPFSProjectSecret") {
            projectSecret = savedSecret
        }
    }
    
    private func saveConfiguration() {
        UserDefaults.standard.set(gatewayURL, forKey: "IPFSGatewayURL")
        UserDefaults.standard.set(projectId, forKey: "IPFSProjectId")
        UserDefaults.standard.set(projectSecret, forKey: "IPFSProjectSecret")
        
        // Reinitialize IPFS manager with new configuration
        Task {
            do {
                try await ipfsManager.initialize()
                await MainActor.run {
                    connectionStatus = "✅ Connected"
                    testResult = "✅ Configuration saved successfully"
                }
            } catch {
                await MainActor.run {
                    connectionStatus = "❌ Connection Failed"
                    testResult = "❌ Failed to connect: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func testIPFSConnection() {
        isTestingConnection = true
        testResult = nil
        
        Task {
            do {
                let testData = "IPFS test - \(Date())".data(using: .utf8)!
                let testFilename = "ipfs_test_\(Int(Date().timeIntervalSince1970)).txt"
                
                try await ipfsManager.storeData(testData, with: testFilename, usingKey: "test_key")
                
                // Test retrieval
                _ = try await ipfsManager.retrieveData(with: testFilename, usingKey: "test_key")
                
                // Test file info
                if let fileInfo = ipfsManager.getFileInfo(testFilename) {
                    await MainActor.run {
                        testResult = "✅ Test successful - IPFS hash: \(fileInfo.hash)"
                        isTestingConnection = false
                    }
                }
                
            } catch {
                await MainActor.run {
                    testResult = "❌ Test failed: \(error.localizedDescription)"
                    isTestingConnection = false
                }
            }
        }
    }
}

struct PinningServiceRow: View {
    let name: String
    let cost: String
    let url: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(name)
                    .fontWeight(.medium)
                Text(cost)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Link("Visit", destination: URL(string: url)!)
                .font(.caption)
                .buttonStyle(.bordered)
        }
        .padding(.vertical, 2)
    }
}

struct InfuraInstructionsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Setting up Infura IPFS")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        InstructionStep(number: 1, text: "Go to https://infura.io and create an account")
                        InstructionStep(number: 2, text: "Click 'Create New Project' and select 'IPFS'")
                        InstructionStep(number: 3, text: "Give your project a name (e.g., 'Digital Court IPFS')")
                        InstructionStep(number: 4, text: "Copy the Project ID from the project settings")
                        InstructionStep(number: 5, text: "Copy the Project Secret (API Key Secret)")
                        InstructionStep(number: 6, text: "Paste both in the configuration fields")
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Benefits of Infura:")
                            .font(.headline)
                        
                        Text("• 5GB free storage")
                        Text("• 100GB bandwidth per month")
                        Text("• Reliable hosted IPFS node")
                        Text("• No need to run your own node")
                        Text("• Enterprise-grade infrastructure")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("Infura Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
