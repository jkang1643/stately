# Bitchat Web Development Interface

This directory contains web-based development interfaces for testing and iterating on the Bitchat app without needing a Mac.

## Files

### `index.html` - Basic Development Interface
A simple web interface that replicates the core Bitchat UI and functionality:

**Features:**
- Complete UI replica of the Swift app
- Mock data for testing different scenarios
- Interactive controls for simulating app states
- Real-time message simulation
- Channel and private chat testing
- Autocomplete and command testing

**Usage:**
Open `index.html` in any modern web browser to start testing.

### `advanced.html` - Advanced Development Interface
A comprehensive development tool with debugging capabilities:

**Features:**
- Split-pane interface with simulator and debug panel
- Real-time logging system
- Performance metrics monitoring
- Multiple test scenarios
- State inspection tools
- Message delivery simulation
- Network condition simulation

**Test Scenarios:**
- **Normal Operation**: Standard conditions with 4 peers, 3 channels
- **High Load**: Stress testing with 15 peers, 8 channels, high message volume
- **Poor Network**: Limited connectivity simulation
- **Offline Mode**: Complete offline testing

**Debug Tools:**
- **Logs Tab**: Real-time application logs with different severity levels
- **State Tab**: Live application state inspection
- **Performance Tab**: Metrics visualization (latency, memory, processing time)
- **Scenarios Tab**: Quick switching between test conditions

## Key Features Replicated

### UI Components
- ✅ Terminal-style green text interface
- ✅ Header with nickname input and peer count
- ✅ Message list with timestamps and formatting
- ✅ Sidebar with channels and peers
- ✅ Input field with autocomplete
- ✅ Private chat mode
- ✅ Channel switching
- ✅ Delivery status indicators

### Functionality
- ✅ Message sending and receiving
- ✅ @mention highlighting and autocomplete
- ✅ #hashtag highlighting
- ✅ Channel management
- ✅ Private messaging
- ✅ Peer discovery simulation
- ✅ RSSI-based signal strength indicators
- ✅ Unread message counts
- ✅ System messages

### Development Tools
- ✅ Mock data generators
- ✅ Scenario switching
- ✅ Real-time logging
- ✅ Performance monitoring
- ✅ State inspection
- ✅ Interactive testing controls

## Usage Instructions

1. **Basic Testing**: Open `index.html` for simple UI and functionality testing
2. **Advanced Development**: Open `advanced.html` for comprehensive debugging
3. **Scenario Testing**: Use the debug panel to switch between different test scenarios
4. **Performance Monitoring**: Monitor metrics in real-time while testing
5. **State Debugging**: Inspect application state and logs for troubleshooting

## Browser Compatibility

- ✅ Chrome/Chromium 90+
- ✅ Firefox 88+
- ✅ Safari 14+
- ✅ Edge 90+

## Development Benefits

1. **Cross-Platform Testing**: Test on any computer without macOS
2. **Rapid Iteration**: Instant updates without compilation
3. **Debug Capabilities**: Comprehensive logging and monitoring
4. **Scenario Testing**: Test edge cases and different conditions
5. **UI Validation**: Verify design and user experience
6. **Feature Development**: Prototype new features quickly

## Future Enhancements

- WebRTC integration for real P2P testing
- Bluetooth Web API integration (where supported)
- Multi-device simulation
- Network topology visualization
- Message encryption/decryption testing
- Protocol compatibility testing with Swift version

This development interface provides a complete testing environment for the Bitchat application, enabling rapid development and testing without platform constraints.