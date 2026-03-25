import SwiftUI

/// Test Runner interface for monitoring and executing tests
/// Provides visibility into testing framework status and results
struct TestRunnerView: View {
    @StateObject private var testingFramework = TestingFramework.shared
    @State private var selectedCategory: TestCategory? = nil
    @State private var showFailedOnly: Bool = false
    @State private var expandedSuites: Set<String> = []
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with test summary and controls
            headerSection
            
            Divider()
            
            HStack(spacing: 0) {
                // Test results list
                testResultsList
                
                Divider()
                
                // Test details panel
                testDetailsPanel
            }
        }
        .navigationTitle("Test Runner")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Run All Tests") {
                    testingFramework.runAllTests()
                }
                .disabled(testingFramework.isRunningTests)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Overall status
            HStack {
                Circle()
                    .fill(testingFramework.overallStatus.color)
                    .frame(width: 12, height: 12)
                
                Text(testingFramework.overallStatus.displayName)
                    .font(.headline)
                    .fontWeight(.medium)
                
                if testingFramework.isRunningTests {
                    ProgressView()
                        .scaleEffect(0.7)
                    
                    Text("Running: \(testingFramework.currentTestSuite)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Quick stats
                testSummaryStats
            }
            
            // Filter controls
            HStack {
                // Category filter
                Picker("Category", selection: $selectedCategory) {
                    Text("All Categories").tag(Optional<TestCategory>(nil))
                    ForEach(TestCategory.allCases, id: \.self) { category in
                        Text(category.displayName).tag(Optional(category))
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: 200)
                
                Toggle("Failed Only", isOn: $showFailedOnly)
                
                Spacer()
                
                // Action buttons
                Button("Clear Results") {
                    testingFramework.testResults.removeAll()
                }
                .disabled(testingFramework.testResults.isEmpty)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
    }
    
    private var testSummaryStats: some View {
        HStack(spacing: 16) {
            let summary = testingFramework.getTestSummary()
            
            StatView(title: "Total", value: "\(summary.totalTests)", color: .primary)
            StatView(title: "Passed", value: "\(summary.passedTests)", color: .green)
            StatView(title: "Failed", value: "\(summary.failedTests)", color: .red)
            
            if summary.totalTests > 0 {
                StatView(title: "Pass Rate", value: summary.formattedPassRate, color: summary.passRate > 0.8 ? .green : .orange)
            }
        }
    }
    
    // MARK: - Test Results List
    private var testResultsList: some View {
        List {
            ForEach(groupedTestResults, id: \.key) { suite, tests in
                Section {
                    ForEach(tests) { test in
                        TestResultRow(result: test)
                    }
                } header: {
                    HStack {
                        Image(systemName: expandedSuites.contains(suite) ? "chevron.down" : "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        
                        Text(suite)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        // Suite statistics
                        let suiteTests = tests
                        let passed = suiteTests.filter { $0.status == .passed }.count
                        let failed = suiteTests.filter { $0.status == .failed }.count
                        
                        HStack(spacing: 8) {
                            if passed > 0 {
                                Text("✓\(passed)")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            if failed > 0 {
                                Text("✗\(failed)")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if expandedSuites.contains(suite) {
                                expandedSuites.remove(suite)
                            } else {
                                expandedSuites.insert(suite)
                            }
                        }
                    }
                }
                .collapsible(isExpanded: expandedSuites.contains(suite))
            }
        }
        .listStyle(SidebarListStyle())
        .frame(minWidth: 300)
    }
    
    private var groupedTestResults: [(key: String, value: [TestResult])] {
        let filtered = filteredTestResults
        let grouped = Dictionary(grouping: filtered) { $0.suiteName }
        return grouped.sorted { $0.key < $1.key }
    }
    
    private var filteredTestResults: [TestResult] {
        var results = testingFramework.testResults
        
        if let category = selectedCategory {
            results = results.filter { $0.category == category }
        }
        
        if showFailedOnly {
            results = results.filter { $0.status == .failed }
        }
        
        return results
    }
    
    // MARK: - Test Details Panel
    private var testDetailsPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let selectedTest = selectedTestResult {
                testDetailView(for: selectedTest)
            } else {
                // Overall summary when no specific test is selected
                overallSummaryView
            }
        }
        .frame(minWidth: 400)
        .padding()
    }
    
    @State private var selectedTestResult: TestResult? = nil
    
    private func testDetailView(for result: TestResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Test header
            HStack {
                Circle()
                    .fill(result.status.color)
                    .frame(width: 16, height: 16)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.testName)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(result.suiteName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(result.status.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(result.status.color.opacity(0.2))
                        .foregroundColor(result.status.color)
                        .cornerRadius(4)
                    
                    if result.duration > 0 {
                        Text(String(format: "%.2fs", result.duration))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Divider()
            
            // Test metadata
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                MetadataRow(title: "Category", value: result.category.displayName, color: result.category.color)
                MetadataRow(title: "Priority", value: result.priority.displayName, color: result.priority.color)
                MetadataRow(title: "Start Time", value: DateFormatter.shortTime.string(from: result.startTime))
                
                if let endTime = result.endTime {
                    MetadataRow(title: "End Time", value: DateFormatter.shortTime.string(from: endTime))
                }
            }
            
            Divider()
            
            // Test message
            VStack(alignment: .leading, spacing: 8) {
                Text("Result")
                    .font(.headline)
                
                ScrollView {
                    Text(result.message)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(8)
                }
            }
            
            // Error details if available
            if let error = result.error {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Error Details")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    ScrollView {
                        Text(error.localizedDescription)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.red.opacity(0.05))
                            .cornerRadius(8)
                    }
                }
            }
            
            Spacer()
        }
    }
    
    private var overallSummaryView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Test Summary")
                .font(.title2)
                .fontWeight(.semibold)
            
            let summary = testingFramework.getTestSummary()
            
            // Performance metrics
            GroupBox("Performance") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Average Duration")
                        Spacer()
                        Text(summary.formattedAverageDuration)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Total Tests")
                        Spacer()
                        Text("\(summary.totalTests)")
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Pass Rate")
                        Spacer()
                        Text(summary.formattedPassRate)
                            .fontWeight(.medium)
                            .foregroundColor(summary.passRate > 0.8 ? .green : .orange)
                    }
                }
                .padding()
            }
            
            // Critical failures
            if summary.criticalFailures > 0 {
                GroupBox("Critical Issues") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(summary.criticalFailures) critical test(s) failed")
                            .foregroundColor(.red)
                            .fontWeight(.medium)
                        
                        ForEach(testingFramework.getCriticalFailures()) { failure in
                            HStack {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 6, height: 6)
                                
                                Text(failure.testName)
                                    .font(.caption)
                                
                                Spacer()
                                
                                Text(failure.suiteName)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.leading)
                        }
                    }
                    .padding()
                }
            }
            
            // Category breakdown
            GroupBox("By Category") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(TestCategory.allCases, id: \.self) { category in
                        let categoryTests = testingFramework.getTestsByCategory(category)
                        let passed = categoryTests.filter { $0.status == .passed }.count
                        let total = categoryTests.count
                        
                        if total > 0 {
                            HStack {
                                Circle()
                                    .fill(category.color)
                                    .frame(width: 8, height: 8)
                                
                                Text(category.displayName)
                                    .font(.caption)
                                
                                Spacer()
                                
                                Text("\(passed)/\(total)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
                .padding()
            }
            
            Spacer()
        }
    }
}

// MARK: - Supporting Views

struct TestResultRow: View {
    let result: TestResult
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(result.status.color)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(result.testName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(result.category.displayName)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(result.category.color.opacity(0.2))
                        .foregroundColor(result.category.color)
                        .cornerRadius(3)
                    
                    Text(result.priority.displayName)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(result.priority.color.opacity(0.2))
                        .foregroundColor(result.priority.color)
                        .cornerRadius(3)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if result.duration > 0 {
                    Text(String(format: "%.2fs", result.duration))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                if result.status == .running {
                    ProgressView()
                        .scaleEffect(0.6)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

struct StatView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct MetadataRow: View {
    let title: String
    let value: String
    let color: Color?
    
    init(title: String, value: String, color: Color? = nil) {
        self.title = title
        self.value = value
        self.color = color
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color ?? .primary)
        }
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - View Modifier for Collapsible Sections

struct CollapsibleModifier: ViewModifier {
    let isExpanded: Bool
    
    func body(content: Content) -> some View {
        if isExpanded {
            content
        } else {
            EmptyView()
        }
    }
}

extension View {
    func collapsible(isExpanded: Bool) -> some View {
        modifier(CollapsibleModifier(isExpanded: isExpanded))
    }
}

// Preview removed due to macro compatibility issue
// TestRunnerView can be accessed through the main application