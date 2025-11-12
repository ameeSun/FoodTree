# FoodTree Architecture Documentation

This document provides a deep dive into the technical architecture of the FoodTree iOS app.

---

## Architecture Overview

FoodTree follows a **SwiftUI-first architecture** with clear separation of concerns:

```
 
 Presentation Layer 
 (SwiftUI Views, ViewModels, Navigation) 
 
 Business Logic Layer 
 (AppState, Managers, Data Transformation) 
 
 Data Layer 
 (Models, Mock Services, Local Storage) 
 
 System Layer 
 (CoreLocation, MapKit, UserNotifications) 
 
```

---

## Design Patterns

### 1. MVVM (Model-View-ViewModel)

**Models** (`FoodPost`, `AppNotification`, etc.)
- Pure data structures
- Conform to `Identifiable`, `Equatable` for SwiftUI
- No business logic

**Views** (SwiftUI Views)
- Declarative UI components
- Observe ViewModels via `@ObservedObject` or `@StateObject`
- Minimal logic (presentation only)

**ViewModels** (`MapViewModel`, `FeedViewModel`, etc.)
- Conform to `ObservableObject`
- Manage state with `@Published` properties
- Handle user actions and data transformation

**Example:**

```swift
// Model
struct FoodPost: Identifiable {
 let id: String
 let title: String
 // ... other properties
}

// ViewModel
class MapViewModel: ObservableObject {
 @Published var posts: [FoodPost] = []
 @Published var filters = MapFilters()
 
 func applyFilters() { /* ... */ }
}

// View
struct MapView: View {
 @StateObject private var viewModel = MapViewModel()
 
 var body: some View {
 Map(/* ... */)
 .onChange(of: viewModel.filters) { /* ... */ }
 }
}
```

### 2. Coordinator Pattern (Navigation)

Navigation is handled through:
- **RootTabView**: Main tab coordinator
- **Modal presentations**: `.sheet()`, `.fullScreenCover()`
- **NavigationView**: For hierarchical navigation

### 3. Dependency Injection

Dependencies are injected via:
- **`@EnvironmentObject`**: For app-wide state (AppState)
- **`@StateObject`**: For view-owned objects (ViewModels)
- **Initializer injection**: For reusable components

**Example:**

```swift
// App-level injection
@main
struct FoodTreeApp: App {
 @StateObject private var appState = AppState()
 
 var body: some Scene {
 WindowGroup {
 RootTabView()
 .environmentObject(appState) // <- Injected
 }
 }
}

// View consumption
struct ProfileView: View {
 @EnvironmentObject var appState: AppState // <- Consumed
}
```

### 4. Composition over Inheritance

All UI components are **composable**:
- Small, single-purpose views
- Combine using `VStack`, `HStack`, `ZStack`
- Reusable modifiers (`.ftShadow()`, `.toast()`)

---

## Data Flow

### State Management Hierarchy

```
AppState (Global)
 
RootTabView (Tab Selection)
 
MapView / FeedView / etc. (Screen State)
 
ViewModels (Local State)
 
Components (UI State)
```

### Data Flow Diagram

```
User Action -> View -> ViewModel -> Update @Published -> View Re-renders
 
 Haptic Feedback
 
 Animation Trigger
```

**Example Flow:**

1. User taps "On My Way" button
2. `FoodDetailView` calls `toggleOnMyWay()`
3. `isOnMyWay` state updates
4. `FTHaptics.success()` fires
5. `showSuccessConfetti = true`
6. SwiftUI re-renders with new state
7. Confetti animation plays

---

## Component Architecture

### Atomic Design Hierarchy

**Atoms** (Smallest components)
- `DietaryChip`
- `StatusPill`
- `PerishabilityBadge`
- Color tokens, Typography

**Molecules** (Simple combinations)
- `FoodCard`
- `MapPinView`
- `QuantityDial`
- `FilterPill`

**Organisms** (Complex components)
- `BottomSheet`
- `FoodDetailContent`
- `HeroGallery`
- `OrganizerPostCard`

**Templates** (Page layouts)
- `MapView`
- `FeedView`
- `PostComposerView`
- `OrganizerDashboardView`

**Pages** (Complete screens)
- `RootTabView` (combines all templates)

---

## Data Persistence

### Current Implementation (Demo)

**UserDefaults:**
- Onboarding completion state
- User preferences (dietary, radius)
- (Intentionally minimal for prototype)

**In-Memory:**
- All post data (via `MockData`)
- Notifications
- Filter states

### Production Recommendations

**Core Data:**
```swift
// Post entity
entity Post {
 attribute id: String
 attribute title: String
 attribute createdAt: Date
 // ... other attributes
 relationship organizer: Organizer
}
```

**CloudKit:**
- Sync posts across devices
- Public database for food posts
- Private database for saved posts

**Keychain:**
- Store authentication tokens
- User credentials

---

## Navigation Architecture

### Tab-Based Navigation

```
RootTabView
 Map (NavigationView)
 FilterView (sheet)
 Feed (NavigationView)
 FoodDetailView (sheet)
 Post (Modal)
 PostComposerView (fullScreenCover)
 PostSuccessView (fullScreenCover)
 Inbox (NavigationView)
 Profile (NavigationView)
 SettingsView (sheet)
 OrganizerDashboardView (sheet)
```

### Deep Linking (Future)

URL Scheme: `foodtree://`

**Supported routes:**
- `foodtree://post/{id}` -> Open specific post
- `foodtree://map?lat={lat}&lng={lng}` -> Open map at location
- `foodtree://profile` -> Open profile
- `foodtree://compose` -> Open post composer

---

## Animation System

### Animation Philosophy

1. **Purposeful**: Every animation serves a functional purpose
2. **Consistent**: Same timing for similar actions
3. **Respectful**: Honors Reduce Motion setting
4. **Delightful**: Adds personality without overwhelming

### Animation Layers

**Layer 1: Micro-interactions (50-180ms)**
- Button press scales (0.95-0.97)
- Toggle switches
- Checkbox animations

**Layer 2: Transitions (180-240ms)**
- Card appearances
- Sheet presentations
- Tab switches

**Layer 3: Page animations (240-500ms)**
- Onboarding page swipes
- Full-screen modal transitions
- Map pin drop-ins

**Layer 4: Celebrations (1-3s)**
- Confetti bursts
- Success animations
- Loading states

### Spring Animations

Custom spring parameters:

```swift
// Quick snap
Animation.spring(response: 0.25, dampingFraction: 0.8)

// Playful bounce
Animation.spring(response: 0.35, dampingFraction: 0.6)

// Smooth slide
Animation.spring(response: 0.45, dampingFraction: 0.85)
```

---

## Haptic Feedback Strategy

### Haptic Hierarchy

**Light (UIImpactFeedbackGenerator.light)**
- Filter selections
- Tab switches
- Non-critical interactions

**Medium (UIImpactFeedbackGenerator.medium)**
- "Claimed", "Saved", "Hidden"
- Post published
- Settings changed

**Success (UINotificationFeedbackGenerator.success)**
- "On My Way" confirmed
- Post successfully created
- Goal achieved

**Warning (UINotificationFeedbackGenerator.warning)**
- Mark as Gone
- Report submitted
- Destructive action confirmed

**Error (UINotificationFeedbackGenerator.error)**
- Failed action
- Validation error
- Network error

---

## Dependency Management

### Current: No External Dependencies

FoodTree is built with **zero third-party dependencies**, using only:
- SwiftUI (UI framework)
- MapKit (maps)
- CoreLocation (location services)
- UserNotifications (push notifications)
- Combine (reactive programming)

**Benefits:**
- Faster compile times
- No dependency conflicts
- Full control over codebase
- Easier maintenance

### Future: Recommended Libraries

**If scaling to production:**

**Networking:**
- `Alamofire` or native `URLSession` + async/await

**Image Loading:**
- `Kingfisher` or `SDWebImage`

**Analytics:**
- `Firebase Analytics` (with privacy respect)

**Crash Reporting:**
- `Firebase Crashlytics` or `Sentry`

**Testing:**
- `Quick/Nimble` for BDD-style tests

---

## Testing Architecture

### Unit Tests (Recommended)

```swift
// ViewModelTests.swift
class MapViewModelTests: XCTestCase {
 func testFilteringPosts() {
 let viewModel = MapViewModel()
 viewModel.filters.dietary = [.vegan]
 
 viewModel.applyFilters()
 
 XCTAssertTrue(viewModel.posts.allSatisfy { 
 $0.dietary.contains(.vegan) 
 })
 }
}
```

### UI Tests (Recommended)

```swift
// FoodTreeUITests.swift
class OnboardingTests: XCTestCase {
 func testOnboardingFlow() {
 let app = XCUIApplication()
 app.launch()
 
 XCTAssertTrue(app.staticTexts["Welcome to FoodTree"].exists)
 
 app.buttons["Next"].tap()
 app.buttons["Next"].tap()
 app.buttons["Get Started"].tap()
 
 XCTAssertTrue(app.staticTexts["Enable Location"].exists)
 }
}
```

### Accessibility Tests

```swift
func testVoiceOverLabels() {
 let app = XCUIApplication()
 app.launch()
 
 let postButton = app.buttons["Post food"]
 XCTAssertTrue(postButton.exists)
 XCTAssertNotNil(postButton.label)
}
```

---

## Performance Considerations

### View Rendering Optimization

**LazyVStack for long lists:**
```swift
ScrollView {
 LazyVStack {
 ForEach(posts) { post in
 FoodCard(post: post)
 }
 }
}
```

**Avoid expensive computations in `body`:**
```swift
// Bad - recomputes every render
var body: some View {
 Text(expensiveComputation())
}

// Good - computed once
var body: some View {
 Text(precomputedValue)
}
```

**Use `.id()` for stable identity:**
```swift
ForEach(posts) { post in
 FoodCard(post: post)
 .id(post.id) // <- Helps SwiftUI track changes
}
```

### Memory Management

**Weak references in closures:**
```swift
Button(action: { [weak self] in
 self?.handleTap()
})
```

**Image caching (future):**
```swift
// Use URLCache or custom image cache
```

---

## Security & Privacy

### Current Implementation

**No PII stored:**
- No email/phone in UserDefaults
- No location history persisted
- No analytics tracking

**Mock data only:**
- No real user data
- No real organizer verification
- No real food safety tracking

### Production Security Checklist

- [ ] Encrypt sensitive data (Keychain)
- [ ] HTTPS only for API calls
- [ ] Certificate pinning
- [ ] Input validation and sanitization
- [ ] Rate limiting on backend
- [ ] OAuth 2.0 for authentication
- [ ] JWT tokens with expiration
- [ ] Privacy-preserving analytics
- [ ] GDPR compliance (if applicable)
- [ ] Regular security audits

---

## Localization Architecture (Future)

### i18n Strategy

**String localization:**
```swift
// Use SwiftUI Text with LocalizedStringKey
Text("map.title") // <- Auto-localizes

// Localizable.strings (English)
"map.title" = "Map";

// Localizable.strings (Spanish)
"map.title" = "Mapa";
```

**Date/Number formatting:**
```swift
// Respects locale automatically
Text(post.createdAt, style: .relative)
Text(post.quantityApprox, format: .number)
```

---

## Scalability Roadmap

### Phase 1: Current (Prototype)
- Complete UI/UX
- Mock data
- No backend

### Phase 2: MVP (Backend Integration)
- [ ] Real API
- [ ] Authentication
- [ ] Firebase/CloudKit storage
- [ ] Push notifications

### Phase 3: Growth
- [ ] Real-time updates (WebSocket)
- [ ] Advanced filtering
- [ ] Post analytics
- [ ] In-app chat (optional)

### Phase 4: Scale
- [ ] Multi-campus support
- [ ] Admin dashboard (web)
- [ ] Moderation tools
- [ ] Partner integrations

---

## Development Workflow

### Recommended Git Flow

```
main (production-ready)
 
develop (integration branch)
 
feature/map-improvements
feature/post-composer-v2
bugfix/notification-crash
```

### Code Review Checklist

- [ ] SwiftUI best practices followed
- [ ] Accessibility labels present
- [ ] Haptic feedback appropriate
- [ ] Animation timings match design system
- [ ] No force unwraps (`!`) in production code
- [ ] Error handling present
- [ ] Comments for complex logic
- [ ] No hardcoded strings (use localization)

---

**End of Architecture Documentation**

For implementation details, see `IMPLEMENTATION_GUIDE.md`.
For design specifications, see `README.md`.

