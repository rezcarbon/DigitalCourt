import SwiftUI

struct FirebaseStorageConfigView: View {
    @StateObject private var firebaseManager = FirebaseStorageManager.shared
    @State private var connectionStatus = "Checking..."
    @State private var isTestingConnection = false
    @State private var testResult: String?
    
    var body: some View {
        List {
            Section(header: Text("Firebase Configuration")) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("Firebase Cloud Storage")
                            .font(.headline)
                    }
                    
                    Text("Firebase provides 5GB of free storage with Google's cloud infrastructure.")
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
                    
                    HStack {
                        Text("Configuration:")
                        Spacer()
                        Text(firebaseConfigured ? "✅ Ready" : "⚠️ Setup Required")
                            .fontWeight(.medium)
                            .foregroundColor(firebaseConfigured ? .green : .orange)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section(header: Text("Features")) {
                FeatureRow(icon: "cloud.fill", title: "Cloud Storage", description: "5GB free tier")
                FeatureRow(icon: "lock.shield", title: "Security", description: "Enterprise-grade encryption")
                FeatureRow(icon: "speedometer", title: "Performance", description: "Global CDN network")
                FeatureRow(icon: "dollarsign.circle", title: "Cost", description: "Free up to 5GB")
            }
            
            Section(header: Text("Test Connection")) {
                VStack(alignment: .leading, spacing: 12) {
                    Button(action: testConnection) {
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
                }
            }
            
            Section(header: Text("Configuration Steps")) {
                VStack(alignment: .leading, spacing: 8) {
                    ConfigStep(number: 1, title: "Firebase Project", description: "GoogleService-Info.plist is configured", isCompleted: firebaseConfigured)
                    ConfigStep(number: 2, title: "Authentication", description: "Firebase Auth setup", isCompleted: firebaseConfigured)
                    ConfigStep(number: 3, title: "Storage Rules", description: "Security rules configured", isCompleted: firebaseConfigured)
                    ConfigStep(number: 4, title: "SDK Integration", description: "Firebase SDK initialized", isCompleted: firebaseConfigured)
                }
            }
        }
        .navigationTitle("Firebase Storage")
        .onAppear {
            checkFirebaseStatus()
        }
    }
    
    private var firebaseConfigured: Bool {
        // Check if GoogleService-Info.plist exists
        return Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil
    }
    
    private func checkFirebaseStatus() {
        Task {
            let isConfigured = await firebaseManager.isConfigured()
            await MainActor.run {
                connectionStatus = isConfigured ? "✅ Connected" : "⚠️ Setup Required"
            }
        }
    }
    
    private func testConnection() {
        isTestingConnection = true
        testResult = nil
        
        Task {
            do {
                // Test upload
                let testData = "Firebase test - \(Date())".data(using: .utf8)!
                let testFilename = "test_\(Int(Date().timeIntervalSince1970)).txt"
                
                try await firebaseManager.storeData(testData, with: testFilename, usingKey: "test_key")
                
                // Test download
                _ = try await firebaseManager.retrieveData(with: testFilename, usingKey: "test_key")
                
                // Cleanup
                try await firebaseManager.deleteData(with: testFilename)
                
                await MainActor.run {
                    testResult = "✅ Test successful - Firebase storage is working"
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

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading) {
                Text(title)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

struct ConfigStep: View {
    let number: Int
    let title: String
    let description: String
    let isCompleted: Bool
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(isCompleted ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 24, height: 24)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                } else {
                    Text("\(number)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}
