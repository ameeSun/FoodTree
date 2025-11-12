# FoodTree Quick Start Guide

Get up and running with FoodTree in 5 minutes!

---

## What is FoodTree?

FoodTree is a playful, iOS-native mobile app that helps Stanford students discover leftover food from campus events. Think **Apple Maps + Apple Wallet had a friendly, animated baby**.

---

## Quick Setup (TL;DR)

1. **Open Xcode 15.0+**
2. **Create New Project:** iOS App, SwiftUI, name it "FoodTree"
3. **Copy all `.swift` files** into the Xcode project
4. **Add `Info.plist`** to project
5. **Press Command-R** to build and run
6. **Done!**

---

## What You'll See

### First Launch: Onboarding
- Welcome screen with playful animations
- Permission requests (location, notifications)
- Skip or complete the flow

### Main Experience: 5 Tabs

**1. Map (Home)**
- Live map centered on Stanford campus
- 8 animated food pins (sized by quantity, colored by status)
- Pull up bottom sheet to see nearby food cards
- Tap filters to customize your search

**2. Feed**
- Scrollable list of food posts
- Swipe right to save, left to hide
- Pull to refresh with shimmer loaders
- Tap any card for full details

**3. Post (Center FAB)**
- 5-step post composer:
 1. Photos (camera/gallery)
 2. Details (title, description, dietary tags)
 3. Quantity & perishability
 4. Location (Stanford buildings)
 5. Review & publish
- Success screen with confetti

**4. Inbox**
- Notifications for nearby posts, running low alerts
- Filter by All/Unread/Posts/Updates
- Mark as read/unread

**5. Profile**
- Toggle Student/Organizer role
- Access Organizer Dashboard
- Settings: dietary preferences, search radius, quiet hours

---

## Try These Features

### Student Actions
- Tap a map pin -> see food card
- Tap "On My Way" -> confetti + success haptic
- Tap "Navigate" -> map options dialog
- Save or hide posts from feed

### Organizer Actions
- Create a new post (tap + button)
- Switch to Organizer role in Profile
- Open Dashboard -> manage your posts
- Adjust quantity with interactive dial
- Mark posts as Low or Gone
- Extend time by 15 minutes

---

## Demo Data

**8 Stanford Buildings:**
- Huang Engineering Center
- Gates Computer Science
- Old Union
- Tresidder Union
- EVGR C Courtyard
- Memorial Court
- Y2E2
- Fraternity Row

**Sample Posts:**
- Burrito bowls (6 min ago, 35 portions)
- Veggie sushi (15 min ago, 25 portions)
- Pizza slices (30 min ago, LOW)
- Mediterranean plates (10 min ago, 40 portions)
- Cookies & milk (5 min ago, 60 portions)

All data is **mock** and resets on app restart.

---

## Design Highlights

**Colors:**
- Stanford Green (`#2FB16A`) - primary brand color
- Persimmon (`#FF6A5C`) - accents and badges
- Semantic states: success, warning, error

**Animations:**
- Map pins pulse when available
- Cards scale on press (180-240ms)
- Confetti on success moments
- Physics-based bottom sheet

**Haptics:**
- Light tap on filters
- Medium on "Post published"
- Success on "On My Way"
- Warning on destructive actions

---

## Accessibility

**Built-in support for:**
- VoiceOver (all buttons labeled)
- Dynamic Type (text scales)
- Reduce Motion (disables confetti)
- High Contrast (WCAG AA)
- Large hit areas (44pt minimum)

**Test it:**
1. Settings -> Accessibility -> VoiceOver -> On
2. Swipe through the app
3. Double-tap to activate elements

---

## File Structure at a Glance

```
FoodTree/
 FoodTreeApp.swift - App entry point
 Models/FoodPost.swift - Data models
 Design/DesignSystem.swift - Colors, typography, haptics
 Components/ - Reusable UI (chips, cards, pins)
 Views/ - Screens (Map, Feed, Profile, etc.)
 Helpers/ - Extensions, managers
 Mock/MockData.swift - Stanford demo data
 Info.plist - Permissions
```

---

## Troubleshooting

**"Cannot find type 'FoodPost'"**
-> Ensure all files are added to the Xcode target

**"MapKit not found"**
-> Add MapKit framework: Target -> General -> Frameworks

**Blank screen on launch**
-> Check deployment target is iOS 17.0+

**No posts showing on map**
-> Location defaults to Stanford campus center (mock data)

---

## Next Steps

1. **Explore the app** - tap everything!
2. **Read `README.md`** - full design system documentation
3. **Check `IMPLEMENTATION_GUIDE.md`** - detailed setup instructions
4. **Review `ARCHITECTURE.md`** - technical deep dive

---

## Pro Tips

**For Designers:**
- All design tokens in `DesignSystem.swift`
- Animation timings: 180ms (quick), 240ms (normal), 360ms (slow)
- Corner radius: 24pt cards, 12pt pills, 16pt buttons

**For Developers:**
- Use `@StateObject` for view-owned objects
- Use `@EnvironmentObject` for app-wide state
- All haptics via `FTHaptics` utility
- All animations via `FTAnimation` constants

**For Product Managers:**
- Complete clickable prototype with realistic flows
- No backend required (all mock data)
- Ready for user testing and feedback

---

## Ship It!

This is a **fully functional front-end prototype** ready for:
- User research sessions
- Design reviews
- Stakeholder demos
- Developer handoff

**To make it production-ready:**
- Add backend API integration
- Implement authentication
- Connect real map routing
- Add analytics (privacy-respecting)

---

## Questions?

- **Technical:** See `IMPLEMENTATION_GUIDE.md`
- **Design:** See `README.md` design system section
- **Architecture:** See `ARCHITECTURE.md`

---

**Built with love at Stanford**

FoodTree v1.0.0 - Making campus food sharing delightful

