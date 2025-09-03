import Foundation
import SwiftData
import Combine

@MainActor
class BrainManager: ObservableObject {
    @Published var brains: [DBrain] = []
    
    private var modelContext: ModelContext?
    private let versionManager = VersionManager.shared
    
    init() {
        setupModelContext()
    }
    
    private func setupModelContext() {
        do {
            // Updated to include all model types
            let container = try ModelContainer(
                for: DSoulCapsule.self, 
                DBrain.self, 
                DMessage.self, 
                DChatChamber.self, 
                DMemoryMetadata.self, 
                SensoryInputModule.self, 
                EmotionalCore.self, 
                ExecutiveOversight.self, 
                SkillInfusionLayer.self, 
                REvolutionEngine.self, 
                AISheetsIntegration.self
            )
            self.modelContext = container.mainContext
        } catch {
            print("Failed to create model container: \(error)")
        }
    }
    
    func initializeEnhancedBrain(named name: String, with soulCapsule: DSoulCapsule, seed: String) -> DBrain {
        let brain = DBrain(name: name, positronicCoreSeed: seed, soulCapsule: soulCapsule)
        
        // Initialize modules based on system version
        initializeModules(for: brain)
        
        // Add to context if available
        if let context = modelContext {
            context.insert(brain)
        }
        
        return brain
    }
    
    private func initializeModules(for brain: DBrain) {
        // Initialize modules that are available based on version
        let availableModules = BrainLoader.shared.getEnhancedBootSequenceData().availableModules
        
        // Create module instances based on what's available
        if availableModules.contains("SensoryInput"), let context = modelContext {
            let sensoryModule = SensoryInputModule(sensoryType: "boot_initialization")
            context.insert(sensoryModule)
        }
        
        if availableModules.contains("EmotionalCore"), let context = modelContext {
            let emotionalModule = EmotionalCore(emotionType: "initialization", intensity: 0.5, context: "brain_boot")
            context.insert(emotionalModule)
        }
        
        if availableModules.contains("ExecutiveOversight"), let context = modelContext {
            let oversightModule = ExecutiveOversight(
                goal: "System Initialization",
                priority: 10,
                ethicalAlignmentScore: 1.0
            )
            context.insert(oversightModule)
        }
        
        // Initialize skill layers with version tracking
        if availableModules.contains("SkillInfusion"), let context = modelContext {
            // Get the current version of the SkillInfusion module
            let skillInfusionVersion = versionManager.getVersion(for: "SkillInfusion")?.description ?? "1.0.0"
            
            let skillLayer = SkillInfusionLayer(
                skillName: "SystemInitialization",
                category: "adaptive",
                proficiencyLevel: 1.0,
                version: skillInfusionVersion
            )
            context.insert(skillLayer)
        }
        
        // Initialize evolution engine
        if availableModules.contains("RZeroEvolution"), let context = modelContext {
            let evolutionEngine = REvolutionEngine(
                cycleNumber: 0,
                improvementType: "system_initialization",
                beforeScore: 0.0,
                afterScore: 1.0,
                algorithm: "initial_boot"
            )
            context.insert(evolutionEngine)
        }
        
        // Initialize AI Sheets Integration
        if availableModules.contains("AISheetsIntegration"), let context = modelContext {
            let aiSheets = AISheetsIntegration(
                sheetID: "system_boot_\(UUID().uuidString)",
                modelName: "default",
                taskType: "initialization",
                version: versionManager.getVersion(for: "AISheetsIntegration")?.description ?? "1.0.0"
            )
            context.insert(aiSheets)
        }
    }
    
    func saveBrain(_ brain: DBrain) {
        // Save is automatic with SwiftData, but we can explicitly save if needed
        try? modelContext?.save()
    }
    
    /// Update a brain's modules after a system update
    func updateBrainModules(_ brain: DBrain) {
        // Reinitialize modules with new versions
        initializeModules(for: brain)
        
        // Update brain timestamp
        // brain.lastUpdated = Date()
    }
}