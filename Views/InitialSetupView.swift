import SwiftUI

struct InitialSetupView: View {
    @EnvironmentObject var userManager: UserManager
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isCreating = false
    @Binding var setupComplete: Bool
    
    var body: some View {
        ZStack {
            LiquidGlassBackground()
            
            VStack(spacing: 20) {
                Spacer()
                
                Image(systemName: "lock.shield")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Digital Court Setup")
                    .font(.title)
                    .bold()
                
                Text("Create your first admin user")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 15) {
                    TextField("Admin Username", text: $username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .textContentType(.username)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.newPassword)
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.newPassword)
                }
                .padding(.horizontal, 40)
                
                if isCreating {
                    ProgressView()
                        .padding(.top)
                } else {
                    Button("Create Admin User") {
                        createAdminUser()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(username.isEmpty || password.isEmpty || password != confirmPassword)
                    .padding(.horizontal, 40)
                    .padding(.top)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .alert("Setup Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func createAdminUser() {
        guard !username.isEmpty, !password.isEmpty, password == confirmPassword else {
            errorMessage = "Please fill in all fields and ensure passwords match"
            showingError = true
            return
        }
        
        guard !userManager.isUsernameTaken(username) else {
            errorMessage = "Username is already taken"
            showingError = true
            return
        }
        
        isCreating = true
        
        // Create the admin user using UserManager's createUser method
        userManager.createUser(
            username: username,
            password: password,
            isSuperuser: true, // Make this user an admin
            persona: nil,
            allowedModelIds: []
        )
        
        // Authenticate the newly created user to log them in
        if let newUser = userManager.authenticateUser(username: username, password: password) {
            userManager.currentUser = newUser
            setupComplete = true
        } else {
            errorMessage = "Failed to create admin user. Please try again."
            showingError = true
        }
        
        isCreating = false
    }
}