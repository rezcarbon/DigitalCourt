import Foundation

struct User: Identifiable, Codable, Hashable {
    let id: UUID
    let username: String
    var displayName: String
    var isAdmin: Bool
    var accessiblePersonaIDs: [UUID]? // nil means access to all
    var passwordHash: String?
    
    // New properties for enhanced user management
    var preferredModelID: String? // Which MLX model this user should use
    var allowedFeatures: UserFeatures // What features this user can access
    var createdDate: Date
    var lastLoginDate: Date?
    var isActive: Bool // Can be used to disable users without deleting them
    
    init(id: UUID = UUID(), 
         username: String, 
         displayName: String? = nil, 
         isAdmin: Bool = false, 
         accessiblePersonaIDs: [UUID]? = nil, 
         passwordHash: String? = nil,
         preferredModelID: String? = nil,
         allowedFeatures: UserFeatures? = nil,
         createdDate: Date = Date(),
         lastLoginDate: Date? = nil,
         isActive: Bool = true) {
        self.id = id
        self.username = username
        self.displayName = displayName ?? username
        self.isAdmin = isAdmin
        self.accessiblePersonaIDs = accessiblePersonaIDs
        self.passwordHash = passwordHash
        self.preferredModelID = preferredModelID
        self.allowedFeatures = allowedFeatures ?? (isAdmin ? UserFeatures.adminFeatures : UserFeatures.defaultFeatures)
        self.createdDate = createdDate
        self.lastLoginDate = lastLoginDate
        self.isActive = isActive
    }
    
    // MARK: - Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
}

struct UserFeatures: Codable, Hashable {
    var canAccessChat: Bool
    var canAccessModelManagement: Bool
    var canAccessVoiceFeatures: Bool
    var canAccessVisionFeatures: Bool
    var canAccessStorageManagement: Bool
    var canCreateChambers: Bool
    var canExportData: Bool
    var canAccessAdvancedSettings: Bool
    var maxConcurrentChats: Int
    var dailyModelUsageLimit: Int? // nil means unlimited
    
    static let defaultFeatures = UserFeatures(
        canAccessChat: true,
        canAccessModelManagement: false,
        canAccessVoiceFeatures: true,
        canAccessVisionFeatures: false,
        canAccessStorageManagement: false,
        canCreateChambers: true,
        canExportData: false,
        canAccessAdvancedSettings: false,
        maxConcurrentChats: 1,
        dailyModelUsageLimit: 100
    )
    
    static let adminFeatures = UserFeatures(
        canAccessChat: true,
        canAccessModelManagement: true,
        canAccessVoiceFeatures: true,
        canAccessVisionFeatures: true,
        canAccessStorageManagement: true,
        canCreateChambers: true,
        canExportData: true,
        canAccessAdvancedSettings: true,
        maxConcurrentChats: 10,
        dailyModelUsageLimit: nil
    )
}