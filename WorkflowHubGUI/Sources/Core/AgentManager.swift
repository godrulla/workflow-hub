import Foundation
import SwiftUI
import Combine

/// Focused manager for Elite Agent state and operations
/// Implements ZEN's performance optimization recommendations for state management
@MainActor
class AgentManager: ObservableObject {
    static let shared = AgentManager()
    
    // MARK: - Published Properties
    @Published var agents: [EliteAgent] = []
    @Published var selectedAgent: EliteAgent?
    @Published var agentMetrics: [String: AgentMetrics] = [:]
    @Published var lastUpdate: Date = Date()
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let performanceManager = PerformanceManager.shared
    private let updateQueue = DispatchQueue(label: "agent-manager-updates", qos: .userInitiated)
    
    // MARK: - Adaptive Update Management
    private var updateTimer: Timer?
    private let baseUpdateInterval: TimeInterval = 2.0
    
    private init() {
        setupEliteAgents()
        startAdaptiveUpdates()
        bindToPerformanceManager()
    }
    
    // MARK: - Agent Management
    private func setupEliteAgents() {
        agents = [
            EliteAgent(
                name: "ARQ",
                specialization: ["System Architecture", "Technical Design", "Infrastructure Planning"],
                status: .executing,
                currentTask: "System Architecture Review",
                progress: 0.65,
                lastActivity: Date().addingTimeInterval(-300),
                expertiseLevel: 0.95,
                currentLoad: 3,
                maxParallelTasks: 5
            ),
            EliteAgent(
                name: "ORC",
                specialization: ["Workflow Management", "Task Orchestration", "Process Optimization"],
                status: .executing,
                currentTask: "Workflow Orchestration",
                progress: 0.80,
                lastActivity: Date().addingTimeInterval(-150),
                expertiseLevel: 0.92,
                currentLoad: 2,
                maxParallelTasks: 4
            ),
            EliteAgent(
                name: "ZEN",
                specialization: ["Performance Optimization", "System Efficiency", "Resource Management"],
                status: .executing,
                currentTask: "Performance Analysis",
                progress: 0.45,
                lastActivity: Date().addingTimeInterval(-60),
                expertiseLevel: 0.98,
                currentLoad: 1,
                maxParallelTasks: 3
            ),
            EliteAgent(
                name: "VEX",
                specialization: ["Code Implementation", "Quality Assurance", "Technical Execution"],
                status: .executing,
                currentTask: "Code Quality Review",
                progress: 0.55,
                lastActivity: Date().addingTimeInterval(-90),
                expertiseLevel: 0.90,
                currentLoad: 4,
                maxParallelTasks: 6
            ),
            EliteAgent(
                name: "SAGE",
                specialization: ["Strategic Planning", "Business Analysis", "Decision Support"],
                status: .idle,
                currentTask: nil,
                progress: 0.0,
                lastActivity: Date().addingTimeInterval(-900),
                expertiseLevel: 0.94,
                currentLoad: 0,
                maxParallelTasks: 3
            ),
            EliteAgent(
                name: "NOVA",
                specialization: ["Innovation", "Creative Solutions", "Future Vision"],
                status: .idle,
                currentTask: nil,
                progress: 0.0,
                lastActivity: Date().addingTimeInterval(-1800),
                expertiseLevel: 0.88,
                currentLoad: 0,
                maxParallelTasks: 2
            ),
            EliteAgent(
                name: "ECHO",
                specialization: ["Communication", "Context Management", "Information Flow"],
                status: .completed,
                currentTask: nil,
                progress: 0.0,
                lastActivity: Date().addingTimeInterval(-30),
                expertiseLevel: 0.91,
                currentLoad: 0,
                maxParallelTasks: 4
            )
        ]
        
        // Initialize metrics for all agents
        for agent in agents {
            agentMetrics[agent.name] = AgentMetrics(
                agentId: agent.name,
                tasksCompleted: Int.random(in: 15...50),
                averageExecutionTime: TimeInterval.random(in: 30...300),
                successRate: Double.random(in: 0.85...0.99),
                resourceUtilization: Double.random(in: 0.3...0.8)
            )
        }
    }
    
    // MARK: - Performance-Optimized Updates
    private func startAdaptiveUpdates() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: adaptiveUpdateInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updateAgentStates()
            }
        }
    }
    
    private var adaptiveUpdateInterval: TimeInterval {
        let activityLevel = calculateSystemActivity()
        switch activityLevel {
        case .intensive: return baseUpdateInterval * 0.5
        case .active: return baseUpdateInterval * 0.75
        case .normal: return baseUpdateInterval
        case .idle: return baseUpdateInterval * 2.0
        }
    }
    
    private func calculateSystemActivity() -> ActivityLevel {
        let totalLoad = agents.reduce(0) { $0 + $1.currentLoad }
        let activeAgents = agents.filter { $0.status == .executing }.count
        
        if totalLoad > 15 || activeAgents > 5 {
            return .intensive
        } else if totalLoad > 8 || activeAgents > 3 {
            return .active
        } else if totalLoad > 0 || activeAgents > 0 {
            return .normal
        } else {
            return .idle
        }
    }
    
    // MARK: - State Updates
    @MainActor
    private func updateAgentStates() async {
        let updatedAgents = self.agents.map { agent -> EliteAgent in
            var updatedAgent = agent
            
            // Simulate realistic agent activity
            if agent.status == .executing {
                // Occasionally complete tasks
                if Double.random(in: 0...1) < 0.1 {
                    updatedAgent.currentLoad = max(0, agent.currentLoad - 1)
                    updatedAgent.lastActivity = Date()
                }
                
                // Occasionally get new tasks
                if Double.random(in: 0...1) < 0.05 && agent.currentLoad < agent.maxParallelTasks {
                    updatedAgent.currentLoad = agent.currentLoad + 1
                    updatedAgent.lastActivity = Date()
                }
            }
            
            // Update status based on load
            if updatedAgent.currentLoad == 0 {
                updatedAgent.status = .idle
            } else if updatedAgent.currentLoad >= updatedAgent.maxParallelTasks {
                updatedAgent.status = .executing
            } else {
                updatedAgent.status = .executing
            }
            
            return updatedAgent
        }
        
        self.agents = updatedAgents
        self.lastUpdate = Date()
        self.updateAgentMetrics()
    }
    
    private func updateAgentMetrics() {
        for agent in agents {
            if var metrics = agentMetrics[agent.name] {
                // Update metrics based on current state
                metrics.resourceUtilization = Double(agent.currentLoad) / Double(agent.maxParallelTasks)
                
                // Simulate metric updates
                if agent.status == .executing {
                    metrics.tasksCompleted += Int.random(in: 0...1)
                    metrics.averageExecutionTime = metrics.averageExecutionTime * 0.95 + TimeInterval.random(in: 20...60) * 0.05
                    metrics.successRate = min(0.99, metrics.successRate + Double.random(in: -0.01...0.02))
                }
                
                agentMetrics[agent.name] = metrics
            }
        }
    }
    
    // MARK: - Performance Manager Integration
    private func bindToPerformanceManager() {
        performanceManager.$currentMetrics
            .receive(on: DispatchQueue.main)
            .sink { [weak self] metrics in
                self?.adjustUpdateFrequency(based: metrics)
            }
            .store(in: &cancellables)
    }
    
    private func adjustUpdateFrequency(based metrics: PerformanceMetrics) {
        // Reduce update frequency if system is under pressure
        if metrics.cpuUsage > 0.8 || metrics.memoryUsageMB > 800 {
            updateTimer?.invalidate()
            updateTimer = Timer.scheduledTimer(withTimeInterval: baseUpdateInterval * 3.0, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    await self?.updateAgentStates()
                }
            }
        } else if metrics.cpuUsage < 0.3 && metrics.memoryUsageMB < 300 {
            updateTimer?.invalidate()
            updateTimer = Timer.scheduledTimer(withTimeInterval: baseUpdateInterval * 0.5, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    await self?.updateAgentStates()
                }
            }
        }
    }
    
    // MARK: - Agent Operations
    func assignTask(_ task: AgentTask, to agentName: String) {
        guard let agentIndex = agents.firstIndex(where: { $0.name == agentName }) else { return }
        var agent = agents[agentIndex]
        
        if agent.currentLoad < agent.maxParallelTasks {
            agent.currentLoad += 1
            agent.status = .executing
            agent.lastActivity = Date()
            agents[agentIndex] = agent
        }
    }
    
    func completeTask(for agentName: String) {
        guard let agentIndex = agents.firstIndex(where: { $0.name == agentName }) else { return }
        var agent = agents[agentIndex]
        
        agent.currentLoad = max(0, agent.currentLoad - 1)
        agent.lastActivity = Date()
        
        if agent.currentLoad == 0 {
            agent.status = .idle
        }
        
        agents[agentIndex] = agent
        
        // Update metrics
        if var metrics = agentMetrics[agentName] {
            metrics.tasksCompleted += 1
            agentMetrics[agentName] = metrics
        }
    }
    
    func getAvailableAgent(for task: AgentTask) -> EliteAgent? {
        return agents
            .filter { $0.currentLoad < $0.maxParallelTasks }
            .filter { task.requiredSpecializations.isEmpty || !Set(task.requiredSpecializations).isDisjoint(with: Set($0.specialization)) }
            .sorted { $0.currentLoad < $1.currentLoad }
            .first
    }
    
    func getAgentMetrics(for agentName: String) -> AgentMetrics? {
        return agentMetrics[agentName]
    }
    
    // MARK: - Cleanup
    deinit {
        updateTimer?.invalidate()
        cancellables.removeAll()
    }
}

// MARK: - Supporting Types

struct AgentTask {
    let id = UUID()
    let title: String
    let description: String
    let priority: TaskPriority
    let requiredSpecializations: [String]
    let estimatedDuration: TimeInterval
    let deadline: Date?
}

struct AgentMetrics {
    let agentId: String
    var tasksCompleted: Int
    var averageExecutionTime: TimeInterval
    var successRate: Double
    var resourceUtilization: Double
    
    var efficiency: Double {
        return successRate * (1.0 - resourceUtilization)
    }
    
    var formattedSuccessRate: String {
        return String(format: "%.1f%%", successRate * 100)
    }
    
    var formattedResourceUtilization: String {
        return String(format: "%.0f%%", resourceUtilization * 100)
    }
}

enum TaskPriority: Int, CaseIterable, Codable {
    case low = 1
    case normal = 2
    case high = 3
    case critical = 4
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .normal: return "Normal"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .gray
        case .normal: return .blue
        case .high: return .orange
        case .critical: return .red
        }
    }
}