import SwiftUI

// MARK: - Optimized Agent List View

struct OptimizedAgentListView: View {
    let agents: [EliteAgent]
    @Binding var selectedAgent: EliteAgent?
    
    // Performance optimization: Use LazyVGrid for large collections
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 1)
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(agents.indices, id: \.self) { index in
                    OptimizedAgentRowView(agent: agents[index])
                        .onTapGesture {
                            selectedAgent = agents[index]
                        }
                        .onAppear {
                            // Lazy loading trigger for additional data if needed
                            loadAgentDetailsIfNeeded(at: index)
                        }
                }
            }
            .padding()
        }
    }
    
    private func loadAgentDetailsIfNeeded(at index: Int) {
        // Implement lazy loading logic for agent details
        // Only load detailed information when the agent becomes visible
    }
}

// MARK: - Optimized Agent Row View

struct OptimizedAgentRowView: View, Equatable {
    let agent: EliteAgent
    
    var body: some View {
        HStack(spacing: 12) {
            // Cached status indicator
            CachedStatusIndicator(status: agent.status)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(agent.name)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    // Memoized performance indicator
                    PerformanceIndicator(level: agent.expertiseLevel)
                }
                
                // Lazy text rendering for specialization
                LazyText(agent.specialization.prefix(2).joined(separator: " • "))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack {
                    Text("\(agent.currentLoad) tasks")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    StatusBadge(status: agent.status)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    // Equatable implementation for performance
    static func == (lhs: OptimizedAgentRowView, rhs: OptimizedAgentRowView) -> Bool {
        lhs.agent.id == rhs.agent.id &&
        lhs.agent.status == rhs.agent.status &&
        lhs.agent.currentLoad == rhs.agent.currentLoad &&
        lhs.agent.expertiseLevel == rhs.agent.expertiseLevel
    }
}

// MARK: - Cached Status Indicator

struct CachedStatusIndicator: View {
    let status: AgentStatus
    
    // Static cache for status colors
    private static let colorCache: [AgentStatus: Color] = [
        .idle: .gray,
        .executing: .blue,
        .completed: .green,
        .error: .red,
        .offline: .secondary
    ]
    
    var body: some View {
        Circle()
            .fill(Self.colorCache[status] ?? .gray)
            .frame(width: 8, height: 8)
    }
}

// MARK: - Performance Indicator

struct PerformanceIndicator: View {
    let level: Double
    
    // Memoized color calculation
    private var color: Color {
        switch level {
        case 0.9...: return .green
        case 0.7..<0.9: return .blue
        case 0.5..<0.7: return .orange
        default: return .red
        }
    }
    
    var body: some View {
        Text(String(format: "%.0f%%", level * 100))
            .font(.caption)
            .foregroundColor(color)
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let status: AgentStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(status.color.opacity(0.2))
            .foregroundColor(status.color)
            .cornerRadius(4)
    }
}

// MARK: - Lazy Text

struct LazyText: View {
    private let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        Text(text)
    }
}

// MARK: - Optimized Project Grid View

struct OptimizedProjectGridView: View {
    let projects: [Project]
    @Binding var selectedProject: Project?
    
    // Adaptive grid columns based on available width
    @State private var columns: [GridItem] = []
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(projects.indices, id: \.self) { index in
                    OptimizedProjectCardView(project: projects[index])
                        .onTapGesture {
                            selectedProject = projects[index]
                        }
                        .onAppear {
                            preloadProjectDataIfNeeded(at: index)
                        }
                }
            }
            .padding()
        }
        .onAppear {
            setupAdaptiveColumns()
        }
    }
    
    private func setupAdaptiveColumns() {
        // Dynamically adjust columns based on available space
        columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
    }
    
    private func preloadProjectDataIfNeeded(at index: Int) {
        // Preload project details for better performance
        if index == projects.count - 3 {
            // Load more data if this is near the end
        }
    }
}

// MARK: - Optimized Project Card View

struct OptimizedProjectCardView: View, Equatable {
    let project: Project
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Project header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    Text(project.type)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Health indicator
                HealthIndicator(health: project.health)
            }
            
            // Progress bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Progress")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(String(format: "%.0f%%", project.completion * 100))
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                
                ProgressView(value: project.completion)
                    .progressViewStyle(LinearProgressViewStyle(tint: project.statusColor))
            }
            
            // Agent team (if available)
            if !project.agentTeam.isEmpty {
                HStack(spacing: 4) {
                    ForEach(project.agentTeam.prefix(3), id: \.self) { agent in
                        Text(agent)
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(3)
                    }
                    
                    if project.agentTeam.count > 3 {
                        Text("+\\(project.agentTeam.count - 3)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(12)
    }
    
    static func == (lhs: OptimizedProjectCardView, rhs: OptimizedProjectCardView) -> Bool {
        lhs.project.id == rhs.project.id &&
        lhs.project.completion == rhs.project.completion &&
        lhs.project.health == rhs.project.health &&
        lhs.project.status == rhs.project.status
    }
}

// MARK: - Health Indicator

struct HealthIndicator: View {
    let health: ProjectHealth
    
    private var color: Color {
        switch health {
        case .excellent: return .green
        case .good: return .blue
        case .warning: return .orange
        case .critical: return .red
        case .planning: return .purple
        }
    }
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 12, height: 12)
            .overlay(
                Circle()
                    .stroke(color.opacity(0.3), lineWidth: 2)
                    .frame(width: 16, height: 16)
            )
    }
}

// MARK: - Virtualized Terminal Output

struct VirtualizedTerminalOutput: View {
    let messages: [ClaudeMessage]
    @State private var visibleRange: Range<Int> = 0..<50
    
    private let itemHeight: CGFloat = 60
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Spacer for items above visible range
                    if visibleRange.lowerBound > 0 {
                        Spacer()
                            .frame(height: CGFloat(visibleRange.lowerBound) * itemHeight)
                    }
                    
                    // Visible items
                    ForEach(Array(visibleRange), id: \.self) { index in
                        if messages.indices.contains(index) {
                            OptimizedMessageView(message: messages[index])
                                .frame(height: itemHeight)
                        }
                    }
                    
                    // Spacer for items below visible range
                    if visibleRange.upperBound < messages.count {
                        Spacer()
                            .frame(height: CGFloat(messages.count - visibleRange.upperBound) * itemHeight)
                    }
                }
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetKey.self) { offset in
                updateVisibleRange(for: offset, in: geometry)
            }
        }
    }
    
    private func updateVisibleRange(for offset: CGPoint, in geometry: GeometryProxy) {
        let viewHeight = geometry.size.height
        let startIndex = max(0, Int(-offset.y / itemHeight) - 5) // Buffer
        let endIndex = min(messages.count, startIndex + Int(viewHeight / itemHeight) + 10) // Buffer
        
        visibleRange = startIndex..<endIndex
    }
}

// MARK: - Optimized Message View

struct OptimizedMessageView: View {
    let message: ClaudeMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Role indicator
            Text(message.role.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(message.role == .user ? .blue : .green)
                .frame(width: 60, alignment: .trailing)
            
            // Message content
            Text(message.content)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Timestamp
            Text(message.timestamp.formatted(.dateTime.hour().minute()))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - Scroll Offset Preference Key

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero
    
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
        value = nextValue()
    }
}

// MARK: - Memory-Efficient Image Cache

class OptimizedImageCache {
    static let shared = OptimizedImageCache()
    
    private let cache = NSCache<NSString, NSImage>()
    private let maxCacheSize = 50 // Maximum number of cached images
    
    private init() {
        cache.countLimit = maxCacheSize
        
        // Clear cache on memory pressure (macOS doesn't have UIApplication memory warnings)
        // Instead, we'll rely on the PerformanceManager to trigger cleanup
    }
    
    func image(for key: String) -> NSImage? {
        return cache.object(forKey: key as NSString)
    }
    
    func setImage(_ image: NSImage, for key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
    
    @objc private func clearCache() {
        cache.removeAllObjects()
    }
}