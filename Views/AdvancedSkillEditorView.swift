import SwiftUI

struct AdvancedSkillEditorView: View {
    @StateObject private var skillManager = SkillManager.shared
    @Environment(\.dismiss) private var dismiss
    
    let category: SkillCategory
    @State private var editedSkills: [String]
    @State private var newSkillName = ""
    @State private var showingAddSkill = false
    @State private var skillToDelete: String?
    @State private var showingDeleteAlert = false
    @State private var editingSkillIndex: Int?
    @State private var editedSkillName = ""
    
    init(category: SkillCategory) {
        self.category = category
        // Convert Skill objects to strings for editing
        self._editedSkills = State(initialValue: category.skills.map { $0.name })
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Category: \(category.name)")) {
                    ForEach(editedSkills.indices, id: \.self) { index in
                        HStack {
                            if editingSkillIndex == index {
                                TextField("Skill name", text: $editedSkillName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .onSubmit {
                                        saveEditedSkill(at: index)
                                    }
                                
                                Button("Save") {
                                    saveEditedSkill(at: index)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                
                                Button("Cancel") {
                                    cancelEdit()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                
                            } else {
                                VStack(alignment: .leading) {
                                    Text(editedSkills[index])
                                        .fontWeight(.medium)
                                    
                                    let activeSkills = skillManager.getActiveSkills(for: category.name)
                                    let isActive = activeSkills.contains { $0.name == editedSkills[index] }
                                    
                                    Text(isActive ? "Currently Active" : "Inactive")
                                        .font(.caption)
                                        .foregroundColor(isActive ? .green : .secondary)
                                }
                                
                                Spacer()
                                
                                Button("Edit") {
                                    startEdit(at: index)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                
                                Button("Delete") {
                                    skillToDelete = editedSkills[index]
                                    showingDeleteAlert = true
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .foregroundColor(.red)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    
                    // Add new skill row
                    if showingAddSkill {
                        HStack {
                            TextField("New skill name", text: $newSkillName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onSubmit {
                                    addNewSkill()
                                }
                            
                            Button("Add") {
                                addNewSkill()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            .disabled(newSkillName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            
                            Button("Cancel") {
                                showingAddSkill = false
                                newSkillName = ""
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    } else {
                        Button(action: {
                            showingAddSkill = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add New Skill")
                            }
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                Section(header: Text("Category Actions")) {
                    Button("Export Category") {
                        exportCategory()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Validate Skills") {
                        validateSkills()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Reset to Original") {
                        resetToOriginal()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.orange)
                }
            }
            .navigationTitle("Edit Skills")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save Changes") {
                        saveChanges()
                    }
                    .fontWeight(.medium)
                }
            }
            .alert("Delete Skill", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    if let skill = skillToDelete {
                        deleteSkill(skill)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                if let skill = skillToDelete {
                    Text("Are you sure you want to delete '\(skill)'? This action cannot be undone.")
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func startEdit(at index: Int) {
        editingSkillIndex = index
        editedSkillName = editedSkills[index]
    }
    
    private func saveEditedSkill(at index: Int) {
        let trimmedName = editedSkillName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty && !editedSkills.contains(trimmedName) {
            editedSkills[index] = trimmedName
        }
        cancelEdit()
    }
    
    private func cancelEdit() {
        editingSkillIndex = nil
        editedSkillName = ""
    }
    
    private func addNewSkill() {
        let trimmedName = newSkillName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty && !editedSkills.contains(trimmedName) {
            editedSkills.append(trimmedName)
            editedSkills.sort()
        }
        showingAddSkill = false
        newSkillName = ""
    }
    
    private func deleteSkill(_ skillName: String) {
        editedSkills.removeAll { $0 == skillName }
        skillToDelete = nil
    }
    
    private func saveChanges() {
        // First, remove all original skills from this category
        for skill in category.skills {
            skillManager.removeSkill(skill.name, from: category.name)
        }
        
        // Then add all edited skills
        for skillName in editedSkills {
            _ = skillManager.addCustomSkill(skillName, to: category.name)
        }
        
        dismiss()
    }
    
    private func resetToOriginal() {
        editedSkills = category.skills.map { $0.name }
    }
    
    private func exportCategory() {
        skillManager.exportSkillsets(type: .all) { result in
            // Handle export result
            switch result {
            case .success(let url):
                print("✅ Exported category to: \(url)")
            case .failure(let error):
                print("❌ Export failed: \(error)")
            }
        }
    }
    
    private func validateSkills() {
        let hasEmptySkills = editedSkills.contains { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let hasDuplicates = Set(editedSkills).count != editedSkills.count
        
        var validationMessage = ""
        if hasEmptySkills {
            validationMessage += "• Empty skill names found\n"
        }
        if hasDuplicates {
            validationMessage += "• Duplicate skills found\n"
        }
        
        if validationMessage.isEmpty {
            validationMessage = "✅ All skills are valid"
        }
        
        print(validationMessage)
    }
}

// Preview
struct AdvancedSkillEditorView_Previews: PreviewProvider {
    static var previews: some View {
        AdvancedSkillEditorView(
            category: SkillCategory(
                name: "Communication",
                skills: [
                    Skill(name: "Active Listening", category: "Communication"),
                    Skill(name: "Clarity", category: "Communication"),
                    Skill(name: "Empathy", category: "Communication")
                ]
            )
        )
    }
}