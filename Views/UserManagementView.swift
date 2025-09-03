import SwiftUI

struct UserManagementView: View {
    @ObservedObject var userManager = UserManager.shared
    @State private var newUsername = ""
    @State private var newPassword = ""
    @State private var isSuperuser = false
    @State private var persona = ""
    @State private var modelSelection: [String] = []
    @State private var showPersonaSheet: User?
    @State private var showModelSheet: User?

    var allModels: [HuggingFaceModel] {
        HuggingFaceModel.examples
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Add User")) {
                    TextField("Username", text: $newUsername)
                    SecureField("Password", text: $newPassword)
                    Toggle("Superuser", isOn: $isSuperuser)
                    TextField("Persona (optional)", text: $persona)
                    Text("Allow Models").font(.caption)
                    
                    // Break up the ForEach into a separate section to fix type-checking
                    modelSelectionSection
                    
                    Button("Create User") {
                        createNewUser()
                    }
                }
                
                Section(header: Text("Users")) {
                    SwiftUI.ForEach(userManager.users) { user in
                        userRowView(user: user)
                    }
                }
            }
            .navigationTitle("User Management")
            .sheet(item: $showPersonaSheet) { editUser in
                PersonaEditSheet(user: editUser, userManager: userManager)
            }
            .sheet(item: $showModelSheet) { editUser in
                ModelEditSheet(user: editUser, userManager: userManager, allModels: allModels)
            }
        }
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private var modelSelectionSection: some View {
        SwiftUI.ForEach(allModels, id: \.id) { model in
            HStack {
                Toggle(model.name, isOn: Binding(
                    get: { modelSelection.contains(model.id) },
                    set: { checked in
                        if checked {
                            modelSelection.append(model.id)
                        } else {
                            modelSelection.removeAll { $0 == model.id }
                        }
                    }
                ))
            }
        }
    }
    
    @ViewBuilder
    private func userRowView(user: User) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(user.username).fontWeight(.bold)
                if user.isAdmin { 
                    Text("(Admin)").foregroundColor(.purple) 
                }
            }
            
            // Show preferred model if available
            if let preferredModel = user.preferredModelID {
                Text("Preferred Model: \(preferredModel)").font(.caption)
            }
            
            // Show feature access count
            let featureCount = countUserFeatures(user.allowedFeatures)
            Text("Features: \(featureCount)").font(.caption)
            
            HStack {
                Button("Delete") {
                    userManager.deleteUser(user)
                }
                .foregroundColor(.red)
                
                Button("Change Persona") { 
                    showPersonaSheet = user 
                }
                
                Button("Edit Models") { 
                    showModelSheet = user 
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createNewUser() {
        guard !newUsername.isEmpty && !newPassword.isEmpty else { return }
        guard !userManager.isUsernameTaken(newUsername) else { return }
        
        userManager.createUser(
            username: newUsername,
            password: newPassword,
            isSuperuser: isSuperuser,
            persona: persona.isEmpty ? nil : persona,
            allowedModelIds: modelSelection
        )
        
        // Reset form
        newUsername = ""
        newPassword = ""
        isSuperuser = false
        persona = ""
        modelSelection = []
    }
    
    private func countUserFeatures(_ features: UserFeatures) -> Int {
        var count = 0
        if features.canAccessModelManagement { count += 1 }
        if features.canAccessVoiceFeatures { count += 1 }
        if features.canAccessVisionFeatures { count += 1 }
        if features.canAccessStorageManagement { count += 1 }
        if features.canCreateChambers { count += 1 }
        if features.canExportData { count += 1 }
        if features.canAccessAdvancedSettings { count += 1 }
        return count
    }
}

struct PersonaEditSheet: View {
    var user: User
    @ObservedObject var userManager: UserManager
    @State private var personaText: String = ""

    var body: some View {
        VStack {
            TextField("Persona", text: $personaText)
                .padding()
            Button("Save") {
                userManager.assignPersona(personaText, to: user)
            }
            .padding()
        }
        .onAppear {
            // Since User doesn't have a persona property, we'll use an empty string
            personaText = ""
        }
    }
}

struct ModelEditSheet: View {
    var user: User
    @ObservedObject var userManager: UserManager
    let allModels: [HuggingFaceModel]
    @State private var selection: [String] = []

    var body: some View {
        Form {
            SwiftUI.ForEach(allModels, id: \.id) { model in
                Toggle(model.name, isOn: Binding(
                    get: { selection.contains(model.id) },
                    set: { checked in
                        if checked {
                            selection.append(model.id)
                        } else {
                            selection.removeAll { $0 == model.id }
                        }
                    }
                ))
            }
            Button("Save") {
                userManager.assignModels(selection, to: user)
            }
        }
        .onAppear {
            // Since User model structure may be different, initialize with preferred model
            selection = user.preferredModelID != nil ? [user.preferredModelID!] : []
        }
    }
}