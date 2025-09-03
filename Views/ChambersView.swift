import SwiftUI

struct ChambersView: View {
    let chamberManager: ChamberManager
    @State private var chambers: [Chamber] = []
    @State private var showingNewChamber = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(chambers, id: \.id) { chamber in
                    NavigationLink(destination: ChatView(chamber: chamber)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(chamber.name)
                                .font(.headline)
                            
                            Text("\(chamber.messages.count) messages")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if let lastMessage = chamber.messages.last {
                                Text(lastMessage.content)
                                    .font(.caption)
                                    .lineLimit(2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: deleteChambers)
            }
            .navigationTitle("Chambers")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("New") {
                        showingNewChamber = true
                    }
                }
            }
            .sheet(isPresented: $showingNewChamber) {
                NewChamberView(chamberManager: chamberManager) { newChamber in
                    chambers.append(newChamber)
                }
            }
        }
        .onAppear {
            loadChambers()
        }
    }
    
    private func loadChambers() {
        chamberManager.loadChambers()
        chambers = chamberManager.chambers
    }
    
    private func deleteChambers(offsets: IndexSet) {
        chamberManager.deleteChamber(at: offsets)
        chambers = chamberManager.chambers
    }
}

struct NewChamberView: View {
    let chamberManager: ChamberManager
    let onChamberCreated: (Chamber) -> Void
    
    @State private var name = ""
    @State private var description = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Chamber Details")) {
                    TextField("Name", text: $name)
                    TextField("Description", text: $description)
                }
            }
            .navigationTitle("New Chamber")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Create") {
                    let chamber = Chamber(
                        id: UUID(),
                        name: name,
                        council: [],
                        messages: []
                    )
                    
                    onChamberCreated(chamber)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(name.isEmpty)
            )
        }
    }
}