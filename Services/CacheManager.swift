import Foundation
import Combine
import UIKit
import SwiftData

@MainActor
class CacheManager: ObservableObject {
    static let shared = CacheManager()
    
    // Message caching
    private var messageCache: [UUID: [Message]] = [:]
    private var messageCacheTimestamp: [UUID: Date] = [:]
    
    // Image caching - keep on main actor but use async methods
    private let imageCache = NSCache<NSString, UIImage>()
    private let imageCacheQueue = DispatchQueue(label: "com.digitalcourt.imagecache", qos: .utility)
    
    // Data caching - keep on main actor
    private let dataCache = NSCache<NSString, NSData>()
    
    // Soul capsule caching
    private var soulCapsuleCache: [DSoulCapsule] = []
    private var soulCapsuleCacheTimestamp: Date?
    
    // Performance metrics
    @Published var cacheHitRate: Double = 0.0
    @Published var totalCacheSize: Int64 = 0
    
    private var cacheHits: Int = 0
    private var cacheMisses: Int = 0
    
    // Cache configuration
    private let messageCacheExpiry: TimeInterval = 3600 // 1 hour
    private let imageCacheExpiry: TimeInterval = 86400 // 24 hours
    private let maxCacheSize: Int64 = 100 * 1024 * 1024 // 100MB
    
    init() {
        setupCacheConfiguration()
        startCacheCleanupTimer()
    }
    
    // MARK: - Setup
    
    private func setupCacheConfiguration() {
        imageCache.countLimit = 100
        imageCache.totalCostLimit = 50 * 1024 * 1024 // 50MB for images
        
        dataCache.countLimit = 50
        dataCache.totalCostLimit = 25 * 1024 * 1024 // 25MB for data
    }
    
    private func startCacheCleanupTimer() {
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in // Every 5 minutes
            Task { @MainActor in
                self.performCacheCleanup()
            }
        }
    }
    
    // MARK: - Message Caching
    
    func cacheMessages(_ messages: [Message], for chamberId: UUID) {
        messageCache[chamberId] = messages
        messageCacheTimestamp[chamberId] = Date()
        recordCacheWrite()
    }
    
    func getCachedMessages(for chamberId: UUID) -> [Message]? {
        guard let timestamp = messageCacheTimestamp[chamberId],
              Date().timeIntervalSince(timestamp) < messageCacheExpiry else {
            recordCacheMiss()
            return nil
        }
        
        recordCacheHit()
        return messageCache[chamberId]
    }
    
    func invalidateMessagesCache(for chamberId: UUID) {
        messageCache.removeValue(forKey: chamberId)
        messageCacheTimestamp.removeValue(forKey: chamberId)
    }
    
    // MARK: - Image Caching
    
    func cacheImage(_ image: UIImage, for key: String) async {
        let cost = estimateImageSize(image)
        
        // Cache on main actor to avoid threading issues
        imageCache.setObject(image, forKey: key as NSString, cost: cost)
        
        recordCacheWrite()
        updateTotalCacheSize()
    }
    
    func getCachedImage(for key: String) -> UIImage? {
        if let image = imageCache.object(forKey: key as NSString) {
            recordCacheHit()
            return image
        } else {
            recordCacheMiss()
            return nil
        }
    }
    
    func cacheImageData(_ data: Data, for key: String) {
        dataCache.setObject(data as NSData, forKey: key as NSString, cost: data.count)
        recordCacheWrite()
        updateTotalCacheSize()
    }
    
    func getCachedImageData(for key: String) -> Data? {
        if let data = dataCache.object(forKey: key as NSString) {
            recordCacheHit()
            return data as Data
        } else {
            recordCacheMiss()
            return nil
        }
    }
    
    // MARK: - Soul Capsule Caching
    
    func cacheSoulCapsules(_ capsules: [DSoulCapsule]) {
        soulCapsuleCache = capsules
        soulCapsuleCacheTimestamp = Date()
        recordCacheWrite()
    }
    
    func getCachedSoulCapsules() -> [DSoulCapsule]? {
        guard let timestamp = soulCapsuleCacheTimestamp,
              Date().timeIntervalSince(timestamp) < messageCacheExpiry else {
            recordCacheMiss()
            return nil
        }
        
        recordCacheHit()
        return soulCapsuleCache
    }
    
    // MARK: - Generic Data Caching
    
    func cacheData<T: Codable>(_ data: T, for key: String, expiry: TimeInterval = 3600) async {
        do {
            let encodedData = try JSONEncoder().encode(data)
            let cacheItem = CacheItem(data: encodedData, timestamp: Date(), expiry: expiry)
            let itemData = try JSONEncoder().encode(cacheItem)
            
            // Cache directly on main actor to avoid threading issues
            dataCache.setObject(itemData as NSData, forKey: key as NSString, cost: itemData.count)
            
            recordCacheWrite()
            updateTotalCacheSize()
        } catch {
            print("Failed to cache data for key \(key): \(error)")
        }
    }
    
    func getCachedData<T: Codable>(for key: String, type: T.Type) -> T? {
        guard let cachedData = dataCache.object(forKey: key as NSString) as? Data else {
            recordCacheMiss()
            return nil
        }
        
        do {
            let cacheItem = try JSONDecoder().decode(CacheItem.self, from: cachedData)
            
            // Check if expired
            if Date().timeIntervalSince(cacheItem.timestamp) > cacheItem.expiry {
                dataCache.removeObject(forKey: key as NSString)
                recordCacheMiss()
                return nil
            }
            
            let decodedData = try JSONDecoder().decode(type, from: cacheItem.data)
            recordCacheHit()
            return decodedData
        } catch {
            print("Failed to decode cached data for key \(key): \(error)")
            recordCacheMiss()
            return nil
        }
    }
    
    // MARK: - Performance Monitoring
    
    private func recordCacheHit() {
        cacheHits += 1
        updateCacheHitRate()
    }
    
    private func recordCacheMiss() {
        cacheMisses += 1
        updateCacheHitRate()
    }
    
    private func recordCacheWrite() {
        // Could be used for write performance monitoring
    }
    
    private func updateCacheHitRate() {
        let totalRequests = cacheHits + cacheMisses
        cacheHitRate = totalRequests > 0 ? Double(cacheHits) / Double(totalRequests) : 0.0
    }
    
    private func updateTotalCacheSize() {
        // Estimate total cache size
        var size: Int64 = 0
        
        // Messages cache size estimation
        for messages in messageCache.values {
            size += Int64(messages.count * 500) // Rough estimate per message
        }
        
        // Image cache size is handled by NSCache's totalCostLimit
        size += Int64(imageCache.totalCostLimit)
        size += Int64(dataCache.totalCostLimit)
        
        totalCacheSize = size
    }
    
    // MARK: - Cache Management
    
    func clearAllCaches() {
        messageCache.removeAll()
        messageCacheTimestamp.removeAll()
        imageCache.removeAllObjects()
        dataCache.removeAllObjects()
        soulCapsuleCache.removeAll()
        soulCapsuleCacheTimestamp = nil
        
        cacheHits = 0
        cacheMisses = 0
        updateCacheHitRate()
        updateTotalCacheSize()
    }
    
    func clearExpiredCaches() {
        performCacheCleanup()
    }
    
    private func performCacheCleanup() {
        let now = Date()
        
        // Clean expired message caches
        for (chamberId, timestamp) in messageCacheTimestamp {
            if now.timeIntervalSince(timestamp) > messageCacheExpiry {
                messageCache.removeValue(forKey: chamberId)
                messageCacheTimestamp.removeValue(forKey: chamberId)
            }
        }
        
        // Clean expired soul capsule cache
        if let timestamp = soulCapsuleCacheTimestamp,
           now.timeIntervalSince(timestamp) > messageCacheExpiry {
            soulCapsuleCache.removeAll()
            soulCapsuleCacheTimestamp = nil
        }
        
        // NSCache handles its own memory pressure cleanup
        updateTotalCacheSize()
    }
    
    // MARK: - Utility Methods
    
    private func estimateImageSize(_ image: UIImage) -> Int {
        return Int(image.size.width * image.size.height * 4) // Assuming 4 bytes per pixel
    }
    
    func getCacheStatistics() -> CacheStatistics {
        return CacheStatistics(
            hitRate: cacheHitRate,
            totalSize: totalCacheSize,
            messagesCached: messageCache.count,
            imagesCached: imageCache.countLimit,
            dataCached: dataCache.countLimit
        )
    }
    
    // MARK: - Background Processing
    
    func preloadCriticalData() async {
        // Preload frequently accessed data in background
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                // Preload recent messages for active chambers
                // This would integrate with your actual data source
                print("Preloading critical data...")
            }
        }
    }
}

// MARK: - Supporting Types

private struct CacheItem: Codable {
    let data: Data
    let timestamp: Date
    let expiry: TimeInterval
}

struct CacheStatistics {
    let hitRate: Double
    let totalSize: Int64
    let messagesCached: Int
    let imagesCached: Int
    let dataCached: Int
}