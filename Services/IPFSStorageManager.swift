import Foundation
import Combine

@MainActor
class IPFSStorageManager: ObservableObject, CloudStorageProvider {
    static let shared = IPFSStorageManager()
    
    private let gatewayURL = "https://ipfs.infura.io:5001" // You may provide your Infura credentials for rate limit lift.
    private let publicGateway = "https://ipfs.io/ipfs/" // For retrieving files
    
    // Storage for filename to hash mapping
    private var filenameToHash: [String: String] = [:]
    private let mappingKey = "IPFSFilenameMapping"
    
    @Published var isInitialized = false
    @Published var connectionStatus: IPFSConnectionStatus = .disconnected

    private init() {}

    func initialize() async throws {
        await MainActor.run {
            connectionStatus = .connecting
        }
        
        do {
            // Test connection to IPFS gateway
            let testURL = URL(string: "\(gatewayURL)/api/v0/version")!
            var request = URLRequest(url: testURL)
            request.httpMethod = "POST"
            request.timeoutInterval = 10.0
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                await MainActor.run {
                    connectionStatus = .error
                }
                throw IPFSError.connectionFailed
            }
            
            // Try to parse version info
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let version = json["Version"] as? String {
                print("✅ IPFS Gateway connected successfully - Version: \(version)")
            }
            
            // Load existing filename mappings
            loadFilenameMapping()
            
            await MainActor.run {
                connectionStatus = .connected
                isInitialized = true
            }
            
            print("🌐 IPFS Storage Manager initialized successfully")
            
        } catch {
            await MainActor.run {
                connectionStatus = .error
            }
            print("❌ IPFS initialization failed: \(error)")
            throw IPFSError.connectionFailed
        }
    }

    func storeData(_ data: Data, with filename: String, usingKey privateKey: String) async throws {
        guard isInitialized else {
            throw IPFSError.notInitialized
        }
        
        let url = URL(string: "\(gatewayURL)/api/v0/add")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30.0

        // Encrypt the data before storing
        guard let encryptedData = EncryptionService.encrypt(data: data, usingKey: privateKey) else {
            throw IPFSError.encryptionFailed
        }
        
        // Create multipart form data
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(encryptedData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        do {
            let (responseData, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw IPFSError.uploadFailed
            }
            
            guard let json = try JSONSerialization.jsonObject(with: responseData) as? [String: Any],
                  let hash = json["Hash"] as? String else {
                throw IPFSError.invalidResponse
            }
            
            // Store the mapping
            filenameToHash[filename] = hash
            saveFilenameMapping()
            
            print("📤 Uploaded '\(filename)' to IPFS with hash: \(hash)")
            
        } catch {
            print("❌ IPFS upload failed for '\(filename)': \(error)")
            throw IPFSError.uploadFailed
        }
    }

    func retrieveData(with filename: String, usingKey privateKey: String) async throws -> Data {
        guard isInitialized else {
            throw IPFSError.notInitialized
        }
        
        guard let hash = filenameToHash[filename] else {
            throw IPFSError.fileNotFound
        }
        
        let url = URL(string: "\(publicGateway)\(hash)")!
        var request = URLRequest(url: url)
        request.timeoutInterval = 30.0
        
        do {
            let (encryptedData, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw IPFSError.downloadFailed
            }
            
            // Decrypt the data
            guard let decryptedData = EncryptionService.decrypt(data: encryptedData, usingKey: privateKey) else {
                throw IPFSError.decryptionFailed
            }
            
            print("📥 Retrieved '\(filename)' from IPFS hash: \(hash)")
            return decryptedData
            
        } catch {
            print("❌ IPFS retrieval failed for '\(filename)': \(error)")
            throw IPFSError.downloadFailed
        }
    }

    func fileExists(_ filename: String) async -> Bool {
        return filenameToHash[filename] != nil
    }

    func deleteData(with filename: String) async throws {
        // IPFS is immutable, but we can remove from our mapping
        filenameToHash.removeValue(forKey: filename)
        saveFilenameMapping()
        print("🗑️ Removed IPFS mapping for '\(filename)' (content remains immutable on IPFS)")
    }

    func listFiles() async throws -> [String] {
        return Array(filenameToHash.keys)
    }

    func isConfigured() async -> Bool {
        return isInitialized && connectionStatus == .connected
    }
    
    // MARK: - Helper Methods
    
    private func loadFilenameMapping() {
        if let data = UserDefaults.standard.data(forKey: mappingKey),
           let mapping = try? JSONDecoder().decode([String: String].self, from: data) {
            filenameToHash = mapping
            print("📋 Loaded \(mapping.count) IPFS filename mappings")
        }
    }
    
    private func saveFilenameMapping() {
        if let data = try? JSONEncoder().encode(filenameToHash) {
            UserDefaults.standard.set(data, forKey: mappingKey)
        }
    }
    
    // MARK: - Advanced Features
    
    func pinFile(_ filename: String) async throws {
        guard let hash = filenameToHash[filename] else {
            throw IPFSError.fileNotFound
        }
        
        let url = URL(string: "\(gatewayURL)/api/v0/pin/add?arg=\(hash)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw IPFSError.pinningFailed
            }
            
            print("📌 Pinned '\(filename)' (hash: \(hash))")
        } catch {
            throw IPFSError.pinningFailed
        }
    }
    
    func unpinFile(_ filename: String) async throws {
        guard let hash = filenameToHash[filename] else {
            throw IPFSError.fileNotFound
        }
        
        let url = URL(string: "\(gatewayURL)/api/v0/pin/rm?arg=\(hash)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw IPFSError.unpinningFailed
            }
            
            print("📌❌ Unpinned '\(filename)' (hash: \(hash))")
        } catch {
            throw IPFSError.unpinningFailed
        }
    }
    
    func getFileInfo(_ filename: String) -> IPFSFileInfo? {
        guard let hash = filenameToHash[filename] else { return nil }
        
        return IPFSFileInfo(
            filename: filename,
            hash: hash,
            publicURL: "\(publicGateway)\(hash)",
            addedDate: Date() // This would need to be tracked separately for accurate timestamps
        )
    }
}

// MARK: - Supporting Types

enum IPFSConnectionStatus {
    case disconnected
    case connecting
    case connected
    case error
}

struct IPFSFileInfo {
    let filename: String
    let hash: String
    let publicURL: String
    let addedDate: Date
}

enum IPFSError: Error, LocalizedError {
    case notInitialized
    case connectionFailed
    case uploadFailed
    case downloadFailed
    case fileNotFound
    case invalidResponse
    case encryptionFailed
    case decryptionFailed
    case pinningFailed
    case unpinningFailed
    
    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "IPFS storage manager not initialized"
        case .connectionFailed:
            return "Failed to connect to IPFS gateway"
        case .uploadFailed:
            return "Failed to upload file to IPFS"
        case .downloadFailed:
            return "Failed to download file from IPFS"
        case .fileNotFound:
            return "File not found in IPFS mappings"
        case .invalidResponse:
            return "Invalid response from IPFS gateway"
        case .encryptionFailed:
            return "Failed to encrypt data before upload"
        case .decryptionFailed:
            return "Failed to decrypt data after download"
        case .pinningFailed:
            return "Failed to pin file on IPFS"
        case .unpinningFailed:
            return "Failed to unpin file on IPFS"
        }
    }
}