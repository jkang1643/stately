# Stately Privacy Policy

*Last updated: January 2025*

## Our Commitment

Stately is designed with privacy as its foundation. We believe private status sharing is a fundamental right. This policy explains how Stately protects your privacy while enabling proximity-based status awareness.

## Summary

- **No personal data collection** - We don't collect names, emails, or phone numbers
- **No servers** - Everything happens on your device and through peer-to-peer connections
- **No tracking** - We have no analytics, telemetry, or user tracking
- **Open source** - You can verify these claims by reading our code

## What Information Stately Stores

### On Your Device Only

1. **Identity Key** 
   - A cryptographic key generated on first launch
   - Stored locally in your device's secure storage
   - Allows consistent peer identification across app restarts
   - Never leaves your device

2. **Display Name**
   - The name you choose to share with nearby peers
   - Stored only on your device
   - Broadcast with your state to nearby users

3. **Current State**
   - Your selected status (sleeping, working, SOS, etc.)
   - Stored only in device memory (never persisted)
   - Reset to default when app is closed

### Temporary Session Data

During each session, Stately temporarily maintains:
- Active peer connections (forgotten when app closes)
- Nearby peer states (expire after 5 minutes)
- Routing information for state relay
- Bluetooth mesh connection state

## What Information is Shared

### With Nearby Stately Users

When you use Stately, nearby peers can see:
- Your chosen display name
- Your current state (sleeping, working, SOS, etc.)
- Timestamp of your last state update
- Your approximate Bluetooth signal strength (for connection quality)

### Through Mesh Network

When states propagate through the mesh:
- Your state broadcasts up to 3 hops from your device
- Your peer ID (temporary, changes each session)
- Your encrypted state payload
- TTL (time-to-live) for relay limiting

## What We DON'T Do

Stately **never**:
- Collects personal information
- Tracks your location
- Stores data on servers
- Shares data with third parties
- Uses analytics or telemetry
- Creates user profiles
- Requires registration
- Persists state history

## Encryption

All state broadcasts use encryption:
- **AES-256-GCM** for state payload encryption
- **Shared broadcast key** for mesh state encryption
- **Privacy padding** to obscure state content length
- **Ed25519** for optional digital signatures

## Your Rights

You have complete control:
- **Ephemeral States**: Your state exists only while app is running
- **Leave Anytime**: Close the app and your state disappears
- **No Account**: Nothing to delete from servers because there are none
- **Local-Only**: Your data never leaves your device ecosystem

## Bluetooth & Permissions

Stately requires Bluetooth permission to function:
- Used only for peer-to-peer state broadcasting
- No location data is accessed or stored
- Bluetooth is not used for tracking
- You can revoke this permission at any time in system settings

## Children's Privacy

Stately does not knowingly collect information from children. The app has no age verification because it collects no personal information from anyone.

## Data Retention

- **Current State**: Exists only in memory while app is running
- **Peer States**: Expire automatically after 5 minutes
- **Identity Key**: Persists until you delete the app
- **Display Name**: Persists until you change it or delete the app
- **Everything Else**: Exists only during active sessions

## Emergency Features

For SOS functionality:
- SOS state broadcasts get priority in mesh relay
- Local notifications alert nearby peers to emergencies
- No emergency data is stored or transmitted outside the mesh
- SOS state cleared manually or when app closes

## Security Measures

- All state communication is encrypted
- No data transmitted to servers (there are none)
- Open source code for public audit
- Regular security updates
- Ephemeral state storage prevents data accumulation

## Battery & Performance

Stately optimizes for battery life:
- Adaptive broadcast intervals based on battery level
- Reduced activity when app is backgrounded
- No background data collection or transmission
- Privacy-preserving power mode adjustments

## Changes to This Policy

If we update this policy:
- The "Last updated" date will change
- The updated policy will be included in the app
- No retroactive changes can affect data (since we don't collect any)

## Contact

Stately is an open source project. For privacy questions:
- Review our code: https://github.com/yourusername/stately
- Open an issue on GitHub
- Join the discussion in the community

## Philosophy

Privacy isn't just a feature—it's the entire point. Stately proves that proximity-based status awareness doesn't require surrendering your privacy. No accounts, no servers, no surveillance. Just ephemeral status sharing among nearby peers.

---

*This policy is released into the public domain under The Unlicense, just like Stately itself.*