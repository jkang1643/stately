//
// StateProtocolTests.swift
// Stately - State Broadcasting System
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import XCTest
@testable import stately

class StateProtocolTests: XCTestCase {
    
    func testPeerStateCreation() {
        let peerState = PeerState(name: "Alice", state: .sleeping, peerID: "peer123")
        
        XCTAssertEqual(peerState.name, "Alice")
        XCTAssertEqual(peerState.state, .sleeping)
        XCTAssertEqual(peerState.peerID, "peer123")
        XCTAssertFalse(peerState.isExpired)
    }
    
    func testPeerStateExpiration() {
        // Create a state with an old timestamp
        var peerState = PeerState(name: "Bob", state: .available, peerID: "peer456")
        
        // Manually set an old timestamp (6 minutes ago)
        let oldTimestamp = Date(timeIntervalSinceNow: -360)
        peerState = PeerState(
            name: peerState.name,
            state: peerState.state,
            timestamp: oldTimestamp,
            peerID: peerState.peerID
        )
        
        XCTAssertTrue(peerState.isExpired)
    }
    
    func testPeerStatePayloadSerialization() {
        let peerState = PeerState(name: "Charlie", state: .sos, peerID: "peer789")
        
        // Test payload creation
        guard let payload = peerState.toPayload() else {
            XCTFail("Failed to create payload")
            return
        }
        
        // Test payload deserialization
        guard let deserializedState = PeerState.fromPayload(payload, peerID: "peer789") else {
            XCTFail("Failed to deserialize payload")
            return
        }
        
        XCTAssertEqual(deserializedState.name, peerState.name)
        XCTAssertEqual(deserializedState.state, peerState.state)
        XCTAssertEqual(deserializedState.peerID, peerState.peerID)
    }
    
    func testStatePacketCreation() {
        let peerState = PeerState(name: "Diana", state: .redCircle, peerID: "peer101")
        let packet = StatePacket(peerState: peerState, senderID: "peer101")
        
        XCTAssertEqual(packet.version, 1)
        XCTAssertEqual(packet.type, MessageType.stateUpdate.rawValue)
        XCTAssertEqual(packet.ttl, 3)
        XCTAssertEqual(String(data: packet.senderID, encoding: .utf8), "peer101")
    }
    
    func testStatePacketBinarySerialization() {
        let peerState = PeerState(name: "Eve", state: .working, peerID: "peer202")
        let packet = StatePacket(peerState: peerState, senderID: "peer202")
        
        // Test binary encoding
        guard let packetData = packet.data else {
            XCTFail("Failed to encode packet")
            return
        }
        
        // Test binary decoding
        guard let decodedPacket = StatePacket.from(packetData) else {
            XCTFail("Failed to decode packet")
            return
        }
        
        XCTAssertEqual(decodedPacket.version, packet.version)
        XCTAssertEqual(decodedPacket.type, packet.type)
        XCTAssertEqual(decodedPacket.ttl, packet.ttl)
        XCTAssertEqual(decodedPacket.senderID, packet.senderID)
        XCTAssertEqual(decodedPacket.payload, packet.payload)
    }
    
    func testStateTypeProperties() {
        let sleepingState = PeerStateType.sleeping
        XCTAssertEqual(sleepingState.emoji, "💤")
        XCTAssertEqual(sleepingState.displayName, "Sleeping")
        
        let sosState = PeerStateType.sos
        XCTAssertEqual(sosState.emoji, "🆘")
        XCTAssertEqual(sosState.displayName, "SOS")
        
        let quietState = PeerStateType.redCircle
        XCTAssertEqual(quietState.emoji, "🔴")
        XCTAssertEqual(quietState.displayName, "Quiet")
    }
    
    func testTTLDecrement() {
        let peerState = PeerState(name: "Frank", state: .traveling, peerID: "peer303")
        var packet = StatePacket(peerState: peerState, senderID: "peer303")
        
        XCTAssertEqual(packet.ttl, 3)
        
        // Simulate relay
        packet.ttl = packet.ttl - 1
        XCTAssertEqual(packet.ttl, 2)
        
        packet.ttl = packet.ttl - 1
        XCTAssertEqual(packet.ttl, 1)
        
        packet.ttl = packet.ttl - 1
        XCTAssertEqual(packet.ttl, 0)
        
        // Should not relay when TTL is 0
    }
    
    func testMultipleStateUpdates() {
        var states: [PeerState] = []
        
        // Add multiple states from different peers
        states.append(PeerState(name: "Alice", state: .available, peerID: "peer1"))
        states.append(PeerState(name: "Bob", state: .busy, peerID: "peer2"))
        states.append(PeerState(name: "Charlie", state: .sos, peerID: "peer3"))
        
        XCTAssertEqual(states.count, 3)
        
        // Test filtering non-expired states
        let nonExpiredStates = states.filter { !$0.isExpired }
        XCTAssertEqual(nonExpiredStates.count, 3)
        
        // Test SOS state detection
        let sosStates = states.filter { $0.state == .sos }
        XCTAssertEqual(sosStates.count, 1)
        XCTAssertEqual(sosStates.first?.name, "Charlie")
    }
    
    func testStateConfigurationConstants() {
        XCTAssertEqual(StateBroadcastConfig.broadcastInterval, 15.0)
        XCTAssertEqual(StateBroadcastConfig.stateExpiry, 300.0)
        XCTAssertEqual(StateBroadcastConfig.maxPeers, 50)
        XCTAssertEqual(StateBroadcastConfig.defaultTTL, 3)
        XCTAssertEqual(StateBroadcastConfig.lowBatteryInterval, 30.0)
    }
    
    func testJSONSerializationRoundTrip() {
        let originalState = PeerState(name: "Test User", state: .eating, peerID: "test123")
        
        // Convert to JSON payload
        guard let jsonData = originalState.toPayload() else {
            XCTFail("Failed to create JSON payload")
            return
        }
        
        // Parse back from JSON
        guard let parsedState = PeerState.fromPayload(jsonData, peerID: "test123") else {
            XCTFail("Failed to parse JSON payload")
            return
        }
        
        XCTAssertEqual(parsedState.name, originalState.name)
        XCTAssertEqual(parsedState.state, originalState.state)
        XCTAssertEqual(parsedState.peerID, originalState.peerID)
        
        // Timestamps might differ slightly, so check they're close
        let timeDifference = abs(parsedState.timestamp.timeIntervalSince(originalState.timestamp))
        XCTAssertLessThan(timeDifference, 1.0) // Should be within 1 second
    }
}