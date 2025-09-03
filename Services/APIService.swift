import Foundation
import Security

// A centralized service for all network requests to our backend servers
class APIService {
    static let shared = APIService()
    
    // Support for multiple backend endpoints
    private let primaryBaseURL = URL(string: "https://api.digitalcourt.ai/v1")!
    private let fallbackBaseURL = URL(string: "https://backup.digitalcourt.ai/v1")!
    
    // JWT token storage and management
    private var authToken: String? {
        get { KeychainHelper.getToken() }
        set { 
            if let token = newValue {
                KeychainHelper.saveToken(token)
            } else {
                KeychainHelper.deleteToken()
            }
        }
    }
    
    private var currentUser: User?
    private let session: URLSession
    private var retryCount = 0
    private let maxRetries = 3
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        session = URLSession(configuration: config)
    }

    // MARK: - Authentication
    
    /// Registers a new user with the server
    func register(credentials: RegistrationCredentials) async throws -> AuthResponse {
        let endpoint = primaryBaseURL.appendingPathComponent("auth/register")
        
        let response: AuthResponse = try await performRequest(
            url: endpoint, 
            method: "POST", 
            body: credentials,
            requiresAuth: false
        )
        
        // Store the token and user
        authToken = response.token
        currentUser = response.user
        
        return response
    }

    /// Logs in a user and retrieves an authentication token
    func login(credentials: LoginCredentials) async throws -> AuthResponse {
        let endpoint = primaryBaseURL.appendingPathComponent("auth/login")
        
        let response: AuthResponse = try await performRequest(
            url: endpoint, 
            method: "POST", 
            body: credentials,
            requiresAuth: false
        )
        
        // Store the token and user
        authToken = response.token
        currentUser = response.user
        
        return response
    }
    
    /// Refreshes the authentication token
    func refreshToken() async throws -> AuthResponse {
        guard let currentToken = authToken else {
            throw APIError.notAuthenticated
        }
        
        let endpoint = primaryBaseURL.appendingPathComponent("auth/refresh")
        let refreshRequest = RefreshTokenRequest(token: currentToken)
        
        let response: AuthResponse = try await performRequest(
            url: endpoint,
            method: "POST",
            body: refreshRequest,
            requiresAuth: false
        )
        
        authToken = response.token
        currentUser = response.user
        
        return response
    }
    
    /// Logs out the current user
    func logout() async throws {
        let endpoint = primaryBaseURL.appendingPathComponent("auth/logout")
        
        do {
            let _: EmptyResponse = try await performRequest(
                url: endpoint,
                method: "POST",
                body: EmptyResponse() as EmptyResponse?,
                requiresAuth: true
            )
        } catch {
            // Continue with logout even if server request fails
            print("Server logout failed, but continuing with local logout: \(error)")
        }
        
        // Clear local authentication state
        authToken = nil
        currentUser = nil
    }
    
    // MARK: - User Management
    
    func getCurrentUser() -> User? {
        return currentUser
    }
    
    func updateUser(_ user: User) async throws -> User {
        let endpoint = primaryBaseURL.appendingPathComponent("users/\(user.id)")
        
        let response: User = try await performRequest(
            url: endpoint,
            method: "PUT",
            body: user,
            requiresAuth: true
        )
        
        currentUser = response
        return response
    }
    
    func deleteUser(_ userId: UUID) async throws {
        let endpoint = primaryBaseURL.appendingPathComponent("users/\(userId)")
        
        let _: EmptyResponse = try await performRequest(
            url: endpoint,
            method: "DELETE",
            body: EmptyResponse() as EmptyResponse?,
            requiresAuth: true
        )
    }
    
    // MARK: - Memory Management
    
    func syncMemories(_ memories: [Memory]) async throws -> [Memory] {
        let endpoint = primaryBaseURL.appendingPathComponent("memories/sync")
        let syncRequest = MemorySyncRequest(memories: memories)
        
        let response: MemorySyncResponse = try await performRequest(
            url: endpoint,
            method: "POST",
            body: syncRequest,
            requiresAuth: true
        )
        
        return response.memories
    }
    
    func backupMemories(_ memories: [Memory]) async throws {
        let endpoint = primaryBaseURL.appendingPathComponent("memories/backup")
        let backupRequest = MemoryBackupRequest(memories: memories, timestamp: Date())
        
        let _: EmptyResponse = try await performRequest(
            url: endpoint,
            method: "POST",
            body: backupRequest,
            requiresAuth: true
        )
    }
    
    // MARK: - Soul Capsule Management
    
    func syncSoulCapsules(_ capsules: [SoulCapsule]) async throws -> [SoulCapsule] {
        let endpoint = primaryBaseURL.appendingPathComponent("soulcapsules/sync")
        let syncRequest = SoulCapsuleSyncRequest(capsules: capsules)
        
        let response: SoulCapsuleSyncResponse = try await performRequest(
            url: endpoint,
            method: "POST",
            body: syncRequest,
            requiresAuth: true
        )
        
        return response.capsules
    }
    
    // MARK: - Chamber Management
    
    func syncChamber(_ chamber: APIChamber) async throws -> APIChamber {
        let endpoint = primaryBaseURL.appendingPathComponent("chambers/\(chamber.id)")
        
        let response: APIChamber = try await performRequest(
            url: endpoint,
            method: "PUT",
            body: chamber,
            requiresAuth: true
        )
        
        return response
    }
    
    func getChambers() async throws -> [APIChamber] {
        let endpoint = primaryBaseURL.appendingPathComponent("chambers")
        
        let response: ChambersResponse = try await performRequest(
            url: endpoint,
            method: "GET",
            body: EmptyResponse() as EmptyResponse?,
            requiresAuth: true
        )
        
        return response.chambers
    }
    
    // MARK: - File Upload/Download
    
    func uploadFile(_ data: Data, filename: String, contentType: String) async throws -> FileUploadResponse {
        let endpoint = primaryBaseURL.appendingPathComponent("files/upload")
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Create multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(contentType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (responseData, response) = try await session.data(for: request)
        try validateResponse(response, data: responseData)
        
        return try JSONDecoder().decode(FileUploadResponse.self, from: responseData)
    }
    
    func downloadFile(_ fileId: String) async throws -> Data {
        let endpoint = primaryBaseURL.appendingPathComponent("files/\(fileId)")
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
        
        return data
    }

    // MARK: - Generic Request Handler
    
    private func performRequest<T: Decodable, U: Encodable>(
        url: URL, 
        method: String, 
        body: U? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("DigitalCourt/3.0.0", forHTTPHeaderField: "User-Agent")
        
        // Add authentication if required
        if requiresAuth {
            guard let token = authToken else {
                throw APIError.notAuthenticated
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add request body if provided
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        do {
            let (data, response) = try await session.data(for: request)
            try validateResponse(response, data: data)
            
            // Handle empty responses
            if T.self == EmptyResponse.self {
                return EmptyResponse() as! T
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
            
        } catch let error as APIError {
            // Handle token expiration
            if case .tokenExpired = error, requiresAuth {
                do {
                    _ = try await refreshToken()
                    // Retry the original request
                    return try await performRequest(url: url, method: method, body: body, requiresAuth: requiresAuth)
                } catch {
                    throw APIError.authenticationFailed("Token refresh failed")
                }
            }
            throw error
            
        } catch {
            // Handle network errors with fallback
            if retryCount < maxRetries {
                retryCount += 1
                try await Task.sleep(nanoseconds: 1_000_000_000 * UInt64(retryCount)) // Exponential backoff
                return try await performRequest(url: url, method: method, body: body, requiresAuth: requiresAuth)
            }
            
            throw APIError.networkError(error.localizedDescription)
        }
    }
    
    private func validateResponse(_ response: URLResponse?, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse("No HTTP response")
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return // Success
            
        case 401:
            throw APIError.tokenExpired
            
        case 403:
            throw APIError.accessDenied
            
        case 404:
            throw APIError.notFound
            
        case 429:
            throw APIError.rateLimited
            
        case 500...599:
            let serverError = try? JSONDecoder().decode(ServerErrorResponse.self, from: data)
            throw APIError.serverError(serverError?.message ?? "Internal server error")
            
        default:
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw APIError.httpError(httpResponse.statusCode, errorResponse?.message ?? "Unknown error")
        }
    }
}

// MARK: - Keychain Helper

private class KeychainHelper {
    private static let tokenKey = "digitalcourt.auth.token"
    
    static func saveToken(_ token: String) {
        let data = token.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary) // Delete any existing item
        SecItemAdd(query as CFDictionary, nil)
    }
    
    static func getToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return token
    }
    
    static func deleteToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKey
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - API Data Structures

struct RegistrationCredentials: Codable {
    let username: String
    let email: String
    let password: String
    let displayName: String
    let deviceId: String
}

struct LoginCredentials: Codable {
    let username: String
    let password: String
    let deviceId: String
}

struct RefreshTokenRequest: Codable {
    let token: String
}

struct AuthResponse: Codable {
    let token: String
    let user: User
    let expiresAt: Date
}

struct EmptyResponse: Codable {
    init() {}
}

struct MemorySyncRequest: Codable {
    let memories: [Memory]
    let lastSyncDate: Date
    
    init(memories: [Memory]) {
        self.memories = memories
        self.lastSyncDate = Date()
    }
}

struct MemorySyncResponse: Codable {
    let memories: [Memory]
    let conflicts: [MemoryConflict]
    let syncDate: Date
}

struct MemoryBackupRequest: Codable {
    let memories: [Memory]
    let timestamp: Date
    let checksum: String
    
    init(memories: [Memory], timestamp: Date) {
        self.memories = memories
        self.timestamp = timestamp
        self.checksum = memories.map { $0.id.uuidString }.joined().sha256()
    }
}

struct SoulCapsuleSyncRequest: Codable {
    let capsules: [SoulCapsule]
    let lastSyncDate: Date
    
    init(capsules: [SoulCapsule]) {
        self.capsules = capsules
        self.lastSyncDate = Date()
    }
}

struct SoulCapsuleSyncResponse: Codable {
    let capsules: [SoulCapsule]
    let syncDate: Date
}

struct ChambersResponse: Codable {
    let chambers: [APIChamber]
}

struct FileUploadResponse: Codable {
    let fileId: String
    let url: String
    let size: Int64
    let contentType: String
}

struct MemoryConflict: Codable {
    let memoryId: UUID
    let serverVersion: Memory
    let clientVersion: Memory
    let conflictType: ConflictType
    
    enum ConflictType: String, Codable {
        case contentChanged, metadataChanged, deleted
    }
}

struct ErrorResponse: Codable {
    let message: String
    let code: String?
    let details: [String: String]?
}

struct ServerErrorResponse: Codable {
    let message: String
    let timestamp: Date
    let requestId: String?
}

// MARK: - API-Compatible Models

/// A Codable version of Chamber for API communication
struct APIChamber: Codable, Identifiable {
    let id: UUID
    let name: String
    let councilIds: [UUID] // Just store brain IDs instead of full DBrain objects
    let messages: [APIMessage]
    let createdAt: Date
    let updatedAt: Date
    
    init(from chamber: Chamber) {
        self.id = chamber.id
        self.name = chamber.name
        self.councilIds = chamber.council.map { $0.id }
        self.messages = chamber.messages.map { APIMessage(from: $0) }
        self.createdAt = Date() // Default values for API
        self.updatedAt = Date()
    }
}

/// A Codable version of Message for API communication
struct APIMessage: Codable, Identifiable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    let personaName: String?
    
    init(from message: Message) {
        self.id = message.id
        self.content = message.content
        self.isUser = message.isUser
        self.timestamp = message.timestamp
        self.personaName = message.personaName
    }
}

// MARK: - API Errors

enum APIError: Error, LocalizedError {
    case notAuthenticated
    case tokenExpired
    case accessDenied
    case notFound
    case rateLimited
    case authenticationFailed(String)
    case networkError(String)
    case serverError(String)
    case invalidResponse(String)
    case httpError(Int, String)
    case encodingError(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Authentication required"
        case .tokenExpired:
            return "Authentication token has expired"
        case .accessDenied:
            return "Access denied"
        case .notFound:
            return "Resource not found"
        case .rateLimited:
            return "Too many requests - please try again later"
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .invalidResponse(let message):
            return "Invalid response: \(message)"
        case .httpError(let code, let message):
            return "HTTP \(code): \(message)"
        case .encodingError(let message):
            return "Encoding error: \(message)"
        }
    }
}

// MARK: - String Extension for SHA256

import CryptoKit

extension String {
    func sha256() -> String {
        let data = Data(self.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
