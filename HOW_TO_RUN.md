# How to Run FoodTree in Xcode

## Quick Start

Your FoodTree app is now fully set up and ready to run! Here's how to launch it:

### 1. Open the Project
The Xcode project is located at:
```
/Users/sanmaysarada/ASES-FoodTree/FoodTree/FoodTree.xcodeproj
```

You can open it by:
- Double-clicking `FoodTree.xcodeproj` in Finder
- Or running: `open FoodTree/FoodTree.xcodeproj` from the terminal

### 2. Select a Simulator
In Xcode's toolbar (top), click the device selector and choose an iPhone simulator:
- **iPhone 17** (recommended)
- iPhone 17 Pro
- iPhone Air
- Or any other iPhone simulator

### 3. Run the App
Click the **Play** button in the top left, or press **Command-R**

The simulator will launch and your FoodTree app will start!

## What You'll See

1. **Onboarding Flow** - First launch shows welcome screens
2. **Map View** - Main screen with Stanford campus and food pins
3. **5 Tabs**:
   - Map (home)
   - Feed
   - Post
   - Inbox
   - Profile

## Build Status
**BUILD SUCCEEDED** - The project compiles successfully!

## What Was Fixed

To get your app running, I:

1. Moved all Swift files into the Xcode project structure
2. Added missing imports (`Combine`, `CoreLocation`)
3. Fixed SwiftUI syntax issues:
   - StatusPill modifier type mismatch
   - MapView AnyView return type
   - FeedView swipeActions API
4. Removed conflicting Info.plist file
5. Built successfully for iOS Simulator

## Command Line Build

You can also build from the terminal:

```bash
cd /Users/sanmaysarada/ASES-FoodTree/FoodTree
xcodebuild -project FoodTree.xcodeproj \
  -scheme FoodTree \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build
```

## Running vs Building

- **Xcode is NOT the same as Expo Go**
- This is a **native iOS app** written in Swift/SwiftUI
- You must use **Xcode and iOS Simulator** to run it
- Expo Go only works with React Native/JavaScript apps

## Optional: Add Privacy Permissions

If you want to test camera/location features, add these in Xcode:

1. Select **FoodTree** target
2. Go to **Info** tab
3. Add under "Custom iOS Target Properties":

| Key | Value |
|-----|-------|
| `NSLocationWhenInUseUsageDescription` | We need your location to show you nearby food posts and provide walking directions. |
| `NSCameraUsageDescription` | Take photos of food you're posting to share with students. |
| `NSPhotoLibraryUsageDescription` | Choose photos from your library to include in your food post. |

## Need Help?

- **Build errors?** Clean build folder: **Product -> Clean Build Folder** (Shift-Command-K)
- **Simulator issues?** Restart simulator: **Device -> Erase All Content and Settings**
- **Xcode issues?** Quit and reopen Xcode

## Project Structure

```
FoodTree/FoodTree/
├── FoodTreeApp.swift       # App entry point
├── Components/             # Reusable UI components
├── Design/                 # Design system
├── Helpers/                # Utilities
├── Mock/                   # Demo data
├── Models/                 # Data models
└── Views/                  # Screen views
```

---


FoodTree v1.0.0 - Now running in Xcode!

