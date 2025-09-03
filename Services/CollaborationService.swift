import Foundation
import Combine
import SwiftData

@MainActor
class CollaborationService: ObservableObject {
    static let shared = CollaborationService()
    
    @Published var sharedChambers: [SharedChamber] = []
    @Published var collaborators: [User] = []
    @Published var pendingInvitations: [ChamberInvitation] = []
    @Published var isConnected = false
    @Published var connectionStatus: ConnectionStatus = .disconnected
    
    private var modelContext: ModelContext?
    private let userManager = UserManager.shared
    private let cacheManager = CacheManager.shared
    
    // Real-time collaboration simulation
    private var collaborationTimer: Timer?
    private var sessionTimers: [UUID: Timer] = [:]
    private var activeCollaborations: [UUID: CollaborationSession] = [:]
    
    private init() {
        setupCollaborationService()
    }
    
    deinit {
        // Clean up timers to prevent memory leaks
        collaborationTimer?.invalidate()
        sessionTimers.values.forEach { $0.invalidate() }
    }
    
    // MARK: - Setup
    
    func setup(with context: ModelContext) {
        self.modelContext = context
        loadSharedChambers()
        startCollaborationMonitoring()
    }
    
    private func setupCollaborationService() {
        // Simulate connection status
        connectionStatus = .connecting
        
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            self.connectionStatus = .connected
            self.isConnected = true
        }
    }
    
    private func startCollaborationMonitoring() {
        collaborationTimer?.invalidate() // Clean up existing timer
        collaborationTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            Task { @MainActor in
                await self.checkForCollaborationUpdates()
            }
        }
    }
    
    // MARK: - Chamber Sharing
    
    func shareChamber(_ chamber: Chamber, with users: [User], permissions: SharingPermissions = .readWrite) async throws {
        guard let currentUser = userManager.currentUser else {
            throw CollaborationError.notAuthenticated
        }
        
        let sharedChamber = SharedChamber(
            originalChamber: chamber,
            owner: currentUser,
            sharedWith: users,
            permissions: permissions,
            shareDate: Date()
        )
        
        // Create invitations for each user
        for user in users {
            let invitation = ChamberInvitation(
                chamber: chamber,
                from: currentUser,
                to: user,
                permissions: permissions,
                invitationDate: Date()
            )
            
            pendingInvitations.append(invitation)
            
            // Simulate sending invitation
            try await sendInvitation(invitation)
        }
        
        sharedChambers.append(sharedChamber)
        
        // Cache the shared chamber
        await cacheManager.cacheData(sharedChamber, for: "shared_chamber_\(chamber.id)")
        
        print("✅ Chamber '\(chamber.name)' shared with \(users.count) users")
    }
    
    func joinSharedChamber(_ chamberId: UUID) async throws -> Chamber? {
        guard let invitation = pendingInvitations.first(where: { 
            $0.chamber.id == chamberId && $0.status == .pending 
        }) else {
            throw CollaborationError.invitationNotFound
        }
        
        // Accept the invitation
        if let index = pendingInvitations.firstIndex(where: { $0.id == invitation.id }) {
            pendingInvitations[index].status = .accepted
            pendingInvitations[index].responseDate = Date()
        }
        
        // Add to shared chambers
        let sharedChamber = SharedChamber(
            originalChamber: invitation.chamber,
            owner: invitation.from,
            sharedWith: [invitation.to],
            permissions: invitation.permissions,
            shareDate: invitation.invitationDate
        )
        
        sharedChambers.append(sharedChamber)
        
        // Start collaboration session
        startCollaborationSession(for: invitation.chamber.id)
        
        print("✅ Joined shared chamber: \(invitation.chamber.name)")
        return invitation.chamber
    }
    
    func leaveSharedChamber(_ chamberId: UUID) async throws {
        sharedChambers.removeAll { $0.originalChamber.id == chamberId }
        stopCollaborationSession(for: chamberId)
        
        // Remove from cache
        _ = cacheManager.getCachedData(for: "shared_chamber_\(chamberId)", type: SharedChamber.self)
        
        print("✅ Left shared chamber")
    }
    
    // MARK: - Real-time Collaboration
    
    private func startCollaborationSession(for chamberId: UUID) {
        let session = CollaborationSession(
            chamberId: chamberId,
            participants: [],
            startTime: Date(),
            isActive: true
        )
        
        activeCollaborations[chamberId] = session
        
        // Clean up existing timer for this chamber
        sessionTimers[chamberId]?.invalidate()
        
        // Simulate real-time updates
        sessionTimers[chamberId] = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
            Task { @MainActor in
                if !self.activeCollaborations.keys.contains(chamberId) {
                    timer.invalidate()
                    self.sessionTimers.removeValue(forKey: chamberId)
                    return
                }
                
                await self.simulateCollaborationActivity(for: chamberId)
            }
        }
    }
    
    private func stopCollaborationSession(for chamberId: UUID) {
        activeCollaborations.removeValue(forKey: chamberId)
        sessionTimers[chamberId]?.invalidate()
        sessionTimers.removeValue(forKey: chamberId)
    }
    
    private func simulateCollaborationActivity(for chamberId: UUID) async {
        // Simulate typing indicators, presence updates, etc.
        if var session = activeCollaborations[chamberId] {
            session.lastActivity = Date()
            activeCollaborations[chamberId] = session
            
            // Notify UI of collaboration activity
            objectWillChange.send()
        }
    }
    
    // MARK: - Presence & Typing Indicators
    
    func updatePresence(for chamberId: UUID, status: PresenceStatus) async {
        guard var session = activeCollaborations[chamberId] else { return }
        
        if let currentUser = userManager.currentUser {
            let presence = UserPresence(
                user: currentUser,
                status: status,
                lastSeen: Date(),
                chamberId: chamberId
            )
            
            session.presences[currentUser.id] = presence
            activeCollaborations[chamberId] = session
        }
    }
    
    func startTyping(in chamberId: UUID) async {
        await updatePresence(for: chamberId, status: .typing)
    }
    
    func stopTyping(in chamberId: UUID) async {
        await updatePresence(for: chamberId, status: .online)
    }
    
    func getActiveUsers(for chamberId: UUID) -> [User] {
        guard let session = activeCollaborations[chamberId] else { return [] }
        
        return session.presences.values.compactMap { presence in
            if presence.status != .offline && 
               Date().timeIntervalSince(presence.lastSeen) < 300 { // 5 minutes
                return presence.user
            }
            return nil
        }
    }
    
    // MARK: - Message Synchronization
    
    func syncMessage(_ message: Message, to chamberId: UUID) async throws {
        guard activeCollaborations[chamberId] != nil else {
            throw CollaborationError.noActiveSession
        }
        
        // Simulate message sync to other participants
        _ = MessageSyncData(
            message: message,
            chamberId: chamberId,
            senderId: userManager.currentUser?.id ?? UUID(),
            timestamp: Date()
        )
        
        // In a real implementation, this would send to a server
        print("📤 Syncing message to chamber \(chamberId)")
        
        // Simulate receiving sync acknowledgment
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            print("✅ Message sync confirmed")
        }
    }
    
    func handleIncomingMessage(_ syncData: MessageSyncData) async {
        // Handle incoming synced messages from other users
        guard activeCollaborations[syncData.chamberId] != nil else { return }
        
        // Update UI with incoming message
        print("📥 Received synced message for chamber \(syncData.chamberId)")
        
        // Notify relevant views
        NotificationCenter.default.post(
            name: .collaborationMessageReceived,
            object: syncData
        )
    }
    
    // MARK: - Invitation Management
    
    private func sendInvitation(_ invitation: ChamberInvitation) async throws {
        // Simulate sending invitation via notification service
        print("📧 Sending invitation to \(invitation.to.username)")
        
        // In a real implementation, you would send via push notification or email
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            print("✅ Invitation sent successfully")
        }
    }
    
    func acceptInvitation(_ invitationId: UUID) async throws {
        guard let index = pendingInvitations.firstIndex(where: { $0.id == invitationId }) else {
            throw CollaborationError.invitationNotFound
        }
        
        pendingInvitations[index].status = .accepted
        pendingInvitations[index].responseDate = Date()
        
        let chamber = pendingInvitations[index].chamber
        _ = try await joinSharedChamber(chamber.id)
    }
    
    func declineInvitation(_ invitationId: UUID) async throws {
        guard let index = pendingInvitations.firstIndex(where: { $0.id == invitationId }) else {
            throw CollaborationError.invitationNotFound
        }
        
        pendingInvitations[index].status = .declined
        pendingInvitations[index].responseDate = Date()
        
        print("❌ Invitation declined")
    }
    
    // MARK: - Data Loading
    
    private func loadSharedChambers() {
        // Load from cache or persistent storage
        // For now, initialize empty
        sharedChambers = []
        pendingInvitations = []
    }
    
    private func checkForCollaborationUpdates() async {
        // Check for new invitations, messages, presence updates
        // Simulate periodic updates
        
        let cutoffTime = Date().timeIntervalSince1970 - 300 // 5 minutes ago
        
        for (chamberId, session) in activeCollaborations {
            if session.lastActivity.timeIntervalSince1970 < cutoffTime {
                stopCollaborationSession(for: chamberId)
            }
        }
    }
    
    // MARK: - Utility Methods
    
    func canUserEdit(_ user: User, chamber: Chamber) -> Bool {
        guard let sharedChamber = sharedChambers.first(where: { 
            $0.originalChamber.id == chamber.id 
        }) else {
            return false
        }
        
        return sharedChamber.permissions == .readWrite || sharedChamber.owner.id == user.id
    }
    
    func getCollaborationInfo(for chamberId: UUID) -> CollaborationInfo? {
        guard let session = activeCollaborations[chamberId],
              let sharedChamber = sharedChambers.first(where: { 
                  $0.originalChamber.id == chamberId 
              }) else {
            return nil
        }
        
        return CollaborationInfo(
            session: session,
            sharedChamber: sharedChamber,
            activeUsers: getActiveUsers(for: chamberId)
        )
    }
}

// MARK: - Supporting Types

struct SharedChamber: Identifiable, Codable {
    var id = UUID()
    let originalChamberId: UUID
    let originalChamberName: String
    let ownerId: UUID
    let ownerName: String
    let sharedWithIds: [UUID]
    let sharedWithNames: [String]
    let permissions: SharingPermissions
    let shareDate: Date
    
    // Computed properties for backward compatibility
    var originalChamber: Chamber {
        return Chamber(id: originalChamberId, name: originalChamberName, council: [], messages: [])
    }
    
    var owner: User {
        return User(
            id: ownerId,
            username: ownerName,
            displayName: ownerName,
            isAdmin: false,
            accessiblePersonaIDs: nil
        )
    }
    
    var sharedWith: [User] {
        return zip(sharedWithIds, sharedWithNames).map { (id, name) in
            User(
                id: id,
                username: name,
                displayName: name,
                isAdmin: false,
                accessiblePersonaIDs: nil
            )
        }
    }
    
    init(originalChamber: Chamber, owner: User, sharedWith: [User], permissions: SharingPermissions, shareDate: Date) {
        self.originalChamberId = originalChamber.id
        self.originalChamberName = originalChamber.name
        self.ownerId = owner.id
        self.ownerName = owner.username
        self.sharedWithIds = sharedWith.map { $0.id }
        self.sharedWithNames = sharedWith.map { $0.username }
        self.permissions = permissions
        self.shareDate = shareDate
    }
}

struct ChamberInvitation: Identifiable, Codable {
    var id = UUID()
    let chamberId: UUID
    let chamberName: String
    let fromId: UUID
    let fromName: String
    let toId: UUID
    let toName: String
    let permissions: SharingPermissions
    let invitationDate: Date
    var status: InvitationStatus = .pending
    var responseDate: Date?
    
    // Computed properties for backward compatibility
    var chamber: Chamber {
        return Chamber(id: chamberId, name: chamberName, council: [], messages: [])
    }
    
    var from: User {
        return User(
            id: fromId,
            username: fromName,
            displayName: fromName,
            isAdmin: false,
            accessiblePersonaIDs: nil
        )
    }
    
    var to: User {
        return User(
            id: toId,
            username: toName,
            displayName: toName,
            isAdmin: false,
            accessiblePersonaIDs: nil
        )
    }
    
    init(chamber: Chamber, from: User, to: User, permissions: SharingPermissions, invitationDate: Date) {
        self.chamberId = chamber.id
        self.chamberName = chamber.name
        self.fromId = from.id
        self.fromName = from.username
        self.toId = to.id
        self.toName = to.username
        self.permissions = permissions
        self.invitationDate = invitationDate
    }
}

struct CollaborationSession {
    let chamberId: UUID
    var participants: [User]
    let startTime: Date
    var lastActivity: Date = Date()
    var isActive: Bool
    var presences: [UUID: UserPresence] = [:]
}

struct UserPresence {
    let user: User
    var status: PresenceStatus
    var lastSeen: Date
    let chamberId: UUID
}

struct MessageSyncData {
    let message: Message
    let chamberId: UUID
    let senderId: UUID
    let timestamp: Date
}

struct CollaborationInfo {
    let session: CollaborationSession
    let sharedChamber: SharedChamber
    let activeUsers: [User]
}

enum SharingPermissions: String, Codable, CaseIterable {
    case readOnly = "Read Only"
    case readWrite = "Read & Write"
    case admin = "Admin"
}

enum InvitationStatus: String, Codable {
    case pending = "Pending"
    case accepted = "Accepted"
    case declined = "Declined"
    case expired = "Expired"
}

enum PresenceStatus: String, Codable {
    case online = "Online"
    case typing = "Typing"
    case away = "Away"
    case offline = "Offline"
}

enum ConnectionStatus: String {
    case disconnected = "Disconnected"
    case connecting = "Connecting"
    case connected = "Connected"
    case error = "Error"
}

enum CollaborationError: Error, LocalizedError {
    case notAuthenticated
    case invitationNotFound
    case noActiveSession
    case permissionDenied
    case connectionFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User must be authenticated to share chambers"
        case .invitationNotFound:
            return "Chamber invitation not found"
        case .noActiveSession:
            return "No active collaboration session"
        case .permissionDenied:
            return "Insufficient permissions for this action"
        case .connectionFailed:
            return "Failed to connect to collaboration service"
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let collaborationMessageReceived = Notification.Name("collaborationMessageReceived")
    static let userPresenceUpdated = Notification.Name("userPresenceUpdated")
    static let collaborationInvitationReceived = Notification.Name("collaborationInvitationReceived")
}