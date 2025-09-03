import SwiftUI

struct PerformanceView: View {
    @EnvironmentObject var performanceManager: PerformanceManager
    @EnvironmentObject var cacheManager: CacheManager
    
    @State private var showingDetailedReport = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Performance Overview
                performanceOverviewSection
                
                // Memory Usage
                memoryUsageSection
                
                // Cache Performance
                cachePerformanceSection
                
                // Background Tasks
                backgroundTasksSection
                
                // Quick Actions
                quickActionsSection
            }
            .padding()
        }
        .navigationTitle("Performance")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button("Optimize") {
                    Task {
                        await performanceManager.optimizePerformance()
                    }
                }
                
                Button("Report") {
                    showingDetailedReport = true
                }
            }
        }
        .sheet(isPresented: $showingDetailedReport) {
            PerformanceReportView(report: performanceManager.getPerformanceReport())
        }
    }
    
    private var performanceOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("System Performance")
                .font(.headline)
            
            HStack(spacing: 20) {
                PerformanceGauge(
                    title: "Memory",
                    value: performanceManager.systemPerformance.memoryUsage.percentage,
                    color: memoryColor,
                    format: "%.0f%%"
                )
                
                PerformanceGauge(
                    title: "Cache Hit Rate",
                    value: cacheManager.cacheHitRate * 100,
                    color: cacheColor,
                    format: "%.1f%%"
                )
                
                PerformanceGauge(
                    title: "Background Tasks",
                    value: Double(performanceManager.backgroundTasksActive),
                    color: .blue,
                    format: "%.0f"
                )
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var memoryUsageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Memory Usage")
                .font(.headline)
            
            let memoryUsage = performanceManager.systemPerformance.memoryUsage
            
            VStack(spacing: 8) {
                ProgressView(value: memoryUsage.percentage / 100.0) {
                    HStack {
                        Text("Used Memory")
                        Spacer()
                        Text("\(formatBytes(memoryUsage.used)) / \(formatBytes(memoryUsage.total))")
                    }
                    .font(.caption)
                }
                .tint(memoryColor)
                
                HStack {
                    Text("Usage: \(String(format: "%.1f%%", memoryUsage.percentage))")
                        .font(.caption)
                    
                    Spacer()
                    
                    Text(memoryStatus)
                        .font(.caption)
                        .foregroundColor(memoryColor)
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var cachePerformanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cache Performance")
                .font(.headline)
            
            let stats = cacheManager.getCacheStatistics()
            
            VStack(spacing: 8) {
                HStack {
                    Text("Hit Rate")
                    Spacer()
                    Text("\(String(format: "%.1f%%", stats.hitRate * 100))")
                        .foregroundColor(cacheColor)
                }
                
                HStack {
                    Text("Total Size")
                    Spacer()
                    Text(formatBytes(stats.totalSize))
                }
                
                HStack {
                    Text("Messages Cached")
                    Spacer()
                    Text("\(stats.messagesCached)")
                }
                
                HStack {
                    Text("Images Cached")
                    Spacer()
                    Text("\(stats.imagesCached)")
                }
            }
            .font(.caption)
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var backgroundTasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Background Tasks")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Active Tasks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(performanceManager.backgroundTasksActive)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Status")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(backgroundTaskStatus)
                        .font(.caption)
                        .foregroundColor(backgroundTaskColor)
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionButton(
                    title: "Clear Cache",
                    icon: "trash",
                    color: .red
                ) {
                    cacheManager.clearAllCaches()
                }
                
                QuickActionButton(
                    title: "Optimize Memory",
                    icon: "memorychip",
                    color: .blue
                ) {
                    Task {
                        await performanceManager.optimizePerformance()
                    }
                }
                
                QuickActionButton(
                    title: "Preload Data",
                    icon: "arrow.down.circle",
                    color: .green
                ) {
                    Task {
                        await cacheManager.preloadCriticalData()
                    }
                }
                
                QuickActionButton(
                    title: "Export Logs",
                    icon: "doc.text",
                    color: .orange
                ) {
                    // Export performance logs
                }
            }
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Properties
    
    private var memoryColor: Color {
        let percentage = performanceManager.systemPerformance.memoryUsage.percentage
        if percentage < 70 { return .green }
        else if percentage < 85 { return .orange }
        else { return .red }
    }
    
    private var cacheColor: Color {
        let hitRate = cacheManager.cacheHitRate
        if hitRate > 0.8 { return .green }
        else if hitRate > 0.6 { return .orange }
        else { return .red }
    }
    
    private var memoryStatus: String {
        let percentage = performanceManager.systemPerformance.memoryUsage.percentage
        if percentage < 70 { return "Good" }
        else if percentage < 85 { return "Fair" }
        else { return "Critical" }
    }
    
    private var backgroundTaskStatus: String {
        let count = performanceManager.backgroundTasksActive
        if count == 0 { return "Idle" }
        else if count < 3 { return "Active" }
        else { return "Busy" }
    }
    
    private var backgroundTaskColor: Color {
        let count = performanceManager.backgroundTasksActive
        if count == 0 { return .green }
        else if count < 3 { return .blue }
        else { return .orange }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: bytes)
    }
}

struct PerformanceGauge: View {
    let title: String
    let value: Double
    let color: Color
    let format: String
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                
                Circle()
                    .trim(from: 0, to: min(value / 100.0, 1.0))
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                Text(String(format: format, value))
                    .font(.caption)
                    .fontWeight(.bold)
            }
            .frame(width: 60, height: 60)
            
            Text(title)
                .font(.caption2)
                .multilineTextAlignment(.center)
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(color)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PerformanceReportView: View {
    let report: PerformanceReport
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Performance Report")
                        .font(.title)
                        .padding()
                    
                    // Detailed metrics would go here
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Generated: \(DateFormatter.readable.string(from: report.generatedAt))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("System performance metrics and recommendations would be displayed here in a production app.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    
                    Spacer()
                }
            }
            .navigationTitle("Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Dismiss
                    }
                }
            }
        }
    }
}