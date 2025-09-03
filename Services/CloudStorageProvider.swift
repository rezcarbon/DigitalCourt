import Foundation

// Protocol defining the contract for any cloud storage provider.
// This allows the app to be independent of the specific cloud service being used.
protocol CloudStorageProvider: AnyObject {
    func initialize() async throws
    func storeData(_ data: Data, with filename: String, usingKey privateKey: String) async throws
    func retrieveData(with filename: String, usingKey privateKey: String) async throws -> Data
    func deleteData(with filename: String) async throws
    func fileExists(_ filename: String) async -> Bool
    func listFiles() async throws -> [String]
    
    // Add method to check if provider is properly configured
    func isConfigured() async -> Bool
}

// Add default implementation
extension CloudStorageProvider {
    func isConfigured() async -> Bool {
        // Default implementation - assume configured if no errors during basic check
        // This should be lightweight and not trigger initialization
        return true
    }
}