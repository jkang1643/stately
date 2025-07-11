//
// StateBroadcastService.swift
// Stately - State Broadcasting System
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import Foundation
import CoreBluetooth
import Combine
import CryptoKit
#if os(macOS)
import AppKit
import IOKit.ps
#else
import UIKit
#endif

class StateBroadcastService: NSObject, BatteryOptimizerDelegate {
    static let serviceUUID = CBUUID(string: "F47B5E2D-4A9E-4C5A-9B3F-8E1D2C3A4B5C")
    static let characteristicUUID = CBUUID(string: "A1B2C3D4-E5F6-4A5B-8C9D-0E1F2A3B4C5D")
    
    // Core BLE components
    private var centralManager: CBCentralManager?
    private var peripheralManager: CBPeripheralManager?
    private var discoveredPeripherals: [CBPeripheral] = []
    private var connectedPeripherals: [String: CBPeripheral] = [:]
    private var peripheralCharacteristics: [CBPeripheral: CBCharacteristic] = [:]
    private var characteristic: CBMutableCharacteristic?
    private var subscribedCentrals: [CBCentral] = []
    
    // State management
    private var myState: PeerState
    private var peerStates: [String: PeerState] = [:]
    private let peerStatesLock = NSLock()
    private var activePeers: Set<String> = []
    private let activePeersLock = NSLock()
    
    // Services
    private let encryptionService = EncryptionService()
    private let batteryOptimizer = BatteryOptimizer()
    
    // Broadcasting
    private var broadcastTimer: Timer?
    private var stateCleanupTimer: Timer?
    private var lastBroadcastTime = Date.distantPast
    
    // Configuration
    public let myPeerID: String
    public let myNickname: String
    weak var delegate: StateBroadcastDelegate?
    
    // Relay tracking
    private var recentlySeenPackets: Set<String> = []
    private let recentPacketsLock = NSLock()
    private var packetCleanupTimer: Timer?
    
    init(nickname: String = "anon\(Int.random(in: 1000...9999))") {
        self.myPeerID = UUID().uuidString.prefix(8).lowercased()
        self.myNickname = nickname
        self.myState = PeerState(name: nickname, state: .available, peerID: myPeerID)
        
        super.init()
        
        setupBLEServices()
        startTimers()
        
        // Monitor battery level for optimization
        batteryOptimizer.delegate = self
    }
    
    deinit {
        stopServices()
    }
    
    // MARK: - Public Interface
    
    func startServices() {
        print("[STATE] Starting state broadcasting services for \(myNickname) (\(myPeerID))")
        
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [
            CBCentralManagerOptionShowPowerAlertKey: false
        ])
        
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: [
            CBPeripheralManagerOptionShowPowerAlertKey: false
        ])
    }
    
    func stopServices() {
        broadcastTimer?.invalidate()
        stateCleanupTimer?.invalidate()
        packetCleanupTimer?.invalidate()
        
        centralManager?.stopScan()
        peripheralManager?.stopAdvertising()
        
        // Disconnect from all peers
        for peripheral in connectedPeripherals.values {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
        
        connectedPeripherals.removeAll()
        discoveredPeripherals.removeAll()
    }
    
    func updateMyState(name: String? = nil, state: PeerStateType) {
        let newName = name ?? myState.name
        myState = PeerState(name: newName, state: state, peerID: myPeerID)
        
        print("[STATE] Updated my state: \(newName) -> \(state.emoji) \(state.displayName)")
        
        // Immediately broadcast the new state
        broadcastMyState()
    }
    
    func getCurrentPeerStates() -> [PeerState] {
        peerStatesLock.lock()
        defer { peerStatesLock.unlock() }
        
        // Filter out expired states
        let currentTime = Date()
        return peerStates.values.filter { !$0.isExpired }
    }
    
    func getPeerState(for peerID: String) -> PeerState? {
        peerStatesLock.lock()
        defer { peerStatesLock.unlock() }
        
        let state = peerStates[peerID]
        return state?.isExpired == false ? state : nil
    }
    
    // MARK: - Private Implementation
    
    private func setupBLEServices() {
        // Create characteristic for state broadcasting
        characteristic = CBMutableCharacteristic(
            type: Self.characteristicUUID,
            properties: [.read, .write, .notify, .writeWithoutResponse],
            value: nil,
            permissions: [.readable, .writeable]
        )
        
        guard let characteristic = characteristic else {
            print("[STATE] Failed to create characteristic")
            return
        }
        
        let service = CBMutableService(type: Self.serviceUUID, primary: true)
        service.characteristics = [characteristic]
        
        // Will be added when peripheral manager is ready
    }
    
    private func startTimers() {
        // Start periodic state broadcasting
        broadcastTimer = Timer.scheduledTimer(withTimeInterval: StateBroadcastConfig.broadcastInterval, repeats: true) { [weak self] _ in
            self?.broadcastMyState()
        }
        
        // Start state cleanup (remove expired states)
        stateCleanupTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.cleanupExpiredStates()
        }
        
        // Start packet cleanup (prevent relay loops)
        packetCleanupTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.cleanupRecentPackets()
        }
    }
    
    private func broadcastMyState() {
        let now = Date()
        let timeSinceLastBroadcast = now.timeIntervalSince(lastBroadcastTime)
        
        // Apply battery optimization
        let requiredInterval = batteryOptimizer.shouldOptimizeForBattery() ? 
            StateBroadcastConfig.lowBatteryInterval : 
            StateBroadcastConfig.broadcastInterval
        
        guard timeSinceLastBroadcast >= requiredInterval else {
            return
        }
        
        lastBroadcastTime = now
        
        // Create state packet
        let packet = StatePacket(peerState: myState, senderID: myPeerID)
        
        guard let packetData = packet.data else {
            print("[STATE] Failed to encode state packet")
            return
        }
        
        // Encrypt packet
        guard let encryptedData = encryptionService.encryptBroadcast(packetData) else {
            print("[STATE] Failed to encrypt state packet")
            return
        }
        
        // Broadcast via BLE
        broadcastData(encryptedData)
        
        print("[STATE] Broadcasted state: \(myState.name) -> \(myState.state.emoji) \(myState.state.displayName)")
    }
    
    private func broadcastData(_ data: Data) {
        // Update characteristic value
        characteristic?.value = data
        
        // Notify subscribed centrals
        if let characteristic = characteristic, !subscribedCentrals.isEmpty {
            let success = peripheralManager?.updateValue(
                data,
                for: characteristic,
                onSubscribedCentrals: subscribedCentrals
            ) ?? false
            
            if !success {
                print("[STATE] Failed to broadcast state update")
            }
        }
        
        // Also send to connected peripherals as a central
        for (peerID, peripheral) in connectedPeripherals {
            guard let characteristic = peripheralCharacteristics[peripheral] else { continue }
            
            peripheral.writeValue(
                data,
                for: characteristic,
                type: .withoutResponse
            )
        }
    }
    
    private func handleIncomingData(_ data: Data, from peerID: String) {
        // Decrypt data
        guard let decryptedData = encryptionService.decryptBroadcast(data) else {
            print("[STATE] Failed to decrypt data from \(peerID)")
            return
        }
        
        // Parse packet
        guard let packet = StatePacket.from(decryptedData) else {
            print("[STATE] Failed to parse packet from \(peerID)")
            return
        }
        
        // Check packet type
        guard packet.type == MessageType.stateUpdate.rawValue else {
            print("[STATE] Ignoring non-state packet from \(peerID)")
            return
        }
        
        // Extract sender ID
        let senderIDString = String(data: packet.senderID, encoding: .utf8) ?? "unknown"
        
        // Parse peer state
        guard let peerState = PeerState.fromPayload(packet.payload, peerID: senderIDString) else {
            print("[STATE] Failed to parse peer state from \(peerID)")
            return
        }
        
        // Don't process our own state
        guard senderIDString != myPeerID else {
            return
        }
        
        // Check for relay
        if shouldRelay(packet: packet, senderID: senderIDString) {
            relayPacket(packet)
        }
        
        // Update peer state
        updatePeerState(peerState)
    }
    
    private func shouldRelay(packet: StatePacket, senderID: String) -> Bool {
        // Don't relay if TTL is 0
        guard packet.ttl > 0 else { return false }
        
        // Check if we've seen this packet recently (prevent loops)
        let packetHash = "\(senderID)-\(packet.timestamp)"
        
        recentPacketsLock.lock()
        defer { recentPacketsLock.unlock() }
        
        if recentlySeenPackets.contains(packetHash) {
            return false
        }
        
        recentlySeenPackets.insert(packetHash)
        return true
    }
    
    private func relayPacket(_ packet: StatePacket) {
        // Decrement TTL
        var relayPacket = packet
        relayPacket.ttl = packet.ttl - 1
        
        guard let packetData = relayPacket.data else {
            print("[STATE] Failed to encode relay packet")
            return
        }
        
        // Re-encrypt for relay
        guard let encryptedData = encryptionService.encryptBroadcast(packetData) else {
            print("[STATE] Failed to encrypt relay packet")
            return
        }
        
        // Broadcast relayed packet
        broadcastData(encryptedData)
        
        print("[STATE] Relayed state packet (TTL: \(relayPacket.ttl))")
    }
    
    private func updatePeerState(_ peerState: PeerState) {
        peerStatesLock.lock()
        defer { peerStatesLock.unlock() }
        
        // Check if this is a newer state
        if let existingState = peerStates[peerState.peerID] {
            guard peerState.timestamp > existingState.timestamp else {
                return // Ignore older state
            }
        }
        
        peerStates[peerState.peerID] = peerState
        
        print("[STATE] Updated peer state: \(peerState.name) -> \(peerState.state.emoji) \(peerState.state.displayName)")
        
        // Notify delegate
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.didReceiveStateUpdate(peerState)
        }
    }
    
    private func cleanupExpiredStates() {
        peerStatesLock.lock()
        defer { peerStatesLock.unlock() }
        
        let beforeCount = peerStates.count
        peerStates = peerStates.filter { !$0.value.isExpired }
        
        let removedCount = beforeCount - peerStates.count
        if removedCount > 0 {
            print("[STATE] Cleaned up \(removedCount) expired peer states")
            
            // Update active peers list
            activePeersLock.lock()
            activePeers = Set(peerStates.keys)
            activePeersLock.unlock()
            
            // Notify delegate
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.didUpdatePeerList(Array(self.activePeers))
            }
        }
    }
    
    private func cleanupRecentPackets() {
        recentPacketsLock.lock()
        defer { recentPacketsLock.unlock() }
        
        // Keep only packets from last 2 minutes
        let cutoffTime = Date().timeIntervalSince1970 - 120
        
        recentlySeenPackets = recentlySeenPackets.filter { packetHash in
            let components = packetHash.split(separator: "-")
            guard components.count >= 2,
                  let timestamp = Double(components.last!) else {
                return false
            }
            return timestamp / 1000 > cutoffTime
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension StateBroadcastService: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("[STATE] Central manager powered on - starting scan")
            central.scanForPeripherals(withServices: [Self.serviceUUID], options: [
                CBCentralManagerScanOptionAllowDuplicatesKey: false
            ])
            
        case .poweredOff:
            print("[STATE] Central manager powered off")
            
        case .unauthorized:
            print("[STATE] Central manager unauthorized")
            
        case .unsupported:
            print("[STATE] Central manager unsupported")
            
        default:
            print("[STATE] Central manager state: \(central.state.rawValue)")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let peerID = peripheral.identifier.uuidString.prefix(8).lowercased()
        
        // Don't connect to ourselves
        guard String(peerID) != myPeerID else { return }
        
        print("[STATE] Discovered peer: \(peerID)")
        
        if !discoveredPeripherals.contains(peripheral) {
            discoveredPeripherals.append(peripheral)
            peripheral.delegate = self
            central.connect(peripheral, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        let peerID = peripheral.identifier.uuidString.prefix(8).lowercased()
        print("[STATE] Connected to peer: \(peerID)")
        
        connectedPeripherals[String(peerID)] = peripheral
        peripheral.discoverServices([Self.serviceUUID])
        
        delegate?.didConnectToPeer(String(peerID))
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        let peerID = peripheral.identifier.uuidString.prefix(8).lowercased()
        print("[STATE] Disconnected from peer: \(peerID)")
        
        connectedPeripherals.removeValue(forKey: String(peerID))
        peripheralCharacteristics.removeValue(forKey: peripheral)
        
        delegate?.didDisconnectFromPeer(String(peerID))
    }
}

// MARK: - CBPeripheralDelegate

extension StateBroadcastService: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            if service.uuid == Self.serviceUUID {
                peripheral.discoverCharacteristics([Self.characteristicUUID], for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            if characteristic.uuid == Self.characteristicUUID {
                peripheralCharacteristics[peripheral] = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        
        let peerID = peripheral.identifier.uuidString.prefix(8).lowercased()
        handleIncomingData(data, from: String(peerID))
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("[STATE] Error writing to characteristic: \(error)")
        }
    }
}

// MARK: - CBPeripheralManagerDelegate

extension StateBroadcastService: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            print("[STATE] Peripheral manager powered on - starting advertising")
            
            if let characteristic = characteristic {
                let service = CBMutableService(type: Self.serviceUUID, primary: true)
                service.characteristics = [characteristic]
                peripheral.add(service)
            }
            
        case .poweredOff:
            print("[STATE] Peripheral manager powered off")
            
        default:
            print("[STATE] Peripheral manager state: \(peripheral.state.rawValue)")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error = error {
            print("[STATE] Error adding service: \(error)")
            return
        }
        
        print("[STATE] Service added successfully - starting advertising")
        
        peripheral.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [Self.serviceUUID],
            CBAdvertisementDataLocalNameKey: "StateBeacon"
        ])
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            print("[STATE] Error starting advertising: \(error)")
        } else {
            print("[STATE] Started advertising successfully")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("[STATE] Central subscribed to characteristic")
        
        if !subscribedCentrals.contains(central) {
            subscribedCentrals.append(central)
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        print("[STATE] Central unsubscribed from characteristic")
        
        subscribedCentrals.removeAll { $0 == central }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            guard let data = request.value else { continue }
            
            let peerID = request.central.identifier.uuidString.prefix(8).lowercased()
            handleIncomingData(data, from: String(peerID))
        }
        
        peripheral.respond(to: requests.first!, withResult: .success)
    }
}

// MARK: - BatteryOptimizerDelegate

extension StateBroadcastService: BatteryOptimizerDelegate {
    func batteryLevelDidChange(_ level: Float) {
        print("[STATE] Battery level changed: \(Int(level * 100))%")
        
        // Adjust broadcast frequency based on battery level
        if batteryOptimizer.shouldOptimizeForBattery() {
            print("[STATE] Switching to low-power broadcasting mode")
        }
    }
    
    func powerModeDidChange(_ mode: BatteryOptimizer.PowerMode) {
        print("[STATE] Power mode changed: \(mode)")
    }
}