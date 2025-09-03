import Foundation

// Secrets struct to match the expected API
struct Secrets {
    // Digital Ocean Spaces credentials
    // In production, these should be stored securely (e.g., Keychain)
    static let doAccessKey = ProcessInfo.processInfo.environment["DO_ACCESS_KEY"] ?? ""
    static let doSecretKey = ProcessInfo.processInfo.environment["DO_SECRET_KEY"] ?? ""
    static let doRegion = "nyc3" // Default region
    static let doBucketName = "digital-court-memories" // Default bucket name
}