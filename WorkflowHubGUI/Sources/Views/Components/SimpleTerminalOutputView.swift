import SwiftUI

/// Simplified terminal output view to avoid complex expression compilation issues
struct SimpleTerminalOutputView<T: TerminalManagerProtocol>: View {
    @ObservedObject var terminalManager: T
    @State private var autoScroll = true
    @State private var searchText = ""
    @State private var showingSearch = false
    
    var body: some View {
        VStack(spacing: 0) {
            if showingSearch {
                HStack {
                    TextField("Search...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                    Button("Done") { showingSearch = false }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
            }
            
            if let session = terminalManager.activeSession {
                if session.conversationHistory.isEmpty {
                    Text("No messages yet. Start by typing a command below.")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(session.conversationHistory) { message in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(message.role == .user ? "You" : "Claude")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(message.role == .user ? .blue : .green)
                                        
                                        Spacer()
                                        
                                        Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Text(message.content)
                                        .font(.system(.body, design: .monospaced))
                                        .textSelection(.enabled)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 8)
                                        .background(
                                            message.role == .user 
                                            ? Color.blue.opacity(0.1) 
                                            : Color.green.opacity(0.1)
                                        )
                                        .cornerRadius(6)
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            } else {
                Text("No active terminal session")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: { showingSearch.toggle() }) {
                    Image(systemName: "magnifyingglass")
                }
                .help("Search in Terminal")
                
                Button(action: { autoScroll.toggle() }) {
                    Image(systemName: autoScroll ? "arrow.down.circle.fill" : "arrow.down.circle")
                }
                .help(autoScroll ? "Disable Auto-scroll" : "Enable Auto-scroll")
            }
        }
    }
}