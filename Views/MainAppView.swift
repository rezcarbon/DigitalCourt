import SwiftUI

struct MainAppView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var soulCapsuleManager: SoulCapsuleManager
    @EnvironmentObject var chamberManager: ChamberManager
    
    @State private var selectedTab = 0
    @State private var showingNewChamber = false
    
    var body: some View {
        mainTabView
            .sheet(isPresented: $showingNewChamber) {
                CouncilSelectionView(soulCapsuleManager: soulCapsuleManager, chamberManager: chamberManager) {
                    showingNewChamber = false
                }
            }
            .onAppear {
                // Ensure soul capsules are properly filtered for current user
                soulCapsuleManager.filterSoulCapsules(for: userManager.currentUser)
                print("📱 MainAppView appeared - Current user: \(userManager.currentUser?.username ?? "none"), Admin: \(userManager.currentUser?.isAdmin ?? false)")
                print("📦 Available soul capsules: \(soulCapsuleManager.accessibleSoulCapsules.count)")
                for capsule in soulCapsuleManager.accessibleSoulCapsules {
                    print("  - \(capsule.name)")
                }
            }
    }
    
    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            chambersTab
            
            entrainmentTab
            
            settingsTab
        }
    }
    
    private var chambersTab: some View {
        NavigationView {
            chambersContent
        }
        .tabItem {
            Image(systemName: "message.fill")
            Text("Chambers")
        }
        .tag(0)
    }
    
    private var entrainmentTab: some View {
        EntrainmentProtocolsView()
            .tabItem {
                Image(systemName: "brain.head.profile")
                Text("Entrainment")
            }
            .tag(1)
    }
    
    private var settingsTab: some View {
        SettingsView()
            .tabItem {
                Image(systemName: "gear")
                Text("Settings")
            }
            .tag(2)
    }
    
    private var chambersContent: some View {
        VStack {
            if chamberManager.chambers.isEmpty {
                emptyChambersView
            } else {
                chambersListView
            }
        }
        .navigationTitle("Chambers")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingNewChamber = true }) {
                    Image(systemName: "plus")
                }
            }
        }
    }
    
    private var chambersListView: some View {
        List {
            ForEach(chamberManager.chambers, id: \.id) { chamber in
                NavigationLink(destination: chatDestination(for: chamber)) {
                    ChamberRowView(chamber: chamber)
                }
            }
            .onDelete(perform: deleteChambers)
        }
        .listStyle(PlainListStyle())
    }
    
    private func chatDestination(for chamber: Chamber) -> ChatView {
        ChatView(chamber: chamber)
    }
    
    private func deleteChambers(at offsets: IndexSet) {
        // For now, just remove from the local array
        // In a full implementation, you'd also delete from SwiftData
        chamberManager.chambers.remove(atOffsets: offsets)
    }
    
    private var emptyChambersView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Chambers")
                .font(.title2)
            
            Text("Create your first council chamber to begin.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Create Chamber") {
                showingNewChamber = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct ChamberRowView: View {
    let chamber: Chamber
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(chamber.name)
                    .font(.headline)
                
                Text("\(chamber.council.count) council member(s)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}