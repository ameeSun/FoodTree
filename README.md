# FoodTree

**A playful, elegant iOS app for discovering leftover food on Stanford's campus**

FoodTree helps event organizers share surplus food with students, reducing waste and building community. The app combines the crisp utility of Apple Maps with the friendly animations you'd expect from Apple Wallet fast, delightful, and trustworthy.

---

## Design Philosophy

**Brand Personality:** "Playful orchard + crisp campus utility"

The app feels like Apple Wallet and Apple Maps had a friendly, animated baby. Every interaction is intentional:
- **180-240ms animations** with physics-based springs
- **Haptic feedback** that reinforces actions (light taps on filters, medium on claims, warning on destructive actions)
- **Micro-delights** like confetti leaf bursts on key success moments
- **Reduce Motion** respected throughout

---

## Features

### For Students (Discovery)
- **Live Map** with animated food pins sized by quantity and colored by urgency
- **Feed** with reverse-chronological cards, swipe actions (save/hide)
- **Smart Filters** by dietary preference, distance, time left, perishability
- **Detail Views** with hero image galleries, live availability bars, and "On My Way" actions
- **Push Notifications** for nearby posts, running-low alerts, and smart nudges

### For Organizers (Posting)
- **5-Step Post Composer:**
 1. Photos (camera/library with smart crop)
 2. Details (title, description, dietary tags)
 3. Quantity & perishability (slider + time window)
 4. Location (Stanford building search + access notes)
 5. Review & responsible sharing checklist
- **Organizer Dashboard** with live stats, post management (mark low/gone, extend time, adjust quantity)
- **Verified Organizer** badge system

### Global Features
- **Onboarding** with friendly explainer cards and permission flows
- **Inbox** with notification filters (All, Unread, Posts, Updates)
- **Profile & Settings** with dietary preferences, search radius, quiet hours
- **Accessibility** with VoiceOver labels, dynamic type support, and WCAG AA contrast

---

## Architecture

### Tech Stack
- **SwiftUI** for declarative UI
- **MapKit** for campus map and location services
- **Combine** for reactive data flow (via `@Published` and `ObservableObject`)
- **UserDefaults** for onboarding state persistence

### Project Structure
```
FoodTree/
 FoodTreeApp.swift # App entry point & AppState
 Models/
 FoodPost.swift # Core data models
 Design/
 DesignSystem.swift # Color tokens, typography, layout, haptics
 Components/
 DietaryChip.swift # Dietary tag chips
 StatusPill.swift # Availability status pills
 FoodCard.swift # Reusable food cards (S/M/L)
 QuantityDial.swift # Circular quantity indicator
 BottomSheet.swift # Physics-based bottom sheet
 MapPin.swift # Custom map annotation view
 ConfettiView.swift # Success celebration animation
 LoadingView.swift # Loading states
 ToastView.swift # Non-blocking notifications
 Views/
 RootTabView.swift # Tab navigation (Map, Feed, Post, Inbox, Profile)
 MapView.swift # Live map with pins + bottom sheet
 FeedView.swift # Scrollable card list + swipe actions
 FoodDetailView.swift # Full-screen detail with actions
 PostComposerView.swift # 5-step post creation flow
 InboxView.swift # Notifications list
 ProfileView.swift # User profile & settings
 OnboardingView.swift # First-run onboarding
 OrganizerDashboardView.swift # Post management for organizers
 Mock/
 MockData.swift # Stanford-realistic demo data
 Info.plist # App metadata & permissions
```

---

## Design Tokens

### Colors (Semantic)
```swift
// Background
.bgElev1 // #FAFAFC (off-white)
.bgElev2Card // #FFFFFF (white)

// Brand
.brandPrimary // #2FB16A (Stanford-leaf green)
.brandPrimaryInk // #0E5A36
.brandSecondary // #FF6A5C (Persimmon for accents)

// Ink
.inkPrimary // #0A0A0F
.inkSecondary // #5E5E6A
.inkMuted // #9191A1

// State
.stateSuccess // #22C55E
.stateWarn // #F59E0B
.stateError // #EF4444

// Map POI
.mapPoiAvailable // #2FB16A
.mapPoiLow // #F59E0B
.mapPoiOut // #9CA3AF
```

### Typography (SF Pro)
- **Display:** 28/34, semibold
- **Title:** 20/26, semibold
- **Body:** 16/22, regular
- **Caption:** 13/18, regular

### Layout Constants
- **Card corners:** 24pt radius
- **Pill corners:** 12pt radius
- **Button corners:** 16pt radius
- **Hit areas:** 44pt minimum
- **Shadows:** y-blur 12, opacity 10-12%

---

## Demo Data (Stanford Campus)

The app includes realistic mock data for 8 Stanford buildings:
- Huang Engineering Center
- Gates Computer Science
- Old Union
- Tresidder Union
- EVGR C Courtyard
- Memorial Court
- Y2E2
- Fraternity Row

Sample posts include:
- Burrito bowls (6 min ago, 35 portions, Huang)
- Veggie sushi (15 min ago, 25 portions, Gates)
- Pizza slices (30 min ago, 12 portions LOW, Old Union)
- Mediterranean plates (10 min ago, 40 portions, EVGR)
- Cookies & milk (5 min ago, 60 portions, Tresidder)
- Paneer tikka (20 min ago, 18 portions LOW, Y2E2)

---

## Key Interactions

### Map Interactions
- **Pin tap** expands to Food Card preview; swipe up full detail
- **Map drag** highlights corresponding card in bottom sheet
- **Bottom sheet** has 3 detents: peek (96pt), mid (400pt), full (screen - 100pt)
- **Pin animation** staggered drop-in (60ms each) with idle pulse for available posts

### Feed Interactions
- **Pull-to-refresh** spinning fruit glyph checkmark
- **Swipe right** Save (bookmark badge)
- **Swipe left** Hide (removes from feed)
- **Skeleton loaders** shimmer effect during loading

### Post Composer Interactions
- **Step progress** animated progress bar (1-5)
- **Photo picker** take/upload with auto-crop suggestion
- **Quantity slider** light haptic on change
- **Perishability selector** droplet icon pulses for high-risk
- **Building search** Stanford buildings with checkmark on select
- **Success view** confetti leaf burst + "Post published!"

### Detail View Interactions
- **Hero gallery** swipe through images (TabView with page indicators)
- **On My Way** leaf-checkmark morph + confetti + success haptic
- **Navigate** confirmation dialog (Apple Maps / Google Maps / Copy)
- **Live status bar** drains subtly every 30s; pulses if perishable
- **Share/Report** menu with options

---

## Accessibility

- **VoiceOver:** Every tappable element has descriptive labels
- **Dynamic Type:** All text respects system font scaling
- **Focus Order:** Logical tab order for keyboard/switch control
- **Hit Areas:** Minimum 44pt for all interactive elements
- **Contrast:** WCAG AA (4.5:1 minimum)
- **Reduce Motion:** Disables parallax, confetti, and pulse animations

---

## Privacy Stance

**UI Copy Example:**
> "We never store full PII or sensitive location history beyond what's needed to show nearby posts. Organizers certify food safety basics in the post flow."

**Responsible Sharing Checklist (before publish):**
- Accurate description and allergen information
- Food was held at safe serving temperature
- No home-cooked items / clearly labeled if required
- I've read the Community Guidelines

---

## Out of Scope (Front-End Only)

This is a **complete clickable prototype** with realistic dummy data and states. The following are intentionally NOT implemented:

- Authentication & user management
- Real API networking (all data is mocked)
- Moderation backend
- Organizer verification flow
- Real map tiles (uses system MapKit)
- Analytics persistence
- Rate limiting & abuse prevention
- Payment systems (not applicable)

**Integration Points (stubs included):**
```swift
// API endpoints (not implemented)
GET /posts?lat=&lng=&radius=&filters=
GET /posts/{id}
POST /posts
PATCH /posts/{id}
POST /posts/{id}/interest
POST /reports
GET /notifications
WebSocket ws://.../posts (for live updates)
```

---

## Motion & Animation Specs

### Animation Timings
- **Quick:** 180ms (filter changes, light taps)
- **Normal:** 240ms (card transitions, sheet movements)
- **Slow:** 360ms (onboarding page transitions)
- **Spring:** response 0.35, damping 0.75

### Physics-Based Animations
- **Map pins:** Idle pulse (1.5s ease-out repeat)
- **Bottom sheet:** Spring-based drag with velocity-aware snap
- **Card hover:** 0.97 scale on press (150ms ease-in-out)
- **Confetti:** 30 leaves, 1.5-2.5s fall with random rotation

### Haptic Feedback
- **Light:** Filter changes, tap actions, selections
- **Medium:** "Post published," "Claimed," "Mark Low/Gone"
- **Success:** "On My Way" confirmed
- **Warning:** Destructive actions (report, delete)

---

## Getting Started

### Requirements
- Xcode 15.0+
- iOS 17.0+
- Swift 5.9+

### Installation
1. Clone the repo
2. Open `FoodTree.xcodeproj` in Xcode
3. Select target device (iPhone 15 Pro recommended)
4. Build and run (Command-R)

### First Run
1. Onboarding flow appears automatically
2. Grant location permission (simulated)
3. Grant notification permission (optional)
4. Explore the map with 8 mock posts near Stanford campus
5. Tap **+** to try the post composer flow
6. Switch to **Profile** toggle "Organizer" to see dashboard

---

## Supported Platforms

- **iPhone:** iOS 17.0+, portrait only
- **iPad:** iOS 17.0+, all orientations (optimized for portrait)

---

## Success Criteria

**The app feels fast, fun, and obvious within 10 seconds**
**Students can find + navigate to food in <3 taps from open**
**Organizers can create a complete post in 45 seconds with great defaults**
**Motion and haptics feel intentional, not gimmicky**

---

## Inspiration & Credits

- **Freebites:** Real-time free food alerts (App Store)
- **Stanford Resources:** Food security initiatives, community guidelines
- **Design System:** Apple HIG, SF Symbols, Dynamic Type

---

## License

This is a demo/prototype project created for educational purposes.

---

## Made with love at Stanford

**FoodTree v1.0.0**

