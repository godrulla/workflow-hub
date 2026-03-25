import Foundation
import SwiftUI
import Combine

/// Focused manager for Project state and operations
/// Implements ZEN's performance optimization recommendations for project management
@MainActor
class ProjectManager: ObservableObject {
    static let shared = ProjectManager()
    
    // MARK: - Published Properties
    @Published var projects: [Project] = []
    @Published var selectedProject: Project?
    @Published var projectMetrics: [String: ProjectMetrics] = [:]
    @Published var lastUpdate: Date = Date()
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let performanceManager = PerformanceManager.shared
    private let updateQueue = DispatchQueue(label: "project-manager-updates", qos: .userInitiated)
    
    // MARK: - Update Management
    private var updateTimer: Timer?
    private let baseUpdateInterval: TimeInterval = 5.0 // Projects update less frequently
    
    private init() {
        setupSampleProjects()
        startPeriodicUpdates()
        bindToPerformanceManager()
    }
    
    // MARK: - Project Setup
    private func setupSampleProjects() {
        projects = [
            Project(
                name: "Exxede Investments",
                type: "Investment Platform",
                status: .production,
                priority: 4,
                completion: 0.95,
                agentTeam: ["ARQ", "SAGE", "ZEN"],
                lastModified: Date().addingTimeInterval(-3600),
                health: .excellent
            ),
            Project(
                name: "ReppingDR",
                type: "Social Platform",
                status: .development,
                priority: 3,
                completion: 0.75,
                agentTeam: ["VEX", "NOVA", "ECHO"],
                lastModified: Date().addingTimeInterval(-1800),
                health: .good
            ),
            Project(
                name: "Prolici",
                type: "Productivity Suite",
                status: .development,
                priority: 3,
                completion: 0.85,
                agentTeam: ["ORC", "ZEN", "VEX"],
                lastModified: Date().addingTimeInterval(-7200),
                health: .good
            ),
            Project(
                name: "Exxede.dev",
                type: "Development Platform",
                status: .planning,
                priority: 2,
                completion: 0.35,
                agentTeam: ["ARQ", "NOVA"],
                lastModified: Date().addingTimeInterval(-86400),
                health: .planning
            ),
            Project(
                name: "WorkflowHub GUI",
                type: "AI Agent Interface",
                status: .development,
                priority: 4,
                completion: 0.65,
                agentTeam: ["ARQ", "VEX", "ZEN", "ECHO"],
                lastModified: Date().addingTimeInterval(-300),
                health: .good
            ),
            Project(
                name: "Dominican Tourism Tech",
                type: "Tourism Platform",
                status: .planning,
                priority: 2,
                completion: 0.15,
                agentTeam: ["SAGE", "NOVA"],
                lastModified: Date().addingTimeInterval(-172800),
                health: .planning
            ),
            Project(
                name: "Context Engineering MCP",
                type: "AI Infrastructure",
                status: .production,
                priority: 3,
                completion: 0.90,
                agentTeam: ["ARQ", "ECHO", "ZEN"],
                lastModified: Date().addingTimeInterval(-900),
                health: .excellent
            ),
            Project(
                name: "Elite Agents System",
                type: "AI Agent Framework",
                status: .development,
                priority: 4,
                completion: 0.80,
                agentTeam: ["ARQ", "ORC", "ZEN", "VEX", "SAGE", "NOVA", "ECHO"],
                lastModified: Date().addingTimeInterval(-600),
                health: .good
            )
        ]
        
        // Initialize metrics
        for project in projects {
            projectMetrics[project.id.uuidString] = ProjectMetrics(
                projectId: project.id.uuidString,
                velocity: calculateVelocity(for: project),
                burnRate: calculateBurnRate(for: project),
                qualityScore: calculateQualityScore(for: project),
                riskFactor: calculateRiskFactor(for: project)
            )
        }
    }
    
    // MARK: - Metrics Calculations
    private func calculateVelocity(for project: Project) -> Double {
        // Simplified velocity based on completion and time
        let timeSpan = max(1.0, Date().timeIntervalSince(project.lastModified) / 86400) // days
        return project.completion / timeSpan
    }

    private func calculateBurnRate(for project: Project) -> Double {
        // Simplified burn rate based on completion percentage
        return project.completion
    }
    
    private func calculateQualityScore(for project: Project) -> Double {
        let baseScore = project.completion
        let healthBonus = project.health.qualityMultiplier
        return min(1.0, baseScore * healthBonus)
    }
    
    private func calculateRiskFactor(for project: Project) -> Double {
        var risk = 0.0

        // Low completion with high priority increases risk
        if project.completion < 0.5 && project.priority > 3 {
            risk += 0.3
        }

        // Health status affects risk
        switch project.health {
        case .critical: risk += 0.8
        case .warning: risk += 0.4
        case .good: risk += 0.1
        case .excellent, .planning: break
        }

        return min(1.0, risk)
    }
    
    // MARK: - Performance-Optimized Updates
    private func startPeriodicUpdates() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: baseUpdateInterval, repeats: true) { [weak self] _ in
            self?.updateProjectStates()
        }
    }
    
    private func updateProjectStates() {
        updateQueue.async { [weak self] in
            guard let self = self else { return }

            let updatedProjects = self.projects.map { project -> Project in
                var updatedProject = project

                // Simulate project progress for development projects
                if project.status == .development {
                    // Occasionally increase completion
                    if Double.random(in: 0...1) < 0.05 {
                        updatedProject.completion = min(1.0, project.completion + 0.01)
                        updatedProject.lastModified = Date()
                    }
                }

                return updatedProject
            }

            DispatchQueue.main.async {
                self.projects = updatedProjects
                self.lastUpdate = Date()
                self.updateProjectMetrics()
            }
        }
    }
    
    private func updateProjectMetrics() {
        for project in projects {
            let projectId = project.id.uuidString
            projectMetrics[projectId] = ProjectMetrics(
                projectId: projectId,
                velocity: calculateVelocity(for: project),
                burnRate: calculateBurnRate(for: project),
                qualityScore: calculateQualityScore(for: project),
                riskFactor: calculateRiskFactor(for: project)
            )
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
        let newInterval: TimeInterval
        
        if metrics.cpuUsage > 0.8 || metrics.memoryUsageMB > 800 {
            newInterval = baseUpdateInterval * 2.0 // Slow down updates
        } else if metrics.cpuUsage < 0.3 && metrics.memoryUsageMB < 300 {
            newInterval = baseUpdateInterval * 0.75 // Speed up updates
        } else {
            newInterval = baseUpdateInterval
        }
        
        if abs(updateTimer?.timeInterval ?? 0 - newInterval) > 0.1 {
            updateTimer?.invalidate()
            updateTimer = Timer.scheduledTimer(withTimeInterval: newInterval, repeats: true) { [weak self] _ in
                self?.updateProjectStates()
            }
        }
    }
    
    // MARK: - Project Operations
    func createProject(_ project: Project) {
        projects.append(project)
        let projectId = project.id.uuidString
        projectMetrics[projectId] = ProjectMetrics(
            projectId: projectId,
            velocity: calculateVelocity(for: project),
            burnRate: calculateBurnRate(for: project),
            qualityScore: calculateQualityScore(for: project),
            riskFactor: calculateRiskFactor(for: project)
        )
    }
    
    func updateProject(_ project: Project) {
        guard let index = projects.firstIndex(where: { $0.id == project.id }) else { return }
        projects[index] = project
        
        // Update metrics
        let projectId = project.id.uuidString
        projectMetrics[projectId] = ProjectMetrics(
            projectId: projectId,
            velocity: calculateVelocity(for: project),
            burnRate: calculateBurnRate(for: project),
            qualityScore: calculateQualityScore(for: project),
            riskFactor: calculateRiskFactor(for: project)
        )
    }
    
    func deleteProject(_ project: Project) {
        projects.removeAll { $0.id == project.id }
        projectMetrics.removeValue(forKey: project.id.uuidString)
    }
    
    func getProjectMetrics(for projectId: String) -> ProjectMetrics? {
        return projectMetrics[projectId]
    }
    
    func getProjectsByStatus(_ status: ProjectStatus) -> [Project] {
        return projects.filter { $0.status == status }
    }
    
    func getHighPriorityProjects() -> [Project] {
        return projects.filter { $0.priority >= 3 }.sorted { $0.priority > $1.priority }
    }
    
    func getProjectsWithRisk() -> [Project] {
        return projects.filter { 
            if let metrics = projectMetrics[$0.id.uuidString] {
                return metrics.riskFactor > 0.3
            }
            return false
        }
    }
    
    // MARK: - Cleanup
    deinit {
        updateTimer?.invalidate()
        cancellables.removeAll()
    }
}

// MARK: - Supporting Types

struct ProjectTask: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let title: String
    let description: String
    var status: TaskStatus
    let priority: TaskPriority
    let assignedAgent: String?
    let estimatedHours: Double
    var actualHours: Double?
    let dueDate: Date
    
    var isOverdue: Bool {
        return dueDate < Date() && status != .completed
    }
    
    var completionRatio: Double? {
        guard let actual = actualHours else { return nil }
        return actual / estimatedHours
    }
}

enum TaskStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case inProgress = "in_progress"
    case completed = "completed"
    case blocked = "blocked"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .blocked: return "Blocked"
        case .cancelled: return "Cancelled"
        }
    }
    
    var color: Color {
        switch self {
        case .pending: return .gray
        case .inProgress: return .blue
        case .completed: return .green
        case .blocked: return .orange
        case .cancelled: return .red
        }
    }
}

struct ProjectMetrics {
    let projectId: String
    let velocity: Double // Tasks per day
    let burnRate: Double // Percentage of estimated work completed
    let qualityScore: Double // Overall quality assessment
    let riskFactor: Double // Risk of delays or issues
    
    var formattedVelocity: String {
        return String(format: "%.1f tasks/day", velocity)
    }
    
    var formattedBurnRate: String {
        return String(format: "%.1f%%", burnRate * 100)
    }
    
    var formattedQualityScore: String {
        return String(format: "%.0f%%", qualityScore * 100)
    }
    
    var riskLevel: String {
        switch riskFactor {
        case 0..<0.2: return "Low"
        case 0.2..<0.5: return "Medium"
        case 0.5..<0.8: return "High"
        default: return "Critical"
        }
    }
    
    var riskColor: Color {
        switch riskFactor {
        case 0..<0.2: return .green
        case 0.2..<0.5: return .yellow
        case 0.5..<0.8: return .orange
        default: return .red
        }
    }
}

extension ProjectHealth {
    var qualityMultiplier: Double {
        switch self {
        case .excellent: return 1.2
        case .good: return 1.0
        case .warning: return 0.8
        case .critical: return 0.6
        case .planning: return 1.0
        }
    }
}