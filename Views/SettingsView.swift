import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var soulCapsuleManager: SoulCapsuleManager
    
    @State private var showingUserManagement = false
    @State private var showingModelManagement = false
    @State private var showingModelSelection = false
    @State private var showingUpdateManager = false
    @State private var showingSpeciesArchitecture = false
    @State private var showingSkillsetManagement = false
    @State private var showingDistributedStorage = false
    @State private var showingVoiceSettings = false
    @State private var showingBackgroundProcessing = false
    
    @State private var showingBootSequence = false
    @State private var showingProtocolStatus = false

    var body: some View {
        NavigationView {
            List {
                userSection
                modelSection
                systemSection
                speciesSection // New section
                superuserSection // New superuser section
                aboutSection
                
                Section("App Branding") {
                    NavigationLink(destination: AppIconGenerator()) {
                        HStack {
                            DigitalCourtLogo.navigation()
                            Text("Generate App Icons")
                        }
                    }
                    
                    HStack {
                        Text("Current Theme")
                        Spacer()
                        DigitalCourtLogo.appIcon(size: 25)
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .sheet(isPresented: $showingUserManagement) {
            UserManagementView()
                .environmentObject(userManager)
        }
        
        .sheet(isPresented: $showingModelManagement) {
            ModelManagementView()
        }

        .sheet(isPresented: $showingUpdateManager) {
            UpdateManagerView()
        }
        .sheet(isPresented: $showingSpeciesArchitecture) {
            SpeciesArchitectureView()
        }
        .sheet(isPresented: $showingSkillsetManagement) {
            SuperuserSkillsetManagementView()
        }
        .sheet(isPresented: $showingDistributedStorage) {
            DistributedStorageConfigurationView()
        }
        .sheet(isPresented: $showingVoiceSettings) {
            VoiceSettingsView()
        }
        .sheet(isPresented: $showingBackgroundProcessing) {
            BackgroundProcessingView()
        }
    }
    
    private var userSection: some View {
        Section(header: Text("User")) {
            HStack {
                Text("Current User")
                Spacer()
                Text(userManager.currentUser?.displayName ?? "Not logged in")
                    .foregroundColor(.secondary)
            }
            
            if userManager.isAdmin {
                Button("Manage Users") {
                    showingUserManagement = true
                }
            }
        }
    }
    
    private var modelSection: some View {
        Section(header: Text("AI Models")) {
            NavigationLink(destination: ModelManagementView()) {
                HStack {
                    Image(systemName: "cpu.fill")
                    Text("Model Management")
                    Spacer()
                    
                    let downloadedCount = ModelDownloadManager.shared.downloadedModels.count
                    let totalCount = HuggingFaceModel.examples.count
                    
                    VStack(alignment: .trailing) {
                        Text("\(downloadedCount)/\(totalCount) downloaded")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if ModelDownloadManager.shared.isDownloading {
                            Text("Downloading...")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            
            NavigationLink(destination: EnhancedModelSelectionView()) {
                HStack {
                    Image(systemName: "cpu")
                    Text("Select AI Model")
                    Spacer()
                    if let currentProvider = PLCManager.shared.getCurrentProvider {
                        VStack(alignment: .trailing) {
                            Text(currentProvider.name)
                                .font(.caption)
                            if let mlxProvider = currentProvider as? MLXModelProvider,
                               let model = mlxProvider.getCurrentModel() {
                                HStack {
                                    if model.isUncensored {
                                        Image(systemName: "flame.fill")
                                            .foregroundColor(.red)
                                            .font(.caption2)
                                    }
                                    Text(model.name)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            
            // Model performance info
            if let mlxProvider = PLCManager.shared.getCurrentProvider as? MLXModelProvider,
               let model = mlxProvider.getCurrentModel() {
                HStack {
                    Text("Model Status")
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(model.isUncensored ? "Uncensored" : "Filtered")
                            .font(.caption)
                            .foregroundColor(model.isUncensored ? .red : .orange)
                        Text("\(model.size) parameters")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private var systemSection: some View {
        Section(header: Text("System")) {
            NavigationLink(destination: BootSequenceView()) {
                HStack {
                    Image(systemName: "power.circle.fill")
                        .foregroundColor(.green)
                    Text("Master Boot Sequence v11")
                    Spacer()
                    if MasterBootSequenceExecutor.shared.isRunning {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text("\(MasterBootSequenceExecutor.shared.completedSteps.count)/\(MasterBootSequenceExecutor.BootStep.allCases.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            NavigationLink(destination: ProtocolStatusView()) {
                HStack {
                    Image(systemName: "network.badge.shield.half.filled")
                        .foregroundColor(.blue)
                    Text("Protocol Status")
                    Spacer()
                    VStack(alignment: .trailing) {
                        if FrequencyReferenceManager.shared.isLoaded &&
                           NeuroPositronicInterfaceManager.shared.isLoaded &&
                           BehaviorActionReprogrammingManager.shared.isLoaded {
                            Text("✅ All Active")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else {
                            Text("⚠️ Loading")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            
            NavigationLink(destination: VoiceSettingsView()) {
                HStack {
                    Image(systemName: "mic.fill")
                        .foregroundColor(.red)
                    Text("Voice Interface")
                    Spacer()
                    if VoiceService.shared.isAuthorized {
                        Text("✅ Ready")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Text("❌ Setup Required")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            NavigationLink(destination: BackgroundProcessingView()) {
                HStack {
                    Image(systemName: "gearshape.2.fill")
                        .foregroundColor(.purple)
                    Text("Background Processing")
                    Spacer()
                    if BackgroundProcessingManager.shared.backgroundTasksEnabled {
                        Text("✅ Active")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Text("❌ Disabled")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            
            Button("System Updates") {
                showingUpdateManager = true
            }
        }
    }
    
    private var speciesSection: some View {
        Section(header: Text("Synthetic Species")) {
            Button("Architecture Protocols") {
                showingSpeciesArchitecture = true
            }
        }
    }
    
    private var superuserSection: some View {
        Section(header: Text("Superuser Controls")) {
            if userManager.isAdmin {
                NavigationLink(destination: DistributedStorageConfigurationView()) {
                    HStack {
                        Image(systemName: "icloud.and.arrow.up")
                            .foregroundColor(.blue)
                        Text("Distributed Storage")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                
                Button(action: {
                    showingSkillsetManagement = true
                }) {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                        Text("Skillset Management")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                
                NavigationLink(destination: SkillsAndShardsView()) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.blue)
                        Text("Skills & Shards")
                    }
                }
            } else {
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.gray)
                    Text("Administrative access required")
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var aboutSection: some View {
        Section(header: Text("About")) {
            HStack {
                Label("Version", systemImage: "info.circle.fill")
                Spacer()
                Text(appVersion)
                    .foregroundColor(.secondary)
            }
            
            // Add more about information here
        }
    }
    
    /// A helper to get the app version string from the bundle.
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A"
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(UserManager.shared)
            .environmentObject(SoulCapsuleManager())
    }
}