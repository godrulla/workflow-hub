import Foundation
import Starscream
import Combine

@preconcurrency protocol WebSocketManagerDelegate: AnyObject {
    func webSocketDidConnect()
    func webSocketDidDisconnect()
    func webSocketDidReceiveError(_ error: Error)
    func webSocketDidReceiveMessage(_ message: WebSocketMessage)
}

class WebSocketManager: NSObject {
    weak var delegate: WebSocketManagerDelegate?
    
    private var socket: WebSocket?
    private let serverURL = URL(string: "ws://localhost:8765")!
    private var isConnecting = false
    private var shouldReconnect = true
    
    // Reconnection properties
    private var reconnectTimer: Timer?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    private let reconnectInterval: TimeInterval = 3.0
    
    // Message queue for offline messages
    private var messageQueue: [WebSocketMessage] = []
    
    func connect() {
        guard !isConnecting else { return }
        
        isConnecting = true
        shouldReconnect = true
        
        var request = URLRequest(url: serverURL)
        request.timeoutInterval = 5
        
        socket = WebSocket(request: request)
        socket?.delegate = self
        socket?.connect()
        
        print("Attempting to connect to WebSocket at \(serverURL)")
    }
    
    func disconnect() {
        shouldReconnect = false
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        
        socket?.disconnect()
        socket = nil
        isConnecting = false
        
        print("WebSocket disconnected")
    }
    
    func sendMessage(_ message: WebSocketMessage) {
        guard let socket = socket else {
            // Queue message for when connection is restored
            messageQueue.append(message)
            print("WebSocket not connected, queuing message: \(message.data.action)")
            return
        }
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(message)
            
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                socket.write(string: jsonString)
                print("Sent WebSocket message: \(message.data.action)")
            }
        } catch {
            print("Failed to encode WebSocket message: \(error)")
        }
    }
    
    private func processQueuedMessages() {
        guard socket != nil else { return }
        
        for message in messageQueue {
            sendMessage(message)
        }
        messageQueue.removeAll()
    }
    
    private func scheduleReconnect() {
        guard shouldReconnect && reconnectAttempts < maxReconnectAttempts else {
            print("Max reconnection attempts reached or reconnection disabled")
            delegate?.webSocketDidReceiveError(
                WebSocketError.maxReconnectAttemptsReached
            )
            return
        }
        
        reconnectAttempts += 1
        
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: reconnectInterval, repeats: false) { [weak self] _ in
            print("Attempting reconnection #\(self?.reconnectAttempts ?? 0)")
            self?.connect()
        }
    }
}

// MARK: - WebSocketDelegate
extension WebSocketManager: WebSocketDelegate {
    func didReceive(event: WebSocketEvent, client: WebSocketClient) {
        switch event {
        case .connected(let headers):
            print("WebSocket connected with headers: \(headers)")
            isConnecting = false
            reconnectAttempts = 0
            reconnectTimer?.invalidate()
            reconnectTimer = nil
            
            delegate?.webSocketDidConnect()
            
            // Process any queued messages
            processQueuedMessages()
            
        case .disconnected(let reason, let code):
            print("WebSocket disconnected with reason: \(reason), code: \(code)")
            isConnecting = false
            
            delegate?.webSocketDidDisconnect()
            
            // Schedule reconnection if needed
            if shouldReconnect {
                scheduleReconnect()
            }
            
        case .text(let string):
            print("Received WebSocket text: \(string.prefix(100))...")
            handleReceivedMessage(string)
            
        case .binary(let data):
            print("Received WebSocket binary data: \(data.count) bytes")
            
        case .error(let error):
            print("WebSocket error: \(error?.localizedDescription ?? "Unknown error")")
            isConnecting = false
            
            let wsError = error ?? WebSocketError.unknownError
            delegate?.webSocketDidReceiveError(wsError)
            
            // Schedule reconnection on error
            if shouldReconnect {
                scheduleReconnect()
            }
            
        case .ping(_):
            break
            
        case .pong(_):
            break
            
        case .viabilityChanged(let isViable):
            print("WebSocket viability changed: \(isViable)")
            
        case .reconnectSuggested(let suggested):
            if suggested && shouldReconnect {
                scheduleReconnect()
            }
            
        case .cancelled:
            print("WebSocket cancelled")
            isConnecting = false
            
        case .peerClosed:
            print("WebSocket peer closed connection")
            isConnecting = false
            delegate?.webSocketDidDisconnect()
        }
    }
    
    private func handleReceivedMessage(_ string: String) {
        guard let data = string.data(using: .utf8) else {
            print("Failed to convert string to data")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let message = try decoder.decode(WebSocketMessage.self, from: data)
            
            delegate?.webSocketDidReceiveMessage(message)
        } catch {
            print("Failed to decode WebSocket message: \(error)")
        }
    }
}

// MARK: - WebSocket Message Structure
struct WebSocketMessage: Codable {
    let id: String
    let type: MessageType
    let timestamp: Date
    let source: String
    let target: String?
    let data: MessageData
    
    init(type: MessageType, data: MessageData, target: String? = nil) {
        self.id = UUID().uuidString
        self.type = type
        self.timestamp = Date()
        self.source = "gui"
        self.target = target
        self.data = data
    }
    
    struct MessageData: Codable {
        let action: String
        let payload: [String: Any]
        let metadata: [String: Any]?
        
        init(action: String, payload: [String: Any], metadata: [String: Any]? = nil) {
            self.action = action
            self.payload = payload
            self.metadata = metadata
        }
        
        // Custom encoding/decoding for [String: Any]
        enum CodingKeys: String, CodingKey {
            case action, payload, metadata
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(action, forKey: .action)
            try container.encode(payload.compactMapValues { $0 as? String }, forKey: .payload)
            try container.encodeIfPresent(metadata?.compactMapValues { $0 as? String }, forKey: .metadata)
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            action = try container.decode(String.self, forKey: .action)
            
            // Handle payload as flexible dictionary
            if let payloadDict = try? container.decode([String: String].self, forKey: .payload) {
                payload = payloadDict
            } else {
                payload = [:]
            }
            
            // Handle metadata as flexible dictionary
            if let metadataDict = try? container.decodeIfPresent([String: String].self, forKey: .metadata) {
                metadata = metadataDict
            } else {
                metadata = nil
            }
        }
    }
    
    enum MessageType: String, Codable {
        case command
        case response
        case event
        case stream
    }
}

// MARK: - WebSocket Errors
enum WebSocketError: LocalizedError {
    case connectionFailed
    case maxReconnectAttemptsReached
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .connectionFailed:
            return "Failed to connect to the Workflow Hub backend"
        case .maxReconnectAttemptsReached:
            return "Maximum reconnection attempts reached"
        case .unknownError:
            return "An unknown WebSocket error occurred"
        }
    }
}