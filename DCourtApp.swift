import SwiftUI
import SwiftData
import FirebaseCore

@main
struct DCourtApp: App {
    @StateObject private var userManager = UserManager.shared
    @StateObject private var soulCapsuleManager = SoulCapsuleManager.shared
    @State private var shouldShowLaunchScreen = true
    @State private var chamberManager: ChamberManager?
    @State private var initialSetupComplete = false
    
    init() {
        // Configure Firebase on app launch
        FirebaseApp.configure()
        print("🔥 Firebase configured successfully")
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if userManager.isLoggedIn {
                    if let chamberManager = chamberManager {
                        MainAppView()
                            .modelContainer(for: [
                                DBrain.self,
                                DSoulCapsule.self,
                                DChatChamber.self
                            ])
                            .environmentObject(userManager)
                            .environmentObject(soulCapsuleManager)
                            .environmentObject(chamberManager)
                            .onAppear {
                                setupModelContext()
                            }
                    } else {
                        ProgressView("Initializing...")
                            .progressViewStyle(CircularProgressViewStyle(tint: .red))
                            .scaleEffect(1.2)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black)
                            .onAppear {
                                setupChamberManager()
                            }
                    }
                } else if !userManager.hasUsers {
                    // Show initial setup if no users exist
                    InitialSetupView(setupComplete: $initialSetupComplete)
                        .environmentObject(userManager)
                        .onChange(of: initialSetupComplete) {
                            // Setup completed - user should now be logged in
                        }
                } else {
                    // Show login screen if users exist but no one is logged in
                    LoginView()
                        .environmentObject(userManager)
                }
                
                // Show launch screen logo during initial load
                if shouldShowLaunchScreen {
                    LaunchScreenLogo()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: shouldShowLaunchScreen)
            .animation(.easeInOut(duration: 0.3), value: userManager.hasUsers)
            .animation(.easeInOut(duration: 0.3), value: userManager.isLoggedIn)
            .onAppear {
                // Hide launch screen after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    shouldShowLaunchScreen = false
                }
            }
            .preferredColorScheme(.dark) // Force dark mode
        }
    }
    
    private func setupModelContext() {
        // Setup any additional model context configuration here
        print("🔧 Model context setup completed")
    }
    
    private func setupChamberManager() {
        Task { @MainActor in
            do {
                // Create a temporary model container to initialize ChamberManager
                let container = try ModelContainer(for: DBrain.self, DSoulCapsule.self, DChatChamber.self)
                let context = ModelContext(container)
                
                // Initialize SwiftDataMemoryManager with the context
                SwiftDataMemoryManager.shared.setup(with: context)
                
                self.chamberManager = ChamberManager(modelContext: context)
                
                // Auto-load the bundled model
                await BundledModelManager.shared.autoLoadBestModel()
                
            } catch {
                print("❌ Failed to setup model container: \(error)")
                // Fallback initialization
                self.chamberManager = ChamberManager(modelContext: nil)
            }
        }
    }
}