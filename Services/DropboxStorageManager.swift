import Foundation
import SwiftyDropbox
import Combine

@MainActor
class DropboxStorageManager: ObservableObject, CloudStorageProvider {
    static let shared = DropboxStorageManager()
    private var client: DropboxClient?
    private var isReady: Bool = false
    private let rootFolder = "/DigitalCourtUserData"

    private init() {
        // Setup Dropbox with app key if available
        if let appKey = loadDropboxAppKey() {
            DropboxClientsManager.setupWithAppKey(appKey)
        }
        
        // Try to get authorized client
        self.client = DropboxClientsManager.authorizedClient
        
        // If no authorized client, try to setup with access token manually
        if client == nil, let token = loadDropboxAccessToken() {
            // Manually create client with access token
            self.client = DropboxClient(accessToken: token)
            // Also set it as the authorized client for the manager
            DropboxClientsManager.authorizedClient = self.client
        }
    }
    
    private func loadDropboxAppKey() -> String? {
        if let path = Bundle.main.path(forResource: "DropboxConfig", ofType: "plist"),
           let config = NSDictionary(contentsOfFile: path),
           let appKey = config["DropboxAppKey"] as? String, !appKey.isEmpty {
            return appKey
        }
        return nil
    }
    
    private func loadDropboxAccessToken() -> String? {
        // Try to load from DropboxConfig.plist first
        if let path = Bundle.main.path(forResource: "DropboxConfig", ofType: "plist"),
           let config = NSDictionary(contentsOfFile: path),
           let token = config["DropboxAccessToken"] as? String, !token.isEmpty {
            return token
        }
        
        // Fallback to environment or keychain in production
        return nil
    }

    func initialize() async throws {
        // Check auth by listing folder
        guard let client = client else { 
            throw DropboxStorageError.notInitialized 
        }
        
        do {
            let _: Void = try await withCheckedThrowingContinuation { cont in
                client.files.listFolder(path: rootFolder).response { result, error in
                    if let _ = result { 
                        cont.resume(returning: ()) 
                    } else { 
                        cont.resume(throwing: DropboxStorageError.notInitialized) 
                    }
                }
            }
        } catch {
            // Try to create folder if not exists
            let _: Void = try await withCheckedThrowingContinuation { cont in
                client.files.createFolderV2(path: rootFolder).response { result, error in
                    if let _ = error {
                        cont.resume(throwing: DropboxStorageError.folderCreationFailed)
                    } else {
                        cont.resume(returning: ())
                    }
                }
            }
        }
        isReady = true
    }

    func storeData(_ data: Data, with filename: String, usingKey privateKey: String) async throws {
        guard let client = client else { 
            throw DropboxStorageError.notInitialized 
        }
        
        guard let encrypted = EncryptionService.encrypt(data: data, usingKey: privateKey) else {
            throw DropboxStorageError.encryptionFailed
        }
        
        let path = "\(rootFolder)/\(filename)"
        
        let _: Void = try await withCheckedThrowingContinuation { cont in
            client.files.upload(path: path, input: encrypted).response { result, error in
                if let error = error {
                    cont.resume(throwing: error)
                } else {
                    cont.resume(returning: ())
                }
            }
        }
    }

    func retrieveData(with filename: String, usingKey privateKey: String) async throws -> Data {
        guard let client = client else { 
            throw DropboxStorageError.notInitialized 
        }
        
        let path = "\(rootFolder)/\(filename)"
        
        let fileData: Data = try await withCheckedThrowingContinuation { cont in
            client.files.download(path: path).response { result, error in
                if let (_, data) = result {
                    cont.resume(returning: data)
                } else {
                    cont.resume(throwing: DropboxStorageError.downloadFailed)
                }
            }
        }
        
        guard let decrypted = EncryptionService.decrypt(data: fileData, usingKey: privateKey) else {
            throw DropboxStorageError.decryptionFailed
        }
        
        return decrypted
    }

    func fileExists(_ filename: String) async -> Bool {
        guard let client = client else { return false }
        let path = "\(rootFolder)/\(filename)"
        
        do {
            let _: Bool = try await withCheckedThrowingContinuation { cont in
                client.files.getMetadata(path: path).response { result, error in
                    if let _ = result {
                        cont.resume(returning: true)
                    } else {
                        cont.resume(returning: false)
                    }
                }
            }
            return true
        } catch {
            return false
        }
    }

    func deleteData(with filename: String) async throws {
        guard let client = client else { 
            throw DropboxStorageError.notInitialized 
        }
        
        let path = "\(rootFolder)/\(filename)"
        
        let _: Void = try await withCheckedThrowingContinuation { cont in
            client.files.deleteV2(path: path).response { result, error in
                if let error = error {
                    cont.resume(throwing: error)
                } else {
                    cont.resume(returning: ())
                }
            }
        }
    }

    func listFiles() async throws -> [String] {
        guard let client = client else { 
            throw DropboxStorageError.notInitialized 
        }
        
        let fileNames: [String] = try await withCheckedThrowingContinuation { cont in
            client.files.listFolder(path: rootFolder).response { result, error in
                if let result = result {
                    let names = result.entries.compactMap { entry in
                        // Only return files, not folders
                        if entry is Files.FileMetadata {
                            return entry.name
                        }
                        return nil
                    }
                    cont.resume(returning: names)
                } else {
                    cont.resume(throwing: DropboxStorageError.listingFailed)
                }
            }
        }
        
        return fileNames
    }

    func isConfigured() async -> Bool {
        return client != nil
    }
    
    // MARK: - Additional Helper Methods
    
    func getStorageInfo() async throws -> DropboxStorageInfo {
        guard let client = client else {
            throw DropboxStorageError.notInitialized
        }
        
        let spaceUsage: DropboxStorageInfo = try await withCheckedThrowingContinuation { cont in
            client.users.getSpaceUsage().response { result, error in
                if let result = result {
                    let used = result.used
                    var allocated: UInt64 = 0
                    
                    // Handle different allocation types - make switch exhaustive
                    switch result.allocation {
                    case .individual(let individual):
                        allocated = individual.allocated
                    case .team(let team):
                        allocated = team.allocated
                    case .other:
                        // Handle unknown allocation type
                        allocated = 0
                        print("⚠️ Unknown allocation type: .other")
                    @unknown default:
                        // Handle future cases that might be added to the SDK
                        allocated = 0
                        print("⚠️ Unknown allocation type encountered")
                    }
                    
                    let info = DropboxStorageInfo(
                        used: used,
                        allocated: allocated,
                        available: allocated > used ? allocated - used : 0
                    )
                    cont.resume(returning: info)
                } else {
                    cont.resume(throwing: DropboxStorageError.storageInfoFailed)
                }
            }
        }
        
        return spaceUsage
    }
    
    func createBackup(data: Data, filename: String) async throws {
        let backupFilename = "backup_\(filename)"
        try await storeData(data, with: backupFilename, usingKey: generateBackupKey())
    }
    
    private func generateBackupKey() -> String {
        return EncryptionService.generateEncryptionKey()
    }
    
    // MARK: - Authentication Helpers
    
    func setupOAuth() {
        guard let appKey = loadDropboxAppKey() else {
            print("❌ No Dropbox app key found in configuration")
            return
        }
        
        DropboxClientsManager.setupWithAppKey(appKey)
    }
    
    func isAuthenticated() -> Bool {
        return DropboxClientsManager.authorizedClient != nil
    }
    
    func clearAuthentication() {
        DropboxClientsManager.unlinkClients()
        self.client = nil
    }
}

// MARK: - Supporting Types

struct DropboxStorageInfo {
    let used: UInt64
    let allocated: UInt64
    let available: UInt64
    
    var usedPercentage: Double {
        guard allocated > 0 else { return 0.0 }
        return Double(used) / Double(allocated) * 100.0
    }
    
    var formattedUsed: String {
        return ByteCountFormatter.string(fromByteCount: Int64(used), countStyle: .file)
    }
    
    var formattedAllocated: String {
        return ByteCountFormatter.string(fromByteCount: Int64(allocated), countStyle: .file)
    }
    
    var formattedAvailable: String {
        return ByteCountFormatter.string(fromByteCount: Int64(available), countStyle: .file)
    }
}

// Renamed to avoid conflict with DropboxService's DropboxServiceError
enum DropboxStorageError: Error, LocalizedError {
    case notInitialized
    case downloadFailed
    case uploadFailed
    case encryptionFailed
    case decryptionFailed
    case folderCreationFailed
    case listingFailed
    case storageInfoFailed
    case configurationMissing
    case authenticationRequired
    
    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Dropbox storage manager not initialized"
        case .downloadFailed:
            return "Failed to download file from Dropbox"
        case .uploadFailed:
            return "Failed to upload file to Dropbox"
        case .encryptionFailed:
            return "Failed to encrypt data before upload"
        case .decryptionFailed:
            return "Failed to decrypt data after download"
        case .folderCreationFailed:
            return "Failed to create Dropbox folder"
        case .listingFailed:
            return "Failed to list files in Dropbox"
        case .storageInfoFailed:
            return "Failed to retrieve Dropbox storage information"
        case .configurationMissing:
            return "Dropbox configuration not found"
        case .authenticationRequired:
            return "Dropbox authentication required"
        }
    }
}

// MARK: - SwiftyDropbox Extensions for Better Type Safety

extension Files.FileMetadata {
    var sizeFormatted: String {
        return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }
}

extension Files.FolderMetadata {
    var isShared: Bool {
        return sharingInfo != nil
    }
}