import SwiftUI

struct CouncilSelectionView: View {
    @EnvironmentObject var userManager: UserManager
    @ObservedObject var soulCapsuleManager: SoulCapsuleManager
    @ObservedObject var chamberManager: ChamberManager
    
    @State private var chamberName: String = ""
    @State private var selectionChanged = false
    @State private var isCreatingFusedPersona = false // New state for fused persona creation
    @State private var isCreatingChamber = false // New state for async chamber creation

    var onChamberCreated: () -> Void

    var body: some View {
        NavigationView {
            ZStack {
                LiquidGlassBackground()
                
                VStack {
                    if soulCapsuleManager.accessibleSoulCapsules.isEmpty {
                        emptyStateView
                    } else {
                        formView
                    }
                }
            }
            .navigationTitle("New Council Chamber")
            .toolbar {
                toolbarItems
            }
        }
        .disabled(isCreatingChamber) // Disable UI during chamber creation
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3.sequence")
                .font(.system(size: 60))
            Text("No Personas Available")
                .font(.title2)
            
            if userManager.currentUser?.isAdmin == true {
                Text("Debug Info: You are logged in as admin '\(userManager.currentUser?.username ?? "unknown")' but no personas are loaded.")
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
                Text("Your account does not have access to any personas. Please contact an administrator to get access.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button("Force Reload Personas") {
                soulCapsuleManager.reloadAllPersonas()
                soulCapsuleManager.filterSoulCapsules(for: userManager.currentUser)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .onAppear {
            soulCapsuleManager.debugCurrentState()
        }
    }
    
    private var formView: some View {
        Form {
            Section(header: Text("Council Chamber Name")) {
                TextField("Chamber Name", text: $chamberName)
            }
            .listRowBackground(Color.clear.glassMorphism(opacity: 0.2))
            
            Section(header: Text("Select Council Members")) {
                List {
                    ForEach(Array(soulCapsuleManager.accessibleSoulCapsules), id: \.id) { capsule in
                        Button(action: {
                            soulCapsuleManager.togglePersonaSelection(capsule)
                            selectionChanged.toggle()
                        }) {
                            HStack {
                                Text(capsule.name)
                                Spacer()
                                if soulCapsuleManager.selectedSoulCapsules.contains(capsule) {
                                    Image(systemName: "checkmark.circle.fill")
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
                .listRowBackground(Color.clear.glassMorphism(opacity: 0.2))
            }
            
            // New section for persona fusion option
            if soulCapsuleManager.selectedSoulCapsules.count > 1 {
                Section(header: Text("Persona Fusion")) {
                    Toggle("Create Fused Persona", isOn: $isCreatingFusedPersona)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }
                .listRowBackground(Color.clear.glassMorphism(opacity: 0.2))
            }
        }
        .scrollContentBackground(.hidden)
    }

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Cancel") { onChamberCreated() }
        }
        
        ToolbarItem(placement: .topBarLeading) {
            Button("Refresh") {
                soulCapsuleManager.filterSoulCapsules(for: userManager.currentUser)
                print("🔄 Manual refresh - User: \(userManager.currentUser?.username ?? "none"), Admin: \(userManager.currentUser?.isAdmin ?? false)")
                print("📦 Soul capsules after refresh: \(soulCapsuleManager.accessibleSoulCapsules.count)")
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Create") {
                Task {
                    await createChamber()
                }
            }
            .disabled(soulCapsuleManager.selectedSoulCapsules.isEmpty || chamberName.isEmpty || isCreatingChamber)
        }
    }
    
    private func createChamber() async {
        isCreatingChamber = true
        defer { isCreatingChamber = false }
        
        if isCreatingFusedPersona && soulCapsuleManager.selectedSoulCapsules.count > 1 {
            // Create fused persona chamber
            await chamberManager.createFusedPersonaChamber(
                name: chamberName,
                soulCapsules: soulCapsuleManager.selectedSoulCapsules
            )
        } else {
            // Create regular council chamber
            await chamberManager.createCouncilChamber(
                name: chamberName,
                soulCapsules: soulCapsuleManager.selectedSoulCapsules
            )
        }
        onChamberCreated()
    }
}