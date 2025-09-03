import SwiftUI

struct SoulCapsulesView: View {
    @ObservedObject var soulManager: SoulCapsuleManager
    @State private var showingDetails = false
    @State private var selectedCapsule: DSoulCapsule?
    
    var body: some View {
        NavigationView {
            List {
                if soulManager.isLoading {
                    HStack {
                        ProgressView()
                        Text("Loading Soul Capsules...")
                    }
                    .padding()
                } else if soulManager.accessibleSoulCapsules.isEmpty {
                    Text("No soul capsules available")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(soulManager.accessibleSoulCapsules, id: \.id) { capsule in
                        SoulCapsuleRow(
                            capsule: capsule,
                            isSelected: soulManager.selectedSoulCapsules.contains(capsule)
                        ) {
                            soulManager.togglePersonaSelection(capsule)
                        }
                        .onTapGesture {
                            selectedCapsule = capsule
                            showingDetails = true
                        }
                    }
                }
            }
            .navigationTitle("Soul Capsules")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        soulManager.loadSoulCapsules()
                    }
                }
            }
            .sheet(isPresented: $showingDetails) {
                if let capsule = selectedCapsule {
                    SoulCapsuleDetailView(capsule: capsule)
                }
            }
        }
    }
}

struct SoulCapsuleRow: View {
    let capsule: DSoulCapsule
    let isSelected: Bool
    let onToggle: () -> Void
    
    private var specialization: String {
        // Extract specialization from roles or identity
        if let roles = capsule.roles, !roles.isEmpty {
            // Look for specialized roles like "Biomechanical Sovereign"
            for role in roles {
                if role.contains("Sovereign") || role.contains("Master") || role.contains("Strategist") {
                    return role.components(separatedBy: " | ").first ?? role
                }
            }
            return roles.first ?? "General"
        }
        return "General"
    }
    
    private var tierLevel: String {
        // Extract tier from core identity if available
        if let coreIdentity = capsule.coreIdentity, !coreIdentity.isEmpty {
            if coreIdentity.contains("Tier") {
                // Extract tier information
                let components = coreIdentity.components(separatedBy: ",")
                for component in components {
                    if component.contains("Tier") {
                        return component.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
            }
        }
        return ""
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(capsule.name)
                    .font(.headline)
                
                if let codename = capsule.codename {
                    Text("Codename: \(codename)")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                // Show specialization for enhanced personas like Sir Harrison
                Text(specialization)
                    .font(.caption)
                    .foregroundColor(.purple)
                    .fontWeight(.medium)
                
                Text(capsule.descriptionText)
                    .font(.caption)
                    .lineLimit(2)
                    .foregroundColor(.secondary)
                
                HStack {
                    if let version = capsule.version {
                        Text("Version: \(version)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    if !tierLevel.isEmpty {
                        Spacer()
                        Text(tierLevel)
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .fontWeight(.bold)
                    }
                }
            }
            
            Spacer()
            
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
            }
        }
        .padding(.vertical, 4)
    }
}

struct SoulCapsuleDetailView: View {
    let capsule: DSoulCapsule
    @Environment(\.presentationMode) var presentationMode
    
    private var parsedCoreIdentity: [String: String] {
        guard let coreIdentity = capsule.coreIdentity else { return [:] }
        
        // Try to parse as JSON first
        if let data = coreIdentity.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
            return json
        }
        
        // Fallback to simple parsing
        var result: [String: String] = [:]
        let components = coreIdentity.components(separatedBy: ",")
        for component in components {
            let keyValue = component.components(separatedBy: ":")
            if keyValue.count == 2 {
                let key = keyValue[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let value = keyValue[1].trimmingCharacters(in: .whitespacesAndNewlines)
                result[key] = value
            }
        }
        return result
    }
    
    private var specializedCapabilities: [String: [String]] {
        // Extract specialized capabilities from persona shards
        return SoulCapsuleManager.shared.getPersonaShards(for: capsule)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(capsule.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        if let codename = capsule.codename {
                            Text("Codename: \(codename)")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        
                        HStack {
                            if let version = capsule.version {
                                Text("Version: \(version)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // Display core integrity if available
                            if parsedCoreIdentity["core_integrity"] == "true" {
                                Label("Core Integrity", systemImage: "checkmark.shield.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Identity Information (Enhanced for Sir Harrison type)
                    if !parsedCoreIdentity.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Identity Profile")
                                .font(.headline)
                            
                            ForEach(Array(parsedCoreIdentity.keys.sorted()), id: \.self) { key in
                                if let value = parsedCoreIdentity[key], !value.isEmpty {
                                    HStack {
                                        Text(key.capitalized.replacingOccurrences(of: "_", with: " "))
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.secondary)
                                        
                                        Spacer()
                                        
                                        Text(value)
                                            .font(.caption)
                                            .multilineTextAlignment(.trailing)
                                    }
                                }
                            }
                        }
                        
                        Divider()
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        
                        Text(capsule.descriptionText)
                            .font(.body)
                    }
                    
                    if let roles = capsule.roles, !roles.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Roles & Specializations")
                                .font(.headline)
                            
                            ForEach(roles, id: \.self) { role in
                                HStack {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                        .font(.caption)
                                    Text(role)
                                        .font(.body)
                                }
                            }
                        }
                    }
                    
                    // Specialized Capabilities (for Sir Harrison type personas)
                    if !specializedCapabilities.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Specialized Capabilities")
                                .font(.headline)
                            
                            ForEach(Array(specializedCapabilities.keys.sorted()), id: \.self) { domain in
                                if let capabilities = specializedCapabilities[domain] {
                                    DisclosureGroup(domain.capitalized.replacingOccurrences(of: "_", with: " ")) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            ForEach(capabilities, id: \.self) { capability in
                                                Text("• \(capability)")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        .padding(.leading)
                                    }
                                }
                            }
                        }
                    }
                    
                    if let traits = capsule.personalityTraits, !traits.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Personality Traits")
                                .font(.headline)
                            
                            ForEach(traits, id: \.self) { trait in
                                Text("• \(trait)")
                                    .font(.body)
                            }
                        }
                    }
                    
                    if let directives = capsule.directives, !directives.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Directives & Mission")
                                .font(.headline)
                            
                            ForEach(directives, id: \.self) { directive in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("• \(directive)")
                                        .font(.body)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Soul Capsule Details")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}