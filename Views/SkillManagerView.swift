import SwiftUI
import Charts

struct SkillManagerView: View {
    @ObservedObject var manager = SkillManager.shared
    @State private var newCategory = ""
    @State private var newSkill = ""
    @State private var categoryToEdit: SkillCategory?
    @State private var showEditCat = false
    @State private var skillToEdit: Skill?
    @State private var showEditSkill = false

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Skill Analytics")
                            .font(.title2)
                        Text("Active Skills: \(manager.activeSkills.count) / \(manager.getAllSkills().count)")
                            .font(.caption)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                
                Chart {
                    ForEach(manager.categories, id: \.id) { c in
                        BarMark(x: .value("Skills", c.skills.count), y: .value("Category", c.name))
                    }
                }
                .frame(height: 120)
                .padding()

                Chart {
                    ForEach(manager.categories, id: \.id) { c in
                        if c.skills.count > 0 {
                            SectorMark(angle: .value("Count", c.skills.count), innerRadius: .ratio(0.6))
                                .foregroundStyle(Color.random(for: c.name))
                                .annotation(position: .overlay) { Text(c.name).font(.caption2) }
                        }
                    }
                }
                .frame(height: 150)
                .padding()

                List {
                    // Add Category
                    Section {
                        HStack {
                            TextField("New Category Name", text: $newCategory)
                            Button("Add") {
                                guard !newCategory.isEmpty else { return }
                                manager.addCategory(newCategory)
                                newCategory = ""
                            }
                        }
                    }
                    // Category List - Use SwiftUI.ForEach explicitly
                    SwiftUI.ForEach(manager.categories) { category in
                        Section(header:
                            HStack{
                                Text(category.name)
                                Spacer()
                                Button {
                                    categoryToEdit = category
                                    showEditCat = true
                                } label: {
                                    Image(systemName: "pencil").foregroundColor(.orange)
                                }
                            }
                        ) {
                            HStack {
                                TextField("New Skill Name", text: $newSkill)
                                Button("Add") {
                                    guard !newSkill.isEmpty else { return }
                                    manager.addSkill(newSkill, to: category.name)
                                    newSkill = ""
                                }
                            }
                            SwiftUI.ForEach(category.skills) { skill in
                                HStack {
                                    Text(skill.name)
                                    Spacer()
                                    Toggle("Active", isOn: Binding(
                                        get: { skill.isActive },
                                        set: { val in
                                            if val { manager.activateSkill(skill.name, in: category.name) }
                                            else   { manager.deactivateSkill(skill.name, in: category.name) }
                                        }
                                    )).labelsHidden()
                                    Button {
                                        skillToEdit = skill
                                        showEditSkill = true
                                    } label: {
                                        Image(systemName: "pencil").foregroundColor(.blue)
                                    }
                                    Button(role: .destructive) {
                                        manager.removeSkill(skill.name, from: category.name)
                                    } label: {
                                        Image(systemName: "trash").foregroundColor(.red)
                                    }
                                }
                            }
                            Button(role: .destructive) {
                                manager.removeCategory(category.name)
                            } label: {
                                Text("Delete \(category.name) Category").foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Skill Manager")
            .sheet(item: $categoryToEdit) { cat in
                EditCategorySheet(category: cat)
            }
            .sheet(item: $skillToEdit) { skill in
                EditSkillSheet(skill: skill)
            }
        }
    }
}

struct EditCategorySheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var manager = SkillManager.shared
    @State var category: SkillCategory
    @State private var newName: String = ""

    var body: some View {
        VStack {
            Text("Edit Category Name")
            TextField("Name", text: $newName)
                .padding()
            Button("Save") {
                if !newName.isEmpty {
                    manager.removeCategory(category.name)
                    manager.addCategory(newName)
                    dismiss()
                }
            }
            .padding()
            Button("Cancel") { dismiss() }
        }
        .onAppear { newName = category.name }
        .padding()
    }
}

struct EditSkillSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var manager = SkillManager.shared
    @State var skill: Skill
    @State private var newName: String = ""

    var body: some View {
        VStack {
            Text("Edit Skill Name")
            TextField("Name", text: $newName)
                .padding()
            Button("Save") {
                if !newName.isEmpty {
                    manager.removeSkill(skill.name, from: skill.category)
                    manager.addSkill(newName, to: skill.category)
                    dismiss()
                }
            }
            .padding()
            Button("Cancel") { dismiss() }
        }
        .onAppear { newName = skill.name }
        .padding()
    }
}

extension Color {
    static func random(for string: String) -> Color {
        let v = abs(string.hashValue)
        let hue = Double(v % 256)/255.0
        return Color(hue: hue, saturation: 0.6, brightness: 0.8)
    }
}