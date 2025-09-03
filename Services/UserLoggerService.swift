import Foundation

class UserLoggerService {
    static let shared = UserLoggerService()
    
    private let logFileName = "user_creation.log"
    private let maxLogEntries = 1000
    
    private init() {}
    
    private var logFileURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent(logFileName)
    }
    
    func logUserCreation(_ user: User) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        
        let logEntry = """
        ----------------------------------------------------------------
        Timestamp: \(timestamp)
        Event: New User Created
        Username: \(user.username)
        Password: Hello // For admin reference
        UserID: \(user.id.uuidString)
        Accessible Personas: \(user.accessiblePersonaIDs?.map { $0.uuidString } ?? ["All available"])
        Admin: \(user.isAdmin)
        Features: \(summarizeFeatures(user.allowedFeatures))
        Preferred Model: \(user.preferredModelID ?? "Auto-select")
        ----------------------------------------------------------------
        
        """
        
        appendToLog(logEntry)
        print("👤 User creation logged: \(user.username)")
    }
    
    func logUserUpdate(_ user: User) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        
        let logEntry = """
        ----------------------------------------------------------------
        Timestamp: \(timestamp)
        Event: User Updated
        Username: \(user.username)
        UserID: \(user.id.uuidString)
        Admin: \(user.isAdmin)
        Active: \(user.isActive)
        ----------------------------------------------------------------
        
        """
        
        appendToLog(logEntry)
        print("👤 User update logged: \(user.username)")
    }
    
    func logUserDeletion(_ username: String, userID: UUID) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        
        let logEntry = """
        ----------------------------------------------------------------
        Timestamp: \(timestamp)
        Event: User Deleted
        Username: \(username)
        UserID: \(userID.uuidString)
        ----------------------------------------------------------------
        
        """
        
        appendToLog(logEntry)
        print("👤 User deletion logged: \(username)")
    }
    
    func readLog() -> String {
        do {
            if FileManager.default.fileExists(atPath: logFileURL.path) {
                return try String(contentsOf: logFileURL, encoding: .utf8)
            } else {
                return "No user activity logged yet."
            }
        } catch {
            return "Error reading log file: \(error.localizedDescription)"
        }
    }
    
    private func appendToLog(_ entry: String) {
        do {
            if FileManager.default.fileExists(atPath: logFileURL.path) {
                let fileHandle = try FileHandle(forWritingTo: logFileURL)
                fileHandle.seekToEndOfFile()
                if let data = entry.data(using: .utf8) {
                    fileHandle.write(data)
                }
                fileHandle.closeFile()
            } else {
                try entry.write(to: logFileURL, atomically: true, encoding: .utf8)
            }
            
            // Trim log if it gets too large
            trimLogIfNeeded()
            
        } catch {
            print("Error writing to log file: \(error)")
        }
    }
    
    private func trimLogIfNeeded() {
        do {
            let logContent = try String(contentsOf: logFileURL, encoding: .utf8)
            let lines = logContent.components(separatedBy: .newlines)
            
            if lines.count > maxLogEntries {
                let trimmedLines = Array(lines.suffix(maxLogEntries))
                let trimmedContent = trimmedLines.joined(separator: "\n")
                try trimmedContent.write(to: logFileURL, atomically: true, encoding: .utf8)
            }
        } catch {
            print("Error trimming log file: \(error)")
        }
    }
    
    private func summarizeFeatures(_ features: UserFeatures) -> String {
        var enabledFeatures: [String] = []
        
        if features.canAccessChat { enabledFeatures.append("Chat") }
        if features.canAccessModelManagement { enabledFeatures.append("Models") }
        if features.canAccessVoiceFeatures { enabledFeatures.append("Voice") }
        if features.canAccessVisionFeatures { enabledFeatures.append("Vision") }
        if features.canAccessStorageManagement { enabledFeatures.append("Storage") }
        if features.canCreateChambers { enabledFeatures.append("Chambers") }
        if features.canExportData { enabledFeatures.append("Export") }
        if features.canAccessAdvancedSettings { enabledFeatures.append("Advanced") }
        
        return enabledFeatures.joined(separator: ", ")
    }
}