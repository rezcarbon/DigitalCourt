import Foundation
import Combine
import SwiftUI

/// Storage Redundancy Manager
/// Manages multiple cloud storage providers with automatic failover and redundancy
@MainActor
class StorageRedundancyManager: ObservableObject {
    static let shared = StorageRedundancyManager()

    @Published private(set) var isInitialized = false
    @Published var availableProviders: [StorageProviderStatus] = []
    @Published var primaryProviderKey: String = "firebase"
    @Published var redundancyEnabled: Bool = false
    @Published private(set) var redundancyLevel: RedundancyLevel = .dual

    var providers: [String: CloudStorageProvider] = [:]
    private var healthCheckTimer: Timer?

    private init() {
        providers["firebase"] = FirebaseStorageManager.shared
        providers["dropbox"] = DropboxStorageManager.shared
        providers["arweave"] = ArweaveStorageManager.shared
        providers["ipfs"] = IPFSStorageManager.shared
        availableProviders = [
            StorageProviderStatus(name: "firebase", isHealthy: true, healthScore: 1.0, lastChecked: Date(), consecutiveFailures: 0),
            StorageProviderStatus(name: "dropbox", isHealthy: true, healthScore: 1.0, lastChecked: Date(), consecutiveFailures: 0),
            StorageProviderStatus(name: "arweave", isHealthy: true, healthScore: 1.0, lastChecked: Date(), consecutiveFailures: 0),
            StorageProviderStatus(name: "ipfs", isHealthy: true, healthScore: 1.0, lastChecked: Date(), consecutiveFailures: 0)
        ]
    }
    
    deinit {
        healthCheckTimer?.invalidate()
    }

    func initialize() async throws {
        var errors: [Error] = []
        
        for (key, provider) in providers {
            do {
                try await provider.initialize()
                updateProviderStatus(key, isHealthy: true, resetFailures: true)
                print("✅ Initialized storage provider: \(key)")
            } catch {
                errors.append(error)
                updateProviderStatus(key, isHealthy: false, incrementFailures: true)
                print("❌ Failed to initialize storage provider \(key): \(error)")
            }
        }
        
        // Start periodic health checks
        startPeriodicHealthChecks()
        
        isInitialized = true
        
        // If all providers failed, throw an error
        if errors.count == providers.count {
            throw RedundancyError.allProvidersFailed
        }
    }

    func performHealthCheck() async {
        print("🔍 Starting storage provider health check...")
        
        for (key, provider) in providers {
            let isConfigured = await provider.isConfigured()
            await MainActor.run {
                updateProviderStatus(key, isHealthy: isConfigured, resetFailures: isConfigured)
            }
            
            if isConfigured {
                print("✅ Health check passed for \(key)")
            } else {
                print("⚠️ Health check failed for \(key)")
            }
        }
        
        print("📊 Health check completed. Healthy providers: \(getHealthyProviderCount())/\(providers.count)")
    }
    
    func getProviderStatistics() -> StorageStatistics {
        let totalProviders = availableProviders.count
        let healthyProviders = availableProviders.filter { $0.isHealthy }.count
        let averageHealthScore = availableProviders.map { $0.healthScore }.reduce(0.0, +) / Double(max(1, totalProviders))
        
        return StorageStatistics(
            totalProviders: totalProviders,
            healthyProviders: healthyProviders,
            averageHealthScore: averageHealthScore,
            redundancyLevel: redundancyLevel
        )
    }
    
    func setRedundancyLevel(_ level: RedundancyLevel) {
        redundancyLevel = level
        redundancyEnabled = level != .single
        
        print("🔧 Redundancy level set to: \(level.rawValue) (\(level.requiredProviders) providers)")
    }
    
    private func startPeriodicHealthChecks() {
        healthCheckTimer?.invalidate()
        healthCheckTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in // Every 5 minutes
            Task { @MainActor in
                await self.performHealthCheck()
            }
        }
    }
    
    private func updateProviderStatus(_ providerKey: String, isHealthy: Bool, resetFailures: Bool = false, incrementFailures: Bool = false) {
        if let index = availableProviders.firstIndex(where: { $0.name == providerKey }) {
            var status = availableProviders[index]
            status.isHealthy = isHealthy
            status.lastChecked = Date()
            status.healthScore = isHealthy ? min(1.0, status.healthScore + 0.1) : max(0.0, status.healthScore - 0.2)
            
            if resetFailures {
                status.consecutiveFailures = 0
            } else if incrementFailures {
                status.consecutiveFailures += 1
            }
            
            availableProviders[index] = status
        }
    }
    
    private func getHealthyProviderCount() -> Int {
        return availableProviders.filter { $0.isHealthy }.count
    }

    func storeWithRedundancy(_ data: Data, filename: String, usingKey privateKey: String) async throws {
        guard isInitialized else {
            throw RedundancyError.notInitialized
        }
        
        let requiredProviders = redundancyLevel.requiredProviders
        let healthyProviders = getHealthyProviders()
        
        guard healthyProviders.count >= redundancyLevel.minimumRequired else {
            throw RedundancyError.insufficientProviders(
                required: redundancyLevel.minimumRequired,
                available: healthyProviders.count
            )
        }
        
        var successCount = 0
        var errors: [Error] = []
        
        // Try to store on required number of providers
        let providersToUse = Array(healthyProviders.prefix(requiredProviders))
        
        for providerKey in providersToUse {
            do {
                try await providers[providerKey]?.storeData(data, with: filename, usingKey: privateKey)
                successCount += 1
                updateProviderStatus(providerKey, isHealthy: true, resetFailures: true)
            } catch {
                errors.append(error)
                updateProviderStatus(providerKey, isHealthy: false, incrementFailures: true)
            }
        }
        
        guard successCount >= redundancyLevel.minimumRequired else {
            throw RedundancyError.redundancyNotMet(achieved: successCount, required: redundancyLevel.minimumRequired)
        }
        
        print("✅ Successfully stored '\(filename)' on \(successCount)/\(requiredProviders) providers")
    }

    func retrieveWithFailover(_ filename: String, usingKey privateKey: String) async throws -> Data {
        guard isInitialized else {
            throw RedundancyError.notInitialized
        }
        
        let healthyProviders = getHealthyProviders()
        guard !healthyProviders.isEmpty else {
            throw RedundancyError.allProvidersFailed
        }
        
        // Try providers in order of health score
        let sortedProviders = healthyProviders.sorted { provider1, provider2 in
            let status1 = availableProviders.first { $0.name == provider1 }
            let status2 = availableProviders.first { $0.name == provider2 }
            return (status1?.healthScore ?? 0.0) > (status2?.healthScore ?? 0.0)
        }
        
        for providerKey in sortedProviders {
            do {
                let data = try await providers[providerKey]?.retrieveData(with: filename, usingKey: privateKey)
                updateProviderStatus(providerKey, isHealthy: true, resetFailures: true)
                print("✅ Successfully retrieved '\(filename)' from \(providerKey)")
                return data ?? Data()
            } catch {
                updateProviderStatus(providerKey, isHealthy: false, incrementFailures: true)
                print("⚠️ Failed to retrieve from \(providerKey): \(error)")
                continue
            }
        }
        
        throw RedundancyError.allProvidersFailed
    }

    func fileExists(_ filename: String) async -> Bool {
        let healthyProviders = getHealthyProviders()
        
        for providerKey in healthyProviders {
            if let exists = await providers[providerKey]?.fileExists(filename), exists {
                return true
            }
        }
        
        return false
    }
    
    private func getHealthyProviders() -> [String] {
        return availableProviders.filter { $0.isHealthy }.map { $0.name }
    }

    func setPrimaryProvider(_ key: String) {
        guard providers[key] != nil else { return }
        primaryProviderKey = key
        print("🔧 Primary storage provider set to: \(key)")
    }
    
    func setRedundancy(_ enabled: Bool) {
        redundancyEnabled = enabled
        if enabled && redundancyLevel == .single {
            redundancyLevel = .dual
        } else if !enabled {
            redundancyLevel = .single
        }
        print("🔧 Redundancy \(enabled ? "enabled" : "disabled")")
    }
}

// MARK: - Supporting Models

struct StorageProviderStatus {
    let name: String
    var isHealthy: Bool
    var healthScore: Double // 0.0 to 1.0
    var lastChecked: Date
    var consecutiveFailures: Int
}

struct StorageMapping: Codable {
    let filename: String
    let providers: [String]
    let timestamp: Date
    let redundancyLevel: RedundancyLevel
}

struct StorageStatistics {
    let totalProviders: Int
    let healthyProviders: Int
    let averageHealthScore: Double
    let redundancyLevel: RedundancyLevel
}

enum RedundancyLevel: String, CaseIterable, Codable {
    case single = "Single"
    case dual = "Dual"
    case triple = "Triple"
    case maximum = "Maximum"
    
    var requiredProviders: Int {
        switch self {
        case .single: return 1
        case .dual: return 2
        case .triple: return 3
        case .maximum: return 4
        }
    }
    
    var minimumRequired: Int {
        switch self {
        case .single: return 1
        case .dual: return 1 // At least one must succeed
        case .triple: return 2 // At least two must succeed
        case .maximum: return 2 // At least two must succeed
        }
    }
}

// MARK: - Redundancy Errors

enum RedundancyError: Error, LocalizedError {
    case notInitialized
    case insufficientProviders(required: Int, available: Int)
    case redundancyNotMet(achieved: Int, required: Int)
    case allProvidersFailed
    case mappingNotFound
    
    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Storage redundancy manager not initialized"
        case .insufficientProviders(let required, let available):
            return "Insufficient healthy providers: need \(required), have \(available)"
        case .redundancyNotMet(let achieved, let required):
            return "Redundancy not met: achieved \(achieved), required \(required)"
        case .allProvidersFailed:
            return "All storage providers failed"
        case .mappingNotFound:
            return "Storage mapping not found for file"
        }
    }
}

// Timeout error for health checks
struct TimeoutError: Error {}

// MARK: - Storage Redundancy Configuration View

struct StorageRedundancyView: View {
    @StateObject private var redundancyManager = StorageRedundancyManager.shared
    @State private var selectedRedundancy: RedundancyLevel = .dual
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        Form {
            Section(header: Text("Redundancy Configuration")) {
                Picker("Redundancy Level", selection: $selectedRedundancy) {
                    ForEach(RedundancyLevel.allCases, id: \.self) { level in
                        Text("\(level.rawValue) (\(level.requiredProviders) providers)")
                            .tag(level)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Button("Apply Settings") {
                    applySettings()
                }
                .buttonStyle(.borderedProminent)
            }
            
            Section(header: Text("Provider Status")) {
                ForEach(redundancyManager.availableProviders, id: \.name) { provider in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(provider.name.capitalized)
                                .fontWeight(.medium)
                            
                            Text("Health: \(Int(provider.healthScore * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text(provider.isHealthy ? "✅ Healthy" : "❌ Unhealthy")
                                .font(.caption)
                                .foregroundColor(provider.isHealthy ? .green : .red)
                            
                            Text("Failures: \(provider.consecutiveFailures)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            
            Section(header: Text("Statistics")) {
                let stats = redundancyManager.getProviderStatistics()
                
                RedundancyStatRow(label: "Total Providers", value: "\(stats.totalProviders)")
                RedundancyStatRow(label: "Healthy Providers", value: "\(stats.healthyProviders)")
                RedundancyStatRow(label: "Average Health", value: "\(Int(stats.averageHealthScore * 100))%")
                RedundancyStatRow(label: "Current Redundancy", value: stats.redundancyLevel.rawValue)
            }
            
            Section(header: Text("Actions")) {
                Button("Run Health Check") {
                    runHealthCheck()
                }
                .buttonStyle(.bordered)
                
                Button("Initialize All Providers") {
                    initializeProviders()
                }
                .buttonStyle(.bordered)
            }
        }
        .navigationTitle("Storage Redundancy")
        .onAppear {
            selectedRedundancy = redundancyManager.redundancyLevel
        }
        .alert("Storage Redundancy", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func applySettings() {
        redundancyManager.setRedundancyLevel(selectedRedundancy)
        alertMessage = "Redundancy level set to \(selectedRedundancy.rawValue)"
        showingAlert = true
    }
    
    private func runHealthCheck() {
        Task {
            await redundancyManager.performHealthCheck()
            await MainActor.run {
                alertMessage = "Health check completed. Check provider status above."
                showingAlert = true
            }
        }
    }
    
    private func initializeProviders() {
        Task {
            do {
                try await redundancyManager.initialize()
                await MainActor.run {
                    alertMessage = "All available providers initialized successfully!"
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Provider initialization failed: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
}

struct RedundancyStatRow: View {
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