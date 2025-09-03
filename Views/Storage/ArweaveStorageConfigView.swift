import SwiftUI

struct ArweaveStorageConfigView: View {
    @StateObject private var arweaveManager = ArweaveStorageManager.shared
    @State private var walletText = ""
    @State private var connectionStatus = "Not Configured"
    @State private var testResult: String?
    @State private var showingWalletInstructions = false
    @State private var isTestingConnection = false
    
    var body: some View {
        List {
            Section(header: Text("Arweave Configuration")) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "archivebox.fill")
                            .foregroundColor(.purple)
                        Text("Arweave Permanent Storage")
                            .font(.headline)
                    }
                    
                    Text("Arweave provides permanent, immutable storage. Pay once, store forever on the blockchain.")
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
                }
                .padding(.vertical, 8)
            }
            
            Section(header: Text("Wallet Configuration")) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Arweave Wallet (JSON)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Paste your Arweave wallet JSON here, or add wallet.json to the app bundle:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $walletText)
                        .frame(height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
                        .font(.system(.caption, design: .monospaced))
                    
                    HStack {
                        Button(action: { showingWalletInstructions = true }) {
                            HStack {
                                Image(systemName: "questionmark.circle")
                                Text("How to get an Arweave wallet?")
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.blue)
                        
                        Spacer()
                        
                        Button(action: saveWallet) {
                            Text("Save Wallet")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(walletText.isEmpty)
                    }
                }
            }
            
            Section(header: Text("Features")) {
                FeatureRow(icon: "infinity", title: "Permanent Storage", description: "Pay once, store forever")
                FeatureRow(icon: "lock.shield", title: "Immutable", description: "Data cannot be changed or deleted")
                FeatureRow(icon: "globe", title: "Decentralized", description: "Distributed across global network")
                FeatureRow(icon: "dollarsign.circle", title: "Cost Model", description: "Pay per MB uploaded (~$5/GB)")
            }
            
            if hasWallet {
                Section(header: Text("Test Connection")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Button(action: testArweaveConnection) {
                            HStack {
                                if isTestingConnection {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "checkmark.circle")
                                }
                                Text(isTestingConnection ? "Testing..." : "Test Upload")
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
                        
                        Text("Note: Arweave uploads are permanent and cost AR tokens. Test uploads will use real tokens.")
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .italic()
                    }
                }
            }
            
            Section(header: Text("Current Setup")) {
                VStack(alignment: .leading, spacing: 8) {
                    ConfigStep(number: 1, title: "Wallet", description: "Arweave wallet configuration", isCompleted: hasWallet)
                    ConfigStep(number: 2, title: "Balance", description: "Sufficient AR tokens for uploads", isCompleted: false)
                    ConfigStep(number: 3, title: "Network", description: "Connection to Arweave network", isCompleted: connectionStatus.contains("✅"))
                }
            }
        }
        .navigationTitle("Arweave Storage")
        .onAppear {
            checkArweaveStatus()
            loadExistingWallet()
        }
        .sheet(isPresented: $showingWalletInstructions) {
            ArweaveWalletInstructionsView()
        }
    }
    
    private var hasWallet: Bool {
        return !walletText.isEmpty || Bundle.main.path(forResource: "wallet", ofType: "json") != nil
    }
    
    private func checkArweaveStatus() {
        Task {
            let isConfigured = await arweaveManager.isConfigured()
            await MainActor.run {
                connectionStatus = isConfigured ? "✅ Configured" : "⚠️ Setup Required"
            }
        }
    }
    
    private func loadExistingWallet() {
        // Try to load existing wallet
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let walletURL = documentsPath.appendingPathComponent("wallet.json")
        
        if let data = try? Data(contentsOf: walletURL),
           let walletString = String(data: data, encoding: .utf8) {
            walletText = walletString
        }
    }
    
    private func saveWallet() {
        guard !walletText.isEmpty else { return }
        
        // Validate JSON format
        guard let data = walletText.data(using: .utf8),
              let _ = try? JSONSerialization.jsonObject(with: data) else {
            testResult = "❌ Invalid JSON format"
            return
        }
        
        // Save to documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let walletURL = documentsPath.appendingPathComponent("wallet.json")
        
        do {
            try data.write(to: walletURL)
            testResult = "✅ Wallet saved successfully"
            
            // Re-initialize Arweave manager
            Task {
                try await arweaveManager.initialize()
                await MainActor.run {
                    connectionStatus = "✅ Configured"
                }
            }
        } catch {
            testResult = "❌ Failed to save wallet: \(error.localizedDescription)"
        }
    }
    
    private func testArweaveConnection() {
        isTestingConnection = true
        testResult = nil
        
        Task {
            do {
                let testData = "Arweave test - \(Date())".data(using: .utf8)!
                let testFilename = "arweave_test_\(Int(Date().timeIntervalSince1970)).txt"
                
                try await arweaveManager.storeData(testData, with: testFilename, usingKey: "test_key")
                
                // Note: Arweave retrieval might take time due to mining
                let _ = try await arweaveManager.retrieveData(with: testFilename, usingKey: "test_key")
                
                await MainActor.run {
                    testResult = "✅ Test successful - Data stored on Arweave blockchain"
                    isTestingConnection = false
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

struct ArweaveWalletInstructionsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Getting an Arweave Wallet")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Method 1: ArConnect Browser Extension")
                            .font(.headline)
                        
                        InstructionStep(number: 1, text: "Install ArConnect extension from arconnect.io")
                        InstructionStep(number: 2, text: "Create a new wallet or import existing")
                        InstructionStep(number: 3, text: "Export wallet as JSON file")
                        InstructionStep(number: 4, text: "Copy the JSON content to the app")
                        
                        Divider()
                        
                        Text("Method 2: Command Line")
                            .font(.headline)
                        
                        InstructionStep(number: 1, text: "Install Arweave CLI: npm install -g arweave")
                        InstructionStep(number: 2, text: "Generate wallet: arweave key-create wallet.json")
                        InstructionStep(number: 3, text: "Fund with AR tokens from an exchange")
                        InstructionStep(number: 4, text: "Add wallet.json to app or copy content")
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Important Notes:")
                            .font(.headline)
                            .foregroundColor(.orange)
                        
                        Text("• AR tokens are required for uploads (cost ~$5/GB)")
                        Text("• Storage is permanent - data cannot be deleted")
                        Text("• Wallet private keys must be kept secure")
                        Text("• Transactions may take 10-15 minutes to confirm")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("Arweave Wallet")
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