import Foundation
import Combine
import SwiftUI

/// Core engine for managing Claude Code terminal sessions and process execution
@MainActor
class ClaudeTerminalManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var sessions: [ClaudeSession] = []
    @Published var activeSession: ClaudeSession?
    @Published var isExecuting: Bool = false
    @Published var lastError: TerminalError?
    
    // MARK: - Private Properties
    private var processExecutor: ProcessExecutor
    private var cancellables = Set<AnyCancellable>()
    private let maxSessions = 5
    
    // MARK: - Dependencies
    private weak var appState: AppStateManager?
    
    init(appState: AppStateManager) {
        self.appState = appState
        self.processExecutor = ProcessExecutor()
        
        setupSessionManagement()
        loadPersistedSessions()
    }
    
    // MARK: - Session Management
    
    /// Creates a new Claude session with optional project and agent context
    func createSession(projectId: String? = nil, agentId: String? = nil) -> ClaudeSession {
        // Cleanup old sessions if at limit
        if sessions.count >= maxSessions {
            removeOldestSession()
        }
        
        let session = ClaudeSession(
            id: UUID(),
            projectId: projectId,
            agentId: agentId,
            conversationHistory: [],
            status: .ready,
            lastActivity: Date(),
            workingDirectory: getCurrentWorkingDirectory(projectId: projectId)
        )
        
        sessions.append(session)
        activeSession = session
        
        persistSessions()
        return session
    }
    
    /// Activates a specific session
    func activateSession(_ session: ClaudeSession) {
        activeSession = session
        updateSessionActivity(session.id)
    }
    
    /// Closes and removes a session
    func closeSession(_ sessionId: UUID) {
        // Terminate any running processes for this session
        processExecutor.terminateProcess(sessionId: sessionId)
        
        sessions.removeAll { $0.id == sessionId }
        
        if activeSession?.id == sessionId {
            activeSession = sessions.first
        }
        
        persistSessions()
    }
    
    // MARK: - Command Execution
    
    /// Executes a Claude Code command in the active session
    func executeCommand(_ command: String) async {
        guard let session = activeSession else {
            await setError(.noActiveSession)
            return
        }
        
        guard !command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        isExecuting = true
        lastError = nil
        
        // Add user message to conversation history
        let userMessage = ClaudeMessage(
            id: UUID(),
            content: command,
            role: .user,
            timestamp: Date(),
            tokens: nil
        )
        
        await addMessageToSession(session.id, message: userMessage)
        
        do {
            // Prepare command with context
            let contextualCommand = await prepareCommandWithContext(command, session: session)
            
            // Execute via process executor
            let result = await processExecutor.executeClaudeCommand(
                contextualCommand,
                sessionId: session.id,
                workingDirectory: session.workingDirectory
            )
            
            // Process the response
            await handleCommandResult(result, sessionId: session.id)
            
        } catch {
            await setError(.executionFailed(error.localizedDescription))
        }
        
        isExecuting = false
        updateSessionActivity(session.id)
    }
    
    /// Interrupts the currently executing command
    func interruptExecution() {
        guard let session = activeSession else { return }
        
        processExecutor.terminateProcess(sessionId: session.id)
        isExecuting = false
        
        Task {
            let interruptMessage = ClaudeMessage(
                id: UUID(),
                content: "[Command interrupted by user]",
                role: .system,
                timestamp: Date(),
                tokens: nil
            )
            
            await addMessageToSession(session.id, message: interruptMessage)
        }
    }
    
    // MARK: - Context Management
    
    /// Prepares command with current project and agent context
    private func prepareCommandWithContext(_ command: String, session: ClaudeSession) async -> String {
        var contextualCommand = command
        
        // Add project context if available
        if let projectId = session.projectId,
           let project = appState?.getProject(by: projectId) {
            contextualCommand = addProjectContext(contextualCommand, project: project)
        }
        
        // Add agent context if available
        if let agentId = session.agentId,
           let agent = appState?.getAgent(by: agentId) {
            contextualCommand = addAgentContext(contextualCommand, agent: agent)
        }
        
        // Add working directory context
        contextualCommand = addWorkingDirectoryContext(contextualCommand, directory: session.workingDirectory)
        
        return contextualCommand
    }
    
    private func addProjectContext(_ command: String, project: Project) -> String {
        let projectContext = """
        
        Current project context:
        - Project: \(project.name)
        - Type: \(project.type)
        - Status: \(project.status.displayName)
        - Team: \(project.agentTeam.joined(separator: ", "))
        
        \(command)
        """
        return projectContext
    }
    
    private func addAgentContext(_ command: String, agent: EliteAgent) -> String {
        let agentContext = """
        
        Current agent context:
        - Agent: \(agent.name)
        - Specializations: \(agent.specialization.joined(separator: ", "))
        - Expertise Level: \(Int(agent.expertiseLevel * 100))%
        - Status: \(agent.status.displayName)
        
        \(command)
        """
        return agentContext
    }
    
    private func addWorkingDirectoryContext(_ command: String, directory: URL) -> String {
        return "cd \"\(directory.path)\" && \(command)"
    }
    
    // MARK: - Result Processing
    
    private func handleCommandResult(_ result: ProcessResult, sessionId: UUID) async {
        let assistantMessage = ClaudeMessage(
            id: UUID(),
            content: result.output,
            role: .assistant,
            timestamp: Date(),
            tokens: result.tokens
        )
        
        await addMessageToSession(sessionId, message: assistantMessage)
        
        // Handle any file operations or state changes
        await processFileOperations(result.fileOperations, sessionId: sessionId)
        
        // Sync with WebSocket backend if connected
        await syncWithBackend(result, sessionId: sessionId)
    }
    
    private func processFileOperations(_ operations: [FileOperation], sessionId: UUID) async {
        for operation in operations {
            // Log file operations
            print("File operation: \(operation.type) - \(operation.path)")
            
            // Update project state if needed
            if let projectPath = operation.projectPath {
                await updateProjectFromFileOperation(operation, projectPath: projectPath)
            }
        }
    }
    
    private func syncWithBackend(_ result: ProcessResult, sessionId: UUID) async {
        guard let appState = appState else { return }
        
        // Create WebSocket message for backend sync
        let message = WebSocketMessage(
            type: .event,
            data: WebSocketMessage.MessageData(
                action: "claude_command_executed",
                payload: [
                    "session_id": sessionId.uuidString,
                    "command_duration": result.duration,
                    "tokens_used": result.tokens ?? 0,
                    "success": result.exitCode == 0
                ]
            )
        )
        
        appState.websocketManager?.sendMessage(message)
    }
    
    // MARK: - Session Utilities
    
    private func addMessageToSession(_ sessionId: UUID, message: ClaudeMessage) async {
        guard let index = sessions.firstIndex(where: { $0.id == sessionId }) else { return }
        
        sessions[index].conversationHistory.append(message)
        sessions[index].lastActivity = Date()
        
        // Update session status
        if message.role == .user {
            sessions[index].status = .processing
        } else if message.role == .assistant {
            sessions[index].status = .ready
        }
        
        persistSessions()
    }
    
    private func updateSessionActivity(_ sessionId: UUID) {
        guard let index = sessions.firstIndex(where: { $0.id == sessionId }) else { return }
        sessions[index].lastActivity = Date()
        persistSessions()
    }
    
    private func removeOldestSession() {
        guard let oldestSession = sessions.min(by: { $0.lastActivity < $1.lastActivity }) else { return }
        closeSession(oldestSession.id)
    }
    
    private func getCurrentWorkingDirectory(projectId: String?) -> URL {
        if let projectId = projectId,
           let project = appState?.getProject(by: projectId) {
            // Use project-specific directory
            let projectDir = URL(fileURLWithPath: "/Users/mando/Desktop/workflow-hub/\(project.name)")
            return projectDir
        }
        
        // Default to workflow-hub directory
        return URL(fileURLWithPath: "/Users/mando/Desktop/workflow-hub")
    }
    
    // MARK: - Error Handling
    
    private func setError(_ error: TerminalError) async {
        lastError = error
        print("Terminal Error: \(error.localizedDescription)")
    }
    
    // MARK: - Persistence
    
    private func setupSessionManagement() {
        // Auto-save sessions periodically
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                self.persistSessions()
            }
            .store(in: &cancellables)
    }
    
    private func persistSessions() {
        // TODO: Implement Core Data or SQLite persistence
        // For now, we'll keep sessions in memory
    }
    
    private func loadPersistedSessions() {
        // TODO: Load sessions from persistent storage
        // Create a default session for now
        let defaultSession = createSession()
        activateSession(defaultSession)
    }
    
    // MARK: - Cleanup
    
    deinit {
        // Cleanup handled by ARC - processes will be terminated when processExecutor is deallocated
    }
}

// MARK: - Supporting Types
// Note: TerminalError is defined in TerminalManager.swift to avoid conflicts


// MARK: - File Operation Support

struct FileOperation {
    let type: FileOperationType
    let path: String
    let projectPath: String?
    let content: String?
}

enum FileOperationType {
    case create
    case modify
    case delete
    case move
}

extension ClaudeTerminalManager {
    private func updateProjectFromFileOperation(_ operation: FileOperation, projectPath: String) async {
        // Update project last modified time
        if let project = appState?.getProject(by: projectPath) {
            var updatedProject = project
            updatedProject.lastModified = Date()
            appState?.updateProject(updatedProject)
        }
    }
}