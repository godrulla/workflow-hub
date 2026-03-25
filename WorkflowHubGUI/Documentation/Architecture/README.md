# WorkflowHub GUI - System Architecture Documentation

**By ARQ (Architecture & System Design)**

## Executive Summary

The WorkflowHub GUI represents a sophisticated SwiftUI-based macOS application built with a layered, modular architecture following MVVM+C pattern (Model-View-ViewModel + Coordinator). The system serves as a real-time command and control interface for managing Elite Agents, projects, and Claude CLI interactions.

## Core Architecture Principles

- **Separation of Concerns**: Clear boundaries between UI, business logic, and infrastructure
- **Reactive Programming**: Combine framework for data flow and state management
- **Security-First Design**: Sandboxed process execution with validation layers
- **Real-Time Communication**: WebSocket-based event-driven architecture
- **Scalable Data Flow**: Unidirectional data flow with centralized state management

## Technology Stack

- **Platform**: macOS 14+ (native SwiftUI)
- **Language**: Swift 5.9+
- **Frameworks**: SwiftUI, Combine, Foundation
- **External Dependencies**: 
  - Starscream (WebSocket client)
  - SQLite.swift (future persistence layer)
- **Integration Points**: Claude CLI, MCP Protocol, WebSocket Backend

## Component Architecture

### View Layer (SwiftUI Views)
```
ContentView (Root Container)
├── NavigationSidebar
├── MainContentView (Content Router)
│   ├── DashboardView
│   ├── AgentMonitoringView
│   ├── ProjectCommandCenterView
│   ├── WorkflowDesignerView
│   ├── AnalyticsView
│   ├── ClaudeTerminalView
│   └── SettingsView
└── Inspector Panel (Contextual)
```

**Key Architectural Decisions:**
- **HSplitView Pattern**: Flexible, resizable panels for optimal workspace management
- **View Composition**: Small, reusable view components
- **Navigation State**: Enum-based routing for type-safe navigation
- **Adaptive UI**: Responsive layouts that scale from 1200px to 4K displays

### State Management Layer

**AppStateManager (Singleton Pattern)**
- Central nervous system of the application
- **@MainActor** decorated for thread-safe UI updates
- Publisher-Subscriber pattern using Combine
- Manages:
  - Connection lifecycle
  - Agent orchestration
  - Project state synchronization
  - Token usage tracking
  - System metrics monitoring

**State Flow Architecture:**
```
User Action → View → AppStateManager → WebSocketManager → Backend
                ↑                              ↓
                └────── State Update ←─────────┘
```

### Core Services Architecture

**ClaudeTerminalManager**
- **Purpose**: Orchestrates Claude CLI sessions with context injection
- **Pattern**: Session-based architecture with max 5 concurrent sessions
- **Security**: Command validation and sandboxing
- **Features**:
  - Project/Agent context injection
  - Session persistence (planned)
  - Token tracking per session
  - File operation monitoring

**ProcessExecutor**
- **Purpose**: Secure subprocess execution with resource limits
- **Security Layers**:
  - Command validation (blocks dangerous operations)
  - Path traversal protection
  - Command injection prevention
  - Resource limits (5-minute timeout, 3 concurrent processes)
- **Monitoring**: Real-time process tracking and metrics

**WebSocketManager**
- **Purpose**: Real-time bidirectional communication
- **Features**:
  - Auto-reconnection with exponential backoff
  - Message queuing for offline resilience
  - Type-safe message encoding/decoding
- **Protocol**: Custom JSON-based messaging protocol

## Data Models & Schema

### Core Entity Relationships

```swift
EliteAgent
├── id: UUID
├── name: String (ARQ, ORC, ZEN, etc.)
├── specialization: [String]
├── status: AgentStatus
├── currentTask: String?
├── expertiseLevel: Double (0.0-1.0)
└── maxParallelTasks: Int

Project
├── id: UUID
├── name: String
├── type: String (nextjs, ai_ml, business, etc.)
├── status: ProjectStatus
├── priority: Int (1-5)
├── completion: Double (0.0-1.0)
├── agentTeam: [String] (Agent names)
└── health: ProjectHealth

ClaudeSession
├── id: UUID
├── projectId: String?
├── agentId: String?
├── conversationHistory: [ClaudeMessage]
├── workingDirectory: URL
├── tokens: TokenUsage
└── status: SessionStatus
```

### Message Architecture

```swift
WebSocketMessage
├── id: String
├── type: MessageType (command/response/event/stream)
├── timestamp: Date
├── source: String
├── target: String?
└── data: MessageData
    ├── action: String
    ├── payload: [String: Any]
    └── metadata: [String: Any]?
```

## Integration Patterns

### 1. Claude CLI Integration
- **Pattern**: Command Wrapper with Context Injection
- **Flow**: User Input → Context Enrichment → Process Execution → Output Processing
- **Security**: Multi-layer validation before execution
- **Context Layers**:
  - Project context (working directory, project metadata)
  - Agent context (specialization, current task)
  - Session context (history, tokens)

### 2. WebSocket Communication
- **Pattern**: Event-Driven Architecture with Message Queue
- **Connection Management**: Automatic reconnection with state preservation
- **Message Types**:
  - Commands: User-initiated actions
  - Events: System state changes
  - Streams: Real-time data updates
  - Responses: Command acknowledgments

### 3. MCP (Model Context Protocol) Integration
- **Pattern**: External Process Communication
- **Integration Points**:
  - Context initialization (`/init` command)
  - Field state management
  - Protocol shell execution
- **Data Flow**: GUI → Claude Terminal → MCP Server → Context Engine

## Scalability Considerations

### Current Limitations & Solutions

1. **Agent Scalability (Current: 7 agents)**
   - **Recommendation**: Implement Agent Pool Pattern
   - Dynamic agent spawning based on load
   - Agent clustering by specialization
   - Distributed agent architecture preparation

2. **Project Management (Current: In-memory)**
   - **Recommendation**: Implement Core Data persistence
   - SQLite for local caching
   - Sync protocol for distributed teams
   - Project templates and automation

3. **Session Management (Current: 5 sessions max)**
   - **Recommendation**: Session pooling with LRU eviction
   - Persistent session storage
   - Session migration between devices
   - Collaborative session sharing

4. **WebSocket Scaling**
   - **Recommendation**: Implement connection pooling
   - Multiple WebSocket connections for load distribution
   - Message prioritization and QoS levels
   - Fallback to HTTP polling for resilience

### Future Architecture Evolution

```
Phase 1 (Current) → Phase 2 (6 months) → Phase 3 (12 months)
├── Monolithic GUI → Modular Plugins → Distributed Services
├── Local Execution → Hybrid Cloud → Full Cloud Native
├── Single User → Team Collaboration → Enterprise Scale
└── 7 Agents → 50+ Agents → Unlimited Agent Mesh
```

## Security Architecture

### Defense in Depth Strategy

1. **Process Execution Security**
   - Command validation whitelist
   - Path traversal prevention
   - Resource limits (CPU, memory, time)
   - Sandboxed execution environment

2. **Data Security**
   - No persistent sensitive data in memory
   - Token usage tracking and limits
   - Secure WebSocket with TLS (planned)
   - API key management (planned)

3. **Agent Communication Security**
   - Message authentication (planned)
   - End-to-end encryption for sensitive operations
   - Agent identity verification
   - Audit logging for all operations

### Security Boundaries

```
User Input
    ↓ [Validation Layer]
GUI Application
    ↓ [Process Sandbox]
Claude CLI
    ↓ [Network Security]
WebSocket Backend
    ↓ [Agent Authentication]
Elite Agents
```

## Architectural Patterns in Use

1. **Singleton Pattern**: AppStateManager for global state
2. **Observer Pattern**: Combine publishers for reactive updates
3. **Command Pattern**: WebSocketMessage for action encapsulation
4. **Session Pattern**: ClaudeSession for stateful interactions
5. **Factory Pattern**: Process creation in ProcessExecutor
6. **Strategy Pattern**: Different execution strategies per agent type
7. **Facade Pattern**: ClaudeTerminalManager hiding complexity

## Performance Optimization Strategies

1. **View Optimization**
   - Lazy loading with LazyVGrid/LazyVStack
   - View memoization for expensive computations
   - Minimal view rebuilds with targeted @Published

2. **Data Flow Optimization**
   - Debounced updates (1-second update frequency)
   - Batch message processing
   - Selective state updates

3. **Process Management**
   - Process pooling for Claude CLI
   - Output streaming vs. buffering
   - Concurrent process limits

## Future Architecture Recommendations

### Immediate Priorities (Next Sprint)
1. Implement SQLite persistence for sessions and projects
2. Add comprehensive error recovery mechanisms
3. Implement agent health monitoring dashboard
4. Add WebSocket connection encryption

### Medium-term Evolution (3-6 months)
1. **Plugin Architecture**: Allow custom agent types and workflows
2. **Distributed Execution**: Support remote agent execution
3. **Advanced Analytics**: ML-based performance optimization
4. **Collaboration Features**: Multi-user session sharing

### Long-term Vision (6-12 months)
1. **Microservices Migration**: Break monolith into services
2. **Cloud-Native Architecture**: Kubernetes-ready deployment
3. **AI-Driven Orchestration**: Self-optimizing agent allocation
4. **Enterprise Features**: SAML SSO, audit logs, compliance

## Development Guidelines

### Code Organization
- **Views**: Pure UI components, no business logic
- **Core**: Business logic and service layer
- **Models**: Data structures and domain entities
- **Extensions**: Swift extensions and utilities

### Testing Strategy
- Unit tests for Core services
- Integration tests for WebSocket communication
- UI tests for critical user flows
- Performance tests for process execution

### Deployment Architecture
- macOS native app distribution
- Automatic updates via Sparkle framework (planned)
- Configuration management via .plist files
- Crash reporting and analytics (planned)

---

*This architecture documentation provides a solid foundation for the other specialized agents to understand the system's structure and make informed decisions in their respective domains. The architecture is designed to scale from a single-user productivity tool to an enterprise-grade orchestration platform while maintaining code quality, security, and performance.*

**Next Steps**: Review workflow documentation by ORC and performance analysis by ZEN to complete the technical foundation.