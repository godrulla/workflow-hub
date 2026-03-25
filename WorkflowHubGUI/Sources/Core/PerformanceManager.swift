import Foundation
import SwiftUI

/// Performance management and optimization utilities
/// Implements ZEN's performance optimization recommendations
class PerformanceManager: ObservableObject {
    static let shared = PerformanceManager()
    
    // MARK: - Performance Metrics
    @Published var currentMetrics = PerformanceMetrics()
    
    // MARK: - Memory Management
    private let conversationHistoryManager = ConversationHistoryManager()
    private let memoryPressureMonitor = MemoryPressureMonitor()
    
    // MARK: - Adaptive Update Management
    private var updateFrequency: UpdateFrequency = .normal
    private var activityLevel: ActivityLevel = .normal
    
    private init() {
        startPerformanceMonitoring()
        configureMemoryPressureHandling()
    }
    
    // MARK: - Performance Monitoring
    private func startPerformanceMonitoring() {
        Timer.scheduledTimer(withTimeInterval: adaptiveUpdateInterval, repeats: true) { [weak self] _ in
            self?.updatePerformanceMetrics()
        }
    }
    
    private var adaptiveUpdateInterval: TimeInterval {
        switch activityLevel {
        case .idle: return 5.0
        case .normal: return 1.0
        case .active: return 0.5
        case .intensive: return 0.1
        }
    }
    
    private func updatePerformanceMetrics() {
        let startTime = CFAbsoluteTimeGetCurrent()

        // Get session count safely on main actor
        Task { @MainActor in
            let sessionCount = getActiveSessionCount()

            currentMetrics = PerformanceMetrics(
                memoryUsage: getCurrentMemoryUsage(),
                cpuUsage: getCurrentCPUUsage(),
                activeProcessCount: getActiveProcessCount(),
                sessionCount: sessionCount,
                lastUpdateTime: Date(),
                updateLatency: CFAbsoluteTimeGetCurrent() - startTime
            )

            // Adjust activity level based on metrics
            adjustActivityLevel()
        }
    }
    
    private func adjustActivityLevel() {
        let cpuThreshold: Double = 0.7
        let memoryThreshold: Int64 = 500_000_000 // 500MB
        
        if currentMetrics.cpuUsage > cpuThreshold || currentMetrics.memoryUsage > memoryThreshold {
            activityLevel = .intensive
        } else if currentMetrics.activeProcessCount > 2 {
            activityLevel = .active
        } else if currentMetrics.activeProcessCount == 0 {
            activityLevel = .idle
        } else {
            activityLevel = .normal
        }
    }
    
    // MARK: - Memory Management
    func optimizeMemoryUsage() {
        conversationHistoryManager.pruneOldConversations()
        memoryPressureMonitor.handleMemoryPressure()
        
        // Force garbage collection if memory usage is high
        if currentMetrics.memoryUsage > 1_000_000_000 { // 1GB
            triggerGarbageCollection()
        }
    }
    
    private func triggerGarbageCollection() {
        // Implement aggressive memory cleanup
        DispatchQueue.global(qos: .utility).async {
            // Clear caches and temporary data
            URLCache.shared.removeAllCachedResponses()
            
            // Notify main thread of memory cleanup
            DispatchQueue.main.async { [weak self] in
                self?.updatePerformanceMetrics()
            }
        }
    }
    
    private func configureMemoryPressureHandling() {
        memoryPressureMonitor.onMemoryPressure = { [weak self] level in
            self?.handleMemoryPressure(level)
        }
    }
    
    private func handleMemoryPressure(_ level: MemoryPressureLevel) {
        switch level {
        case .normal:
            break
        case .warning:
            conversationHistoryManager.pruneOldConversations()
        case .critical:
            optimizeMemoryUsage()
        }
    }
    
    // MARK: - System Metrics
    private func getCurrentMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        return result == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }
    
    private func getCurrentCPUUsage() -> Double {
        var info = processor_info_array_t(bitPattern: 0)
        var numCpuInfo = mach_msg_type_number_t()
        var numCpus = natural_t()
        
        let result = host_processor_info(mach_host_self(),
                                       PROCESSOR_CPU_LOAD_INFO,
                                       &numCpus,
                                       &info,
                                       &numCpuInfo)
        
        guard result == KERN_SUCCESS else { return 0.0 }
        
        // Calculate CPU usage (simplified)
        return Double.random(in: 0.1...0.8) // Placeholder implementation
    }
    
    private func getActiveProcessCount() -> Int {
        // Get count from ProcessExecutor
        return ProcessExecutor.shared?.activeProcessCount ?? 0
    }
    
    @MainActor
    private func getActiveSessionCount() -> Int {
        // Get count from AppStateManager
        return AppStateManager.shared.sessions?.count ?? 0
    }
}

// MARK: - Supporting Types

struct PerformanceMetrics {
    let memoryUsage: Int64
    let cpuUsage: Double
    let activeProcessCount: Int
    let sessionCount: Int
    let lastUpdateTime: Date
    let updateLatency: TimeInterval
    
    init(
        memoryUsage: Int64 = 0,
        cpuUsage: Double = 0.0,
        activeProcessCount: Int = 0,
        sessionCount: Int = 0,
        lastUpdateTime: Date = Date(),
        updateLatency: TimeInterval = 0.0
    ) {
        self.memoryUsage = memoryUsage
        self.cpuUsage = cpuUsage
        self.activeProcessCount = activeProcessCount
        self.sessionCount = sessionCount
        self.lastUpdateTime = lastUpdateTime
        self.updateLatency = updateLatency
    }
    
    var memoryUsageMB: Double {
        return Double(memoryUsage) / 1_000_000
    }
    
    var formattedMemoryUsage: String {
        return String(format: "%.1f MB", memoryUsageMB)
    }
    
    var formattedCPUUsage: String {
        return String(format: "%.1f%%", cpuUsage * 100)
    }
}

enum UpdateFrequency {
    case high, normal, low
}

enum ActivityLevel {
    case idle, normal, active, intensive
}

enum MemoryPressureLevel {
    case normal, warning, critical
}

// MARK: - Conversation History Manager

class ConversationHistoryManager {
    private let maxHistoryItems = 1000
    private let pruneThreshold = 800
    private let maxAge: TimeInterval = 7 * 24 * 3600 // 7 days
    
    func pruneOldConversations() {
        // Implementation would prune old conversation history
        // This is a placeholder for the actual implementation
        print("Pruning old conversation history...")
    }
    
    func addMessage(_ message: ClaudeMessage, to session: inout ClaudeSession) {
        session.conversationHistory.append(message)
        
        if session.conversationHistory.count > maxHistoryItems {
            let removeCount = session.conversationHistory.count - pruneThreshold
            session.conversationHistory.removeFirst(removeCount)
        }
    }
    
    func getRecentContext(from session: ClaudeSession, messageCount: Int = 10) -> [ClaudeMessage] {
        return Array(session.conversationHistory.suffix(messageCount))
    }
}

// MARK: - Memory Pressure Monitor

class MemoryPressureMonitor {
    var onMemoryPressure: ((MemoryPressureLevel) -> Void)?
    
    func handleMemoryPressure() {
        let currentUsage = getCurrentMemoryUsage()
        let level = determineMemoryPressureLevel(usage: currentUsage)
        onMemoryPressure?(level)
    }
    
    private func getCurrentMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        return result == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }
    
    private func determineMemoryPressureLevel(usage: Int64) -> MemoryPressureLevel {
        let warningThreshold: Int64 = 500_000_000  // 500MB
        let criticalThreshold: Int64 = 1_000_000_000 // 1GB
        
        if usage > criticalThreshold {
            return .critical
        } else if usage > warningThreshold {
            return .warning
        } else {
            return .normal
        }
    }
}

// MARK: - ProcessExecutor Extension

extension ProcessExecutor {
    static weak var shared: ProcessExecutor?
}

// MARK: - AppStateManager Extension

extension AppStateManager {
    var sessions: [ClaudeSession]? {
        // Return sessions if available
        return nil // Placeholder
    }
}