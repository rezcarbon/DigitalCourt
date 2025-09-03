import Foundation
import UIKit
import BackgroundTasks
import Combine

@MainActor
class PerformanceManager: ObservableObject {
    static let shared = PerformanceManager()
    
    @Published var systemPerformance: SystemPerformance = SystemPerformance()
    @Published var backgroundTasksActive: Int = 0
    
    private let cacheManager = CacheManager.shared
    private let exportService = ExportService.shared
    private var performanceTimer: Timer?
    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = .invalid
    
    init() {
        startPerformanceMonitoring()
        registerBackgroundTasks()
    }
    
    // MARK: - Performance Monitoring
    
    private func startPerformanceMonitoring() {
        performanceTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            Task { @MainActor in
                await self.updateSystemPerformance()
            }
        }
    }
    
    private func updateSystemPerformance() async {
        let memoryUsage = getMemoryUsage()
        let cacheStats = cacheManager.getCacheStatistics()
        
        systemPerformance = SystemPerformance(
            memoryUsage: memoryUsage,
            cacheHitRate: cacheStats.hitRate,
            totalCacheSize: cacheStats.totalSize,
            activeConnections: 1, // Placeholder
            lastUpdated: Date()
        )
    }
    
    private func getMemoryUsage() -> MemoryUsage {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let usedMemory = Int64(info.resident_size)
            let totalMemory = Int64(ProcessInfo.processInfo.physicalMemory)
            
            return MemoryUsage(
                used: usedMemory,
                total: totalMemory,
                percentage: Double(usedMemory) / Double(totalMemory) * 100
            )
        } else {
            return MemoryUsage(used: 0, total: 0, percentage: 0)
        }
    }
    
    // MARK: - Background Task Management
    
    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.digitalcourt.cache-cleanup",
            using: nil
        ) { task in
            Task { @MainActor in
                await self.handleCacheCleanupTask(task as! BGAppRefreshTask)
            }
        }
        
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.digitalcourt.data-sync",
            using: nil
        ) { task in
            Task { @MainActor in
                await self.handleDataSyncTask(task as! BGAppRefreshTask)
            }
        }
    }
    
    private func handleCacheCleanupTask(_ task: BGAppRefreshTask) async {
        backgroundTasksActive += 1
        
        let operation = CacheCleanupOperation()
        
        task.expirationHandler = {
            operation.cancel()
            Task { @MainActor in
                self.backgroundTasksActive -= 1
            }
        }
        
        operation.completionBlock = {
            task.setTaskCompleted(success: !operation.isCancelled)
            Task { @MainActor in
                self.backgroundTasksActive -= 1
            }
        }
        
        OperationQueue().addOperation(operation)
        await scheduleNextCacheCleanup()
    }
    
    private func handleDataSyncTask(_ task: BGAppRefreshTask) async {
        backgroundTasksActive += 1
        
        // Sync critical data
        await performDataSync()
        task.setTaskCompleted(success: true)
        
        backgroundTasksActive -= 1
        await scheduleNextDataSync()
    }
    
    private func scheduleNextCacheCleanup() async {
        let request = BGAppRefreshTaskRequest(identifier: "com.digitalcourt.cache-cleanup")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 24 * 60 * 60) // 24 hours
        
        try? BGTaskScheduler.shared.submit(request)
    }
    
    private func scheduleNextDataSync() async {
        let request = BGAppRefreshTaskRequest(identifier: "com.digitalcourt.data-sync")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes
        
        try? BGTaskScheduler.shared.submit(request)
    }
    
    // MARK: - Background Operations
    
    private func performDataSync() async {
        print("🔄 Performing background data sync...")
        
        // Preload critical data
        await cacheManager.preloadCriticalData()
        
        // Clean up old exports
        await exportService.cleanupOldExports()
        
        print("✅ Background data sync completed")
    }
    
    func optimizePerformance() async {
        print("🚀 Starting performance optimization...")
        
        // Clear expired caches
        cacheManager.clearExpiredCaches()
        
        // Optimize memory usage
        await optimizeMemoryUsage()
        
        // Update performance metrics
        await updateSystemPerformance()
        
        print("✅ Performance optimization completed")
    }
    
    private func optimizeMemoryUsage() async {
        // Force garbage collection and cleanup
        autoreleasepool {
            // Perform memory-intensive cleanup operations
            cacheManager.clearExpiredCaches()
        }
        
        // Allow system to reclaim memory
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
    }
    
    // MARK: - Utility Methods
    
    func getPerformanceReport() -> PerformanceReport {
        return PerformanceReport(
            systemPerformance: systemPerformance,
            cacheStatistics: cacheManager.getCacheStatistics(),
            activeBackgroundTasks: backgroundTasksActive,
            generatedAt: Date()
        )
    }
}

// MARK: - Supporting Types

struct SystemPerformance {
    let memoryUsage: MemoryUsage
    let cacheHitRate: Double
    let totalCacheSize: Int64
    let activeConnections: Int
    let lastUpdated: Date
    
    init() {
        self.memoryUsage = MemoryUsage(used: 0, total: 0, percentage: 0)
        self.cacheHitRate = 0.0
        self.totalCacheSize = 0
        self.activeConnections = 0
        self.lastUpdated = Date()
    }
    
    init(memoryUsage: MemoryUsage, cacheHitRate: Double, totalCacheSize: Int64, activeConnections: Int, lastUpdated: Date) {
        self.memoryUsage = memoryUsage
        self.cacheHitRate = cacheHitRate
        self.totalCacheSize = totalCacheSize
        self.activeConnections = activeConnections
        self.lastUpdated = lastUpdated
    }
}

struct MemoryUsage {
    let used: Int64
    let total: Int64
    let percentage: Double
}

struct PerformanceReport {
    let systemPerformance: SystemPerformance
    let cacheStatistics: CacheStatistics
    let activeBackgroundTasks: Int
    let generatedAt: Date
}

class CacheCleanupOperation: Operation, @unchecked Sendable {
    override func main() {
        guard !isCancelled else { return }
        
        Task { @MainActor in
            CacheManager.shared.clearExpiredCaches()
        }
    }
}