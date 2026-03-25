import Foundation
import SwiftUI

// MARK: - Claude Session Model
struct ClaudeSession: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let projectId: String?
    let agentId: String?
    var conversationHistory: [ClaudeMessage]
    var status: SessionStatus
    var lastActivity: Date
    var workingDirectory: URL
    var tokens: TokenUsage
    var metadata: [String: String]
    
    init(
        id: UUID = UUID(),
        projectId: String? = nil,
        agentId: String? = nil,
        conversationHistory: [ClaudeMessage] = [],
        status: SessionStatus = .ready,
        lastActivity: Date = Date(),
        workingDirectory: URL = URL(fileURLWithPath: "/Users/mando/Desktop/workflow-hub")
    ) {
        self.id = id
        self.projectId = projectId
        self.agentId = agentId
        self.conversationHistory = conversationHistory
        self.status = status
        self.lastActivity = lastActivity
        self.workingDirectory = workingDirectory
        self.tokens = TokenUsage()
        self.metadata = [:]
    }
    
    // MARK: - Computed Properties
    
    var displayName: String {
        if let projectId = projectId {
            return "Claude - \(projectId)"
        } else if let agentId = agentId {
            return "Claude - \(agentId)"
        } else {
            return "Claude Session"
        }
    }
    
    var messageCount: Int {
        return conversationHistory.count
    }
    
    var totalTokens: Int {
        return conversationHistory.compactMap { $0.tokens }.reduce(0, +)
    }
    
    var lastMessage: ClaudeMessage? {
        return conversationHistory.last
    }
    
    var isActive: Bool {
        return status == .processing || Date().timeIntervalSince(lastActivity) < 300 // 5 minutes
    }
    
    var contextDescription: String {
        var contexts: [String] = []
        
        if let projectId = projectId {
            contexts.append("Project: \(projectId)")
        }
        
        if let agentId = agentId {
            contexts.append("Agent: \(agentId)")
        }
        
        contexts.append("Directory: \(workingDirectory.lastPathComponent)")
        
        return contexts.joined(separator: " • ")
    }
    
    var statusColor: Color {
        switch status {
        case .ready:
            return .green
        case .processing:
            return .blue
        case .error:
            return .red
        case .paused:
            return .orange
        case .completed:
            return .gray
        }
    }
    
    // MARK: - Session Operations
    
    mutating func addMessage(_ message: ClaudeMessage) {
        conversationHistory.append(message)
        lastActivity = Date()
        
        if let tokens = message.tokens {
            self.tokens.addTokens(tokens, isInput: message.role == .user)
        }
    }
    
    mutating func updateStatus(_ newStatus: SessionStatus) {
        status = newStatus
        lastActivity = Date()
    }
    
    mutating func updateWorkingDirectory(_ directory: URL) {
        workingDirectory = directory
        lastActivity = Date()
    }
    
    mutating func addMetadata(key: String, value: String) {
        metadata[key] = value
        lastActivity = Date()
    }
    
    mutating func clearHistory() {
        conversationHistory.removeAll()
        tokens = TokenUsage()
        lastActivity = Date()
    }
    
    static func == (lhs: ClaudeSession, rhs: ClaudeSession) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Session Status
enum SessionStatus: String, Codable, CaseIterable {
    case ready = "ready"
    case processing = "processing"
    case error = "error"
    case paused = "paused"
    case completed = "completed"
    
    var displayName: String {
        switch self {
        case .ready:
            return "Ready"
        case .processing:
            return "Processing"
        case .error:
            return "Error"
        case .paused:
            return "Paused"
        case .completed:
            return "Completed"
        }
    }
    
    var iconName: String {
        switch self {
        case .ready:
            return "checkmark.circle.fill"
        case .processing:
            return "arrow.clockwise"
        case .error:
            return "exclamationmark.triangle.fill"
        case .paused:
            return "pause.circle.fill"
        case .completed:
            return "checkmark.circle"
        }
    }
}

// MARK: - Claude Message Model
struct ClaudeMessage: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let content: String
    let role: MessageRole
    let timestamp: Date
    var tokens: Int?
    var metadata: [String: String]?
    var attachments: [MessageAttachment]?
    
    init(
        id: UUID = UUID(),
        content: String,
        role: MessageRole,
        timestamp: Date = Date(),
        tokens: Int? = nil,
        metadata: [String: String]? = nil,
        attachments: [MessageAttachment]? = nil
    ) {
        self.id = id
        self.content = content
        self.role = role
        self.timestamp = timestamp
        self.tokens = tokens
        self.metadata = metadata
        self.attachments = attachments
    }
    
    // MARK: - Computed Properties
    
    var displayContent: String {
        // Process content for display (e.g., syntax highlighting, markdown)
        return content
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    var isFromUser: Bool {
        return role == .user
    }
    
    var isFromClaude: Bool {
        return role == .assistant
    }
    
    var hasAttachments: Bool {
        return attachments?.isEmpty == false
    }
    
    static func == (lhs: ClaudeMessage, rhs: ClaudeMessage) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Message Role
enum MessageRole: String, Codable, CaseIterable {
    case user = "user"
    case assistant = "assistant"
    case system = "system"
    case error = "error"
    
    var displayName: String {
        switch self {
        case .user:
            return "You"
        case .assistant:
            return "Claude"
        case .system:
            return "System"
        case .error:
            return "Error"
        }
    }
    
    var color: Color {
        switch self {
        case .user:
            return .blue
        case .assistant:
            return .green
        case .system:
            return .gray
        case .error:
            return .red
        }
    }
    
    var iconName: String {
        switch self {
        case .user:
            return "person.circle.fill"
        case .assistant:
            return "brain.head.profile"
        case .system:
            return "gear"
        case .error:
            return "exclamationmark.triangle"
        }
    }
}

// MARK: - Message Attachment
struct MessageAttachment: Identifiable, Codable {
    let id: UUID
    let name: String
    let path: String
    let type: AttachmentType
    let size: Int64
    let createdAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        path: String,
        type: AttachmentType,
        size: Int64,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.type = type
        self.size = size
        self.createdAt = createdAt
    }
    
    var sizeFormatted: String {
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

enum AttachmentType: String, Codable {
    case file = "file"
    case image = "image"
    case code = "code"
    case document = "document"
    
    var iconName: String {
        switch self {
        case .file:
            return "doc"
        case .image:
            return "photo"
        case .code:
            return "chevron.left.forwardslash.chevron.right"
        case .document:
            return "doc.text"
        }
    }
}

// MARK: - Token Usage Tracking
struct TokenUsage: Codable {
    var inputTokens: Int = 0
    var outputTokens: Int = 0
    var totalSessions: Int = 0
    var averagePerMessage: Double = 0
    var lastUpdated: Date = Date()
    
    var totalTokens: Int {
        return inputTokens + outputTokens
    }
    
    var costEstimate: Double {
        // Rough Claude pricing estimate
        let inputCost = Double(inputTokens) * 0.008 / 1000.0  // $0.008 per 1k input tokens
        let outputCost = Double(outputTokens) * 0.024 / 1000.0  // $0.024 per 1k output tokens
        return inputCost + outputCost
    }
    
    mutating func addTokens(_ tokens: Int, isInput: Bool = false) {
        if isInput {
            inputTokens += tokens
        } else {
            outputTokens += tokens
        }
        
        updateAverage()
        lastUpdated = Date()
    }
    
    private mutating func updateAverage() {
        totalSessions += 1
        averagePerMessage = Double(totalTokens) / Double(totalSessions)
    }
    
    mutating func reset() {
        inputTokens = 0
        outputTokens = 0
        totalSessions = 0
        averagePerMessage = 0
        lastUpdated = Date()
    }
}

// MARK: - Process Result Model
struct ProcessResult {
    let output: String
    let errorOutput: String?
    let exitCode: Int32
    let duration: TimeInterval
    let tokens: Int?
    let fileOperations: [FileOperation]
    let success: Bool
    
    init(
        output: String,
        errorOutput: String? = nil,
        exitCode: Int32,
        duration: TimeInterval,
        tokens: Int? = nil,
        fileOperations: [FileOperation] = []
    ) {
        self.output = output
        self.errorOutput = errorOutput
        self.exitCode = exitCode
        self.duration = duration
        self.tokens = tokens
        self.fileOperations = fileOperations
        self.success = exitCode == 0
    }
}

// MARK: - Session Extensions for UI
extension ClaudeSession {
    
    /// Get recent messages for display (last 10 by default)
    func recentMessages(limit: Int = 10) -> [ClaudeMessage] {
        return Array(conversationHistory.suffix(limit))
    }
    
    /// Get messages by role
    func messages(by role: MessageRole) -> [ClaudeMessage] {
        return conversationHistory.filter { $0.role == role }
    }
    
    /// Search messages by content
    func searchMessages(_ query: String) -> [ClaudeMessage] {
        return conversationHistory.filter {
            $0.content.localizedCaseInsensitiveContains(query)
        }
    }
    
    /// Get session duration
    var duration: TimeInterval {
        guard let firstMessage = conversationHistory.first else { return 0 }
        return lastActivity.timeIntervalSince(firstMessage.timestamp)
    }
    
    /// Format session summary
    var summary: String {
        return """
        Session: \(displayName)
        Messages: \(messageCount)
        Tokens: \(totalTokens)
        Duration: \(formatDuration(duration))
        Status: \(status.displayName)
        """
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "0s"
    }
}