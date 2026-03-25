import SwiftUI

// Protocol for terminal managers
@preconcurrency protocol TerminalManagerProtocol: ObservableObject {
    var sessions: [ClaudeSession] { get }
    var activeSession: ClaudeSession? { get }
    var isExecuting: Bool { get }
    var lastError: TerminalError? { get }
    
    func createSession(projectId: String?, agentId: String?) -> ClaudeSession
    func activateSession(_ session: ClaudeSession)
    func closeSession(_ sessionId: UUID)
    func executeCommand(_ command: String) async
    func interruptExecution()
    func clearSessionHistory(_ sessionId: UUID)
}

// Temporary simplified terminal manager for testing
class TemporaryTerminalManager: ObservableObject, TerminalManagerProtocol {
    @Published var sessions: [ClaudeSession] = []
    @Published var activeSession: ClaudeSession? = nil
    @Published var isExecuting: Bool = false
    @Published var lastError: TerminalError? = nil
    
    init() {
        // Create a default session for testing
        let defaultSession = ClaudeSession()
        sessions.append(defaultSession)
        activeSession = defaultSession
    }
    
    func createSession(projectId: String? = nil, agentId: String? = nil) -> ClaudeSession {
        let session = ClaudeSession(projectId: projectId, agentId: agentId)
        sessions.append(session)
        activeSession = session
        return session
    }
    
    func activateSession(_ session: ClaudeSession) {
        activeSession = session
    }
    
    func closeSession(_ sessionId: UUID) {
        sessions.removeAll { $0.id == sessionId }
        if activeSession?.id == sessionId {
            activeSession = sessions.first
        }
    }
    
    func executeCommand(_ command: String) async {
        isExecuting = true
        
        // Simulate command execution
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Add mock response
        if activeSession != nil {
            let userMessage = ClaudeMessage(content: command, role: .user)
            let responseMessage = ClaudeMessage(content: "Mock response from Claude: Received command '\(command)'", role: .assistant)
            
            activeSession?.conversationHistory.append(userMessage)
            activeSession?.conversationHistory.append(responseMessage)
        }
        
        isExecuting = false
    }
    
    func interruptExecution() {
        isExecuting = false
    }
    
    func clearSessionHistory(_ sessionId: UUID) {
        if let index = sessions.firstIndex(where: { $0.id == sessionId }) {
            sessions[index].conversationHistory.removeAll()
        }
    }
}

/// Main Claude Code terminal interface with split-pane layout
struct ClaudeTerminalView: View {
    @StateObject private var terminalManager = TerminalManager.shared
    @EnvironmentObject private var appState: AppStateManager
    @State private var showingSessionSelector = false
    @State private var showingAgentPanel = true
    @State private var terminalSplitPosition: CGFloat = 0.7
    @State private var terminalHeight: CGFloat = 400
    
    var body: some View {
        HSplitView {
            // Terminal Pane (Left) - Highly flexible and resizable
            VStack(spacing: 0) {
                // Terminal Header
                TerminalHeaderView(
                    terminalManager: terminalManager,
                    showingSessionSelector: $showingSessionSelector,
                    showingAgentPanel: $showingAgentPanel
                )
                
                // Terminal Content - Flexible vertical layout
                VSplitView {
                    // Output Area - Resizable
                    SimpleTerminalOutputView(terminalManager: terminalManager)
                        .frame(minHeight: 200)
                        .layoutPriority(1)
                    
                    // Input Area - Fixed but expandable
                    VStack(spacing: 0) {
                        Divider()
                        TerminalInputView(terminalManager: terminalManager)
                            .frame(minHeight: 60, maxHeight: 200)
                    }
                }
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(8, corners: [.bottomLeft, .bottomRight])
            }
            .frame(minWidth: 300, idealWidth: 600)
            .layoutPriority(1)
            
            // Agent Management Pane (Right) - Collapsible and flexible
            if showingAgentPanel {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Elite Agents")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: { withAnimation { showingAgentPanel.toggle() } }) {
                            Image(systemName: "xmark.circle")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Close Agent Panel")
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            Text("🤖 ARQ - Architecture Specialist")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("🎼 ORC - Orchestration Manager") 
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("🧘 ZEN - Performance Optimizer")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("⚡ VEX - Execution Specialist")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("🧠 SAGE - Strategic Advisor")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("✨ NOVA - Innovation Catalyst")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("🔮 ECHO - Intelligence Amplifier")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer(minLength: 20)
                            
                            Text("Full Elite Agents integration coming soon...")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .frame(minWidth: 250, idealWidth: 350, maxWidth: 450)
                .background(Color.secondary.opacity(0.05))
                .transition(.move(edge: .trailing))
            }
        }
        .navigationTitle("Claude Terminal")
        .toolbar(content: {
            ToolbarItemGroup(placement: .navigation) {
                Button(action: { withAnimation { showingAgentPanel.toggle() } }) {
                    Image(systemName: showingAgentPanel ? "sidebar.trailing.fill" : "sidebar.trailing")
                }
                .help(showingAgentPanel ? "Hide Elite Agents Panel" : "Show Elite Agents Panel")
            }
            
            ToolbarItemGroup(placement: .principal) {
                HStack {
                    Text("Claude Terminal")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if terminalManager.isExecuting {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            
            ToolbarItemGroup(placement: .primaryAction) {
                Button("New Session") {
                    createNewSession()
                }
                .keyboardShortcut("t", modifiers: .command)
                .help("New Terminal Session (⌘T)")
                
                Button("Clear Terminal") {
                    clearCurrentSession()
                }
                .keyboardShortcut("k", modifiers: .command)
                .help("Clear Current Session (⌘K)")
                
                Menu("Layout") {
                    Button("Maximize Terminal") {
                        withAnimation {
                            showingAgentPanel = false
                        }
                    }
                    
                    Button("Show All Panels") {
                        withAnimation {
                            showingAgentPanel = true
                        }
                    }
                    
                    Divider()
                    
                    Button("Reset Layout") {
                        withAnimation {
                            showingAgentPanel = true
                            terminalSplitPosition = 0.7
                        }
                    }
                } primaryAction: {
                    // Default layout action
                    withAnimation {
                        showingAgentPanel.toggle()
                    }
                }
                .help("Layout Options")
            }
        })
        .sheet(isPresented: $showingSessionSelector) {
            SessionSelectorView(terminalManager: terminalManager)
        }
        .onAppear {
            // Ensure we have an active session
            if terminalManager.activeSession == nil {
                createNewSession()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showingAgentPanel)
    }
    
    private func createNewSession() {
        let session = terminalManager.createSession(
            projectId: appState.selectedProject?.name,
            agentId: appState.selectedAgent?.name
        )
        terminalManager.activateSession(session)
    }
    
    private func clearCurrentSession() {
        terminalManager.activeSession?.clearHistory()
    }
}

// MARK: - Terminal Header View
struct TerminalHeaderView<T: TerminalManagerProtocol>: View {
    @ObservedObject var terminalManager: T
    @Binding var showingSessionSelector: Bool
    @Binding var showingAgentPanel: Bool
    
    var body: some View {
        HStack {
            // Session Info
            HStack(spacing: 12) {
                // Claude Status Indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                    
                    Text("Claude CLI")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(statusText)
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                }
                
                Divider()
                    .frame(height: 16)
                
                // Active Session
                if let session = terminalManager.activeSession {
                    Button(action: { showingSessionSelector = true }) {
                        HStack(spacing: 4) {
                            Text(session.displayName)
                                .font(.subheadline)
                                .foregroundColor(.primaryText)
                            
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                                .foregroundColor(.secondaryText)
                        }
                    }
                    .buttonStyle(.plain)
                    .help("Select Session")
                    
                    if !session.contextDescription.isEmpty {
                        Text("•")
                            .foregroundColor(.tertiaryText)
                        
                        Text(session.contextDescription)
                            .font(.caption)
                            .foregroundColor(.secondaryText)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            // Quick Actions
            HStack(spacing: 8) {
                // Session Count
                if terminalManager.sessions.count > 1 {
                    Text("\(terminalManager.sessions.count) sessions")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accent.opacity(0.1))
                        .foregroundColor(.accent)
                        .cornerRadius(4)
                }
                
                // Processing Indicator
                if terminalManager.isExecuting {
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: 12, height: 12)
                }
                
                // Quick Actions
                Button(action: { showingAgentPanel.toggle() }) {
                    Image(systemName: "person.3.fill")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Toggle Agent Panel")
                
                Button("Export") {
                    exportSession()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.primaryBackground)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.2)),
            alignment: .bottom
        )
    }
    
    private var statusColor: Color {
        if terminalManager.isExecuting {
            return .blue
        } else if terminalManager.lastError != nil {
            return .red
        } else if terminalManager.activeSession != nil {
            return .green
        } else {
            return .gray
        }
    }
    
    private var statusText: String {
        if terminalManager.isExecuting {
            return "Processing"
        } else if terminalManager.lastError != nil {
            return "Error"
        } else if terminalManager.activeSession != nil {
            return "Ready"
        } else {
            return "Disconnected"
        }
    }
    
    private func exportSession() {
        guard let session = terminalManager.activeSession else { return }
        
        // Create export content
        let exportContent = createSessionExport(session)
        
        // Show save panel
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.plainText]
        savePanel.nameFieldStringValue = "claude-session-\(session.id.uuidString.prefix(8)).txt"
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            do {
                try exportContent.write(to: url, atomically: true, encoding: .utf8)
            } catch {
                print("Failed to export session: \(error)")
            }
        }
    }
    
    private func createSessionExport(_ session: ClaudeSession) -> String {
        var export = """
        Claude Terminal Session Export
        ==============================
        Session ID: \(session.id)
        Created: \(session.conversationHistory.first?.timestamp ?? Date())
        Messages: \(session.messageCount)
        Tokens: \(session.totalTokens)
        Context: \(session.contextDescription)
        
        Conversation:
        
        """
        
        for message in session.conversationHistory {
            export += """
            
            [\(message.timestamp)] \(message.role.displayName):
            \(message.content)
            """
            
            if let tokens = message.tokens {
                export += " (\(tokens) tokens)"
            }
            
            export += "\n"
        }
        
        return export
    }
}

// MARK: - Session Selector View
struct SessionSelectorView<T: TerminalManagerProtocol>: View {
    @ObservedObject var terminalManager: T
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSession: ClaudeSession?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Sessions List
                List(terminalManager.sessions, selection: $selectedSession) { session in
                    SessionRowView(session: session, isActive: session.id == terminalManager.activeSession?.id)
                        .tag(session)
                        .onTapGesture {
                            selectedSession = session
                        }
                }
                .listStyle(.inset)
                
                // Actions
                HStack {
                    Button("New Session") {
                        let newSession = terminalManager.createSession(projectId: nil, agentId: nil)
                        selectedSession = newSession
                    }
                    
                    Spacer()
                    
                    if let selected = selectedSession {
                        Button("Delete", role: .destructive) {
                            terminalManager.closeSession(selected.id)
                            selectedSession = nil
                        }
                        .disabled(terminalManager.sessions.count <= 1)
                    }
                }
                .padding()
                .background(Color.secondaryBackground)
            }
            .navigationTitle("Sessions")
            .toolbar(content: {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Select") {
                        if let selected = selectedSession {
                            terminalManager.activateSession(selected)
                        }
                        dismiss()
                    }
                    .disabled(selectedSession == nil)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            })
        }
        .frame(width: 500, height: 400)
        .onAppear {
            selectedSession = terminalManager.activeSession
        }
    }
}

struct SessionRowView: View {
    let session: ClaudeSession
    let isActive: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(session.displayName)
                        .font(.headline)
                        .fontWeight(isActive ? .semibold : .regular)
                    
                    if isActive {
                        Text("Active")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.1))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    }
                }
                
                if !session.contextDescription.isEmpty {
                    Text(session.contextDescription)
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                }
                
                HStack {
                    Text("\(session.messageCount) messages")
                        .font(.caption2)
                        .foregroundColor(.tertiaryText)
                    
                    Text("•")
                        .font(.caption2)
                        .foregroundColor(.tertiaryText)
                    
                    Text(session.lastActivity.formatted(.relative(presentation: .named)))
                        .font(.caption2)
                        .foregroundColor(.tertiaryText)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Image(systemName: session.status.iconName)
                    .foregroundColor(session.statusColor)
                
                if session.totalTokens > 0 {
                    Text("\(session.totalTokens) tokens")
                        .font(.caption2)
                        .foregroundColor(.secondaryText)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: RectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: RectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let topLeft = corners.contains(.topLeft)
        let topRight = corners.contains(.topRight)
        let bottomLeft = corners.contains(.bottomLeft)
        let bottomRight = corners.contains(.bottomRight)
        
        path.move(to: CGPoint(x: rect.minX + (topLeft ? radius : 0), y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - (topRight ? radius : 0), y: rect.minY))
        
        if topRight {
            path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.minY + radius),
                       radius: radius, startAngle: Angle(degrees: -90), endAngle: Angle(degrees: 0), clockwise: false)
        }
        
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - (bottomRight ? radius : 0)))
        
        if bottomRight {
            path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.maxY - radius),
                       radius: radius, startAngle: Angle(degrees: 0), endAngle: Angle(degrees: 90), clockwise: false)
        }
        
        path.addLine(to: CGPoint(x: rect.minX + (bottomLeft ? radius : 0), y: rect.maxY))
        
        if bottomLeft {
            path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.maxY - radius),
                       radius: radius, startAngle: Angle(degrees: 90), endAngle: Angle(degrees: 180), clockwise: false)
        }
        
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + (topLeft ? radius : 0)))
        
        if topLeft {
            path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.minY + radius),
                       radius: radius, startAngle: Angle(degrees: 180), endAngle: Angle(degrees: 270), clockwise: false)
        }
        
        return path
    }
}

struct RectCorner: OptionSet {
    let rawValue: Int
    
    static let topLeft = RectCorner(rawValue: 1 << 0)
    static let topRight = RectCorner(rawValue: 1 << 1)
    static let bottomLeft = RectCorner(rawValue: 1 << 2)
    static let bottomRight = RectCorner(rawValue: 1 << 3)
    
    static let allCorners: RectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
}

// MARK: - Preview
#if DEBUG
struct ClaudeTerminalView_Previews: PreviewProvider {
    static var previews: some View {
        ClaudeTerminalView()
            .environmentObject(AppStateManager.shared)
            .frame(width: 1200, height: 800)
    }
}
#endif