import Foundation
import SwiftUI
import Combine

/// Dedicated Dropbox service for DigitalCourt memory storage using direct API calls
@MainActor
class DropboxService: ObservableObject, CloudStorageProvider {
    static let shared = DropboxService()
    
    @Published private(set) var isInitialized = false
    @Published private(set) var isAuthenticated = false
    @Published private(set) var currentUser: DropboxUser?
    @Published private(set) var connectionStatus: DropboxConnectionStatus = .disconnected
    
    private var accessToken: String?
    private var appKey: String?
    private var appSecret: String?
    private let folderPath = "/DigitalCourt_Memories"
    
    enum DropboxConnectionStatus {
        case disconnected
        case connecting
        case connected
        case error(String)
    }
    
    private init() {
        loadDropboxConfiguration()
    }
    
    // MARK: - CloudStorageProvider Implementation
    
    func initialize() async throws {
        guard let token = accessToken else {
            throw DropboxServiceError.notInitialized
        }
        
        connectionStatus = .connecting
        
        do {
            // Test the connection by getting user info
            let user = try await getCurrentUserInfo(token: token)
            
            await MainActor.run {
                self.currentUser = user
                self.connectionStatus = .connected
                self.isInitialized = true
                print("✅ Dropbox connection successful for user: \(user.name)")
            }
            
            // Create app folder if needed
            try await createAppFolderIfNeeded()
            
        } catch {
            await MainActor.run {
                self.connectionStatus = .error("Connection failed: \(error.localizedDescription)")
                print("❌ Dropbox connection failed: \(error)")
            }
            throw DropboxServiceError.configurationFailed
        }
    }
    
    func storeData(_ data: Data, with filename: String, usingKey privateKey: String) async throws {
        guard let encryptedData = EncryptionService.encrypt(data: data, usingKey: privateKey) else {
            throw DropboxServiceError.encryptionFailed
        }
        
        try await uploadFile(data: encryptedData, filename: filename)
    }
    
    func retrieveData(with filename: String, usingKey privateKey: String) async throws -> Data {
        let encryptedData = try await downloadFile(filename: filename)
        
        guard let decryptedData = EncryptionService.decrypt(data: encryptedData, usingKey: privateKey) else {
            throw DropboxServiceError.decryptionFailed
        }
        
        return decryptedData
    }
    
    func deleteData(with filename: String) async throws {
        try await deleteFile(filename: filename)
    }
    
    func fileExists(_ filename: String) async -> Bool {
        do {
            _ = try await getFileMetadata(path: "\(folderPath)/\(filename)", token: accessToken ?? "")
            return true
        } catch {
            return false
        }
    }
    
    func listFiles() async throws -> [String] {
        let dropboxFiles = try await listDropboxFiles()
        return dropboxFiles.map { $0.name }
    }
    
    func isConfigured() async -> Bool {
        return accessToken != nil && isAuthenticated
    }
    
    // MARK: - Public Methods for UI
    
    /// Returns detailed file information as DropboxFile objects
    func listDropboxFiles() async throws -> [DropboxFile] {
        guard let token = accessToken, isAuthenticated else {
            throw DropboxServiceError.notInitialized
        }
        
        let url = URL(string: "https://api.dropboxapi.com/2/files/list_folder")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body = ["path": folderPath]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw DropboxServiceError.folderNotFound
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let entries = json["entries"] as? [[String: Any]] else {
            return []
        }
        
        return entries.compactMap { entry in
            guard entry[".tag"] as? String == "file",
                  let name = entry["name"] as? String,
                  let size = entry["size"] as? UInt64 else {
                return nil
            }
            
            let modifiedTime = parseDropboxDate(entry["server_modified"] as? String) ?? Date()
            
            return DropboxFile(
                id: entry["id"] as? String ?? UUID().uuidString,
                name: name,
                size: size,
                modifiedTime: modifiedTime
            )
        }
    }
    
    // MARK: - Configuration Loading
    
    private func loadDropboxConfiguration() {
        guard let path = Bundle.main.path(forResource: "DropboxConfig", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path) else {
            print("❌ DropboxConfig.plist not found")
            connectionStatus = .error("Configuration file not found")
            return
        }
        
        self.appKey = config["DropboxAppKey"] as? String
        self.appSecret = config["DropboxAppSecret"] as? String
        
        // Load the pre-configured access token
        if let token = config["DropboxAccessToken"] as? String, !token.isEmpty {
            self.accessToken = token
            self.isAuthenticated = true
            
            print("✅ Dropbox credentials loaded successfully")
            
            // Test connection and load user info
            Task {
                do {
                    try await initialize()
                } catch {
                    print("❌ Failed to initialize Dropbox service: \(error)")
                }
            }
        } else {
            print("❌ No Dropbox access token found")
            connectionStatus = .error("Access token not configured")
        }
    }
    
    // MARK: - Connection Testing
    
    func testConnection() async {
        do {
            try await initialize()
        } catch {
            await MainActor.run {
                self.connectionStatus = .error("Connection test failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - API Operations
    
    private func getCurrentUserInfo(token: String) async throws -> DropboxUser {
        let url = URL(string: "https://api.dropboxapi.com/2/users/get_current_account")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw DropboxServiceError.authenticationFailed
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw DropboxServiceError.invalidResponse
        }
        
        let name = (json["name"] as? [String: Any])?["display_name"] as? String ?? "Unknown"
        let email = json["email"] as? String ?? ""
        let accountId = json["account_id"] as? String ?? ""
        
        return DropboxUser(name: name, email: email, accountId: accountId)
    }
    
    private func createAppFolderIfNeeded() async throws {
        guard let token = accessToken else {
            throw DropboxServiceError.notInitialized
        }
        
        // Check if folder exists first
        do {
            _ = try await getFileMetadata(path: folderPath, token: token)
            print("📁 App folder already exists in Dropbox")
            return
        } catch {
            // Folder doesn't exist, create it
        }
        
        let url = URL(string: "https://api.dropboxapi.com/2/files/create_folder_v2")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body = ["path": folderPath]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode == 200 {
            print("📁 Created app folder in Dropbox: \(folderPath)")
        } else {
            throw DropboxServiceError.configurationFailed
        }
    }
    
    // MARK: - File Operations
    
    private func uploadFile(data: Data, filename: String) async throws {
        guard let token = accessToken, isAuthenticated else {
            throw DropboxServiceError.notInitialized
        }
        
        let filePath = "\(folderPath)/\(filename)"
        
        let url = URL(string: "https://content.dropboxapi.com/2/files/upload")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let apiArg: [String: Any] = ["path": filePath, "mode": "overwrite", "autorename": true]
        let apiArgData = try JSONSerialization.data(withJSONObject: apiArg)
        let apiArgString = String(data: apiArgData, encoding: .utf8)!
        request.setValue(apiArgString, forHTTPHeaderField: "Dropbox-API-Arg")
        
        request.httpBody = data
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw DropboxServiceError.uploadFailed
        }
        
        print("✅ Successfully uploaded '\(filename)' to Dropbox")
    }
    
    private func downloadFile(filename: String) async throws -> Data {
        guard let token = accessToken, isAuthenticated else {
            throw DropboxServiceError.notInitialized
        }
        
        let filePath = "\(folderPath)/\(filename)"
        
        let url = URL(string: "https://content.dropboxapi.com/2/files/download")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let apiArg = ["path": filePath]
        let apiArgData = try JSONSerialization.data(withJSONObject: apiArg)
        let apiArgString = String(data: apiArgData, encoding: .utf8)!
        request.setValue(apiArgString, forHTTPHeaderField: "Dropbox-API-Arg")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw DropboxServiceError.downloadFailed
        }
        
        print("✅ Successfully downloaded '\(filename)' from Dropbox")
        return data
    }
    
    private func deleteFile(filename: String) async throws {
        guard let token = accessToken, isAuthenticated else {
            throw DropboxServiceError.notInitialized
        }
        
        let filePath = "\(folderPath)/\(filename)"
        
        let url = URL(string: "https://api.dropboxapi.com/2/files/delete_v2")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body = ["path": filePath]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw DropboxServiceError.downloadFailed
        }
        
        print("✅ Successfully deleted '\(filename)' from Dropbox")
    }
    
    private func getFileMetadata(path: String, token: String) async throws -> DropboxFileMetadata {
        let url = URL(string: "https://api.dropboxapi.com/2/files/get_metadata")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body = ["path": path]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw DropboxServiceError.fileNotFound
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw DropboxServiceError.invalidResponse
        }
        
        return DropboxFileMetadata(
            name: json["name"] as? String ?? "",
            size: json["size"] as? UInt64 ?? 0,
            serverModified: parseDropboxDate(json["server_modified"] as? String)
        )
    }
    
    // MARK: - Utility Methods
    
    private func parseDropboxDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter.date(from: dateString)
    }
    
    // MARK: - Integration with DigitalCourt Memory System
    
    func storeMemoryData(_ data: Data, memoryId: String, encryptionKey: String) async throws {
        let filename = "memory_\(memoryId).encrypted"
        try await storeData(data, with: filename, usingKey: encryptionKey)
    }
    
    func retrieveMemoryData(memoryId: String, encryptionKey: String) async throws -> Data {
        let filename = "memory_\(memoryId).encrypted"
        return try await retrieveData(with: filename, usingKey: encryptionKey)
    }
}

// MARK: - Supporting Types

struct DropboxUser {
    let name: String
    let email: String
    let accountId: String
}

struct DropboxFile: Identifiable {
    let id: String
    let name: String
    let size: UInt64
    let modifiedTime: Date
}

struct DropboxFileMetadata {
    let name: String
    let size: UInt64
    let serverModified: Date?
}

enum DropboxServiceError: Error, LocalizedError {
    case notInitialized
    case configurationFailed
    case authenticationFailed
    case uploadFailed
    case downloadFailed
    case fileNotFound
    case folderNotFound
    case encryptionFailed
    case decryptionFailed
    case networkError
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Dropbox service not initialized"
        case .configurationFailed:
            return "Dropbox configuration failed"
        case .authenticationFailed:
            return "Dropbox authentication failed"
        case .uploadFailed:
            return "Failed to upload file to Dropbox"
        case .downloadFailed:
            return "Failed to download file from Dropbox"
        case .fileNotFound:
            return "File not found in Dropbox"
        case .folderNotFound:
            return "Folder not found in Dropbox"
        case .encryptionFailed:
            return "Failed to encrypt data"
        case .decryptionFailed:
            return "Failed to decrypt data"
        case .networkError:
            return "Network error occurred"
        case .invalidResponse:
            return "Invalid response from Dropbox API"
        }
    }
}