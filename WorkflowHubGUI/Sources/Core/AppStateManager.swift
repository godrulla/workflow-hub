import SwiftUI
import Foundation
import Combine

@MainActor
class AppStateManager: ObservableObject {
    static let shared = AppStateManager()
    
    // MARK: - Published Properties  
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var tokenUsage: TokenUsageData = TokenUsageData()
    @Published var systemMetrics: SystemMetrics = SystemMetrics()
    @Published var currentWorkflows: [WorkflowExecution] = []
    
    // Core data collections
    @Published var agents: [EliteAgent] = []
    @Published var projects: [Project] = []
    
    // Specialized managers
    @Published var agentManager = AgentManager.shared
    @Published var projectManager = ProjectManager.shared  
    @Published var terminalManager = TerminalManager.shared
    @Published var performanceManager = PerformanceManager.shared
    
    // Claude Terminal
    @Published var claudeTerminalVisible: Bool = false
    @Published var claudeSessions: [ClaudeSession] = []
    
    // UI State
    @Published var showRightPanel: Bool = true
    @Published var showingSettings: Bool = false
    @Published var showingConnectionError: Bool = false
    @Published var selectedAgent: EliteAgent?
    @Published var selectedProject: Project?
    
    // Real-time updates
    @Published var lastUpdated: Date = Date()
    @Published var updateFrequency: Double = 1.0 // seconds
    
    // MARK: - Private Properties
    var websocketManager: WebSocketManager?
    private var cancellables = Set<AnyCancellable>()
    private var updateTimer: Timer?
    
    private init() {
        setupDefaultData()
        startPeriodicUpdates()
    }
    
    // MARK: - Connection Management
    func initializeConnection() {
        websocketManager = WebSocketManager()
        websocketManager?.delegate = self
        websocketManager?.connect()
        
        connectionStatus = .connecting
    }
    
    func disconnect() {
        websocketManager?.disconnect()
        connectionStatus = .disconnected
    }
    
    // MARK: - Data Management
    private func setupDefaultData() {
        // Initialize with default Elite Agents
        agents = EliteAgent.defaultAgents
        
        // Initialize with sample projects (will be updated from backend)
        projects = Project.sampleProjects
    }
    
    private func startPeriodicUpdates() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateFrequency, repeats: true) { _ in
            Task { @MainActor in
                self.requestSystemUpdate()
            }
        }
    }
    
    func requestSystemUpdate() {
        guard connectionStatus == .connected else { return }
        
        websocketManager?.sendMessage(
            WebSocketMessage(
                type: .command,
                data: WebSocketMessage.MessageData(
                    action: "get_system_status",
                    payload: [:]
                )
            )
        )
        
        lastUpdated = Date()
    }
    
    // MARK: - Agent Management
    func updateAgent(_ agent: EliteAgent) {
        if let index = agents.firstIndex(where: { $0.id == agent.id }) {
            agents[index] = agent
        }
    }
    
    func getAgent(by name: String) -> EliteAgent? {
        return agents.first { $0.name == name }
    }
    
    // MARK: - Project Management
    func updateProject(_ project: Project) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index] = project
        }
    }
    
    func getProject(by name: String) -> Project? {
        return projects.first { $0.name == name }
    }
    
    // MARK: - Workflow Execution
    func executeWorkflow(name: String, projectName: String, context: [String: Any] = [:]) {
        guard connectionStatus == .connected else { return }
        
        let message = WebSocketMessage(
            type: .command,
            data: WebSocketMessage.MessageData(
                action: "execute_workflow",
                payload: [
                    "workflow": name,
                    "project": projectName,
                    "context": context
                ]
            )
        )
        
        websocketManager?.sendMessage(message)
    }
    
    func delegateTask(to agentName: String, task: TaskDefinition) {
        guard connectionStatus == .connected else { return }
        
        let message = WebSocketMessage(
            type: .command,
            data: WebSocketMessage.MessageData(
                action: "delegate_task",
                payload: [
                    "agent": agentName,
                    "task": [
                        "type": task.type,
                        "description": task.description,
                        "priority": task.priority,
                        "context": task.context
                    ]
                ]
            )
        )
        
        websocketManager?.sendMessage(message)
    }
    
    // MARK: - Claude Terminal Integration
    
    func initializeClaudeTerminal() {
        // Terminal manager is already initialized as a singleton
        claudeTerminalVisible = true
    }
    
    func toggleClaudeTerminal() {
        claudeTerminalVisible.toggle()
        
        if claudeTerminalVisible {
            initializeClaudeTerminal()
        }
    }
    
    func createClaudeSession(projectId: String? = nil, agentId: String? = nil) -> ClaudeSession? {
        let session = terminalManager.createSession(projectId: projectId, agentId: agentId)
        syncClaudeSessions()
        return session
    }
    
    func syncClaudeSessions() {
        claudeSessions = terminalManager.sessions
    }
    
    // Enhanced agent management methods
    
    func createAgent(name: String, specializations: [String]) {
        let newAgent = EliteAgent(
            name: name,
            specialization: specializations,
            status: .idle,
            currentTask: nil,
            progress: 0.0,
            lastActivity: Date(),
            expertiseLevel: 0.8,
            currentLoad: 0,
            maxParallelTasks: 3
        )
        
        agents.append(newAgent)
        
        // Sync with WebSocket backend
        let message = WebSocketMessage(
            type: .event,
            data: WebSocketMessage.MessageData(
                action: "agent_created",
                payload: [
                    "agent_name": name,
                    "specializations": specializations.joined(separator: ",")
                ]
            )
        )
        
        websocketManager?.sendMessage(message)
    }
    
    func removeAgent(named name: String) {
        agents.removeAll { $0.name == name }
        
        // Sync with WebSocket backend
        let message = WebSocketMessage(
            type: .event,
            data: WebSocketMessage.MessageData(
                action: "agent_deleted",
                payload: [
                    "agent_name": name
                ]
            )
        )
        
        websocketManager?.sendMessage(message)
    }
    
    func updateAgentTask(agentName: String, task: String?, progress: Double = 0.0) {
        guard let index = agents.firstIndex(where: { $0.name == agentName }) else { return }
        
        var agent = agents[index]
        agent.currentTask = task
        agent.progress = progress
        agent.lastActivity = Date()
        agent.status = task != nil ? .executing : .idle
        
        agents[index] = agent
        
        // Update selected agent if it matches
        if selectedAgent?.name == agentName {
            selectedAgent = agent
        }
    }
}

// MARK: - Connection Status Enum
enum ConnectionStatus: Equatable {
    case disconnected
    case connecting
    case connected
    case error(String)
    
    var displayText: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting..."
        case .connected: return "Connected"
        case .error(let message): return "Error: \(message)"
        }
    }
    
    var color: Color {
        switch self {
        case .disconnected: return .red
        case .connecting: return .yellow
        case .connected: return .green
        case .error: return .red
        }
    }
}

// MARK: - WebSocket Delegate
extension AppStateManager: WebSocketManagerDelegate {
    nonisolated func webSocketDidConnect() {
        Task { @MainActor in
            connectionStatus = .connected
            requestSystemUpdate()
        }
    }
    
    nonisolated func webSocketDidDisconnect() {
        Task { @MainActor in
            connectionStatus = .disconnected
        }
    }
    
    nonisolated func webSocketDidReceiveError(_ error: Error) {
        Task { @MainActor in
            connectionStatus = .error(error.localizedDescription)
            showingConnectionError = true
        }
    }
    
    nonisolated func webSocketDidReceiveMessage(_ message: WebSocketMessage) {
        Task { @MainActor in
            processIncomingMessage(message)
        }
    }
    
    private func processIncomingMessage(_ message: WebSocketMessage) {
        switch message.data.action {
        case "agent_status_update":
            handleAgentStatusUpdate(message.data.payload)
        case "project_status_update":
            handleProjectStatusUpdate(message.data.payload)
        case "token_usage_update":
            handleTokenUsageUpdate(message.data.payload)
        case "workflow_update":
            handleWorkflowUpdate(message.data.payload)
        case "system_metrics_update":
            handleSystemMetricsUpdate(message.data.payload)
        default:
            print("Unknown message action: \(message.data.action)")
        }
    }
    
    private func handleAgentStatusUpdate(_ payload: [String: Any]) {
        guard let agentName = payload["agent"] as? String,
              let status = payload["status"] as? String else { return }
        
        if var agent = getAgent(by: agentName) {
            agent.status = AgentStatus(rawValue: status) ?? .idle
            agent.currentTask = payload["task"] as? String
            agent.lastActivity = Date()
            
            if let progress = payload["progress"] as? Double {
                agent.progress = progress
            }
            
            updateAgent(agent)
        }
    }
    
    private func handleProjectStatusUpdate(_ payload: [String: Any]) {
        guard let projectName = payload["project"] as? String else { return }
        
        if var project = getProject(by: projectName) {
            if let status = payload["status"] as? String {
                project.status = ProjectStatus(rawValue: status) ?? .development
            }
            
            if let lastModified = payload["last_modified"] as? String {
                let formatter = ISO8601DateFormatter()
                project.lastModified = formatter.date(from: lastModified) ?? Date()
            }
            
            updateProject(project)
        }
    }
    
    private func handleTokenUsageUpdate(_ payload: [String: Any]) {
        if let totalTokens = payload["total_tokens"] as? Int {
            tokenUsage.totalTokens = totalTokens
        }
        
        if let sessionTokens = payload["session_tokens"] as? Int {
            tokenUsage.sessionTokens = sessionTokens
        }
        
        if let agentBreakdown = payload["agent_breakdown"] as? [String: Int] {
            tokenUsage.agentBreakdown = agentBreakdown
        }
        
        tokenUsage.lastUpdated = Date()
    }
    
    private func handleWorkflowUpdate(_ payload: [String: Any]) {
        // Handle workflow execution updates
        if let workflowId = payload["workflow_id"] as? String,
           let status = payload["status"] as? String {
            
            if currentWorkflows.contains(where: { $0.id == workflowId }) {
                // Update existing workflow
                if let index = currentWorkflows.firstIndex(where: { $0.id == workflowId }) {
                    currentWorkflows[index].status = WorkflowStatus(rawValue: status) ?? .running
                    currentWorkflows[index].lastUpdated = Date()
                }
            } else {
                // Create new workflow execution
                let newWorkflow = WorkflowExecution(
                    id: workflowId,
                    name: payload["workflow_name"] as? String ?? "Unknown",
                    projectName: payload["project"] as? String ?? "Unknown",
                    status: WorkflowStatus(rawValue: status) ?? .running,
                    startTime: Date(),
                    lastUpdated: Date()
                )
                currentWorkflows.append(newWorkflow)
            }
        }
    }
    
    private func handleSystemMetricsUpdate(_ payload: [String: Any]) {
        if let cpuUsage = payload["cpu_usage"] as? Double {
            systemMetrics.cpuUsage = cpuUsage
        }
        
        if let memoryUsage = payload["memory_usage"] as? Double {
            systemMetrics.memoryUsage = memoryUsage
        }
        
        if let activeAgents = payload["active_agents"] as? Int {
            systemMetrics.activeAgents = activeAgents
        }
        
        systemMetrics.lastUpdated = Date()
    }
}