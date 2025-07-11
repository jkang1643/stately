![ChatGPT Image Jul 5, 2025 at 06_07_31 PM]([https://github.com/jkang1643/stately/issues/1#issue-3224429942](https://private-user-images.githubusercontent.com/41090687/465514495-b4edd478-502e-4849-bf88-e1471a7cd782.png?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3NTIyNzU0NDYsIm5iZiI6MTc1MjI3NTE0NiwicGF0aCI6Ii80MTA5MDY4Ny80NjU1MTQ0OTUtYjRlZGQ0NzgtNTAyZS00ODQ5LWJmODgtZTE0NzFhN2NkNzgyLnBuZz9YLUFtei1BbGdvcml0aG09QVdTNC1ITUFDLVNIQTI1NiZYLUFtei1DcmVkZW50aWFsPUFLSUFWQ09EWUxTQTUzUFFLNFpBJTJGMjAyNTA3MTElMkZ1cy1lYXN0LTElMkZzMyUyRmF3czRfcmVxdWVzdCZYLUFtei1EYXRlPTIwMjUwNzExVDIzMDU0NlomWC1BbXotRXhwaXJlcz0zMDAmWC1BbXotU2lnbmF0dXJlPTc1Nzg0MTM4YzdiYWUwYmRmMTQ5N2FkM2NlMzc1ZTdkNTAyOTg0ZDRlMTAyZGNjMTNkZTc3ODc3Y2NhN2U5YzMmWC1BbXotU2lnbmVkSGVhZGVycz1ob3N0In0.d_1wCeBdSsjwCIfhM3tC4KcNxyAGLI-6ehaskTMs7y0))
# Stately

> [!WARNING]
> This software has not received external security review and may contain vulnerabilities and may not necessarily meet its stated security goals. Do not use it for sensitive use cases, and do not rely on its security until it has been reviewed. Work in progress.

A minimal, decentralized state broadcasting tool that works over Bluetooth mesh networks. Share your current status with nearby peers without internet, servers, or accounts - just pure encrypted state synchronization.

## License

This project is licensed under the Apache 2.0 license.

## Features

- **Decentralized State Broadcasting**: Automatic peer discovery and state sharing over Bluetooth LE mesh
- **15-Second State Updates**: Regular broadcast of your current status (sleeping, working, SOS, etc.)
- **Emergency SOS Mode**: One-tap emergency broadcasting with priority relay
- **End-to-End Encryption**: AES-256-GCM encryption for all state data
- **Battery Optimized**: Adaptive broadcast intervals based on battery level and power mode
- **Privacy First**: No accounts, no phone numbers, ephemeral state storage
- **Peer State Tracking**: Real-time view of nearby peer states with timestamps
- **Terminal-Style UI**: Clean, minimal interface with green monospace text
- **Universal App**: Native support for iOS and macOS
- **Mesh Relay**: TTL-based state propagation with 3-hop relay limit

## State Types

Stately supports the following peer states:

- 💤 **Sleeping** - Not available
- 🆘 **SOS** - Emergency - needs help
- 🔴 **Quiet** - Do not disturb  
- ✅ **Available** - Ready to connect
- 🔶 **Busy** - Currently occupied
- 🏃 **Away** - Temporarily away
- 👻 **Invisible** - Hidden from others
- 💼 **Working** - Focused on work
- 🍽️ **Eating** - Having a meal
- ✈️ **Traveling** - On the move

## Setup

### Option 1: Using XcodeGen (Recommended)

1. Install XcodeGen if you haven't already:
   ```bash
   brew install xcodegen
   ```

2. Generate the Xcode project:
   ```bash
   cd stately
   xcodegen generate
   ```

3. Open the generated project:
   ```bash
   open stately.xcodeproj
   ```

### Option 2: Using Swift Package Manager

1. Open the project in Xcode:
   ```bash
   cd stately
   open Package.swift
   ```

2. Select your target device and run

### Option 3: Manual Xcode Project

1. Open Xcode and create a new iOS/macOS App
2. Copy all Swift files from the `stately` directory into your project
3. Update Info.plist with Bluetooth permissions
4. Set deployment target to iOS 16.0 / macOS 13.0

## Usage

### Basic Operation

1. Launch Stately on your device
2. Set your display name (tap your name in the header)
3. Select your current state by tapping the state button
4. Your state broadcasts to nearby peers every 15 seconds
5. View nearby peer states in the main list
6. Tap the SOS button for emergencies

### State Broadcasting

- **Automatic**: States broadcast every 15 seconds by default
- **Battery Adaptive**: Intervals adjust based on battery level:
  - Performance mode: 10 seconds (charging/high battery)
  - Balanced mode: 15 seconds (default)
  - Power saver: 30 seconds (low battery)
  - Ultra-low power: 60 seconds (critical battery)
- **TTL Relay**: States propagate up to 3 hops through the mesh
- **Ephemeral**: No persistent storage - states exist only in memory

### Emergency Features

- **SOS Broadcasting**: Emergency state gets priority relay
- **Local Notifications**: Alerts when nearby peers trigger SOS
- **One-Tap Access**: Red emergency button always visible
- **Clear SOS**: Green button to clear emergency state

## Security & Privacy

### Encryption
- **State Messages**: AES-256-GCM encryption for all state broadcasts
- **Broadcast Key**: Shared symmetric key for state mesh encryption
- **Privacy Padding**: Message padding to obscure state content length
- **Digital Signatures**: Optional Ed25519 signatures for state authenticity

### Privacy Features
- **No Registration**: No accounts, emails, or phone numbers required
- **Ephemeral States**: States exist only in device memory (5-minute expiry)
- **Local-First**: Works completely offline, no servers involved
- **Minimal Data**: Only broadcasts name + state + timestamp

## Performance & Efficiency

### Battery Optimization
- **Adaptive Broadcasting**: Automatic adjustment based on battery level
  - Performance mode: Full broadcasting when charging or >60% battery
  - Balanced mode: Default operation (30-60% battery)  
  - Power saver: Extended intervals when <30% battery
  - Ultra-low power: Minimal broadcasting when <10% battery
- **Background Efficiency**: Reduced broadcasting when app backgrounded
- **Power Mode Detection**: Automatic switching based on device state

### Network Efficiency
- **Compact Protocol**: Efficient binary STATE_UPDATE packets (0x0A)
- **TTL Limiting**: Maximum 3-hop relay to prevent broadcast storms
- **State Expiry**: 5-minute automatic cleanup of stale peer states
- **Connection Limits**: Adaptive peer connections based on power mode

## Technical Architecture

### State Broadcasting Protocol
Stately uses a specialized binary protocol optimized for state broadcasting:
- **STATE_UPDATE (0x0A)**: New message type for peer state broadcasting
- **Compact Format**: Binary encoding with 12-byte header + JSON payload
- **TTL-based Relay**: Maximum 3 hops through mesh network
- **Timestamp Validation**: Automatic expiry of outdated states

### State Packet Format
```
Header (12 bytes):
- Version: 1 byte
- Type: 1 byte (0x0A for STATE_UPDATE)  
- TTL: 1 byte (default 3)
- Timestamp: 8 bytes (UInt64)
- PayloadLength: 2 bytes (UInt16)

Variable sections:
- SenderID: 8 bytes (fixed)
- Payload: JSON state data (encrypted)
```

### Mesh Networking
- Each device acts as both broadcaster and relay
- Automatic peer discovery and state synchronization
- Adaptive duty cycling for battery optimization
- No store-and-forward (ephemeral state only)

## Building for Production

1. Set your development team in project settings
2. Configure code signing
3. Archive and distribute through App Store or TestFlight

## Android Compatibility

The protocol is designed to be platform-agnostic. An Android client can be built using:
- Bluetooth LE APIs
- Same STATE_UPDATE packet structure and encryption
- Compatible service/characteristic UUIDs

## Migration from bitchat

Stately is a focused reimplementation of the bitchat mesh networking stack, optimized specifically for state broadcasting rather than messaging. The core Bluetooth mesh capabilities remain, but the application layer has been completely redesigned for status sharing instead of chat.
