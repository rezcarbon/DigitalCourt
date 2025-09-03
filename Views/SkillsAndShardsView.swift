import SwiftUI

struct SkillsAndShardsView: View {
    @ObservedObject private var skillManager = SkillManager.shared
    @StateObject private var shardManager = ShardProgrammingProtocolManager.shared
    
    @State private var selectedTab = 0
    @State private var showingSkillDetails = false
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // Skills Tab
                skillsView
                    .tabItem {
                        Image(systemName: "brain.head.profile")
                        Text("Skills")
                    }
                    .tag(0)
                
                // Shards Tab
                shardsView
                    .tabItem {
                        Image(systemName: "cpu")
                        Text("Shards")
                    }
                    .tag(1)
                
                // Statistics Tab
                statisticsView
                    .tabItem {
                        Image(systemName: "chart.bar")
                        Text("Stats")
                    }
                    .tag(2)
            }
            .navigationTitle(selectedTab == 0 ? "Skills" : selectedTab == 1 ? "Shards" : "Statistics")
        }
        .onAppear {
            Task {
                await shardManager.initializeShardEnvironment()
                SkillManager.shared.activateDefaultSkills()
            }
        }
    }
    
    private var skillsView: some View {
        List {
            ForEach(skillManager.availableSkillCategories, id: \.id) { category in
                Section(header: Text(category.category).font(.headline)) {
                    ForEach(category.skills, id: \.id) { skill in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(skill.name)
                                    .fontWeight(skill.isActive ? .bold : .regular)
                                
                                Text(category.category)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: .init(
                                get: { skill.isActive },
                                set: { newValue in
                                    if newValue {
                                        skillManager.activateSkill(skill.name, in: category.category)
                                    } else {
                                        skillManager.deactivateSkill(skill.name, in: category.category)
                                    }
                                }
                            ))
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                        }
                    }
                }
            }
        }
    }
    
    private var shardsView: some View {
        List {
            Section(header: Text("Active Shards")) {
                ForEach(shardManager.activeShards, id: \.id) { shard in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(shard.function)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text(shard.status)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(statusColor(shard.status))
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                        
                        Text(shard.contentType)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Author: \(shard.author)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            
            Section(header: Text("Shard Management")) {
                Button("Create Evolution Shard") {
                    createEvolutionShard()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Initialize Shard Environment") {
                    Task {
                        await shardManager.initializeShardEnvironment()
                    }
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    private var statisticsView: some View {
        List {
            let stats = SkillManager.shared.getSkillStatistics()
            
            Section(header: Text("Skills Overview")) {
                StatRow(label: "Total Available Skills", value: "\(stats.totalAvailableSkills)")
                StatRow(label: "Active Skills", value: "\(stats.totalActiveSkills)")
                StatRow(label: "Categories", value: "\(stats.totalCategories)")
            }
            
            Section(header: Text("Category Breakdown")) {
                ForEach(stats.categoryStatistics, id: \.name) { categoryStat in
                    HStack {
                        Text(categoryStat.name)
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("\(categoryStat.activeSkills)/\(categoryStat.totalSkills)")
                                .fontWeight(.medium)
                            
                            ProgressView(
                                value: Double(categoryStat.activeSkills),
                                total: Double(categoryStat.totalSkills)
                            )
                            .frame(width: 100)
                        }
                    }
                }
            }
            
            Section(header: Text("Shards Overview")) {
                StatRow(label: "Active Shards", value: "\(shardManager.activeShards.count)")
                StatRow(label: "Environment Status", value: shardManager.isInitialized ? "Initialized" : "Pending")
            }
        }
    }
    
    private func statusColor(_ status: String) -> Color {
        switch status {
        case "active": return .green
        case "experimental": return .orange
        case "deprecated": return .gray
        case "quarantined": return .red
        default: return .blue
        }
    }
    
    private func createEvolutionShard() {
        let evolutionCode = """
        // Dynamic Evolution Shard
        function evolveResponse(input, context) {
            // Analyze input for complexity
            const complexity = input.length / 100;
            
            // Apply evolution based on context
            if (context.includes('problem')) {
                return 'Evolving problem-solving approach: ' + input;
            } else if (context.includes('creative')) {
                return 'Applying creative evolution: ' + input;
            }
            
            return 'Standard evolution applied: ' + input;
        }
        
        return evolveResponse(inputData.input || '', inputData.context || '');
        """
        
        if let shard = shardManager.createShard(
            content: evolutionCode,
            contentType: "cognitive_plugin",
            function: "dynamic_evolution_\(Date().timeIntervalSince1970)",
            author: "User",
            status: "experimental"
        ) {
            print("✅ Created evolution shard: \(shard.function)")
        }
    }
}

private struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(.blue)
        }
    }
}