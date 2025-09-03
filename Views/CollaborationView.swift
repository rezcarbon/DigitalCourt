import SwiftUI

struct CollaborationView: View {
    let chamber: Chamber
    @EnvironmentObject var collaborationService: CollaborationService
    @EnvironmentObject var userManager: UserManager
    
    @State private var selectedUsers: Set<User> = []
    @State private var selectedPermissions: SharingPermissions = .readWrite
    @State private var showingUserPicker = false
    @State private var isSharing = false
    @State private var shareError: String?
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Chamber Info
                    chamberInfoSection
                    
                    // Active Collaborators
                    activeCollaboratorsSection
                    
                    // Share Chamber Section
                    shareChamberSection
                    
                    // Pending Invitations
                    pendingInvitationsSection
                }
                .padding()
            }
            .navigationTitle("Collaboration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Dismiss view
                    }
                }
            }
        }
        .alert("Sharing Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(shareError ?? "Unknown error occurred")
        }
    }
    
    private var chamberInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading) {
                    Text(chamber.name)
                        .font(.headline)
                    Text("\(chamber.messages.count) messages • \(chamber.council.count) council members")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    private var activeCollaboratorsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Active Collaborators")
                    .font(.headline)
                
                Spacer()
                
                // Connection status indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(collaborationService.isConnected ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    
                    Text(collaborationService.connectionStatus.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            let activeUsers = collaborationService.getActiveUsers(for: chamber.id)
            
            if activeUsers.isEmpty {
                HStack {
                    Image(systemName: "person.slash")
                        .foregroundColor(.secondary)
                    Text("No active collaborators")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            } else {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 120))
                ], spacing: 12) {
                    ForEach(activeUsers, id: \.id) { user in
                        CollaboratorCard(user: user, chamberId: chamber.id)
                    }
                }
            }
        }
    }
    
    private var shareChamberSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Share Chamber")
                .font(.headline)
            
            // Permissions selector
            VStack(alignment: .leading, spacing: 8) {
                Text("Permissions")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("Permissions", selection: $selectedPermissions) {
                    ForEach(SharingPermissions.allCases, id: \.self) { permission in
                        Text(permission.rawValue).tag(permission)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Selected users
            if !selectedUsers.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Selected Users (\(selectedUsers.count))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 100))
                    ], spacing: 8) {
                        ForEach(Array(selectedUsers), id: \.id) { user in
                            UserChip(user: user) {
                                selectedUsers.remove(user)
                            }
                        }
                    }
                }
            }
            
            HStack(spacing: 12) {
                Button("Select Users") {
                    showingUserPicker = true
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Share Chamber") {
                    shareChamber()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedUsers.isEmpty || isSharing)
                
                if isSharing {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
        .sheet(isPresented: $showingUserPicker) {
            UserPickerView(selectedUsers: $selectedUsers)
        }
    }
    
    private var pendingInvitationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pending Invitations")
                .font(.headline)
            
            let pendingInvitations = collaborationService.pendingInvitations.filter { 
                $0.chamber.id == chamber.id 
            }
            
            if pendingInvitations.isEmpty {
                Text("No pending invitations")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            } else {
                ForEach(pendingInvitations) { invitation in
                    InvitationCard(invitation: invitation)
                }
            }
        }
    }
    
    private func shareChamber() {
        isSharing = true
        
        Task {
            do {
                try await collaborationService.shareChamber(
                    chamber,
                    with: Array(selectedUsers),
                    permissions: selectedPermissions
                )
                
                await MainActor.run {
                    selectedUsers.removeAll()
                    isSharing = false
                }
            } catch {
                await MainActor.run {
                    shareError = error.localizedDescription
                    showingError = true
                    isSharing = false
                }
            }
        }
    }
}

struct CollaboratorCard: View {
    let user: User
    let chamberId: UUID
    @EnvironmentObject var collaborationService: CollaborationService
    
    var body: some View {
        VStack(spacing: 8) {
            // User avatar placeholder
            Circle()
                .fill(Color.blue.gradient)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(user.username.prefix(1).uppercased())
                        .font(.headline)
                        .foregroundColor(.white)
                )
            
            Text(user.username)
                .font(.caption)
                .lineLimit(1)
            
            // Presence indicator
            if let presence = getPresenceStatus() {
                Text(presence.rawValue)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(presenceColor(presence))
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func getPresenceStatus() -> PresenceStatus? {
        // This would get the actual presence from the collaboration service
        return .online // Placeholder
    }
    
    private func presenceColor(_ status: PresenceStatus) -> Color {
        switch status {
        case .online: return .green
        case .typing: return .blue
        case .away: return .orange
        case .offline: return .gray
        }
    }
}

struct UserChip: View {
    let user: User
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(user.username)
                .font(.caption)
                .lineLimit(1)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.2))
        .cornerRadius(8)
    }
}

struct InvitationCard: View {
    let invitation: ChamberInvitation
    @EnvironmentObject var collaborationService: CollaborationService
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("To: \(invitation.to.username)")
                    .font(.subheadline)
                
                Text("Permissions: \(invitation.permissions.rawValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Sent: \(DateFormatter.readable.string(from: invitation.invitationDate))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text(invitation.status.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(statusColor(invitation.status))
                    .foregroundColor(.white)
                    .cornerRadius(4)
                
                if invitation.status == .pending {
                    Button("Cancel") {
                        // Cancel invitation
                    }
                    .font(.caption2)
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func statusColor(_ status: InvitationStatus) -> Color {
        switch status {
        case .pending: return .orange
        case .accepted: return .green
        case .declined: return .red
        case .expired: return .gray
        }
    }
}