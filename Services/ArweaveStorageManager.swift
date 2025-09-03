import Foundation
import Combine
import Arweave

// Data structures for tracking Arweave transactions
struct ArweaveTxMeta: Codable {
    let txid: String
    let size: Int
    let tags: [String: String]
    let timestamp: Date
}

struct ArweaveFileMeta: Codable {
    var versions: [ArweaveTxMeta]
    var latest: ArweaveTxMeta? {
        versions.last
    }
}

@MainActor
class ArweaveStorageManager: ObservableObject, CloudStorageProvider {
    
    static let shared = ArweaveStorageManager()
    private var arweave: Arweave?
    private var wallet: Wallet?

    // File for storing transaction mappings
    private let txMapFileName = "arweave_file_tx_map.json"
    private var txMapFileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent(txMapFileName)
    }
    
    // File for storing complete index
    private let indexFileName = "arweave_file_index.json"
    private var indexFileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent(indexFileName)
    }

    private init() {
        // Don't try to initialize Arweave instance here
        // We'll initialize it when needed or when we know the proper initialization method
        print("🔍 ArweaveStorageManager initialized - Arweave instance will be set up when needed")
    }
    
    func initialize() async throws {
        // Try to initialize Arweave instance if we haven't already
        if self.arweave == nil {
            // For now, we'll just log that we need proper initialization
            // In production, you would use the correct initialization method from the Arweave library
            print("⚠️ Arweave initialization skipped - using local storage fallback")
            print("💡 To enable Arweave: Add proper Arweave() initialization once library documentation is available")
        }
        
        // Try to load wallet from bundle or documents directory
        if let bundlePath = Bundle.main.path(forResource: "wallet", ofType: "json"),
           let data = try? Data(contentsOf: URL(fileURLWithPath: bundlePath)) {
            do {
                wallet = try Wallet(jwkFileData: data)
                print("Wallet loaded from bundle")
            } catch {
                print("Failed to load wallet from bundle: \(error)")
                throw ArweaveError.walletNotConfigured
            }
        } else {
            // Try documents directory
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let walletURL = docs.appendingPathComponent("wallet.json")
            
            if let data = try? Data(contentsOf: walletURL) {
                do {
                    wallet = try Wallet(jwkFileData: data)
                    print("Wallet loaded from documents directory")
                } catch {
                    print("Failed to load wallet from documents: \(error)")
                    throw ArweaveError.walletNotConfigured
                }
            } else {
                print("No wallet file found - will use local storage fallback")
                // Don't throw error, just continue with local storage
                return
            }
        }
    }

    // MARK: - Transaction Map Methods
    private func loadTxMap() -> [String: String] {
        guard let data = try? Data(contentsOf: txMapFileURL) else { return [:] }
        return (try? JSONDecoder().decode([String: String].self, from: data)) ?? [:]
    }
    
    private func saveTxMap(_ map: [String: String]) {
        if let data = try? JSONEncoder().encode(map) {
            try? data.write(to: txMapFileURL, options: [.atomic])
        }
    }
    
    private func setTxId(_ txid: String, for filename: String) {
        var map = loadTxMap()
        map[filename] = txid
        saveTxMap(map)
    }
    
    private func getTxId(for filename: String) -> String? {
        loadTxMap()[filename]
    }

    // MARK: - Index Methods
    private func loadIndex() -> [String: ArweaveFileMeta] {
        guard let data = try? Data(contentsOf: indexFileURL) else { return [:] }
        return (try? JSONDecoder().decode([String: ArweaveFileMeta].self, from: data)) ?? [:]
    }
    
    private func saveIndex(_ index: [String: ArweaveFileMeta]) {
        do {
            let data = try JSONEncoder().encode(index)
            try data.write(to: indexFileURL, options: [.atomic])
        } catch {
            print("Failed to save index: \(error)")
        }
    }
    
    private func recordTx(filename: String, txid: String, size: Int, tags: [String: String]) {
        // Update both the simple tx map and the detailed index
        setTxId(txid, for: filename)
        
        var index = loadIndex()
        let txMeta = ArweaveTxMeta(txid: txid, size: size, tags: tags, timestamp: Date())
        
        if var fileMeta = index[filename] {
            fileMeta.versions.append(txMeta)
            index[filename] = fileMeta
        } else {
            index[filename] = ArweaveFileMeta(versions: [txMeta])
        }
        
        saveIndex(index)
    }

    // MARK: - CloudStorageProvider Implementation
    func storeData(_ data: Data, with filename: String, usingKey privateKey: String) async throws {
        // Always use local storage fallback until Arweave instance is properly configured
        print("📁 Using local storage (Arweave integration pending proper initialization)")
        try await storeDataLocally(data, with: filename, usingKey: privateKey)
        
        /* 
        // This code will be enabled once Arweave initialization is properly configured
        guard let wallet = self.wallet else { 
            print("⚠️ No wallet configured, using local storage")
            try await storeDataLocally(data, with: filename, usingKey: privateKey)
            return
        }
        
        // Check if Arweave instance is available
        guard let arweave = self.arweave else {
            print("⚠️ Arweave not available, using local storage fallback")
            try await storeDataLocally(data, with: filename, usingKey: privateKey)
            return
        }
        
        guard let encrypted = EncryptionService.encrypt(data: data, usingKey: privateKey) else {
            throw ArweaveError.encryptionFailed
        }
        
        var tx = Transaction(data: encrypted)
        let contentTags = [
            "App-File-Name": filename,
            "Content-Type": "application/octet-stream"
        ]
        tx.tags = contentTags.map { Transaction.Tag(name: $0.key, value: $0.value) }
        
        let signedTx = try await tx.sign(with: wallet)
        try await signedTx.commit()
        
        recordTx(filename: filename, txid: signedTx.id, size: encrypted.count, tags: contentTags)
        print("Arweave: Uploaded \(filename) with TX id \(signedTx.id)")
        */
    }
    
    // Fallback local storage when Arweave is not available
    private func storeDataLocally(_ data: Data, with filename: String, usingKey privateKey: String) async throws {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let arweaveBackupPath = documentsPath.appendingPathComponent("arweave_backup")
        
        // Create backup directory if it doesn't exist
        try FileManager.default.createDirectory(at: arweaveBackupPath, withIntermediateDirectories: true)
        
        guard let encrypted = EncryptionService.encrypt(data: data, usingKey: privateKey) else {
            throw ArweaveError.encryptionFailed
        }
        
        let fileURL = arweaveBackupPath.appendingPathComponent(filename)
        try encrypted.write(to: fileURL)
        
        // Record as local storage
        recordTx(filename: filename, txid: "local_\(UUID().uuidString)", size: encrypted.count, tags: ["Storage-Type": "Local"])
        print("✅ Stored locally as fallback: \(filename)")
    }

    func retrieveData(with filename: String, usingKey privateKey: String) async throws -> Data {
        // Use the more comprehensive implementation with version support
        return try await retrieveData(with: filename, usingKey: privateKey, versionIndex: nil)
    }

    func retrieveData(with filename: String, usingKey privateKey: String, versionIndex: Int? = nil) async throws -> Data {
        let idx = loadIndex()
        guard let meta = idx[filename], !meta.versions.isEmpty else {
            // Try local storage fallback
            return try await retrieveDataLocally(with: filename, usingKey: privateKey)
        }
        
        // Default: latest. If versionIndex supplied and in bounds, use that version
        let txMeta: ArweaveTxMeta
        if let i = versionIndex, i >= 0, i < meta.versions.count {
            txMeta = meta.versions[i]
        } else {
            txMeta = meta.latest!
        }
        
        // Check if this is a local storage transaction
        if txMeta.txid.hasPrefix("local_") {
            return try await retrieveDataLocally(with: filename, usingKey: privateKey)
        }
        
        /*
        // This code will be enabled once Arweave is properly initialized
        let base64String = try await Transaction.data(for: txMeta.txid)
        guard let arweaveData = Data(base64Encoded: base64String) else {
            throw ArweaveError.fileNotFound
        }
        
        guard let decrypted = EncryptionService.decrypt(data: arweaveData, usingKey: privateKey) else {
            throw ArweaveError.decryptionFailed
        }
        
        return decrypted
        */
        
        // For now, fallback to local storage
        return try await retrieveDataLocally(with: filename, usingKey: privateKey)
    }
    
    private func retrieveDataLocally(with filename: String, usingKey privateKey: String) async throws -> Data {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let arweaveBackupPath = documentsPath.appendingPathComponent("arweave_backup")
        let fileURL = arweaveBackupPath.appendingPathComponent(filename)
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw ArweaveError.fileNotFound
        }
        
        let encryptedData = try Data(contentsOf: fileURL)
        
        guard let decrypted = EncryptionService.decrypt(data: encryptedData, usingKey: privateKey) else {
            throw ArweaveError.decryptionFailed
        }
        
        return decrypted
    }

    func deleteData(with filename: String) async throws {
        var idx = loadIndex()
        idx.removeValue(forKey: filename)
        saveIndex(idx)
        
        // Also remove from simple tx map
        var map = loadTxMap()
        map.removeValue(forKey: filename)
        saveTxMap(map)
        
        // Also try to delete from local storage
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let arweaveBackupPath = documentsPath.appendingPathComponent("arweave_backup")
        let fileURL = arweaveBackupPath.appendingPathComponent(filename)
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
            print("✅ Deleted local file: \(filename)")
        }
    }

    func listFiles() async throws -> [String] {
        Array(loadIndex().keys)
    }

    func fileMetadata(for filename: String) -> ArweaveFileMeta? {
        loadIndex()[filename]
    }

    func fileExists(_ filename: String) async -> Bool {
        // Check both index and local storage
        if getTxId(for: filename) != nil {
            return true
        }
        
        // Check local storage
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let arweaveBackupPath = documentsPath.appendingPathComponent("arweave_backup")
        let fileURL = arweaveBackupPath.appendingPathComponent(filename)
        
        return FileManager.default.fileExists(atPath: fileURL.path)
    }
    
    func isConfigured() async -> Bool {
        // For now, consider it configured if we can use local storage
        return true
    }
    
    // MARK: - Future Arweave Integration
    
    /// Call this method when proper Arweave initialization is available
    func enableArweaveIntegration(with arweaveInstance: Arweave) {
        self.arweave = arweaveInstance
        print("✅ Arweave integration enabled")
    }
}

enum ArweaveError: Error {
    case walletNotConfigured
    case fileNotFound
    case listNotSupported
    case deletionNotSupported
    case encryptionFailed
    case decryptionFailed
}