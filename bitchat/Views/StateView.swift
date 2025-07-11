//
// StateView.swift
// Stately - State Broadcasting System
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import SwiftUI

struct StateView: View {
    @StateObject private var viewModel = StateViewModel()
    @State private var showNameEditor = false
    @State private var tempName = ""
    @Environment(\.colorScheme) var colorScheme
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color.white
    }
    
    private var textColor: Color {
        colorScheme == .dark ? Color.green : Color(red: 0, green: 0.5, blue: 0)
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.green.opacity(0.8) : Color(red: 0, green: 0.5, blue: 0).opacity(0.8)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            mainContentView
        }
        .background(backgroundColor)
        .foregroundColor(textColor)
        .sheet(isPresented: $viewModel.showStateSelector) {
            StateSelectionView(
                currentState: viewModel.myState,
                onStateSelected: { state in
                    viewModel.updateMyState(state)
                    viewModel.showStateSelector = false
                }
            )
        }
        .alert("Edit Name", isPresented: $showNameEditor) {
            TextField("Name", text: $tempName)
            Button("Cancel", role: .cancel) {
                tempName = viewModel.myName
            }
            Button("Save") {
                viewModel.updateMyName(tempName)
            }
        } message: {
            Text("Enter your display name for nearby peers")
        }
        .onAppear {
            tempName = viewModel.myName
            viewModel.refreshNearbyPeers()
        }
    }
    
    private var headerView: some View {
        HStack {
            // App title and status
            VStack(alignment: .leading, spacing: 2) {
                Text("Stately")
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .foregroundColor(textColor)
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(viewModel.isConnected ? textColor : Color.red)
                        .frame(width: 8, height: 8)
                    
                    Text(viewModel.isConnected ? "broadcasting" : "searching...")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(secondaryTextColor)
                }
            }
            
            Spacer()
            
            // My state display
            Button(action: {
                viewModel.showStateSelector = true
            }) {
                HStack(spacing: 8) {
                    Text(viewModel.myState.emoji)
                        .font(.system(size: 24))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.myName)
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(textColor)
                            .onTapGesture {
                                tempName = viewModel.myName
                                showNameEditor = true
                            }
                        
                        Text(viewModel.myState.displayName)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(secondaryTextColor)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(secondaryTextColor.opacity(0.1))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Network info
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 12))
                    Text("\(viewModel.connectedPeersCount)")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                }
                .foregroundColor(viewModel.isConnected ? textColor : Color.red)
                
                Text("nearby")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(secondaryTextColor)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(backgroundColor.opacity(0.95))
    }
    
    private var mainContentView: some View {
        VStack(spacing: 0) {
            // Nearby peers section
            if viewModel.nearbyPeers.isEmpty {
                emptyStateView
            } else {
                nearbyPeersView
            }
            
            Spacer()
            
            // Emergency SOS button
            sosButtonView
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 48))
                .foregroundColor(secondaryTextColor.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("Searching for nearby peers...")
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(secondaryTextColor)
                
                Text("Make sure Bluetooth is enabled and other devices are running Stately")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(secondaryTextColor.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
        }
    }
    
    private var nearbyPeersView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Section header
                HStack {
                    Text("NEARBY PEERS")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(secondaryTextColor)
                    
                    Spacer()
                    
                    Text("\(viewModel.nearbyPeers.count)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(secondaryTextColor)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
                // Peer list
                ForEach(viewModel.nearbyPeers, id: \.peerID) { peerState in
                    PeerStateRow(peerState: peerState, textColor: textColor, secondaryTextColor: secondaryTextColor)
                }
            }
        }
    }
    
    private var sosButtonView: some View {
        VStack(spacing: 8) {
            if viewModel.myState == .sos {
                // SOS is active - show clear button
                Button(action: {
                    viewModel.clearSOS()
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                        Text("Clear SOS")
                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.green)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            } else {
                // Normal state - show SOS button
                Button(action: {
                    viewModel.triggerSOS()
                }) {
                    HStack {
                        Text("🆘")
                            .font(.system(size: 20))
                        Text("Emergency SOS")
                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.red)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
            
            Text("Long press your state to change it • SOS broadcasts emergency signal")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(secondaryTextColor.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}

struct PeerStateRow: View {
    let peerState: PeerState
    let textColor: Color
    let secondaryTextColor: Color
    
    private var timeAgo: String {
        let interval = Date().timeIntervalSince(peerState.timestamp)
        
        if interval < 60 {
            return "now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // State emoji
            Text(peerState.state.emoji)
                .font(.system(size: 24))
            
            // Peer info
            VStack(alignment: .leading, spacing: 2) {
                Text(peerState.name)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(textColor)
                
                Text(peerState.state.displayName)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(secondaryTextColor)
            }
            
            Spacer()
            
            // Timestamp
            Text(timeAgo)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(secondaryTextColor.opacity(0.7))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            peerState.state == .sos ? 
            Color.red.opacity(0.1) : 
            Color.clear
        )
    }
}

struct StateSelectionView: View {
    let currentState: PeerStateType
    let onStateSelected: (PeerStateType) -> Void
    @Environment(\.colorScheme) var colorScheme
    
    private var textColor: Color {
        colorScheme == .dark ? Color.green : Color(red: 0, green: 0.5, blue: 0)
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.green.opacity(0.8) : Color(red: 0, green: 0.5, blue: 0).opacity(0.8)
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(PeerStateType.allCases, id: \.self) { state in
                    StateSelectionRow(
                        state: state,
                        isSelected: state == currentState,
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor
                    ) {
                        onStateSelected(state)
                    }
                }
            }
            .navigationTitle("Select State")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Cancel") {
                onStateSelected(currentState) // Keep current state
            })
        }
    }
}

struct StateSelectionRow: View {
    let state: PeerStateType
    let isSelected: Bool
    let textColor: Color
    let secondaryTextColor: Color
    let onTap: () -> Void
    
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
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text(state.emoji)
                    .font(.system(size: 24))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(state.displayName)
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .foregroundColor(textColor)
                    
                    Text(getStateDescription(state))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(secondaryTextColor)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(textColor)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .background(isSelected ? textColor.opacity(0.1) : Color.clear)
    }
}

#Preview {
    StateView()
}