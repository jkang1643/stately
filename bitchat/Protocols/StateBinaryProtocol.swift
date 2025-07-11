//
// StateBinaryProtocol.swift
// Stately - State Broadcasting System
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import Foundation

extension Data {
    func trimmingNullBytes() -> Data {
        if let nullIndex = self.firstIndex(of: 0) {
            return self.prefix(nullIndex)
        }
        return self
    }
}

// Binary Protocol Format for State Broadcasting:
// Header (Fixed 12 bytes):
// - Version: 1 byte
// - Type: 1 byte (0x0A for STATE_UPDATE)
// - TTL: 1 byte (default 3 for state messages)
// - Timestamp: 8 bytes (UInt64)
// - PayloadLength: 2 bytes (UInt16)
//
// Variable sections:
// - SenderID: 8 bytes (fixed)
// - Payload: Variable length JSON state data

struct StateBinaryProtocol {
    static let headerSize = 12
    static let senderIDSize = 8
    
    // Encode StatePacket to binary format
    static func encode(_ packet: StatePacket) -> Data? {
        var data = Data()
        
        // Header
        data.append(packet.version)
        data.append(packet.type)
        data.append(packet.ttl)
        
        // Timestamp (8 bytes, big-endian)
        for i in (0..<8).reversed() {
            data.append(UInt8((packet.timestamp >> (i * 8)) & 0xFF))
        }
        
        // Payload length (2 bytes, big-endian)
        let payloadLength = UInt16(packet.payload.count)
        data.append(UInt8((payloadLength >> 8) & 0xFF))
        data.append(UInt8(payloadLength & 0xFF))
        
        // SenderID (exactly 8 bytes)
        let senderBytes = packet.senderID.prefix(senderIDSize)
        data.append(senderBytes)
        if senderBytes.count < senderIDSize {
            data.append(Data(repeating: 0, count: senderIDSize - senderBytes.count))
        }
        
        // Payload
        data.append(packet.payload)
        
        return data
    }
    
    // Decode binary data to StatePacket
    static func decode(_ data: Data) -> StatePacket? {
        guard data.count >= headerSize + senderIDSize else { return nil }
        
        var offset = 0
        
        // Header
        let version = data[offset]; offset += 1
        guard version == 1 else { return nil } // Only support version 1
        
        let type = data[offset]; offset += 1
        let ttl = data[offset]; offset += 1
        
        // Timestamp
        let timestampData = data[offset..<offset+8]
        let timestamp = timestampData.reduce(0) { result, byte in
            (result << 8) | UInt64(byte)
        }
        offset += 8
        
        // Payload length
        let payloadLengthData = data[offset..<offset+2]
        let payloadLength = payloadLengthData.reduce(0) { result, byte in
            (result << 8) | UInt16(byte)
        }
        offset += 2
        
        // Check total expected size
        let expectedSize = headerSize + senderIDSize + Int(payloadLength)
        guard data.count >= expectedSize else { return nil }
        
        // SenderID
        let senderID = data[offset..<offset+senderIDSize].trimmingNullBytes()
        offset += senderIDSize
        
        // Payload
        let payload = data[offset..<offset+Int(payloadLength)]
        
        return StatePacket(
            type: type,
            senderID: senderID,
            payload: Data(payload),
            ttl: ttl
        )
    }
}

// Update the original BinaryProtocol to handle StatePacket
extension BinaryProtocol {
    // Add support for StatePacket encoding
    static func encode(_ packet: StatePacket) -> Data? {
        return StateBinaryProtocol.encode(packet)
    }
    
    // Add support for StatePacket decoding
    static func decodeState(_ data: Data) -> StatePacket? {
        return StateBinaryProtocol.decode(data)
    }
}