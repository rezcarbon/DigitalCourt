//
//  ContentView.swift
//  DCourt
//
//  Created by M Reezan M Fadzil on 10/08/2025.
//

import SwiftUI
import SwiftData
import Combine

struct ContentView: View {
    @StateObject private var userManager = UserManager.shared
    @StateObject private var soulManager = SoulCapsuleManager.shared
    
    // Don't initialize VoiceService immediately to avoid privacy crash
    // @StateObject private var voiceService = VoiceService.shared
    
    // Enhanced services - make these optional to prevent initialization issues
    @StateObject private var cacheManager = CacheManager.shared
    @StateObject private var exportService = ExportService.shared
    @StateObject private var collaborationService = CollaborationService.shared
    @StateObject private var performanceManager = PerformanceManager.shared
    
    // Add login state management
    @State private var tempUsername = ""
    @State private var tempPassword = ""
    @State private var chamberManager: ChamberManager?
    @State private var modelContainer: ModelContainer?
    @State private var initializationStep = "Starting..."
    @State private var hasError = false
    @State private var errorMessage = ""
    @State private var showAdminInterface = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Add the logo at the top
                DigitalCourtLogo.navigation(size: 120)
                    .padding(.top, 20)
                
                // ... existing content ...
            }
            .navigationTitle("Digital Court")
            .background(Color.black.ignoresSafeArea())
        }
    }
}

struct FeatureChip: View {
    let icon: String
    let text: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)
            Text(text)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    ContentView()
}