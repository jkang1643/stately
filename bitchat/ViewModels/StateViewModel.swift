//
// StateViewModel.swift
// Stately - State Broadcasting System
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import Foundation
import SwiftUI
import Combine

class StateViewModel: ObservableObject {
    @Published var myName: String = ""
    @Published var myState: PeerStateType = .available
    @Published var nearbyPeers: [PeerState] = []
    @Published var connectedPeersCount: Int = 0
    @Published var isConnected: Bool = false
    @Published var showStateSelector: Bool = false
    @Published var batteryLevel: Float = 1.0
    @Published var powerMode: BatteryOptimizer.PowerMode = .performance
    
    private let stateBroadcastService: StateBroadcastService
    private let userDefaults = UserDefaults.standard
    private let nameKey = "state.myName"
    private let stateKey = "state.myState"
    
    init() {
        // Load saved preferences
        loadSettings()
        
        // Initialize broadcast service
        stateBroadcastService = StateBroadcastService(nickname: myName)
        stateBroadcastService.delegate = self
        
        // Start services
        stateBroadcastService.startServices()
        
        // Update service with current state
        updateBroadcastService()
    }
    
    deinit {
        stateBroadcastService.stopServices()
    }
    
    // MARK: - Public Interface
    
    func updateMyState(_ newState: PeerStateType) {
        myState = newState
        saveSettings()
        updateBroadcastService()
    }
    
    func updateMyName(_ newName: String) {
        myName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        if myName.isEmpty {
            myName = "anon\(Int.random(in: 1000...9999))"
        }
        saveSettings()
        updateBroadcastService()
    }
    
    func refreshNearbyPeers() {
        let currentStates = stateBroadcastService.getCurrentPeerStates()
        nearbyPeers = currentStates.sorted { $0.timestamp > $1.timestamp }
    }
    
    func getStateDisplayInfo(for state: PeerStateType) -> (emoji: String, name: String, description: String) {
        return (state.emoji, state.displayName, getStateDescription(state))
    }
    
    private func getStateDescription(_ state: PeerStateType) -> String {
        switch state {
        case .sleeping: return "Not available"
        case .sos: return "Emergency - needs help"
        case .redCircle: return "Do not disturb"
        case .available: return "Ready to connect"
        case .busy: return "Currently occupied"
        case .away: return "Temporarily away"
        case .invisible: return "Hidden from others"
        case .working: return "Focused on work"
        case .eating: return "Having a meal"
        case .traveling: return "On the move"
        }
    }
    
    // MARK: - Private Implementation
    
    private func loadSettings() {
        myName = userDefaults.string(forKey: nameKey) ?? "anon\(Int.random(in: 1000...9999))"
        
        if let stateRaw = userDefaults.string(forKey: stateKey),
           let savedState = PeerStateType(rawValue: stateRaw) {
            myState = savedState
        }
    }
    
    private func saveSettings() {
        userDefaults.set(myName, forKey: nameKey)
        userDefaults.set(myState.rawValue, forKey: stateKey)
        userDefaults.synchronize()
    }
    
    private func updateBroadcastService() {
        stateBroadcastService.updateMyState(name: myName, state: myState)
    }
    
    // MARK: - Emergency Functions
    
    func triggerSOS() {
        updateMyState(.sos)
        
        // Haptic feedback for emergency
        #if os(iOS)
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.prepare()
        
        // Triple strong pulses for SOS
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                impactFeedback.impactOccurred()
            }
        }
        #endif
    }
    
    func clearSOS() {
        if myState == .sos {
            updateMyState(.available)
        }
    }
    
    // MARK: - Battery and Performance
    
    func updateBatteryInfo(_ level: Float, powerMode: BatteryOptimizer.PowerMode) {
        batteryLevel = level
        self.powerMode = powerMode
    }
}

// MARK: - StateBroadcastDelegate

extension StateViewModel: StateBroadcastDelegate {
    func didReceiveStateUpdate(_ peerState: PeerState) {
        DispatchQueue.main.async { [weak self] in
            self?.refreshNearbyPeers()
        }
    }
    
    func didUpdatePeerList(_ peers: [String]) {
        DispatchQueue.main.async { [weak self] in
            self?.connectedPeersCount = peers.count
            self?.isConnected = !peers.isEmpty
            self?.refreshNearbyPeers()
        }
    }
    
    func didConnectToPeer(_ peerID: String) {
        DispatchQueue.main.async { [weak self] in
            self?.connectedPeersCount += 1
            self?.isConnected = true
        }
    }
    
    func didDisconnectFromPeer(_ peerID: String) {
        DispatchQueue.main.async { [weak self] in
            self?.connectedPeersCount = max(0, (self?.connectedPeersCount ?? 1) - 1)
            self?.isConnected = (self?.connectedPeersCount ?? 0) > 0
        }
    }
}