import SwiftUI

struct MainContentView: View {
    let selectedItem: SidebarItem
    
    var body: some View {
        Group {
            switch selectedItem {
            case .dashboard:
                DashboardView()
            case .agents:
                AgentMonitoringView()
            case .projects:
                ProjectCommandCenterView()
            case .workflows:
                WorkflowDesignerView()
            case .analytics:
                AnalyticsView()
            case .commander:
                ClaudeTerminalView()
            case .settings:
                SettingsView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct DashboardView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Good day, Armando!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Your productivity command center is ready")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Navigate using the sidebar to access different sections")
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Dashboard")
    }
}

struct ProjectCommandCenterView: View {
    @StateObject private var projectManager = ProjectManager.shared
    @State private var selectedProject: Project?
    
    var body: some View {
        HSplitView {
            // Left panel - Project list
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Projects")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(projectManager.projects.count) active")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                    
                    Button(action: {}) {
                        Image(systemName: "plus.circle")
                    }
                    .help("Create New Project")
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                
                List(projectManager.projects, selection: $selectedProject) { project in
                    ProjectRowView(project: project)
                        .tag(project)
                }
                .listStyle(.sidebar)
            }
            .frame(minWidth: 350)
            
            // Right panel - Project details
            if let project = selectedProject {
                ProjectDetailView(project: project)
                    .frame(minWidth: 500)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "folder.badge.gearshape")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    
                    Text("Select a Project")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("Choose a project to view details, status, and manage tasks")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.secondary.opacity(0.05))
            }
        }
        .navigationTitle("Project Command Center")
        .onAppear {
            if selectedProject == nil {
                selectedProject = projectManager.projects.first
            }
        }
    }
}

struct WorkflowDesignerView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.triangle.branch")
                .font(.system(size: 64))
                .foregroundColor(.purple)
            
            Text("Workflow Designer")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Design and execute automated workflows")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Workflows")
    }
}

struct AnalyticsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 64))
                .foregroundColor(.green)
            
            Text("Analytics Dashboard")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Performance metrics and insights")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Analytics")
    }
}

struct SettingsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "gearshape")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("Settings")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Application preferences and configuration")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Settings")
    }
}

struct ProjectRowView: View {
    let project: Project
    
    var body: some View {
        HStack(spacing: 12) {
            // Priority indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(project.priorityColor)
                .frame(width: 4, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(project.name)
                        .font(.headline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(String(format: "%.0f%%", project.completion * 100))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(project.type)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack {
                    // Status badge
                    Text(project.status.displayName)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(project.statusColor.opacity(0.2))
                        .foregroundColor(project.statusColor)
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    Text(project.lastModified.formatted(.relative(presentation: .named)))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct ProjectDetailView: View {
    let project: Project
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(project.name)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text(project.type)
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            HStack {
                                Circle()
                                    .fill(project.statusColor)
                                    .frame(width: 8, height: 8)
                                Text(project.status.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            
                            Text("Priority: \(project.priority)")
                                .font(.caption)
                                .foregroundColor(project.priorityColor)
                        }
                    }
                    
                    Text("Project \(project.type) - \(project.status.displayName)")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                    
                    // Progress bar
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Progress")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(String(format: "%.0f%% Complete", project.completion * 100))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        ProgressView(value: project.completion)
                            .progressViewStyle(LinearProgressViewStyle(tint: project.statusColor))
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(12)
                
                // Metrics Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ProjectMetricCard(title: "Completion", value: String(format: "%.0f%%", project.completion * 100), icon: "chart.pie.fill", color: project.statusColor)
                    ProjectMetricCard(title: "Priority", value: "\(project.priority)", icon: "exclamationmark.triangle.fill", color: project.priorityColor)
                    ProjectMetricCard(title: "Last Update", value: project.lastModified.formatted(.relative(presentation: .named)), icon: "clock.fill", color: .blue)
                    ProjectMetricCard(title: "Status", value: project.status.displayName, icon: "circle.fill", color: project.statusColor)
                }
                
                // Actions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Actions")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        ActionButton(title: "Open Project", icon: "folder.fill", color: .blue) {}
                        ActionButton(title: "View Tasks", icon: "list.bullet", color: .green) {}
                        ActionButton(title: "Deploy Agent", icon: "person.crop.circle", color: .purple) {}
                        ActionButton(title: "Generate Report", icon: "doc.text.fill", color: .orange) {}
                    }
                }
                
                // Team Assignment (placeholder)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Assigned Elite Agents")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 8) {
                        ForEach(project.agentTeam, id: \.self) { agent in
                            Text(agent)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(6)
                        }
                        
                        Button(action: {}) {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.secondary)
                        }
                        .help("Assign Agent")
                    }
                }
            }
            .padding()
        }
    }
}

struct ProjectMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}