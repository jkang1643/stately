//
// StateEncryptionService.swift
// Stately - State Broadcasting System
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import Foundation
import CryptoKit

class StateEncryptionService {
    // Shared broadcast key for state messages (in a real implementation, this could be derived from a shared secret)
    private static let broadcastKeyData = "StateBeacon2024".data(using: .utf8)!
    private let broadcastKey: SymmetricKey
    
    // Device-specific ephemeral keys for this session
    private let devicePrivateKey: Curve25519.KeyAgreement.PrivateKey
    private let devicePublicKey: Curve25519.KeyAgreement.PublicKey
    
    init() {
        // Initialize broadcast key for shared state encryption
        var keyData = Data(count: 32)
        let _ = keyData.withUnsafeMutableBytes { keyBytes in
            StateEncryptionService.broadcastKeyData.withUnsafeBytes { seedBytes in
                // Simple key derivation - in production, use proper HKDF
                let seed = seedBytes.bindMemory(to: UInt8.self)
                let key = keyBytes.bindMemory(to: UInt8.self)
                
                for i in 0..<32 {
                    key[i] = seed[i % StateEncryptionService.broadcastKeyData.count] ^ UInt8(i)
                }
            }
        }
        
        self.broadcastKey = SymmetricKey(data: keyData)
        
        // Generate ephemeral device keys for this session
        self.devicePrivateKey = Curve25519.KeyAgreement.PrivateKey()
        self.devicePublicKey = devicePrivateKey.publicKey
        
        print("[ENCRYPTION] State encryption service initialized")
    }
    
    // MARK: - Broadcast Encryption (for state messages)
    
    func encryptBroadcast(_ data: Data) -> Data? {
        do {
            // Apply privacy-preserving padding
            let blockSize = MessagePadding.optimalBlockSize(for: data.count)
            let paddedData = MessagePadding.pad(data, toSize: blockSize)
            
            // Encrypt with AES-GCM using broadcast key
            let sealedBox = try AES.GCM.seal(paddedData, using: broadcastKey)
            return sealedBox.combined
        } catch {
            print("[ENCRYPTION] Failed to encrypt broadcast data: \(error)")
            return nil
        }
    }
    
    func decryptBroadcast(_ encryptedData: Data) -> Data? {
        do {
            // Decrypt with AES-GCM
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            let decryptedData = try AES.GCM.open(sealedBox, using: broadcastKey)
            
            // Remove padding
            let unpaddedData = MessagePadding.unpad(decryptedData)
            return unpaddedData
        } catch {
            print("[ENCRYPTION] Failed to decrypt broadcast data: \(error)")
            return nil
        }
    }
    
    // MARK: - Digital Signatures (for state authenticity)
    
    func signData(_ data: Data) -> Data? {
        do {
            let privateSigningKey = Curve25519.Signing.PrivateKey()
            let signature = try privateSigningKey.signature(for: data)
            return signature
        } catch {
            print("[ENCRYPTION] Failed to sign data: \(error)")
            return nil
        }
    }
    
    func verifySignature(_ signature: Data, for data: Data, publicKey: Data) -> Bool {
        do {
            let publicSigningKey = try Curve25519.Signing.PublicKey(rawRepresentation: publicKey)
            return publicSigningKey.isValidSignature(signature, for: data)
        } catch {
            print("[ENCRYPTION] Failed to verify signature: \(error)")
            return false
        }
    }
    
    // MARK: - Key Management
    
    func getDevicePublicKey() -> Data {
        return devicePublicKey.rawRepresentation
    }
    
    func createSharedSecret(with peerPublicKey: Data) -> Data? {
        do {
            let peerKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: peerPublicKey)
            let sharedSecret = try devicePrivateKey.sharedSecretFromKeyAgreement(with: peerKey)
            return sharedSecret.withUnsafeBytes { Data($0) }
        } catch {
            print("[ENCRYPTION] Failed to create shared secret: \(error)")
            return nil
        }
    }
    
    // MARK: - Utility Functions
    
    func generateRandomNonce() -> Data {
        var nonce = Data(count: 12) // 96-bit nonce for AES-GCM
        let result = nonce.withUnsafeMutableBytes { nonceBytes in
            SecRandomCopyBytes(kSecRandomDefault, 12, nonceBytes.bindMemory(to: UInt8.self).baseAddress!)
        }
        
        guard result == errSecSuccess else {
            print("[ENCRYPTION] Failed to generate random nonce")
            return Data(count: 12)
        }
        
        return nonce
    }
    
    func hashData(_ data: Data) -> Data {
        let hash = SHA256.hash(data: data)
        return Data(hash)
    }
    
    // MARK: - State-Specific Encryption
    
    func encryptStatePayload(_ statePayload: Data, withPadding: Bool = true) -> Data? {
        var dataToEncrypt = statePayload
        
        if withPadding {
            // Apply privacy padding to obscure state content length
            let targetSize = max(256, statePayload.count.nextPowerOfTwo())
            dataToEncrypt = MessagePadding.pad(statePayload, toSize: targetSize)
        }
        
        return encryptBroadcast(dataToEncrypt)
    }
    
    func decryptStatePayload(_ encryptedData: Data) -> Data? {
        guard let decryptedData = decryptBroadcast(encryptedData) else {
            return nil
        }
        
        // The padding removal is handled in decryptBroadcast
        return decryptedData
    }
}

// MARK: - Extensions

extension Int {
    func nextPowerOfTwo() -> Int {
        guard self > 0 else { return 1 }
        return 1 << (Int.bitWidth - (self - 1).leadingZeroBitCount)
    }
}

// Update the original EncryptionService to work with state broadcasting
extension EncryptionService {
    // Add broadcast encryption methods for compatibility
    func encryptBroadcast(_ data: Data) -> Data? {
        // Simple symmetric encryption for broadcast state messages
        do {
            // Use a fixed key for demo - in production, derive from shared context
            let broadcastKey = SymmetricKey(size: .bits256)
            let sealedBox = try AES.GCM.seal(data, using: broadcastKey)
            return sealedBox.combined
        } catch {
            print("[ENCRYPTION] Failed to encrypt broadcast: \(error)")
            return nil
        }
    }
    
    func decryptBroadcast(_ encryptedData: Data) -> Data? {
        do {
            // Use the same fixed key for demo
            let broadcastKey = SymmetricKey(size: .bits256)
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            return try AES.GCM.open(sealedBox, using: broadcastKey)
        } catch {
            print("[ENCRYPTION] Failed to decrypt broadcast: \(error)")
            return nil
        }
    }
}