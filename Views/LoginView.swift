import SwiftUI

struct LoginView: View {
    @EnvironmentObject var userManager: UserManager
    @State private var username = ""
    @State private var password = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isLoggingIn = false

    var body: some View {
        ZStack {
            // Dark background
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Your custom Sith Empire logo
                VStack(spacing: 20) {
                    DigitalCourtLogo.login()
                    
                    Text("Digital Court")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Enter your credentials to proceed.")
                        .font(.body)
                        .foregroundColor(.gray)
                }
                
                // Login form with dark styling
                VStack(spacing: 15) {
                    TextField("Username", text: $username)
                        .textFieldStyle(DarkTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .textContentType(.username)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(DarkTextFieldStyle())
                        .textContentType(.password)
                }
                .padding(.horizontal, 40)
                
                if isLoggingIn {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .red))
                        .scaleEffect(1.2)
                        .padding(.top)
                } else {
                    Button("Login") {
                        login()
                    }
                    .buttonStyle(SithButtonStyle())
                    .disabled(username.isEmpty || password.isEmpty)
                    .padding(.horizontal, 40)
                    .padding(.top)
                }
                
                // Admin login hint with dark styling
                VStack(spacing: 4) {
                    Text("Admin Login:")
                        .font(.caption)
                        .foregroundColor(.red.opacity(0.8))
                        .fontWeight(.semibold)
                    
                    Text("Username: Infinite")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.gray)
                    
                    Text("Password: immortal")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red.opacity(0.1))
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
                
                Spacer()
            }
            .padding()
            
            // DEBUG: Visible user list for development
            #if DEBUG
            VStack(alignment: .leading, spacing: 10) {
                Text("🛠 Debug Users:")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)
                
                ScrollView(.vertical, showsIndicators: true) {
                    ForEach(userManager.users, id: \.id) { user in
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(user.username) \(user.isAdmin ? "[admin]" : "") \(user.isActive ? "✔️" : "❌")")
                                .font(.caption2)
                                .foregroundColor(.white)
                            if let hash = user.passwordHash {
                                Text("hash:\n\(hash)")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                .frame(maxHeight: 100)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10).fill(Color.yellow.opacity(0.15))
            )
            .padding(.vertical, 8)
            #endif
            
        }
        .preferredColorScheme(.dark)
        .alert("Login Failed", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func login() {
        isLoggingIn = true
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        Task {
            do {
                try await userManager.login(username: username, password: password)
                // Login successful - the view will update automatically
                await MainActor.run {
                    isLoggingIn = false
                    
                    // Success haptic feedback
                    let successFeedback = UINotificationFeedbackGenerator()
                    successFeedback.notificationOccurred(.success)
                }
            } catch {
                // Login failed
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showingError = true
                    self.isLoggingIn = false
                    
                    // Error haptic feedback
                    let errorFeedback = UINotificationFeedbackGenerator()
                    errorFeedback.notificationOccurred(.error)
                }
            }
        }
    }
}

// MARK: - Custom Styles

struct DarkTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.1))
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .foregroundColor(.white)
            .font(.system(size: 16))
    }
}

struct SithButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [
                        configuration.isPressed ? Color.red.opacity(0.8) : Color.red,
                        configuration.isPressed ? Color.red.opacity(0.6) : Color.red.opacity(0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundColor(.white)
            .font(.system(size: 16, weight: .semibold))
            .cornerRadius(10)
            .shadow(
                color: .red.opacity(0.4), 
                radius: configuration.isPressed ? 2 : 5,
                y: configuration.isPressed ? 1 : 3
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(UserManager.shared)
            .preferredColorScheme(.dark)
    }
}