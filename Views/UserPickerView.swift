import SwiftUI

struct UserPickerView: View {
    @Binding var selectedUsers: Set<User>
    @EnvironmentObject var userManager: UserManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var allUsers: [User] = []
    
    var filteredUsers: [User] {
        if searchText.isEmpty {
            return allUsers.filter { $0.id != userManager.currentUser?.id }
        } else {
            return allUsers.filter { user in
                user.username.localizedCaseInsensitiveContains(searchText) &&
                user.id != userManager.currentUser?.id
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search users...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
                
                // Selected users count
                if !selectedUsers.isEmpty {
                    HStack {
                        Text("\(selectedUsers.count) user(s) selected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                
                // Users list
                List {
                    ForEach(filteredUsers, id: \.id) { user in
                        UserPickerRowView(
                            user: user,
                            isSelected: selectedUsers.contains(user)
                        ) {
                            toggleUserSelection(user)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Select Users")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadUsers()
        }
    }
    
    private func toggleUserSelection(_ user: User) {
        if selectedUsers.contains(user) {
            selectedUsers.remove(user)
        } else {
            selectedUsers.insert(user)
        }
    }
    
    private func loadUsers() {
        // Get all users from UserManager - use proper method access
        allUsers = userManager.users
    }
}

struct UserPickerRowView: View {
    let user: User
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // User avatar
                Circle()
                    .fill(Color.blue.gradient)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(user.username.prefix(1).uppercased())
                            .font(.headline)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(user.username)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(user.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if user.isAdmin {
                        Text("Administrator")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}