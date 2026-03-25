import Foundation
import SwiftUI

// MARK: - Elite Agent Model
struct EliteAgent: Identifiable, Codable, Equatable, Hashable {
    let id = UUID()
    let name: String
    let specialization: [String]
    var status: AgentStatus
    var currentTask: String?
    var progress: Double
    var lastActivity: Date
    let expertiseLevel: Double
    var currentLoad: Int
    let maxParallelTasks: Int
    
    static let defaultAgents = [
        EliteAgent(
            name: "ARQ",
            specialization: ["architecture", "system_design", "scalability", "cloud"],
            status: .idle,
            currentTask: nil,
            progress: 0.0,
            lastActivity: Date(),
            expertiseLevel: 0.95,
            currentLoad: 0,
            maxParallelTasks: 3
        ),
        EliteAgent(
            name: "ORC",
            specialization: ["orchestration", "coordination", "workflow", "management"],
            status: .idle,
            currentTask: nil,
            progress: 0.0,
            lastActivity: Date(),
            expertiseLevel: 0.98,
            currentLoad: 0,
            maxParallelTasks: 5
        ),
        EliteAgent(
            name: "ZEN",
            specialization: ["code_quality", "refactoring", "algorithms", "optimization"],
            status: .idle,
            currentTask: nil,
            progress: 0.0,
            lastActivity: Date(),
            expertiseLevel: 0.93,
            currentLoad: 0,
            maxParallelTasks: 3
        ),
        EliteAgent(
            name: "VEX",
            specialization: ["ui_ux", "design", "user_experience", "creativity"],
            status: .idle,
            currentTask: nil,
            progress: 0.0,
            lastActivity: Date(),
            expertiseLevel: 0.92,
            currentLoad: 0,
            maxParallelTasks: 2
        ),
        EliteAgent(
            name: "SAGE",
            specialization: ["strategy", "market_analysis", "intelligence", "forecasting"],
            status: .idle,
            currentTask: nil,
            progress: 0.0,
            lastActivity: Date(),
            expertiseLevel: 0.94,
            currentLoad: 0,
            maxParallelTasks: 3
        ),
        EliteAgent(
            name: "NOVA",
            specialization: ["innovation", "breakthrough", "emerging_tech", "r_and_d"],
            status: .idle,
            currentTask: nil,
            progress: 0.0,
            lastActivity: Date(),
            expertiseLevel: 0.91,
            currentLoad: 0,
            maxParallelTasks: 2
        ),
        EliteAgent(
            name: "ECHO",
            specialization: ["community", "content", "culture", "communication"],
            status: .idle,
            currentTask: nil,
            progress: 0.0,
            lastActivity: Date(),
            expertiseLevel: 0.90,
            currentLoad: 0,
            maxParallelTasks: 3
        )
    ]
    
    var displayDescription: String {
        switch name {
        case "ARQ":
            return "The Visionary Architect - Building tomorrow's systems with today's vision"
        case "ORC":
            return "The Master Orchestrator - Conducting symphonies of complex workflows"
        case "ZEN":
            return "The Code Zen Master - Writing code that transcends mere functionality"
        case "VEX":
            return "The Creative Visionary - Designing experiences that move souls"
        case "SAGE":
            return "The Strategic Oracle - Seeing patterns others miss, predicting what others can't"
        case "NOVA":
            return "The Innovation Catalyst - Turning impossible ideas into inevitable realities"
        case "ECHO":
            return "The Voice of the People - Amplifying authentic human connections"
        default:
            return "Elite Agent"
        }
    }
    
    var iconName: String {
        switch name {
        case "ARQ": return "building.2"
        case "ORC": return "music.note.list"
        case "ZEN": return "brain.head.profile"
        case "VEX": return "paintbrush.pointed"
        case "SAGE": return "eye"
        case "NOVA": return "sparkles"
        case "ECHO": return "megaphone"
        default: return "person.circle"
        }
    }
    
    var statusColor: Color {
        switch status {
        case .idle: return .gray
        case .executing: return .blue
        case .completed: return .green
        case .error: return .red
        case .offline: return .red.opacity(0.5)
        }
    }
    
    var availabilityPercentage: Double {
        return max(0, Double(maxParallelTasks - currentLoad) / Double(maxParallelTasks))
    }
}

enum AgentStatus: String, Codable, CaseIterable {
    case idle = "idle"
    case executing = "executing"
    case completed = "completed"
    case error = "error"
    case offline = "offline"
    
    var displayName: String {
        switch self {
        case .idle: return "Ready"
        case .executing: return "Working"
        case .completed: return "Completed"
        case .error: return "Error"
        case .offline: return "Offline"
        }
    }
    
    var color: Color {
        switch self {
        case .idle: return .gray
        case .executing: return .blue
        case .completed: return .green
        case .error: return .red
        case .offline: return .secondary
        }
    }
}

// MARK: - Project Model
struct Project: Identifiable, Codable, Equatable, Hashable {
    let id = UUID()
    let name: String
    let type: String
    var status: ProjectStatus
    let priority: Int
    var completion: Double
    let agentTeam: [String]
    var lastModified: Date
    var health: ProjectHealth
    
    static let sampleProjects = [
        Project(
            name: "exxede.diy",
            type: "nextjs",
            status: .production,
            priority: 5,
            completion: 0.85,
            agentTeam: ["ARQ", "ZEN", "ORC"],
            lastModified: Date(),
            health: .good
        ),
        Project(
            name: "ReppingDR",
            type: "business",
            status: .production,
            priority: 5,
            completion: 0.85,
            agentTeam: ["SAGE", "ECHO", "VEX", "ORC"],
            lastModified: Date(),
            health: .good
        ),
        Project(
            name: "Context-Engineering",
            type: "ai_ml",
            status: .production,
            priority: 4,
            completion: 0.90,
            agentTeam: ["NOVA", "ARQ", "ZEN"],
            lastModified: Date(),
            health: .excellent
        ),
        Project(
            name: "CLAI",
            type: "ai_ml",
            status: .production,
            priority: 4,
            completion: 0.90,
            agentTeam: ["ZEN", "ARQ", "NOVA"],
            lastModified: Date(),
            health: .good
        ),
        Project(
            name: "Ocean Paradise",
            type: "real_estate",
            status: .planning,
            priority: 3,
            completion: 0.25,
            agentTeam: ["SAGE", "VEX", "ORC"],
            lastModified: Date(),
            health: .planning
        )
    ]
    
    var priorityColor: Color {
        switch priority {
        case 5: return .red
        case 4: return .orange
        case 3: return .yellow
        case 2: return .blue
        default: return .gray
        }
    }
    
    var statusColor: Color {
        switch status {
        case .production: return .green
        case .development: return .blue
        case .planning: return .orange
        case .archived: return .gray
        case .error: return .red
        }
    }
    
    var healthColor: Color {
        switch health {
        case .excellent: return .green
        case .good: return .blue
        case .warning: return .orange
        case .critical: return .red
        case .planning: return .purple
        }
    }
    
    var typeIcon: String {
        switch type {
        case "nextjs", "react": return "globe"
        case "business": return "building.2"
        case "ai_ml": return "brain.head.profile"
        case "real_estate": return "house"
        case "python": return "terminal"
        default: return "folder"
        }
    }
}

enum ProjectStatus: String, Codable, CaseIterable {
    case production = "production"
    case development = "development"
    case planning = "planning"
    case archived = "archived"
    case error = "error"
    
    var displayName: String {
        switch self {
        case .production: return "Production"
        case .development: return "Development"
        case .planning: return "Planning"
        case .archived: return "Archived"
        case .error: return "Error"
        }
    }
}

enum ProjectHealth: String, Codable, CaseIterable {
    case excellent = "excellent"
    case good = "good"
    case warning = "warning"
    case critical = "critical"
    case planning = "planning"
    
    var displayName: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .warning: return "Warning"
        case .critical: return "Critical"
        case .planning: return "Planning"
        }
    }
}

// MARK: - Token Usage Model
struct TokenUsageData: Codable {
    var totalTokens: Int = 0
    var sessionTokens: Int = 0
    var agentBreakdown: [String: Int] = [:]
    var lastUpdated: Date = Date()
    
    var costEstimate: Double {
        // Rough estimate: $0.002 per 1K tokens (GPT-4 pricing)
        return Double(totalTokens) / 1000.0 * 0.002
    }
    
    var sessionCostEstimate: Double {
        return Double(sessionTokens) / 1000.0 * 0.002
    }
    
    var topAgentUsage: [(agent: String, tokens: Int)] {
        return agentBreakdown.sorted { $0.value > $1.value }.map { (agent: $0.key, tokens: $0.value) }
    }
}

// MARK: - System Metrics Model
struct SystemMetrics: Codable {
    var cpuUsage: Double = 0.0
    var memoryUsage: Double = 0.0
    var activeAgents: Int = 0
    var lastUpdated: Date = Date()
    
    var systemHealthColor: Color {
        let overallUsage = max(cpuUsage, memoryUsage)
        
        if overallUsage > 90 {
            return .red
        } else if overallUsage > 70 {
            return .orange
        } else if overallUsage > 50 {
            return .yellow
        } else {
            return .green
        }
    }
    
    var systemHealthStatus: String {
        let overallUsage = max(cpuUsage, memoryUsage)
        
        if overallUsage > 90 {
            return "Critical"
        } else if overallUsage > 70 {
            return "High Load"
        } else if overallUsage > 50 {
            return "Moderate"
        } else {
            return "Optimal"
        }
    }
}

// MARK: - Workflow Execution Model
struct WorkflowExecution: Identifiable, Codable {
    let id: String
    let name: String
    let projectName: String
    var status: WorkflowStatus
    let startTime: Date
    var lastUpdated: Date
    var progress: Double = 0.0
    var currentStep: String?
    var steps: [WorkflowStep] = []
    
    var duration: TimeInterval {
        return lastUpdated.timeIntervalSince(startTime)
    }
    
    var estimatedCompletion: Date? {
        guard progress > 0 else { return nil }
        let remainingTime = (duration / progress) * (1.0 - progress)
        return Date().addingTimeInterval(remainingTime)
    }
}

struct WorkflowStep: Identifiable, Codable {
    let id = UUID()
    let name: String
    var status: WorkflowStepStatus
    let startTime: Date
    var endTime: Date?
    var agent: String?
    var output: String?
}

enum WorkflowStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case running = "running"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
    
    var color: Color {
        switch self {
        case .pending: return .gray
        case .running: return .blue
        case .completed: return .green
        case .failed: return .red
        case .cancelled: return .orange
        }
    }
}

enum WorkflowStepStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case running = "running"
    case completed = "completed"
    case failed = "failed"
    case skipped = "skipped"
}

// MARK: - Task Definition Model
struct TaskDefinition: Identifiable, Codable {
    let id = UUID()
    let type: String
    let description: String
    let priority: Int
    let context: [String: String]
    let requiredCapabilities: [String]
    
    var priorityColor: Color {
        switch priority {
        case 5: return .red
        case 4: return .orange
        case 3: return .yellow
        case 2: return .blue
        default: return .gray
        }
    }
}

// MARK: - Analytics Data Models
struct ProductivityMetrics: Codable {
    let tasksCompleted: Int
    let averageCompletionTime: TimeInterval
    let agentUtilization: [String: Double]
    let projectProgress: [String: Double]
    let tokenEfficiency: Double
    let period: TimePeriod
    
    enum TimePeriod: String, Codable, CaseIterable {
        case hourly = "hourly"
        case daily = "daily"
        case weekly = "weekly"
        case monthly = "monthly"
    }
}

struct PerformanceInsight: Identifiable, Codable {
    let id = UUID()
    let type: InsightType
    let title: String
    let description: String
    let impact: ImpactLevel
    let recommendation: String
    let timestamp: Date
    
    enum InsightType: String, Codable, CaseIterable {
        case performance = "performance"
        case efficiency = "efficiency"
        case bottleneck = "bottleneck"
        case opportunity = "opportunity"
    }
    
    enum ImpactLevel: String, Codable, CaseIterable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case critical = "critical"
        
        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .yellow
            case .high: return .orange
            case .critical: return .red
            }
        }
    }
}

// MARK: - UI Extensions
extension Color {
    static let primaryBackground = Color(NSColor.windowBackgroundColor)
    static let secondaryBackground = Color(NSColor.controlBackgroundColor)
    static let tertiaryBackground = Color(NSColor.tertiaryLabelColor).opacity(0.1)
    
    static let primaryText = Color(NSColor.labelColor)
    static let secondaryText = Color(NSColor.secondaryLabelColor)
    static let tertiaryText = Color(NSColor.tertiaryLabelColor)
    
    static let accent = Color.accentColor
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    static let info = Color.blue
}