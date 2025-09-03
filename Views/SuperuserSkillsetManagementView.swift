import SwiftUI
import UniformTypeIdentifiers

struct SuperuserSkillsetManagementView: View {
    @StateObject private var skillManager = SkillManager.shared
    @StateObject private var userManager = UserManager.shared
    @State private var isShowingFilePicker = false
    @State private var isShowingCreateSkillsheet = false
    @State private var isShowingEditMode = false
    @State private var alertMessage = ""
    @State private var showingAlert = false
    @State private var selectedCategory: SkillCategory?
    
    // New skill creation
    @State private var newSkillName = ""
    @State private var newSkillCategory = ""
    @State private var newCategoryName = ""
    @State private var isCreatingNewCategory = false
    
    // Skillset export
    @State private var isShowingExportOptions = false
    
    var body: some View {
        NavigationView {
            List {
                if userManager.isAdmin {
                    adminSection
                    skillsetManagementSection
                    importExportSection
                    customSkillCreationSection
                } else {
                    Text("Access Denied")
                        .foregroundColor(.red)
                        .font(.title2)
                }
            }
            .navigationTitle("Skillset Management")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if userManager.isAdmin {
                        Button("Edit Mode") {
                            isShowingEditMode.toggle()
                        }
                    }
                }
            }
            .fileImporter(
                isPresented: $isShowingFilePicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .sheet(isPresented: $isShowingCreateSkillsheet) {
                CreateSkillsheetView(
                    newSkillName: $newSkillName,
                    newSkillCategory: $newSkillCategory,
                    newCategoryName: $newCategoryName,
                    isCreatingNewCategory: $isCreatingNewCategory,
                    availableCategories: skillManager.availableSkillCategories.map { $0.name },
                    onSave: { skillName, category in
                        addCustomSkill(skillName: skillName, category: category)
                    }
                )
            }
            .alert("Skillset Management", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .confirmationDialog("Export Options", isPresented: $isShowingExportOptions) {
                Button("Export All Skillsets") {
                    exportAllSkillsets()
                }
                Button("Export Active Skills Only") {
                    exportActiveSkills()
                }
                Button("Export Custom Skills") {
                    exportCustomSkills()
                }
                Button("Cancel", role: .cancel) { }
            }
        }
    }
    
    private var adminSection: some View {
        Section(header: Text("Superuser Controls").font(.headline)) {
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundColor(.yellow)
                Text("Administrative Access Active")
                    .fontWeight(.medium)
                Spacer()
                Text("User: \(userManager.currentUser?.displayName ?? "Unknown")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
    
    private var skillsetManagementSection: some View {
        Section(header: Text("Current Skillsets").font(.headline)) {
            ForEach(skillManager.availableSkillCategories, id: \.id) { category in
                HStack {
                    VStack(alignment: .leading) {
                        Text(category.name)
                            .fontWeight(.medium)
                        Text("\(category.skills.count) skills")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if isShowingEditMode {
                        Button("Edit") {
                            selectedCategory = category
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    
                    let activeCount = skillManager.getActiveSkills(for: category.name).count
                    Text("\(activeCount) active")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(activeCount > 0 ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                        .cornerRadius(4)
                }
                .padding(.vertical, 2)
            }
        }
    }
    
    private var importExportSection: some View {
        Section(header: Text("Import & Export").font(.headline)) {
            Button(action: {
                isShowingFilePicker = true
            }) {
                Label("Import Skillset JSON", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(.borderedProminent)
            
            Button(action: {
                isShowingExportOptions = true
            }) {
                Label("Export Skillsets", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.bordered)
            
            Button(action: {
                validateAllSkillsets()
            }) {
                Label("Validate Skillsets", systemImage: "checkmark.seal")
            }
            .buttonStyle(.bordered)
        }
    }
    
    private var customSkillCreationSection: some View {
        Section(header: Text("Create Custom Skills").font(.headline)) {
            Button(action: {
                isShowingCreateSkillsheet = true
            }) {
                Label("Add New Skill", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            
            Button(action: {
                createSkillsetTemplate()
            }) {
                Label("Create Skillset Template", systemImage: "doc.badge.plus")
            }
            .buttonStyle(.bordered)
        }
    }
    
    // MARK: - Actions
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            importSkillsetFromFile(url: url)
        case .failure(let error):
            alertMessage = "Failed to import file: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func importSkillsetFromFile(url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let skillset = try JSONDecoder().decode(ComprehensiveSkillSet.self, from: data)
            
            // Merge with existing skillsets
            skillManager.mergeSkillset(skillset)
            
            alertMessage = "Successfully imported skillset: \(skillset.metadata.name)"
            showingAlert = true
            
        } catch {
            alertMessage = "Failed to import skillset: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func addCustomSkill(skillName: String, category: String) {
        let success = skillManager.addCustomSkill(skillName, to: category)
        
        if success {
            alertMessage = "Successfully added skill '\(skillName)' to category '\(category)'"
        } else {
            alertMessage = "Failed to add skill '\(skillName)' (may already exist)"
        }
        showingAlert = true
    }
    
    private func exportAllSkillsets() {
        skillManager.exportSkillsets(type: .all) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let url):
                    alertMessage = "Skillsets exported to: \(url.lastPathComponent)"
                case .failure(let error):
                    alertMessage = "Export failed: \(error.localizedDescription)"
                }
                showingAlert = true
            }
        }
    }
    
    private func exportActiveSkills() {
        skillManager.exportSkillsets(type: .activeOnly) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let url):
                    alertMessage = "Active skills exported to: \(url.lastPathComponent)"
                case .failure(let error):
                    alertMessage = "Export failed: \(error.localizedDescription)"
                }
                showingAlert = true
            }
        }
    }
    
    private func exportCustomSkills() {
        skillManager.exportSkillsets(type: .customOnly) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let url):
                    alertMessage = "Custom skills exported to: \(url.lastPathComponent)"
                case .failure(let error):
                    alertMessage = "Export failed: \(error.localizedDescription)"
                }
                showingAlert = true
            }
        }
    }
    
    private func validateAllSkillsets() {
        let validation = skillManager.validateSkillsets()
        alertMessage = validation.isValid ? 
            "All skillsets are valid ✅" : 
            "Validation failed: \(validation.errors.joined(separator: ", "))"
        showingAlert = true
    }
    
    private func createSkillsetTemplate() {
        skillManager.createSkillsetTemplate { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let url):
                    alertMessage = "Template created at: \(url.lastPathComponent)"
                case .failure(let error):
                    alertMessage = "Template creation failed: \(error.localizedDescription)"
                }
                showingAlert = true
            }
        }
    }
}

struct CreateSkillsheetView: View {
    @Binding var newSkillName: String
    @Binding var newSkillCategory: String
    @Binding var newCategoryName: String
    @Binding var isCreatingNewCategory: Bool
    let availableCategories: [String]
    let onSave: (String, String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Skill Information")) {
                    TextField("Skill Name", text: $newSkillName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Section(header: Text("Category")) {
                    Toggle("Create New Category", isOn: $isCreatingNewCategory)
                    
                    if isCreatingNewCategory {
                        TextField("New Category Name", text: $newCategoryName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    } else {
                        Picker("Select Category", selection: $newSkillCategory) {
                            ForEach(availableCategories, id: \.self) { category in
                                Text(category).tag(category)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                
                Section(header: Text("Preview")) {
                    HStack {
                        Text("Skill:")
                        Spacer()
                        Text(newSkillName.isEmpty ? "Enter skill name" : newSkillName)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Category:")
                        Spacer()
                        Text(isCreatingNewCategory ? 
                             (newCategoryName.isEmpty ? "Enter category name" : newCategoryName) :
                             (newSkillCategory.isEmpty ? "Select category" : newSkillCategory))
                            .fontWeight(.medium)
                    }
                }
            }
            .navigationTitle("Create Skill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let category = isCreatingNewCategory ? newCategoryName : newSkillCategory
                        onSave(newSkillName, category)
                        dismiss()
                    }
                    .disabled(newSkillName.isEmpty || 
                             (isCreatingNewCategory ? newCategoryName.isEmpty : newSkillCategory.isEmpty))
                }
            }
        }
    }
}

#Preview {
    SuperuserSkillsetManagementView()
}