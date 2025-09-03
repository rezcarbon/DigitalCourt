import Foundation
import FirebaseStorage
import FirebaseCore
import Combine

@MainActor
class FirebaseStorageManager: ObservableObject, CloudStorageProvider {
    static let shared = FirebaseStorageManager()
    
    private var storage: Storage?
    private var rootReference: StorageReference?
    private let folderName = "DigitalCourtUserData"
    private var _isInitialized = false

    private init() {}

    // Initializes the Firebase Storage service.
    func initialize() async throws {
        // FirebaseApp.configure() is called in DCourtApp.swift
        self.storage = Storage.storage()
        guard let storage = self.storage else {
            throw StorageError.notInitialized
        }
        self.rootReference = storage.reference().child(folderName)
        self._isInitialized = true
        print("Firebase Storage Manager initialized successfully.")
    }

    // Encrypts and uploads data to Firebase Storage.
    func storeData(_ data: Data, with filename: String, usingKey privateKey: String) async throws {
        guard let rootRef = rootReference else {
            throw StorageError.notInitialized
        }

        // Encrypt the data before uploading
        guard let encryptedData = EncryptionService.encrypt(data: data, usingKey: privateKey) else {
            throw StorageError.uploadFailed("Encryption failed.")
        }
        
        let fileRef = rootRef.child(filename)

        print("Uploading encrypted data to Firebase Storage as '\(filename)'...")
        _ = try await fileRef.putDataAsync(encryptedData)
        print("Successfully uploaded '\(filename)' to Firebase Storage.")
    }

    // Downloads and decrypts data from Firebase Storage.
    func retrieveData(with filename: String, usingKey privateKey: String) async throws -> Data {
        guard let rootRef = rootReference else {
            throw StorageError.notInitialized
        }
        
        let fileRef = rootRef.child(filename)
        
        print("Downloading '\(filename)' from Firebase Storage...")
        // Download size limit: 10MB. Can be increased if needed.
        let downloadedData = try await fileRef.data(maxSize: 10 * 1024 * 1024)
        
        // Decrypt the data after downloading
        guard let decryptedData = EncryptionService.decrypt(data: downloadedData, usingKey: privateKey) else {
            throw StorageError.downloadFailed("Decryption failed.")
        }
        
        print("Successfully downloaded and decrypted '\(filename)'.")
        return decryptedData
    }

    // Checks if a file exists in Firebase Storage.
    func fileExists(_ filename: String) async -> Bool {
        guard let rootRef = rootReference else {
            return false
        }
        
        let fileRef = rootRef.child(filename)
        
        do {
            _ = try await fileRef.getMetadata()
            return true
        } catch {
            return false
        }
    }

    // Deletes a file from Firebase Storage.
    func deleteData(with filename: String) async throws {
        guard let rootRef = rootReference else {
            throw StorageError.notInitialized
        }
        
        let fileRef = rootRef.child(filename)
        try await fileRef.delete()
        print("Successfully deleted '\(filename)' from Firebase Storage.")
    }

    // Lists all files in the Firebase Storage folder.
    func listFiles() async throws -> [String] {
        guard let rootRef = rootReference else {
            throw StorageError.notInitialized
        }
        
        let result = try await rootRef.listAll()
        return result.items.map { $0.name }
    }

    // Check if Firebase is configured without triggering initialization
    func isConfigured() async -> Bool {
        return _isInitialized && FirebaseApp.app() != nil
    }
}

// Custom errors for Firebase Storage
enum StorageError: Error, LocalizedError {
    case notInitialized
    case uploadFailed(String)
    case downloadFailed(String)
    case fileNotFound
    
    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Firebase Storage has not been initialized."
        case .uploadFailed(let reason):
            return "Failed to upload file to Firebase Storage: \(reason)"
        case .downloadFailed(let reason):
            return "Failed to download file from Firebase Storage: \(reason)"
        case .fileNotFound:
            return "The requested file was not found in Firebase Storage."
        }
    }
}