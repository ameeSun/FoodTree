# FoodTree Implementation Guide

This document provides a complete guide to building and running the FoodTree iOS app in Xcode.

---

## Prerequisites

- **macOS** 13.0 (Ventura) or later
- **Xcode** 15.0 or later
- **iOS Simulator** or physical device running iOS 17.0+
- **Swift** 5.9+ (included with Xcode)

---

## Setting Up the Xcode Project

Since this is provided as source files, you'll need to create an Xcode project:

### Option 1: Create New Xcode Project

1. **Open Xcode** -> Select "Create New Project"
2. Choose **iOS** -> **App** -> Next
3. Configure project:
 - **Product Name:** FoodTree
 - **Team:** Your Apple Developer account (or leave blank for local development)
 - **Organization Identifier:** edu.stanford or your own
 - **Interface:** SwiftUI
 - **Language:** Swift
 - **Storage:** None (we're using simple UserDefaults)
4. Click **Next** and choose the directory containing these files
5. Xcode will create `FoodTree.xcodeproj`

### Option 2: Use Terminal to Create Project Structure

```bash
# Navigate to the project directory
cd /Users/sanmaysarada/ASES-FoodTree

# Create Xcode project structure (if needed)
# The files are already organized correctly
```

---

## File Organization in Xcode

Once you have the project open, organize files into groups:

```
FoodTree.xcodeproj/
 FoodTree/
 App/
 FoodTreeApp.swift
 Models/
 FoodPost.swift
 Design/
 DesignSystem.swift
 Components/
 DietaryChip.swift
 StatusPill.swift
 FoodCard.swift
 QuantityDial.swift
 BottomSheet.swift
 MapPin.swift
 ConfettiView.swift
 LoadingView.swift
 ToastView.swift
 Views/
 RootTabView.swift
 MapView.swift
 FeedView.swift
 FoodDetailView.swift
 PostComposerView.swift
 InboxView.swift
 ProfileView.swift
 OnboardingView.swift
 OrganizerDashboardView.swift
 Helpers/
 Extensions.swift
 LocationManager.swift
 NotificationManager.swift
 Mock/
 MockData.swift
 Assets.xcassets/
 (image assets - see below)
 Info.plist
 README.md
 IMPLEMENTATION_GUIDE.md
 .gitignore
```

---

## Adding Assets

### Creating the Asset Catalog

1. In Xcode, right-click the `FoodTree` group
2. Select **New File** -> **Resource** -> **Asset Catalog**
3. Name it `Assets.xcassets`

### Required Image Assets

Create placeholder images for the mock food posts:

**Food Images (for MockData):**
- `burrito_bowls` - colorful burrito bowl photo
- `sushi` - veggie sushi platter
- `pizza` - pizza slices
- `mediterranean` - falafel and hummus
- `cookies` - cookies and milk
- `indian` - paneer tikka with rice
- `bagels` - assorted bagels
- `fruit_cheese` - fruit and cheese platter

**App Icon:**
1. In `Assets.xcassets`, create **AppIcon**
2. Use a leaf/tree icon with Stanford green (#2FB16A)
3. Generate all required sizes (1024x1024 for App Store, plus device sizes)

**Launch Screen:**
- Xcode will auto-generate from Info.plist settings (leaf icon on green background)

### Color Assets (Optional)

You can add color assets to `Assets.xcassets` for easier dark mode support:

1. Right-click -> **New Color Set**
2. Name them: `BrandPrimary`, `BrandSecondary`, etc.
3. Set values to match `DesignSystem.swift`

---

## Project Configuration

### Build Settings

1. Select project in Navigator -> **FoodTree** target
2. **General** tab:
 - **Deployment Target:** iOS 17.0
 - **iPhone Orientation:** Portrait only
 - **iPad Orientation:** All
3. **Signing & Capabilities** tab:
 - Select your Team (or use "Sign to Run Locally" for simulator)
 - **Bundle Identifier:** `edu.stanford.foodtree` or your own

### Capabilities to Add

1. Click **+ Capability** button:
 - **Maps** (for MapKit)
 - **Push Notifications** (for future implementation)
 - **Background Modes** -> Location updates (optional)

### Info.plist Permissions

Already configured in `Info.plist`:
- `NSLocationWhenInUseUsageDescription`
- `NSCameraUsageDescription`
- `NSPhotoLibraryUsageDescription`

---

## Building and Running

### Using iOS Simulator

1. Select a simulator from the scheme selector (recommend **iPhone 15 Pro**)
2. Press **Command-R** or click the Play button
3. First launch will show onboarding flow
4. Grant permissions when prompted (simulated)
5. Explore the map with 8 mock posts

### Using Physical Device

1. Connect your iPhone via USB
2. Select your device from the scheme selector
3. Ensure your device is running iOS 17.0+
4. Build and run (Command-R)
5. You may need to trust the developer certificate on the device

### Troubleshooting Build Issues

**"SwiftUI not found"**
- Ensure Xcode 15.0+ is installed
- Check Deployment Target is iOS 17.0+

**"Missing import CoreLocation"**
- MapKit framework should auto-link
- If not: Target -> General -> Frameworks -> + -> MapKit.framework

**"File not found"**
- Ensure all files are added to the target
- Check File Inspector ( Command-1) -> Target Membership checkbox

---

## Testing the App

### Manual Test Flow

**First Run (Onboarding):**
1. See welcome screens with animations
2. Grant location permission
3. Grant notification permission (optional)
4. Land on Map view

**Student Discovery Flow:**
1. See 8 pins on Stanford campus
2. Tap a pin -> card preview appears
3. Pull up bottom sheet -> see full list
4. Tap "On My Way" -> success haptic + confetti
5. Tap "Navigate" -> dialog with map options

**Feed View:**
1. Switch to Feed tab
2. Pull to refresh -> skeleton loaders -> posts appear
3. Swipe right on card -> Save action
4. Swipe left on card -> Hide action (removes from feed)
5. Tap card -> full detail view

**Post Composer:**
1. Tap + button in tab bar
2. Step 1: Add photos (mock)
3. Step 2: Enter title + dietary tags
4. Step 3: Adjust quantity slider + perishability
5. Step 4: Select building from list
6. Step 5: Review + check guidelines
7. Tap Publish -> confetti success screen

**Organizer Dashboard:**
1. Switch to Profile tab
2. Toggle role to "Organizer"
3. Tap "Organizer Dashboard" button
4. See active posts with stats
5. Tap "Adjust Qty" -> interactive dial
6. Tap "Mark as Low" -> moves to Low tab
7. Tap "Extend +15m" -> success toast

**Inbox:**
1. Switch to Inbox tab
2. See mock notifications
3. Tap notification -> mark as read
4. Filter by Unread/Posts/Updates
5. Tap "Mark all read"

**Profile & Settings:**
1. View profile info
2. Toggle dietary preferences
3. Adjust search radius slider
4. Configure notification types

### Accessibility Testing

**VoiceOver:**
1. Enable VoiceOver: Settings -> Accessibility -> VoiceOver
2. Navigate through app with swipe gestures
3. Verify all buttons have descriptive labels

**Dynamic Type:**
1. Settings -> Accessibility -> Display & Text Size -> Larger Text
2. Increase text size to maximum
3. Verify all text scales properly

**Reduce Motion:**
1. Settings -> Accessibility -> Motion -> Reduce Motion -> On
2. Verify no parallax or confetti animations play

---

## Known Limitations (Demo Mode)

Since this is a **front-end prototype with mock data**, the following are expected:

### Not Implemented
- Real networking (all API calls are stubbed)
- Authentication (no login/signup)
- Real camera capture (shows placeholder picker)
- Actual map routing (opens system maps in real app)
- Real-time WebSocket updates
- Push notifications delivery
- Image upload to server
- Persistent data storage (except onboarding state)

### Simulated Features
- Location always returns Stanford campus center
- Notifications are pre-generated at launch
- Post publish doesn't actually save
- "On My Way" doesn't notify organizers
- Photo picker just adds mock image names

---

## Performance Optimization

### Current Performance Targets

- **Launch time:** < 1 second on iPhone 15 Pro
- **Map pin rendering:** < 200ms for 50 pins
- **Feed scroll:** 60 FPS with lazy loading
- **Animation frame rate:** 60 FPS (120 FPS on ProMotion devices)
- **Memory usage:** < 100 MB during normal use

### Profiling in Xcode

1. **Instruments:**
 - Product -> Profile (Command-I)
 - Choose "Time Profiler" to measure animation performance
 - Choose "Allocations" to check memory usage

2. **View Hierarchy Debugger:**
 - Debug -> View Debugging -> Capture View Hierarchy
 - Inspect layer composition for optimization opportunities

---

## Customization Guide

### Changing Brand Colors

Edit `DesignSystem.swift`:

```swift
// Change primary green to a different color
static let brandPrimary = Color(hex: "YOUR_HEX_HERE")
```

All components will automatically update.

### Adding New Buildings

Edit `MockData.swift`:

```swift
static let buildings = [
 // Add your building here
 StanfordBuilding(name: "Your Building", lat: 37.xxx, lng: -122.xxx),
 // ... existing buildings
]
```

### Customizing Animation Timings

Edit `DesignSystem.swift`:

```swift
struct FTAnimation {
 static let quick: Double = 0.18 // Your timing
 static let normal: Double = 0.24 // Your timing
 static let slow: Double = 0.36 // Your timing
}
```

### Adding New Dietary Tags

1. Edit `FoodPost.swift`:

```swift
enum DietaryTag: String, CaseIterable {
 // Add your new tag
 case newTag = "newtag"
 
 var displayName: String {
 case .newTag: return "New Tag"
 }
 
 var icon: String {
 case .newTag: return "star.fill"
 }
}
```

2. All dietary filters will automatically include the new tag.

---

## Deployment Checklist

Before submitting to the App Store (future):

### Required Changes
- [ ] Implement real authentication backend
- [ ] Connect to production API
- [ ] Add crash reporting (e.g., Firebase Crashlytics)
- [ ] Add analytics (respecting privacy)
- [ ] Implement real map API keys
- [ ] Add real image upload/storage
- [ ] Implement moderation system
- [ ] Add rate limiting
- [ ] Set up push notification certificates
- [ ] Write privacy policy
- [ ] Add terms of service
- [ ] Localization (if supporting multiple languages)

### App Store Assets
- [ ] Screenshots (6.7", 6.5", 5.5" sizes)
- [ ] App Preview video (optional but recommended)
- [ ] App Store icon (1024x1024)
- [ ] Marketing materials
- [ ] Privacy questionnaire responses

---

## Device Testing Matrix

Recommended devices to test on:

| Device | Screen Size | Notes |
|--------|-------------|-------|
| iPhone SE (3rd gen) | 4.7" | Smallest screen, single-hand reach |
| iPhone 15 | 6.1" | Standard size, most common |
| iPhone 15 Pro Max | 6.7" | Largest screen, ProMotion 120Hz |
| iPad Pro 11" | 11" | Verify layout on larger screens |

---

## Advanced Configuration

### Custom URL Scheme (Deep Linking)

Add to `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
 <dict>
 <key>CFBundleURLSchemes</key>
 <array>
 <string>foodtree</string>
 </array>
 </dict>
</array>
```

Then handle in `FoodTreeApp.swift`:

```swift
.onOpenURL { url in
 // Handle deep link: foodtree://post/{id}
}
```

### App Groups (for sharing data with widgets)

1. Add App Groups capability
2. Create group: `group.edu.stanford.foodtree`
3. Use shared UserDefaults:

```swift
let sharedDefaults = UserDefaults(suiteName: "group.edu.stanford.foodtree")
```

---

## Contributing

To contribute to FoodTree:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Follow Swift style guide (SwiftLint recommended)
4. Ensure all views are accessible (VoiceOver tested)
5. Test on multiple device sizes
6. Submit a pull request with screenshots

---

## Support

For questions or issues:

- **Technical issues:** Open a GitHub issue
- **Design questions:** Refer to `README.md` design system
- **Stanford-specific:** Contact ASES or Dean of Students office

---

## License

This project is created for educational purposes as part of Stanford ASES initiatives.

---

**Happy coding!**

