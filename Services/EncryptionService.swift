import Foundation
import CryptoKit

/// Handles AES-256 encryption and decryption for securing AI memory and communications.
/// This service ensures that the AI's data is protected both at rest and in transit.
struct EncryptionService {
    
    /// Encrypts a block of data using a given key.
    /// - Parameters:
    ///   - data: The plaintext `Data` to be encrypted.
    ///   - key: A base64-encoded string representing the 256-bit encryption key.
    /// - Returns: The encrypted `Data` (ciphertext), or `nil` if encryption fails.
    static func encrypt(data: Data, usingKey key: String) -> Data? {
        guard let symmetricKey = symmetricKey(from: key) else {
            print("Encryption Error: Failed to create a valid symmetric key.")
            return nil
        }
        
        do {
            // AES.GCM is a modern, secure encryption algorithm that provides both confidentiality and integrity.
            let sealedBox = try AES.GCM.seal(data, using: symmetricKey)
            // The combined property contains the nonce, ciphertext, and authentication tag, which are all needed for decryption.
            return sealedBox.combined
        } catch {
            print("Encryption Error: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Decrypts a block of data using a given key.
    /// - Parameters:
    ///   - data: The encrypted `Data` (ciphertext).
    ///   - key: A base64-encoded string representing the 256-bit encryption key.
    /// - Returns: The original plaintext `Data`, or `nil` if decryption fails.
    static func decrypt(data: Data, usingKey key: String) -> Data? {
        guard let symmetricKey = symmetricKey(from: key) else {
            print("Decryption Error: Failed to create a valid symmetric key.")
            return nil
        }
        
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            let decryptedData = try AES.GCM.open(sealedBox, using: symmetricKey)
            return decryptedData
        } catch {
            print("Decryption Error: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Generates a new, random 256-bit key and returns it as a base64-encoded string.
    /// - Returns: A new base64-encoded encryption key.
    static func generateEncryptionKey() -> String {
        let key = SymmetricKey(size: .bits256)
        return key.withUnsafeBytes { Data(Array($0)).base64EncodedString() }
    }
    
    /// Converts a base64-encoded string key into a `SymmetricKey`.
    private static func symmetricKey(from base64String: String) -> SymmetricKey? {
        guard let keyData = Data(base64Encoded: base64String) else { return nil }
        return SymmetricKey(data: keyData)
    }
}