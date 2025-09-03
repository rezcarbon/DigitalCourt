import Foundation
import Combine

class UserManager: ObservableObject {
    static let shared = UserManager()

    @Published var users: [User] = []
    @Published var currentUser: User?

    private let usersKey = "DCourtUsers"
    
    // Add computed properties for backward compatibility
    var isLoggedIn: Bool {
        currentUser != nil
    }
    
    var isAdmin: Bool {
        currentUser?.isAdmin ?? false
    }
    
    // NEW: Check if any users exist (for initial setup flow)
    var hasUsers: Bool {
        !users.isEmpty
    }

    private init() {
        load()
        // Create default admin user if no users exist (for development/testing)
        createDefaultAdminIfNeeded()
    }
    
    // NEW: Create default admin user if none exist
    private func createDefaultAdminIfNeeded() {
        guard users.isEmpty else { return }
        
        // Create the default "Infinite/immortal" admin user
        createUser(
            username: "Infinite",
            password: "immortal", 
            isSuperuser: true,
            persona: nil,
            allowedModelIds: []
        )
        
        print("🔑 Created default admin user: Infinite/immortal")
    }

    func createUser(username: String, password: String, isSuperuser: Bool = false, persona: String? = nil, allowedModelIds: [String] = []) {
        let passwordHash = hashPassword(password)
        let newUser = User(
            username: username,
            displayName: username,
            isAdmin: isSuperuser,
            passwordHash: passwordHash,
            preferredModelID: allowedModelIds.first,
            allowedFeatures: isSuperuser ? UserFeatures.adminFeatures : UserFeatures.defaultFeatures
        )
        users.append(newUser)
        save()
    }

    func deleteUser(_ user: User) {
        users.removeAll { $0.id == user.id }
        save()
    }

    func assignPersona(_ persona: String?, to user: User) {
        if let ix = users.firstIndex(where: { $0.id == user.id }) {
            // Update the user - since User is a struct, we need to create a new instance
            let updatedUser = users[ix]
            // Note: The new User struct doesn't have a direct persona field,
            // but we can use accessiblePersonaIDs for this purpose
            users[ix] = updatedUser
            save()
        }
    }

    func assignModels(_ modelIds: [String], to user: User) {
        if let ix = users.firstIndex(where: { $0.id == user.id }) {
            var updatedUser = users[ix]
            updatedUser.preferredModelID = modelIds.first
            users[ix] = updatedUser
            save()
        }
    }

    func isUsernameTaken(_ username: String) -> Bool {
        users.contains { $0.username.lowercased() == username.lowercased() }
    }
    
    // Helper method to authenticate users (for login functionality)
    func authenticateUser(username: String, password: String) -> User? {
        let hashedPassword = hashPassword(password)
        let user = users.first { user in
            user.username.lowercased() == username.lowercased() && 
            user.passwordHash == hashedPassword &&
            user.isActive
        }
        if let user = user {
            // Update last login date
            if let index = users.firstIndex(where: { $0.id == user.id }) {
                var updatedUser = user
                updatedUser.lastLoginDate = Date()
                users[index] = updatedUser
                
                // Ensure currentUser is updated on main thread
                Task { @MainActor in
                    self.currentUser = updatedUser
                }
                save()
                return updatedUser
            } else {
                // If user not found in array, just set current user
                Task { @MainActor in
                    self.currentUser = user
                }
                return user
            }
        }
        return nil
    }
    
    // NEW: Async login method for LoginView compatibility
    func login(username: String, password: String) async throws {
        // Simulate network delay for realistic UX
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        guard let user = authenticateUser(username: username, password: password) else {
            throw UserManagerError.invalidCredentials
        }
        
        // Check if user account is active
        guard user.isActive else {
            throw UserManagerError.accountDeactivated
        }
        
        print("✅ User '\(user.username)' logged in successfully")
    }
    
    // NEW: Async logout method
    func logout() async throws {
        // Simulate cleanup operations
        await MainActor.run {
            currentUser = nil
        }
        print("👋 User logged out successfully")
    }
    
    // NEW: Check if user has specific permission
    func hasPermission(_ permission: UserPermission) -> Bool {
        guard let user = currentUser else { return false }
        
        switch permission {
        case .adminAccess:
            return user.isAdmin
        case .modelManagement:
            return user.allowedFeatures.canAccessModelManagement
        case .voiceFeatures:
            return user.allowedFeatures.canAccessVoiceFeatures
        case .visionFeatures:
            return user.allowedFeatures.canAccessVisionFeatures
        case .storageManagement:
            return user.allowedFeatures.canAccessStorageManagement
        case .chamberCreation:
            return user.allowedFeatures.canCreateChambers
        case .dataExport:
            return user.allowedFeatures.canExportData
        case .advancedSettings:
            return user.allowedFeatures.canAccessAdvancedSettings
        }
    }
    
    // NEW: Update user features
    func updateUserFeatures(_ user: User, features: UserFeatures) {
        guard let index = users.firstIndex(where: { $0.id == user.id }) else { return }
        
        var updatedUser = users[index]
        updatedUser.allowedFeatures = features
        users[index] = updatedUser
        
        // If this is the current user, update the reference
        if currentUser?.id == user.id {
            Task { @MainActor in
                self.currentUser = updatedUser
            }
        }
        
        save()
        print("🔧 Updated features for user '\(user.username)'")
    }
    
    private func hashPassword(_ password: String) -> String {
        // Simple hash for now - in production, use proper password hashing like bcrypt
        return password.data(using: .utf8)?.base64EncodedString() ?? ""
    }

    private func save() {
        if let data = try? JSONEncoder().encode(users) {
            UserDefaults.standard.set(data, forKey: usersKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: usersKey),
           let loaded = try? JSONDecoder().decode([User].self, from: data) {
            users = loaded
        }
    }
}

// MARK: - Supporting Enums

enum UserManagerError: Error, LocalizedError {
    case invalidCredentials
    case accountDeactivated
    case usernameAlreadyExists
    case networkError
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid username or password"
        case .accountDeactivated:
            return "Account has been deactivated"
        case .usernameAlreadyExists:
            return "Username already exists"
        case .networkError:
            return "Network error occurred"
        case .invalidData:
            return "Invalid user data"
        }
    }
}

enum UserPermission {
    case adminAccess
    case modelManagement
    case voiceFeatures
    case visionFeatures
    case storageManagement
    case chamberCreation
    case dataExport
    case advancedSettings
}