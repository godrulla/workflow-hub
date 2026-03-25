import SwiftUI

struct AgentMonitoringView: View {
    @StateObject private var agentManager = AgentManager.shared
    @State private var selectedAgent: EliteAgent?
    
    var body: some View {
        HSplitView {
            // Left panel - Agent list
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Elite Agents")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "plus.circle")
                    }
                    .help("Deploy New Agent")
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                
                List(agentManager.agents, selection: $selectedAgent) { agent in
                    AgentRowView(agent: agent)
                        .tag(agent)
                }
                .listStyle(.sidebar)
            }
            .frame(minWidth: 300)
            
            // Right panel - Agent details
            if let agent = selectedAgent {
                AgentDetailView(agent: agent)
                    .frame(minWidth: 400)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "person.3.sequence")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    
                    Text("Select an Elite Agent")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("Choose an agent from the list to view details and performance metrics")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.secondary.opacity(0.05))
            }
        }
        .navigationTitle("Elite Agents")
        .onAppear {
            if selectedAgent == nil {
                selectedAgent = agentManager.agents.first
            }
        }
    }
}

struct AgentRowView: View {
    let agent: EliteAgent
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(agent.status.color)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(agent.name)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(String(format: "%.0f%%", agent.expertiseLevel * 100))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(agent.specialization.prefix(2).joined(separator: " • "))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack {
                    Text("\(agent.currentLoad) tasks")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(agent.status.displayName)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(agent.status.color.opacity(0.2))
                        .foregroundColor(agent.status.color)
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct AgentDetailView: View {
    let agent: EliteAgent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(agent.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(agent.specialization.joined(separator: " • "))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack {
                        Circle()
                            .fill(agent.status.color)
                            .frame(width: 10, height: 10)
                        Text(agent.status.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Text(String(format: "%.1f%% Performance", agent.expertiseLevel * 100))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(10)
            
            // Metrics
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                MetricCard(title: "Tasks Completed", value: "\(agent.currentLoad)", icon: "checkmark.circle.fill", color: .green)
                MetricCard(title: "Avg Response Time", value: String(format: "%.1fs", Double.random(in: 1.0...5.0)), icon: "clock.fill", color: .blue)
                MetricCard(title: "Performance Score", value: String(format: "%.1f%%", agent.expertiseLevel * 100), icon: "chart.line.uptrend.xyaxis", color: .purple)
                MetricCard(title: "Active Sessions", value: agent.status == .executing ? "1" : "0", icon: "terminal.fill", color: .orange)
            }
            
            // Capabilities
            VStack(alignment: .leading, spacing: 12) {
                Text("Specializations")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 1), spacing: 8) {
                    ForEach(agent.specialization, id: \.self) { spec in
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text(spec)
                                .font(.subheadline)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
            
            // Actions
            HStack(spacing: 12) {
                Button("Deploy Task") {
                    // Deploy task to agent
                }
                .buttonStyle(.borderedProminent)
                
                Button("View History") {
                    // View agent history
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Menu("More") {
                    Button("Reset Performance") {}
                    Button("View Logs") {}
                    Divider()
                    Button("Deactivate", role: .destructive) {}
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
        }
        .padding()
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Spacer()
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(10)
    }
}