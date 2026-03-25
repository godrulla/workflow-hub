import Foundation
import Combine

/// Secure process executor for Claude CLI commands with sandboxing and monitoring
class ProcessExecutor: NSObject, @unchecked Sendable {
    
    // MARK: - Properties
    var activeProcesses: [UUID: Process] = [:]
    private let processQueue = DispatchQueue(label: "com.workflowhub.process", qos: .userInitiated)
    private let maxConcurrentProcesses = 3
    private let commandTimeout: TimeInterval = 300 // 5 minutes
    
    // Security settings
    private let allowedExecutables: Set<String> = [
        "/usr/local/bin/claude",
        "/opt/homebrew/bin/claude", 
        "/usr/bin/claude",
        "/bin/bash",
        "/usr/bin/env"
    ]
    
    private let allowedPaths: Set<String> = [
        "/Users/mando/Desktop/workflow-hub",
        "/Users/mando/.claude",
        "/tmp/workflow-hub",
        "/var/tmp"
    ]
    
    private let blockedCommands: Set<String> = [
        "rm -rf",
        "sudo",
        "chmod +x",
        "chown",
        "su",
        "passwd"
    ]
    
    // MARK: - Public Methods
    
    /// Executes a Claude Code command with security validation and monitoring
    func executeClaudeCommand(
        _ command: String,
        sessionId: UUID,
        workingDirectory: URL,
        timeout: TimeInterval? = nil
    ) async -> ProcessResult {
        
        // Validate command security
        guard validateCommand(command) else {
            return ProcessResult(
                output: "",
                errorOutput: "Command blocked for security reasons",
                exitCode: -1,
                duration: 0
            )
        }
        
        // Check concurrent process limit
        if activeProcesses.count >= maxConcurrentProcesses {
            return ProcessResult(
                output: "",
                errorOutput: "Maximum concurrent processes reached",
                exitCode: -2,
                duration: 0
            )
        }
        
        return await withCheckedContinuation { continuation in
            processQueue.async {
                let result = self.executeCommandInternal(
                    command,
                    sessionId: sessionId,
                    workingDirectory: workingDirectory,
                    timeout: timeout ?? self.commandTimeout
                )
                continuation.resume(returning: result)
            }
        }
    }
    
    /// Terminates a running process by session ID
    func terminateProcess(sessionId: UUID) {
        processQueue.async {
            if let process = self.activeProcesses[sessionId] {
                process.terminate()
                self.activeProcesses.removeValue(forKey: sessionId)
                print("Terminated process for session: \(sessionId)")
            }
        }
    }
    
    /// Terminates all running processes
    func terminateAllProcesses() {
        processQueue.async {
            for (sessionId, process) in self.activeProcesses {
                process.terminate()
                print("Terminated process for session: \(sessionId)")
            }
            self.activeProcesses.removeAll()
        }
    }
    
    // MARK: - Private Methods
    
    private func executeCommandInternal(
        _ command: String,
        sessionId: UUID,
        workingDirectory: URL,
        timeout: TimeInterval
    ) -> ProcessResult {
        
        let startTime = Date()
        
        do {
            // Create and configure process
            let process = try createSecureProcess(
                command: command,
                workingDirectory: workingDirectory
            )
            
            // Set up I/O pipes
            let outputPipe = Pipe()
            let errorPipe = Pipe()
            
            process.standardOutput = outputPipe
            process.standardError = errorPipe
            process.standardInput = nil // No input for security
            
            // Store active process
            activeProcesses[sessionId] = process
            
            // Launch process
            try process.run()
            
            // Set up timeout
            let timeoutTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { _ in
                if process.isRunning {
                    process.terminate()
                    print("Process timed out for session: \(sessionId)")
                }
            }
            
            // Wait for completion
            process.waitUntilExit()
            timeoutTimer.invalidate()
            
            // Clean up
            activeProcesses.removeValue(forKey: sessionId)
            
            // Read output
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            
            let output = String(data: outputData, encoding: .utf8) ?? ""
            let errorOutput = String(data: errorData, encoding: .utf8)
            
            let duration = Date().timeIntervalSince(startTime)
            let tokens = extractTokenCount(from: output)
            let fileOperations = extractFileOperations(from: output)
            
            return ProcessResult(
                output: output,
                errorOutput: errorOutput?.isEmpty == false ? errorOutput : nil,
                exitCode: process.terminationStatus,
                duration: duration,
                tokens: tokens,
                fileOperations: fileOperations
            )
            
        } catch {
            activeProcesses.removeValue(forKey: sessionId)
            let duration = Date().timeIntervalSince(startTime)
            
            return ProcessResult(
                output: "",
                errorOutput: "Process execution failed: \(error.localizedDescription)",
                exitCode: -3,
                duration: duration
            )
        }
    }
    
    private func createSecureProcess(command: String, workingDirectory: URL) throws -> Process {
        let process = Process()
        
        // Determine Claude executable path
        let claudePath = findClaudeExecutable()
        guard let executablePath = claudePath else {
            throw ProcessError.claudeNotFound
        }
        
        // Set up process
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = parseCommandArguments(command)
        process.currentDirectoryURL = workingDirectory
        
        // Set up secure environment
        var environment = Foundation.ProcessInfo.processInfo.environment
        
        // Add Claude-specific environment variables if needed
        environment["CLAUDE_CLI_SESSION"] = "workflow-hub"
        environment["CLAUDE_CLI_CONTEXT"] = "gui"
        
        // Remove potentially dangerous environment variables
        environment.removeValue(forKey: "LD_LIBRARY_PATH")
        environment.removeValue(forKey: "DYLD_LIBRARY_PATH")
        
        process.environment = environment
        
        // Apply resource limits
        applyResourceLimits(to: process)
        
        return process
    }
    
    private func findClaudeExecutable() -> String? {
        for path in allowedExecutables {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }
        
        // Try to find claude in PATH
        let whichProcess = Process()
        whichProcess.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        whichProcess.arguments = ["claude"]
        
        let pipe = Pipe()
        whichProcess.standardOutput = pipe
        whichProcess.standardError = nil
        
        do {
            try whichProcess.run()
            whichProcess.waitUntilExit()
            
            if whichProcess.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                    return path
                }
            }
        } catch {
            print("Failed to find claude executable: \(error)")
        }
        
        return nil
    }
    
    private func parseCommandArguments(_ command: String) -> [String] {
        // Remove 'claude' from the beginning if present
        var cleanCommand = command
        if cleanCommand.hasPrefix("claude ") {
            cleanCommand = String(cleanCommand.dropFirst(6))
        } else if cleanCommand == "claude" {
            cleanCommand = ""
        }
        
        // Parse arguments (simplified shell parsing)
        return cleanCommand.isEmpty ? [] : parseShellArguments(cleanCommand)
    }
    
    private func parseShellArguments(_ command: String) -> [String] {
        var arguments: [String] = []
        var currentArg = ""
        var inQuotes = false
        var quoteChar: Character = "\""
        var escaping = false
        
        for char in command {
            if escaping {
                currentArg.append(char)
                escaping = false
                continue
            }
            
            if char == "\\" {
                escaping = true
                continue
            }
            
            if inQuotes {
                if char == quoteChar {
                    inQuotes = false
                } else {
                    currentArg.append(char)
                }
            } else {
                if char == "\"" || char == "'" {
                    inQuotes = true
                    quoteChar = char
                } else if char.isWhitespace {
                    if !currentArg.isEmpty {
                        arguments.append(currentArg)
                        currentArg = ""
                    }
                } else {
                    currentArg.append(char)
                }
            }
        }
        
        if !currentArg.isEmpty {
            arguments.append(currentArg)
        }
        
        return arguments
    }
    
    private func applyResourceLimits(to process: Process) {
        // Note: Process resource limits in Swift are limited
        // For more advanced limits, we would need to use posix_spawn with attributes
        // For now, we rely on the timeout mechanism
    }
    
    // MARK: - Security Validation
    
    private func validateCommand(_ command: String) -> Bool {
        let lowercaseCommand = command.lowercased()
        
        // Check for blocked commands
        for blockedCommand in blockedCommands {
            if lowercaseCommand.contains(blockedCommand.lowercased()) {
                print("Blocked dangerous command: \(blockedCommand)")
                return false
            }
        }
        
        // Check for path traversal attempts
        if command.contains("../") || command.contains("..\\") {
            print("Blocked path traversal attempt")
            return false
        }
        
        // Check for command injection patterns
        let injectionPatterns = ["|", ";", "&", "$(", "`", "&&", "||"]
        for pattern in injectionPatterns {
            if command.contains(pattern) {
                print("Blocked potential command injection: \(pattern)")
                return false
            }
        }
        
        return true
    }
    
    // MARK: - Output Processing
    
    private func extractTokenCount(from output: String) -> Int? {
        // Look for token usage patterns in Claude output
        let patterns = [
            #"(\d+) tokens"#,
            #"Tokens used: (\d+)"#,
            #"Token count: (\d+)"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: output.utf16.count)
                if let match = regex.firstMatch(in: output, options: [], range: range) {
                    if match.numberOfRanges > 1 {
                        let tokenRange = match.range(at: 1)
                        if let range = Range(tokenRange, in: output) {
                            let tokenString = String(output[range])
                            return Int(tokenString)
                        }
                    }
                }
            }
        }
        
        return nil
    }
    
    private func extractFileOperations(from output: String) -> [FileOperation] {
        var operations: [FileOperation] = []
        
        // Look for file operation indicators in Claude output
        let lines = output.components(separatedBy: .newlines)
        
        for line in lines {
            if line.contains("Created file:") || line.contains("Writing to:") {
                if let path = extractPath(from: line) {
                    operations.append(FileOperation(
                        type: .create,
                        path: path,
                        projectPath: extractProjectPath(from: path),
                        content: nil
                    ))
                }
            } else if line.contains("Modified file:") || line.contains("Updated:") {
                if let path = extractPath(from: line) {
                    operations.append(FileOperation(
                        type: .modify,
                        path: path,
                        projectPath: extractProjectPath(from: path),
                        content: nil
                    ))
                }
            } else if line.contains("Deleted file:") || line.contains("Removed:") {
                if let path = extractPath(from: line) {
                    operations.append(FileOperation(
                        type: .delete,
                        path: path,
                        projectPath: extractProjectPath(from: path),
                        content: nil
                    ))
                }
            }
        }
        
        return operations
    }
    
    private func extractPath(from line: String) -> String? {
        // Extract file path from various formats
        let patterns = [
            #"([/~][^\s]+)"#, // Unix paths
            #"([A-Za-z]:\\[^\s]+)"#, // Windows paths
            #"'([^']+)'"#, // Quoted paths
            #"\"([^\"]+)\""# // Double quoted paths
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(location: 0, length: line.utf16.count)
                if let match = regex.firstMatch(in: line, options: [], range: range) {
                    if match.numberOfRanges > 1 {
                        let pathRange = match.range(at: 1)
                        if let range = Range(pathRange, in: line) {
                            let path = String(line[range])
                            return path
                        }
                    }
                }
            }
        }
        
        return nil
    }
    
    private func extractProjectPath(from filePath: String) -> String? {
        // Extract project name from file path
        if filePath.contains("/workflow-hub/") {
            let components = filePath.components(separatedBy: "/workflow-hub/")
            if components.count > 1 {
                let projectPath = components[1].components(separatedBy: "/").first
                return projectPath
            }
        }
        
        return nil
    }
}

// MARK: - Process Errors

enum ProcessError: LocalizedError {
    case claudeNotFound
    case invalidCommand
    case executionTimeout
    case securityViolation
    case resourceLimit
    
    var errorDescription: String? {
        switch self {
        case .claudeNotFound:
            return "Claude CLI executable not found"
        case .invalidCommand:
            return "Invalid or unsafe command"
        case .executionTimeout:
            return "Command execution timed out"
        case .securityViolation:
            return "Command blocked for security reasons"
        case .resourceLimit:
            return "Process resource limits exceeded"
        }
    }
}

// MARK: - String Range Extension

extension String {
    init?(_ string: String, range: Range<String.Index>) {
        guard range.lowerBound >= string.startIndex && range.upperBound <= string.endIndex else {
            return nil
        }
        self = String(string[range])
    }
}


// MARK: - Process Monitoring Extension

extension ProcessExecutor {
    
    /// Get information about currently active processes
    var activeProcessMonitorInfo: [UUID: ProcessMonitorInfo] {
        var info: [UUID: ProcessMonitorInfo] = [:]
        
        for (sessionId, process) in activeProcesses {
            info[sessionId] = ProcessMonitorInfo(
                sessionId: sessionId,
                isRunning: process.isRunning,
                processId: process.processIdentifier,
                startTime: Date() // We would need to track this separately
            )
        }
        
        return info
    }
    
    /// Get count of active processes
    var activeProcessCount: Int {
        return activeProcesses.count
    }
}

struct ProcessMonitorInfo {
    let sessionId: UUID
    let isRunning: Bool
    let processId: Int32
    let startTime: Date
}