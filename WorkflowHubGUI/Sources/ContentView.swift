import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppStateManager
    @State private var selectedSidebarItem: SidebarItem = .commander
    @State private var sidebarWidth: CGFloat = 280
    @State private var inspectorWidth: CGFloat = 350
    @State private var showSidebar: Bool = true
    
    var body: some View {
        HSplitView {
            // Left Sidebar - Collapsible and Resizable
            if showSidebar {
                NavigationSidebar(selectedItem: $selectedSidebarItem)
                    .frame(minWidth: 200, idealWidth: sidebarWidth, maxWidth: 400)
                    .transition(.move(edge: .leading))
            }
            
            // Main Content Area - Highly flexible
            MainContentView(selectedItem: selectedSidebarItem)
                .frame(minWidth: 400)
                .layoutPriority(1) // Give priority to main content
            
            // Right Inspector Panel - Contextual and collapsible
            if appState.showRightPanel {
                VStack {
                    Text("Inspector Panel")
                        .font(.headline)
                        .padding()
                    Spacer()
                }
                .frame(minWidth: 250, idealWidth: inspectorWidth, maxWidth: 500)
                .background(Color(NSColor.controlBackgroundColor))
                .transition(.move(edge: .trailing))
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            appState.initializeConnection()
        }
        .sheet(isPresented: $appState.showingSettings) {
            SettingsView()
        }
        .alert("Connection Error", isPresented: $appState.showingConnectionError) {
            Button("Retry") {
                appState.initializeConnection()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Unable to connect to the Workflow Hub backend. Please ensure the system is running.")
        }
    }
    
    @ToolbarContentBuilder
    private var contextualToolbarContent: some ToolbarContent {
        switch selectedSidebarItem {
        case .commander:
            ToolbarItem {
                Button("New Session") {
                    // New Claude session action
                }
            }
            ToolbarItem {
                Button("Clear Terminal") {
                    // Clear terminal action
                }
            }
        case .agents:
            ToolbarItem {
                Button("Deploy Agent") {
                    // Deploy new agent action
                }
            }
        case .projects:
            ToolbarItem {
                Button("New Project") {
                    // Create new project action
                }
            }
        default:
            ToolbarItem {
                Button("Refresh") {
                    appState.initializeConnection()
                }
            }
        }
    }
}

// MARK: - Sidebar Items Enum
enum SidebarItem: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case agents = "Elite Agents"
    case projects = "Projects"
    case workflows = "Workflows"
    case analytics = "Analytics"
    case commander = "Commander"
    case settings = "Settings"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .dashboard: return "rectangle.3.group"
        case .agents: return "person.3"
        case .projects: return "folder.badge.gearshape"
        case .workflows: return "arrow.triangle.branch"
        case .analytics: return "chart.bar.xaxis"
        case .commander: return "terminal"
        case .settings: return "gearshape"
        }
    }
    
    var description: String {
        switch self {
        case .dashboard: return "System overview and status"
        case .agents: return "Monitor and manage Elite Agents"
        case .projects: return "Track all 23+ business projects"
        case .workflows: return "Execute and monitor workflows"
        case .analytics: return "Performance metrics and insights"
        case .commander: return "Direct command interface"
        case .settings: return "Application preferences"
        }
    }
}

