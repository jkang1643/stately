//
// StateProtocol.swift
// Stately - State Broadcasting System
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import Foundation
import CryptoKit

// Updated MessageType enum with STATE_UPDATE
enum MessageType: UInt8 {
    case announce = 0x01
    case keyExchange = 0x02
    case leave = 0x03
    case stateUpdate = 0x0A  // New: Peer state broadcasting
    // Removed: message, fragments, channels, delivery tracking
}

// Predefined state types with emoji representations
enum PeerStateType: String, CaseIterable, Codable {
    case sleeping = "sleeping"
    case sos = "sos"
    case redCircle = "red_circle"
    case available = "available"
    case busy = "busy"
    case away = "away"
    case invisible = "invisible"
    case working = "working"
    case eating = "eating"
    case traveling = "traveling"
    
    var emoji: String {
        switch self {
        case .sleeping: return "💤"
        case .sos: return "🆘"
        case .redCircle: return "🔴"
        case .available: return "🟢"
        case .busy: return "🟡"
        case .away: return "🟠"
        case .invisible: return "⚫"
        case .working: return "💼"
        case .eating: return "🍽️"
        case .traveling: return "✈️"
        }
    }
    
    var displayName: String {
        switch self {
        case .sleeping: return "Sleeping"
        case .sos: return "SOS"
        case .redCircle: return "Quiet"
        case .available: return "Available"
        case .busy: return "Busy"
        case .away: return "Away"
        case .invisible: return "Invisible"
        case .working: return "Working"
        case .eating: return "Eating"
        case .traveling: return "Traveling"
        }
    }
}

// Peer state structure
struct PeerState: Codable, Equatable {
    let name: String
    let state: PeerStateType
    let timestamp: Date
    let peerID: String
    
    init(name: String, state: PeerStateType, peerID: String) {
        self.name = name
        self.state = state
        self.timestamp = Date()
        self.peerID = peerID
    }
    
    // Check if state is expired (older than 5 minutes)
    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > 300 // 5 minutes
    }
    
    // Create JSON payload for network transmission
    func toPayload() -> Data? {
        let payload = [
            "name": name,
            "state": state.rawValue,
            "timestamp": timestamp.timeIntervalSince1970
        ]
        return try? JSONSerialization.data(withJSONObject: payload)
    }
    
    // Create PeerState from JSON payload
    static func fromPayload(_ data: Data, peerID: String) -> PeerState? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let name = json["name"] as? String,
              let stateRaw = json["state"] as? String,
              let timestampRaw = json["timestamp"] as? TimeInterval,
              let state = PeerStateType(rawValue: stateRaw) else {
            return nil
        }
        
        var peerState = PeerState(name: name, state: state, peerID: peerID)
        peerState = PeerState(
            name: name,
            state: state,
            timestamp: Date(timeIntervalSince1970: timestampRaw),
            peerID: peerID
        )
        return peerState
    }
}

// Updated BitchatPacket for state broadcasting
struct StatePacket: Codable {
    let version: UInt8
    let type: UInt8
    let senderID: Data
    let timestamp: UInt64
    let payload: Data
    var ttl: UInt8
    
    init(type: UInt8, senderID: Data, payload: Data, ttl: UInt8 = 3) {
        self.version = 1
        self.type = type
        self.senderID = senderID
        self.timestamp = UInt64(Date().timeIntervalSince1970 * 1000)
        self.payload = payload
        self.ttl = ttl
    }
    
    // Convenience initializer for state updates
    init(peerState: PeerState, senderID: String) {
        guard let payload = peerState.toPayload() else {
            fatalError("Failed to create payload from peer state")
        }
        
        self.init(
            type: MessageType.stateUpdate.rawValue,
            senderID: senderID.data(using: .utf8) ?? Data(),
            payload: payload,
            ttl: 3 // Limit propagation to 3 hops for state updates
        )
    }
    
    var data: Data? {
        return BinaryProtocol.encode(self)
    }
    
    static func from(_ data: Data) -> StatePacket? {
        guard let packet = BinaryProtocol.decode(data) else { return nil }
        return StatePacket(
            type: packet.type,
            senderID: packet.senderID,
            payload: packet.payload,
            ttl: packet.ttl
        )
    }
}

// State broadcasting delegate protocol
protocol StateBroadcastDelegate: AnyObject {
    func didReceiveStateUpdate(_ peerState: PeerState)
    func didUpdatePeerList(_ peers: [String])
    func didConnectToPeer(_ peerID: String)
    func didDisconnectFromPeer(_ peerID: String)
}

// Provide default implementations
extension StateBroadcastDelegate {
    func didReceiveStateUpdate(_ peerState: PeerState) {}
    func didUpdatePeerList(_ peers: [String]) {}
    func didConnectToPeer(_ peerID: String) {}
    func didDisconnectFromPeer(_ peerID: String) {}
}

// State broadcasting configuration
struct StateBroadcastConfig {
    static let broadcastInterval: TimeInterval = 15.0  // Broadcast every 15 seconds
    static let stateExpiry: TimeInterval = 300.0       // States expire after 5 minutes
    static let maxPeers: Int = 50                      // Limit peer storage
    static let defaultTTL: UInt8 = 3                   // Limit relay hops
    static let lowBatteryInterval: TimeInterval = 30.0 // Slower broadcast when battery low
}

// Special recipient ID for broadcast state messages
struct SpecialRecipients {
    static let broadcast = Data(repeating: 0xFF, count: 8)  // All 0xFF = broadcast
}