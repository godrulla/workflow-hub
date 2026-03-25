import SwiftUI

/// Intelligent command input view with auto-completion and history
struct TerminalInputView<T: TerminalManagerProtocol>: View {
    @ObservedObject var terminalManager: T
    @State private var currentCommand = ""
    @State private var suggestions: [CommandSuggestion] = []
    @State private var showingSuggestions = false
    @State private var historyIndex = -1
    @State private var originalCommand = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Suggestions Popup
            if showingSuggestions && !suggestions.isEmpty {
                SuggestionPopupView(
                    suggestions: suggestions,
                    onSelect: { suggestion in
                        selectSuggestion(suggestion)
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // Input Area
            HStack(spacing: 12) {
                // Prompt Indicator
                HStack(spacing: 4) {
                    Image(systemName: promptIcon)
                        .foregroundColor(promptColor)
                        .font(.caption)
                    
                    Text(promptText)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondaryText)
                }
                .frame(minWidth: 60, alignment: .trailing)
                
                // Command Input
                TextField("Enter Claude command...", text: $currentCommand)
                    .textFieldStyle(.plain)
                    .font(.system(.body, design: .monospaced))
                    .focused($isInputFocused)
                    .onSubmit {
                        submitCommand()
                    }
                    .onChange(of: currentCommand) { _, newValue in
                        handleCommandChange(newValue)
                    }
                    .onKeyPress(.upArrow) {
                        navigateHistory(direction: .up)
                        return .handled
                    }
                    .onKeyPress(.downArrow) {
                        navigateHistory(direction: .down)
                        return .handled
                    }
                    .onKeyPress(.tab) {
                        if let firstSuggestion = suggestions.first {
                            selectSuggestion(firstSuggestion)
                            return .handled
                        }
                        return .ignored
                    }
                    .onKeyPress(.escape) {
                        if terminalManager.isExecuting {
                            terminalManager.interruptExecution()
                        } else {
                            currentCommand = ""
                            suggestions = []
                            showingSuggestions = false
                        }
                        return .handled
                    }
                
                // Action Buttons
                HStack(spacing: 6) {
                    // Interrupt Button (when executing)
                    if terminalManager.isExecuting {
                        Button(action: { terminalManager.interruptExecution() }) {
                            Image(systemName: "stop.circle.fill")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                        .help("Stop Execution (Esc)")
                    }
                    
                    // Send Button
                    Button(action: { submitCommand() }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(currentCommand.isEmpty ? .gray : .blue)
                    }
                    .buttonStyle(.plain)
                    .disabled(currentCommand.isEmpty || terminalManager.isExecuting)
                    .help("Send Command (Enter)")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.primaryBackground)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray.opacity(0.2)),
                alignment: .top
            )
        }
        .onAppear {
            isInputFocused = true
        }
        .animation(.easeInOut(duration: 0.2), value: showingSuggestions)
    }
    
    // MARK: - Computed Properties
    
    private var promptIcon: String {
        if terminalManager.isExecuting {
            return "arrow.clockwise"
        } else if let session = terminalManager.activeSession, session.status == .error {
            return "exclamationmark.triangle"
        } else {
            return "chevron.right"
        }
    }
    
    private var promptColor: Color {
        if terminalManager.isExecuting {
            return .blue
        } else if let session = terminalManager.activeSession, session.status == .error {
            return .red
        } else {
            return .green
        }
    }
    
    private var promptText: String {
        if let session = terminalManager.activeSession {
            let dir = session.workingDirectory.lastPathComponent
            return "~/\(dir)>"
        } else {
            return "claude>"
        }
    }
    
    // MARK: - Command Handling
    
    private func submitCommand() {
        guard !currentCommand.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        guard !terminalManager.isExecuting else { return }
        
        let command = currentCommand.trimmingCharacters(in: .whitespaces)
        
        // Add to command history
        addToHistory(command)
        
        // Clear input
        currentCommand = ""
        suggestions = []
        showingSuggestions = false
        historyIndex = -1
        
        // Execute command
        Task {
            await terminalManager.executeCommand(command)
        }
        
        // Maintain focus
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isInputFocused = true
        }
    }
    
    private func handleCommandChange(_ newValue: String) {
        // Reset history navigation
        if historyIndex >= 0 && newValue != getHistoryCommand(at: historyIndex) {
            historyIndex = -1
        }
        
        // Generate suggestions
        generateSuggestions(for: newValue)
    }
    
    private func generateSuggestions(for input: String) {
        let trimmedInput = input.trimmingCharacters(in: .whitespaces).lowercased()
        
        guard !trimmedInput.isEmpty else {
            suggestions = []
            showingSuggestions = false
            return
        }
        
        var newSuggestions: [CommandSuggestion] = []
        
        // Claude commands
        for command in claudeCommands {
            if command.command.lowercased().hasPrefix(trimmedInput) {
                newSuggestions.append(command)
            }
        }
        
        // History suggestions
        for historyCommand in commandHistory.reversed() {
            if historyCommand.lowercased().contains(trimmedInput) {
                newSuggestions.append(CommandSuggestion(
                    command: historyCommand,
                    description: "From history",
                    category: .history
                ))
            }
        }
        
        // Context-aware suggestions
        if let session = terminalManager.activeSession {
            newSuggestions.append(contentsOf: contextSuggestions(for: trimmedInput, session: session))
        }
        
        // Limit suggestions
        suggestions = Array(newSuggestions.prefix(8))
        showingSuggestions = !suggestions.isEmpty
    }
    
    private func selectSuggestion(_ suggestion: CommandSuggestion) {
        currentCommand = suggestion.command
        suggestions = []
        showingSuggestions = false
        
        // Auto-submit for some commands
        if suggestion.autoSubmit {
            submitCommand()
        }
    }
    
    // MARK: - History Navigation
    
    private func navigateHistory(direction: HistoryDirection) {
        guard !commandHistory.isEmpty else { return }
        
        if historyIndex == -1 {
            originalCommand = currentCommand
        }
        
        switch direction {
        case .up:
            if historyIndex < commandHistory.count - 1 {
                historyIndex += 1
                currentCommand = getHistoryCommand(at: historyIndex)
            }
        case .down:
            if historyIndex > 0 {
                historyIndex -= 1
                currentCommand = getHistoryCommand(at: historyIndex)
            } else if historyIndex == 0 {
                historyIndex = -1
                currentCommand = originalCommand
            }
        }
    }
    
    private func getHistoryCommand(at index: Int) -> String {
        let reversedIndex = commandHistory.count - 1 - index
        return commandHistory[reversedIndex]
    }
    
    private var commandHistory: [String] {
        // Get history from active session
        guard let session = terminalManager.activeSession else { return [] }
        return session.conversationHistory
            .filter { $0.role == .user }
            .map { $0.content }
    }
    
    private func addToHistory(_ command: String) {
        // History is automatically managed by the session
    }
    
    // MARK: - Context Suggestions
    
    private func contextSuggestions(for input: String, session: ClaudeSession) -> [CommandSuggestion] {
        var suggestions: [CommandSuggestion] = []
        
        // Project-specific suggestions
        if let projectId = session.projectId {
            if input.contains("project") || input.contains("analyze") {
                suggestions.append(CommandSuggestion(
                    command: "claude analyze project \(projectId)",
                    description: "Analyze current project",
                    category: .project
                ))
            }
        }
        
        // Agent-specific suggestions
        if let agentId = session.agentId {
            if input.contains("agent") || input.contains("task") {
                suggestions.append(CommandSuggestion(
                    command: "claude assign task to \(agentId)",
                    description: "Assign task to \(agentId)",
                    category: .agent
                ))
            }
        }
        
        // File operation suggestions
        if input.contains("create") || input.contains("edit") {
            suggestions.append(CommandSuggestion(
                command: "claude create file",
                description: "Create a new file",
                category: .file
            ))
        }
        
        return suggestions
    }
}

// MARK: - Suggestion Popup View
struct SuggestionPopupView: View {
    let suggestions: [CommandSuggestion]
    let onSelect: (CommandSuggestion) -> Void
    @State private var selectedIndex = 0
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(suggestions.enumerated()), id: \.element.id) { index, suggestion in
                SuggestionRowView(
                    suggestion: suggestion,
                    isSelected: index == selectedIndex
                )
                .onTapGesture {
                    onSelect(suggestion)
                }
                .background(
                    index == selectedIndex ? Color.accentColor.opacity(0.1) : Color.clear
                )
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

struct SuggestionRowView: View {
    let suggestion: CommandSuggestion
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: suggestion.category.iconName)
                .foregroundColor(suggestion.category.color)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(suggestion.command)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.primaryText)
                
                if !suggestion.description.isEmpty {
                    Text(suggestion.description)
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                }
            }
            
            Spacer()
            
            if suggestion.autoSubmit {
                Image(systemName: "return")
                    .font(.caption2)
                    .foregroundColor(.tertiaryText)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

// MARK: - Command Suggestion Model
struct CommandSuggestion: Identifiable {
    let id = UUID()
    let command: String
    let description: String
    let category: SuggestionCategory
    var autoSubmit: Bool = false
    
    init(command: String, description: String, category: SuggestionCategory, autoSubmit: Bool = false) {
        self.command = command
        self.description = description
        self.category = category
        self.autoSubmit = autoSubmit
    }
}

enum SuggestionCategory {
    case claude
    case project
    case agent
    case file
    case history
    
    var iconName: String {
        switch self {
        case .claude:
            return "brain.head.profile"
        case .project:
            return "folder"
        case .agent:
            return "person.circle"
        case .file:
            return "doc"
        case .history:
            return "clock"
        }
    }
    
    var color: Color {
        switch self {
        case .claude:
            return .blue
        case .project:
            return .orange
        case .agent:
            return .green
        case .file:
            return .purple
        case .history:
            return .gray
        }
    }
}

enum HistoryDirection {
    case up
    case down
}

// MARK: - Claude Commands Database
private let claudeCommands: [CommandSuggestion] = [
    CommandSuggestion(
        command: "claude --help",
        description: "Show Claude CLI help",
        category: .claude
    ),
    CommandSuggestion(
        command: "claude --version",
        description: "Show Claude version",
        category: .claude
    ),
    CommandSuggestion(
        command: "claude create project",
        description: "Create a new project",
        category: .project
    ),
    CommandSuggestion(
        command: "claude analyze code",
        description: "Analyze code in current directory",
        category: .file
    ),
    CommandSuggestion(
        command: "claude create file",
        description: "Create a new file",
        category: .file
    ),
    CommandSuggestion(
        command: "claude edit file",
        description: "Edit an existing file",
        category: .file
    ),
    CommandSuggestion(
        command: "claude create agent",
        description: "Create a new agent",
        category: .agent
    ),
    CommandSuggestion(
        command: "claude assign task",
        description: "Assign task to an agent",
        category: .agent
    ),
    CommandSuggestion(
        command: "claude list agents",
        description: "List all available agents",
        category: .agent
    ),
    CommandSuggestion(
        command: "claude optimize project",
        description: "Optimize current project",
        category: .project
    ),
    CommandSuggestion(
        command: "claude generate docs",
        description: "Generate documentation",
        category: .file
    ),
    CommandSuggestion(
        command: "claude review code",
        description: "Review code changes",
        category: .file
    ),
    CommandSuggestion(
        command: "claude test project",
        description: "Run project tests",
        category: .project
    ),
    CommandSuggestion(
        command: "claude deploy project",
        description: "Deploy project to production",
        category: .project
    )
]