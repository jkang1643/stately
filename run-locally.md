# Running Stately Locally (No Global Tools Required)

## Prerequisites
- macOS with Xcode installed (iOS apps require macOS)
- Physical iOS device or iOS Simulator (Bluetooth features work better on real devices)

## Option 1: Use Existing Xcode Project (Easiest)

The project already has a generated Xcode project file. Simply:

1. **On macOS**: Double-click `stately.xcodeproj` in Finder
2. **Or open from Xcode**: File → Open → Navigate to `stately.xcodeproj`

## Option 2: Use Swift Package Manager

1. Open Xcode
2. File → Open Package
3. Navigate to the project folder and select `Package.swift`

## Option 3: If You Need to Regenerate the Project

If the existing project is outdated, you can regenerate it without global installations:

### Using Homebrew (temporary, can be uninstalled after)
```bash
# Install XcodeGen temporarily
brew install xcodegen

# Generate the project
xcodegen generate

# Uninstall if desired
brew uninstall xcodegen
```

### Using Swift Package Manager (no additional tools)
```bash
# Open Package.swift in Xcode
open Package.swift
```

## Running the App

1. **Select your target**:
   - iOS: Choose an iOS device or simulator
   - macOS: Choose macOS target

2. **Set up signing**:
   - In Xcode, go to project settings
   - Select your development team
   - Or use "Sign to Run Locally" for testing

3. **Build and run**:
   - Press ⌘+R or click the Play button

## Important Notes

- **Bluetooth features require physical devices** - iOS Simulator has limited Bluetooth support
- **Multiple devices needed** - To test the state broadcasting, you'll need at least 2 devices
- **Permissions** - The app will request Bluetooth permissions on first run
- **State Broadcasting** - Each device will broadcast its status every 15 seconds to nearby peers

## Testing State Broadcasting

To test the state broadcasting functionality:
1. Install Stately on at least 2 devices
2. Enable Bluetooth on both devices
3. Launch the app on both devices
4. Set different states on each device (sleeping, working, SOS, etc.)
5. Verify that peer states appear in the nearby peers list
6. Test emergency SOS functionality

## Troubleshooting

If you get build errors:
1. Make sure Xcode is up to date
2. Check that your deployment target matches (iOS 16.0+, macOS 13.0+)
3. Verify your development team is set up in Xcode preferences
4. Ensure Bluetooth permissions are granted

## Clean Setup (No Global Dependencies)

This project is designed to work without any global tools:
- ✅ Uses standard Xcode project structure
- ✅ Includes all necessary configuration files
- ✅ Works with Swift Package Manager
- ✅ No external dependencies or global tools required