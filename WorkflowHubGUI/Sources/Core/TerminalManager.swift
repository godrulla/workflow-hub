import Foundation
import SwiftUI
import Combine

/// Focused manager for Claude Terminal state and operations
/// Implements ZEN's performance optimization recommendations for terminal management
@MainActor
class TerminalManager: ObservableObject, @preconcurrency TerminalManagerProtocol {
    static let shared = TerminalManager()
    
    // MARK: - Published Properties
    @Published var sessions: [ClaudeSession] = []
    @Published var activeSession: ClaudeSession?
    @Published var isExecuting: Bool = false
    @Published var connectionStatus: TerminalConnectionStatus = .disconnected
    @Published var lastUpdate: Date = Date()
    @Published var lastError: TerminalError? = nil
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let performanceManager = PerformanceManager.shared
    private let processQueue = DispatchQueue(label: "terminal-process-queue", qos: .userInitiated)
    private let messageQueue = DispatchQueue(label: "terminal-message-queue", qos: .utility)
    
    // MARK: - Session Management
    private var maxSessions = 5
    private var sessionCleanupTimer: Timer?
    
    // MARK: - WebSocket Connection
    private var webSocketTask: URLSessionWebSocketTask?
    private let webSocketURL = URL(string: "ws://localhost:8765")!
    
    private init() {
        setupDefaultSession()
        startSessionCleanup()
        bindToPerformanceManager()
        connectToWebSocket()
    }
    
    // MARK: - Session Setup
    private func setupDefaultSession() {
        let defaultSession = ClaudeSession(
            projectId: nil,
            agentId: nil,
            conversationHistory: [],
            status: .ready,
            workingDirectory: FileManager.default.homeDirectoryForCurrentUser
        )
        
        sessions.append(defaultSession)
        activeSession = defaultSession
    }
    
    // MARK: - WebSocket Connection
    private func connectToWebSocket() {
        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: webSocketURL)
        webSocketTask?.resume()
        
        connectionStatus = .connecting
        
        // Start listening for messages
        receiveWebSocketMessage()
        
        // Send heartbeat to establish connection
        sendHeartbeat()
    }
    
    private func receiveWebSocketMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                DispatchQueue.main.async {
                    self?.handleWebSocketMessage(message)
                    self?.receiveWebSocketMessage() // Continue listening
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.handleWebSocketError(error)
                }
            }
        }
    }
    
    private func handleWebSocketMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            if let data = text.data(using: .utf8) {
                handleIncomingMessage(data)
            }
        case .data(let data):
            handleIncomingMessage(data)
        @unknown default:
            print("Unknown WebSocket message type")
        }
    }
    
    private func handleIncomingMessage(_ data: Data) {
        messageQueue.async { [weak self] in
            do {
                let message = try JSONDecoder().decode(TerminalWebSocketMessage.self, from: data)
                DispatchQueue.main.async {
                    self?.processIncomingMessage(message)
                }
            } catch {
                print("Failed to decode WebSocket message: \(error)")
            }
        }
    }
    
    private func processIncomingMessage(_ message: TerminalWebSocketMessage) {
        switch message.type {
        case .response:
            handleCommandResponse(message)
        case .event:
            handleSystemEvent(message)
        case .stream:
            handleStreamingResponse(message)
        case .heartbeat:
            connectionStatus = .connected
        default:
            print("Unhandled message type: \(message.type)")
        }
        
        lastUpdate = Date()
    }
    
    private func handleCommandResponse(_ message: TerminalWebSocketMessage) {
        guard let sessionId = message.data.metadata?["session_id"]?.value as? String,
              let session = sessions.first(where: { $0.id.uuidString == sessionId }) else { return }
        
        let response = ClaudeMessage(
            content: message.data.payload["content"]?.value as? String ?? "No response",
            role: .assistant,
            timestamp: Date()
        )
        
        updateSessionHistory(sessionId: session.id, with: response)
        isExecuting = false
    }
    
    private func handleSystemEvent(_ message: TerminalWebSocketMessage) {
        // Handle system events like agent status updates, performance metrics, etc.
        print("System event: \(message.data.action)")
    }
    
    private func handleStreamingResponse(_ message: TerminalWebSocketMessage) {
        // Handle streaming responses for real-time updates
        print("Streaming: \(message.data.payload)")
    }
    
    private func handleWebSocketError(_ error: Error) {
        connectionStatus = .error
        print("WebSocket error: \(error)")
        
        // Attempt reconnection after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            self?.connectToWebSocket()
        }
    }
    
    private func sendHeartbeat() {
        let heartbeat = TerminalWebSocketMessage(
            id: UUID().uuidString,
            type: .heartbeat,
            timestamp: Date(),
            source: "terminal",
            target: "server",
            data: TerminalWebSocketMessage.MessageData(
                action: "ping",
                payload: [:],
                metadata: nil
            )
        )
        
        sendWebSocketMessage(heartbeat)
        
        // Schedule next heartbeat
        DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) { [weak self] in
            self?.sendHeartbeat()
        }
    }
    
    private func sendWebSocketMessage(_ message: TerminalWebSocketMessage) {
        guard let data = try? JSONEncoder().encode(message) else { return }
        guard let string = String(data: data, encoding: .utf8) else { return }
        
        webSocketTask?.send(.string(string)) { error in
            if let error = error {
                print("Failed to send WebSocket message: \(error)")
            }
        }
    }
    
    // MARK: - Command Execution
    func executeCommand(_ command: String) {
        guard let session = activeSession else { return }
        guard !command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isExecuting = true
        
        // Add user message to history
        let userMessage = ClaudeMessage(
            content: command,
            role: .user,
            timestamp: Date()
        )
        
        updateSessionHistory(sessionId: session.id, with: userMessage)
        
        // Send command via WebSocket
        let commandMessage = TerminalWebSocketMessage(
            id: UUID().uuidString,
            type: .command,
            timestamp: Date(),
            source: "terminal",
            target: "claude",
            data: TerminalWebSocketMessage.MessageData(
                action: "execute_command",
                payload: [
                    "command": AnyCodable(command),
                    "session_id": AnyCodable(session.id.uuidString),
                    "working_directory": AnyCodable(session.workingDirectory.path),
                    "context": AnyCodable(getContextForSession(session))
                ],
                metadata: [
                    "session_id": AnyCodable(session.id.uuidString),
                    "timestamp": AnyCodable(Date().timeIntervalSince1970)
                ]
            )
        )
        
        sendWebSocketMessage(commandMessage)
    }
    
    private func getContextForSession(_ session: ClaudeSession) -> [String: Any] {
        var context: [String: Any] = [:]
        
        if let projectId = session.projectId {
            context["project_id"] = projectId
        }
        
        if let agentId = session.agentId {
            context["agent_id"] = agentId
        }
        
        // Add recent conversation history
        let recentMessages = Array(session.conversationHistory.suffix(10))
        context["recent_history"] = recentMessages.map { message in
            return [
                "role": message.role.rawValue,
                "content": message.content,
                "timestamp": message.timestamp.timeIntervalSince1970
            ]
        }
        
        return context
    }
    
    // MARK: - TerminalManagerProtocol Methods
    func createSession(projectId: String?, agentId: String?) -> ClaudeSession {
        return createNewSession(projectId: projectId, agentId: agentId)
    }
    
    func activateSession(_ session: ClaudeSession) {
        activeSession = session
    }
    
    func interruptExecution() {
        isExecuting = false
    }
    
    func clearSessionHistory(_ sessionId: UUID) {
        guard let sessionIndex = sessions.firstIndex(where: { $0.id == sessionId }) else { return }
        sessions[sessionIndex].clearHistory()
    }

    // MARK: - Session Management
    func createNewSession(projectId: String? = nil, agentId: String? = nil) -> ClaudeSession {
        let newSession = ClaudeSession(
            projectId: projectId,
            agentId: agentId,
            conversationHistory: [],
            status: .ready,
            workingDirectory: FileManager.default.homeDirectoryForCurrentUser
        )
        
        sessions.append(newSession)
        
        // Remove oldest session if we exceed the limit
        if sessions.count > maxSessions {
            let oldestSession = sessions.min(by: { $0.lastActivity < $1.lastActivity })
            if let oldest = oldestSession {
                closeSession(oldest.id)
            }
        }
        
        return newSession
    }
    
    func switchToSession(_ sessionId: UUID) {
        guard let session = sessions.first(where: { $0.id == sessionId }) else { return }
        activeSession = session
    }
    
    func closeSession(_ sessionId: UUID) {
        sessions.removeAll { $0.id == sessionId }
        
        // If we closed the active session, switch to another one
        if activeSession?.id == sessionId {
            activeSession = sessions.first
        }
    }
    
    private func updateSessionHistory(sessionId: UUID, with message: ClaudeMessage) {
        guard let sessionIndex = sessions.firstIndex(where: { $0.id == sessionId }) else { return }
        
        sessions[sessionIndex].conversationHistory.append(message)
        sessions[sessionIndex].lastActivity = Date()
        
        // Update token usage if available
        if message.role == .assistant {
            // Estimate token usage (this would be provided by the actual response)
            let estimatedInputTokens = 100
            let estimatedOutputTokens = message.content.count / 4 // Rough estimation
            sessions[sessionIndex].tokens.inputTokens += estimatedInputTokens
            sessions[sessionIndex].tokens.outputTokens += estimatedOutputTokens
        }
        
        // Trigger UI update for active session
        if sessionId == activeSession?.id {
            activeSession = sessions[sessionIndex]
        }
    }
    
    // MARK: - Performance Optimization
    private func startSessionCleanup() {
        sessionCleanupTimer = Timer.scheduledTimer(withTimeInterval: 300.0, repeats: true) { [weak self] _ in
            self?.cleanupInactiveSessions()
        }
    }
    
    private func cleanupInactiveSessions() {
        let oneHourAgo = Date().addingTimeInterval(-3600)
        let inactiveSessions = sessions.filter { 
            ($0.status == .completed || $0.status == .error) && $0.lastActivity < oneHourAgo 
        }
        
        for session in inactiveSessions {
            if session.id != activeSession?.id {
                closeSession(session.id)
            }
        }
    }
    
    // MARK: - Performance Manager Integration
    private func bindToPerformanceManager() {
        performanceManager.$currentMetrics
            .receive(on: DispatchQueue.main)
            .sink { [weak self] metrics in
                self?.adjustPerformanceSettings(based: metrics)
            }
            .store(in: &cancellables)
    }
    
    private func adjustPerformanceSettings(based metrics: PerformanceMetrics) {
        // Adjust max sessions based on memory usage
        if metrics.memoryUsageMB > 800 {
            maxSessions = 3
        } else if metrics.memoryUsageMB > 500 {
            maxSessions = 4
        } else {
            maxSessions = 5
        }
        
        // Cleanup if we exceed the new limit
        if sessions.count > maxSessions {
            let excessCount = sessions.count - maxSessions
            let oldestSessions = sessions
                .filter { $0.id != activeSession?.id }
                .sorted { $0.lastActivity < $1.lastActivity }
                .prefix(excessCount)
            
            for session in oldestSessions {
                closeSession(session.id)
            }
        }
    }
    
    // MARK: - Utility Methods
    func getSessionById(_ id: UUID) -> ClaudeSession? {
        return sessions.first { $0.id == id }
    }
    
    func getActiveSessions() -> [ClaudeSession] {
        return sessions.filter { $0.status == .ready || $0.status == .processing }
    }
    
    func getTotalTokenUsage() -> TokenUsage {
        return sessions.reduce(TokenUsage()) { total, session in
            TokenUsage(
                inputTokens: total.inputTokens + session.tokens.inputTokens,
                outputTokens: total.outputTokens + session.tokens.outputTokens
            )
        }
    }
    
    // MARK: - Cleanup
    deinit {
        sessionCleanupTimer?.invalidate()
        webSocketTask?.cancel()
        cancellables.removeAll()
    }
}

// MARK: - Supporting Types

enum TerminalError: LocalizedError {
    case connectionFailed(String)
    case executionFailed(String)
    case sessionNotFound(String)
    case invalidCommand(String)
    case noActiveSession
    case processingError(String)
    
    var errorDescription: String? {
        switch self {
        case .connectionFailed(let message): return "Connection failed: \(message)"
        case .executionFailed(let message): return "Execution failed: \(message)"
        case .sessionNotFound(let message): return "Session not found: \(message)"
        case .invalidCommand(let message): return "Invalid command: \(message)"
        case .noActiveSession: return "No active terminal session"
        case .processingError(let message): return "Processing error: \(message)"
        }
    }
}

enum TerminalConnectionStatus {
    case disconnected
    case connecting
    case connected
    case error
    
    var displayName: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting"
        case .connected: return "Connected"
        case .error: return "Error"
        }
    }
    
    var color: Color {
        switch self {
        case .disconnected: return .gray
        case .connecting: return .yellow
        case .connected: return .green
        case .error: return .red
        }
    }
}

struct TerminalWebSocketMessage: Codable {
    let id: String
    let type: MessageType
    let timestamp: Date
    let source: String
    let target: String?
    let data: MessageData
    
    struct MessageData: Codable {
        let action: String
        let payload: [String: AnyCodable]
        let metadata: [String: AnyCodable]?
    }
}

enum MessageType: String, Codable {
    case command = "command"
    case response = "response"
    case event = "event"
    case stream = "stream"
    case heartbeat = "heartbeat"
}

struct AnyCodable: Codable {
    let value: Any
    
    init<T>(_ value: T?) {
        self.value = value ?? ()
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else {
            value = ()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if let intValue = value as? Int {
            try container.encode(intValue)
        } else if let doubleValue = value as? Double {
            try container.encode(doubleValue)
        } else if let stringValue = value as? String {
            try container.encode(stringValue)
        } else if let boolValue = value as? Bool {
            try container.encode(boolValue)
        }
    }
}