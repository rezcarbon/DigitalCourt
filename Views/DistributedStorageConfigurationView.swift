import SwiftUI

struct DistributedStorageConfigurationView: View {
    @StateObject private var redundancyManager = StorageRedundancyManager.shared

    enum StorageProvider: String, CaseIterable {
        case firebase = "Firebase"
        case dropbox = "Dropbox"
        case arweave = "Arweave"
        case ipfs = "IPFS"
        
        var icon: String {
            switch self {
            case .firebase: return "flame.fill"
            case .dropbox: return "shippingbox.fill"
            case .arweave: return "archivebox.fill"
            case .ipfs: return "network"
            }
        }
        var freeStorage: String {
            switch self {
            case .firebase: return "5GB"
            case .dropbox: return "2GB"
            case .arweave: return "Pay per use"
            case .ipfs: return "Unlimited*"
            }
        }
        var description: String {
            switch self {
            case .firebase: return "Google's cloud platform with generous free tier"
            case .dropbox: return "Popular cloud storage with 2GB free tier"
            case .arweave: return "Permanent storage blockchain (pay once, store forever)"
            case .ipfs: return "Decentralized storage network (requires pinning service)"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Distributed Storage Overview")) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "shield.lefthalf.filled")
                                .foregroundColor(.blue)
                            Text("True Independence")
                                .fontWeight(.medium)
                        }
                        
                        Text("Your encrypted memories are distributed across multiple free cloud providers for maximum security and availability.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.green)
                            Text("End-to-End Encrypted")
                                .fontWeight(.medium)
                        }
                        
                        Text("All data is encrypted locally before upload. Cloud providers never see your unencrypted data.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Available Storage Providers")) {
                    ForEach(StorageProvider.allCases, id: \.self) { provider in
                        NavigationLink(destination: destinationView(for: provider)) {
                            HStack {
                                Image(systemName: provider.icon)
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(provider.rawValue)
                                        .fontWeight(.medium)
                                    
                                    Text(provider.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text(provider.freeStorage)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.green)
                                    
                                    let isHealthy = redundancyManager.availableProviders.first { $0.name == provider.rawValue.lowercased() }?.isHealthy ?? false
                                    
                                    Text(isHealthy ? "✅ Ready" : "❌ Setup")
                                        .font(.caption2)
                                        .foregroundColor(isHealthy ? .green : .orange)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                Section(header: Text("Provider Settings")) {
                    Picker("Primary Provider", selection: $redundancyManager.primaryProviderKey) {
                        ForEach(redundancyManager.availableProviders, id: \.name) { provider in
                            Text(provider.name.capitalized).tag(provider.name)
                        }
                    }
                    .pickerStyle(.segmented)
                    Toggle("Enable Redundant Storage (Write to Both)", isOn: $redundancyManager.redundancyEnabled)
                }
                
                Section(header: Text("Storage Statistics")) {
                    let stats = redundancyManager.getProviderStatistics()
                    
                    StatRow(label: "Configured Providers", value: "\(stats.healthyProviders)/\(stats.totalProviders)")
                    StatRow(label: "Average Health", value: "\(Int(stats.averageHealthScore * 100))%")
                    StatRow(label: "Redundancy Level", value: stats.redundancyLevel.rawValue)
                    
                    Button("Initialize All Providers") {
                        initializeAllProviders()
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Section(header: Text("Total Free Storage Available")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Up to 52GB+ of free distributed storage:")
                            .fontWeight(.medium)
                        
                        ForEach(StorageProvider.allCases, id: \.self) { provider in
                            HStack {
                                Text("• \(provider.rawValue)")
                                Spacer()
                                Text(provider.freeStorage)
                                    .fontWeight(.medium)
                                    .foregroundColor(.green)
                            }
                            .font(.caption)
                        }
                        
                        Divider()
                        
                        Text("* IPFS storage is unlimited but may require paid pinning services for persistence")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("Live Status / Test")) {
                    ForEach(redundancyManager.availableProviders, id: \.name) { provider in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(provider.name.capitalized)
                                    .fontWeight(.semibold)
                                Text(provider.isHealthy ? "✅ Ready" : "❌ Error")
                                    .font(.caption)
                                    .foregroundColor(provider.isHealthy ? .green : .red)
                            }
                            Spacer()
                            Button("Test Upload") {
                                Task {
                                    do {
                                        let testdata = "Ping-\(Date())".data(using: .utf8)!
                                        try await redundancyManager.providers[provider.name]?.storeData(testdata, with: "TestPing-\(Int(Date().timeIntervalSince1970)).txt", usingKey: "testkey")
                                    } catch {
                                        print("Test Failed for \(provider.name): \(error)")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Distributed Storage")
            .onAppear {
                Task {
                    if !redundancyManager.isInitialized {
                        do {
                            try await redundancyManager.initialize()
                        } catch {
                            print("Failed to initialize redundancy manager: \(error)")
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func destinationView(for provider: StorageProvider) -> some View {
        switch provider {
        case .firebase:
            FirebaseStorageConfigView()
        case .dropbox:
            DropboxStorageConfigView()
        case .arweave:
            ArweaveStorageConfigView()
        case .ipfs:
            IPFSStorageConfigView()
        }
    }
    
    private func initializeAllProviders() {
        Task {
            do {
                try await redundancyManager.initialize()
            } catch {
                print("Failed to initialize providers: \(error)")
            }
        }
    }
}

struct DistributedStorageConfigurationView_Previews: PreviewProvider {
    static var previews: some View {
        DistributedStorageConfigurationView()
    }
}

private struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(.blue)
        }
    }
}