# FoodTree Component Showcase

Visual reference guide for all reusable UI components in FoodTree.

---

## Design Foundations

### Color Palette

```
 
 Brand Colors 
 
 brandPrimary #2FB16A Stanford-leaf green 
 brandPrimaryInk #0E5A36 Dark green 
 brandSecondary #FF6A5C Persimmon for accents 
 
 Background Colors 
 
 bgElev1 #FAFAFC Off-white base 
 bgElev2Card #FFFFFF White cards 
 
 Text Colors (Ink) 
 
 inkPrimary #0A0A0F Near black 
 inkSecondary #5E5E6A Medium gray 
 inkMuted #9191A1 Light gray 
 
 State Colors 
 
 stateSuccess #22C55E Green for success 
 stateWarn #F59E0B Orange for warning 
 stateError #EF4444 Red for error 
 
 Map POI Colors 
 
 mapPoiAvailable #2FB16A Available food 
 mapPoiLow #F59E0B Running low 
 mapPoiOut #9CA3AF Gone/Expired 
 
```

### Typography Scale

```
 
 Display Text (28pt, semibold) 
 Welcome to FoodTree 
 
 Title Text (20pt, semibold) 
 Leftover Burrito Bowls 
 
 Body Text (16pt, regular) 
 Chicken and veggie burrito bowls from our CS Club meeting. 
 
 Caption Text (13pt, regular) 
 Posted 6 min ago EVGR C courtyard Vegan bowls 
 
```

### Spacing & Layout

```
 
 Spacing Scale 
 
 S: 8pt 
 M: 16pt 
 L: 24pt 
 XL: 32pt 
 
 Corner Radius 
 
 Card: 24pt 
 Pill: 12pt 
 Button: 16pt 
 
 Shadows 
 
 Radius: 12pt, Opacity: 10-12%, Y-offset: 4pt 
 
```

---

## Atom Components

### DietaryChip

**Purpose:** Display dietary information tags

```swift
DietaryChip(tag: .vegan, size: .medium)
DietaryChip(tag: .glutenFree, size: .small)
```

**Visual:**
```
 
 Vegan <- Medium size
 

 
 Vegan <- Small size
 

Color: Green background (#2FB16A @ 10% opacity)
 Green text (#0E5A36)
 
Exception: "Contains Nuts" -> Red (#EF4444)
```

**All Available Tags:**
- Vegan
- Vegetarian
- Halal
- Kosher
- Gluten-free
- Dairy-free
- Contains nuts (warning style)

---

### StatusPill

**Purpose:** Show post availability status

```swift
StatusPill(status: .available, animated: true)
StatusPill(status: .low, animated: false)
```

**Visual:**
```
 
 Available <- Pulsing dot (if animated)
 

 
 Low <- Static dot
 

 
 Gone <- Grayed out
 

 
 Expired <- Grayed out
 

Colors:
- Available: Green (#2FB16A)
- Low: Orange (#F59E0B)
- Gone/Expired: Gray (#9CA3AF)
```

---

### PerishabilityBadge

**Purpose:** Indicate food perishability level

```swift
PerishabilityBadge(perishability: .high, showAnimation: true)
```

**Visual:**
```
 
 Very perishable <- Droplet pulses if .high
 

 
 Perishable <- Orange
 

 
 Keeps well <- Green
 

Colors:
- High: Red (#EF4444)
- Medium: Orange (#F59E0B)
- Low: Green (#22C55E)
```

---

## Molecule Components

### FoodCard

**Purpose:** Primary component for displaying food posts

**Sizes:** Small (280pt wide), Medium (full width), Large (full width + more detail)

```swift
FoodCard(
 post: foodPost, 
 size: .medium, 
 userLocation: coordinate
)
```

**Visual Structure:**
```
 
 
 
 [Hero Image 180pt tall] 
 
 [ Available] <- Status pill 
 
 
 Leftover Burrito Bowls <- Title 
 
 Vegan Gluten-free Dairy-free <- Tags 
 
 ~35 40 min 0.2 mi <- Meta info 
 
 Stanford CS Club Huang Engineering <- Organizer 
 
 
```

**Interaction:**
- Tap -> Opens detail view
- Scale down to 0.97 on press
- Shadow depth increases on hover

---

### MapPinView

**Purpose:** Custom map annotation showing food availability

```swift
MapPinView(post: foodPost, isSelected: false)
```

**Visual:**
```
 Idle State Selected State
 (48pt) (56pt)

 
 
 
 35 35 <- Quantity or icon
 
 
 
 <- Pulse ring <- White selection ring

Pin Size by Quantity:
- 50+: 48pt (selected: 56pt)
- 20-49: 40pt (selected: 48pt)
- <20: 32pt (selected: 40pt)

Colors:
- Available: Green (#2FB16A)
- Low: Orange (#F59E0B)
- Gone: Gray (#9CA3AF)

Animation:
- Idle pulse: 1.5s ease-out repeat
- Drop-in: Staggered 60ms delay per pin
```

---

### QuantityDial

**Purpose:** Circular progress indicator for portions remaining

```swift
QuantityDial(quantity: 75, size: 120, interactive: false)
```

**Visual:**
```
 
 
 75% filled 
 
 
 75 <- Quantity number
 
 
 portions <- Label
 
 

Ring Colors:
- 50-100: Green (#2FB16A)
- 20-49: Orange (#F59E0B)
- 0-19: Gray (#9CA3AF)

Sizes: 80pt, 120pt, 160pt

Interactive mode: Drag to adjust quantity
```

---

## Organism Components

### BottomSheet

**Purpose:** Physics-based draggable sheet with multiple detents

```swift
BottomSheet(
 detent: $detent, 
 detents: [.peek, .mid, .full]
) {
 // Content
}
```

**Visual:**
```
Detent States:

Full (screen height - 100pt)
 
 <- Handle 
 
 [Full Content] 
 
 
 
 

Mid (400pt)
 
 <- Handle 
 
 [Mid Content] 
 
 
 Visible part

Peek (96pt)
 
 <- Handle 
 [Peek Content] 
 
 Visible part

Features:
- Drag handle (36pt 5pt capsule)
- Spring animation (response 0.35, damping 0.75)
- Velocity-aware snapping
- Shadow (radius 20pt, opacity 15%)
- Rounded top corners (24pt)
```

---

### FilterView

**Purpose:** Comprehensive filter sheet with all options

**Visual:**
```
 Filters 
 
 DIETARY PREFERENCES 
 
 [ Vegan] [ Vegetarian] [ Halal] 
 [ Kosher] [ Gluten-free] [ Dairy] 
 [ Contains nuts] 
 
 
 
 Distance [ ] 1.5 mi 
 
 Time remaining [ ] 60 min 
 
 
 
 Perishable items only 
 Verified organizers only 
 
 
 
 [Clear all filters] 
 
 [Cancel] [Apply] 
 

Interactions:
- Chips toggle on/off
- Sliders adjust values with haptic feedback
- Toggles for binary options
- Clear resets all to defaults
```

---

### HeroGallery

**Purpose:** Swipeable image carousel for post details

**Visual:**
```
 
 
 
 
 [Hero Image 320pt tall] 
 < Swipe to see more images > 
 
 
 <- Page indicators
 

Features:
- Swipe left/right to change image
- Page indicators show position
- Pinch to zoom (future enhancement)
- Parallax on scroll (if Reduce Motion off)
```

---

### ConfettiView

**Purpose:** Celebratory animation for success moments

```swift
ConfettiView()
 .onAppear { /* Triggers animation */ }
```

**Visual:**
```
 
 
 
 
 
 
 
 

30 leaf icons in 4 colors:
- Green (#2FB16A)
- Success (#22C55E)
- Persimmon (#FF6A5C)
- Orange (#F59E0B)

Animation:
- Random X offset: -200 to 200
- Fall from -100 to +800
- Rotate 0-720 degrees
- Fade out (opacity 1 -> 0)
- Duration: 1.5-2.5s per leaf
- Staggered start: 0-0.3s delay

Respects Reduce Motion setting
```

---

## Screen Templates

### MapView

**Layout:**
```
 
 [ ] [@] <- Top bar (60pt)
 Search buildings... 
 
 
 
 
 Stanford Campus Map 
 
 <- Pins
 
 
 
 
 
 <- Sheet handle
 
 < [Card] [Card] [Card] > <- Horizontal scroll 
 
 
 [Map] [Feed] [+] [Inbox] [Profile] <- Tab bar
 

Interactions:
- Pull sheet up/down (3 detents)
- Tap pin -> highlights card
- Tap card -> centers map on pin
- Tap filter -> opens FilterView
```

---

### FeedView

**Layout:**
```
 
 Feed [ ] <- Nav bar
 
 
 
 [Image] 
 
 Leftover Burrito Bowls 
 Vegan Gluten-free 
 ~35 40 min 0.2 mi 
 Stanford CS Club 
 
 
 
 
 [Image] 
 Veggie Sushi Platters 
 Vegetarian Dairy-free 
 
 
 
 [Image] 
 Pizza Slices Low 
 
 
 

Swipe Actions:
- Swipe right -> Save (green)
- Swipe left -> Hide (gray)

Pull-to-refresh at top
```

---

### PostComposerView

**5-Step Flow:**

```
Step 1: Photos
 
 [Cancel] Post Food 
 <- Progress (1/5)
 
 Add photos 
 Show what's available... 
 
 
 
 <- Take Photo 
 Take Photo 
 
 
 
 
 Choose from <- Library 
 Library 
 
 
 
 [Next ->] 
 

Step 2: Details
 
 <- Progress (2/5)
 
 What's available? 
 
 Title 
 
 e.g., Leftover pizza slices 
 
 
 Description (optional) 
 
 Add details... 
 
 
 Dietary information 
 [ Vegan] [ Vegetarian] [ Halal] 
 [ Kosher] [ Gluten-free] [ Dairy] 
 
 [<- Back] [Next ->] 
 

Step 3: Quantity
 
 <- Progress (3/5)
 
 How much is available? 
 
 Approximate portions [20] 
 
 1 100 
 
 Perishability 
 Keeps well 
 Perishable 
 Very perishable 
 
 Available for how long? 
 [30 min] [60 min] [90 min] 
 
 [<- Back] [Next ->] 
 

Step 4: Location
 
 <- Progress (4/5)
 
 Where can students pick it up? 
 
 Building 
 
 Search buildings 
 
 
 
 Huang Engineering Center 
 
 
 Gates Computer Science 
 
 
 Access instructions 
 
 e.g., Second floor lounge... 
 
 
 [<- Back] [Next ->] 
 

Step 5: Review
 
 <- Progress (5/5)
 
 Review your post 
 
 
 [Preview Card with all details] 
 
 
 Responsible sharing 
 
 I confirm that: 
 Accurate description & allergen info 
 Safe serving temperature 
 Read Community Guidelines 
 
 
 [<- Back] [Publish] 
 

Success Screen
 
 
 
 
 
 
 
 
 Post published! 
 Students nearby will be notified 
 
 
 
 Share link 
 
 
 
 Done 
 
 
```

---

## Animation Specifications

### Map Pin Drop-In

```
Frame 0ms: (offscreen above)
Frame 60ms: Pin 1 appears, drops in
Frame 120ms: Pin 2 appears, drops in
Frame 180ms: Pin 3 appears, drops in
...
Frame 480ms: Pin 8 appears, drops in

Each pin:
- Starts at y: -100
- Ends at y: 0
- Duration: 400ms
- Easing: cubic-bezier(0.34, 1.56, 0.64, 1) (bounce)
```

### Bottom Sheet Gesture

```
User drags handle:
 
Track finger position
 
Update sheet offset in real-time
 
On finger lift:
 
Calculate velocity
 
Snap to nearest detent:
- velocity > 300: skip to next detent
- velocity < -300: skip to previous detent
- else: snap to closest
 
Animate with spring:
 response: 0.35
 dampingFraction: 0.75
```

### Card Press Animation

```
Finger down:
 scale: 1.0 -> 0.97 (150ms ease-in-out)
 shadow: 12pt -> 8pt (150ms)

Finger up:
 scale: 0.97 -> 1.0 (150ms ease-in-out)
 shadow: 8pt -> 12pt (150ms)
```

### Confetti Burst

```
On trigger:
 Generate 30 leaf particles
 
For each particle:
 Random X: -200 to 200
 Random rotation: 0 to 720 
 Random duration: 1.5 to 2.5s
 Random delay: 0 to 0.3s
 
 Animate:
 y: -100 -> 800
 rotation: 0 -> random 
 opacity: 1 -> 0
 easing: ease-out
```

---

## Layout Grids

### Tab Bar Layout

```
 
 Map Feed + Inbox Profile 
 
 
 (3) <- Badge
 

Heights:
- Icon: 28pt
- Text: 11pt
- Total: 60pt (including safe area)
- Badge: 18pt diameter

FAB:
- Size: 56pt diameter
- Offset Y: -20pt
- Shadow: 12pt, 30% opacity
```

### Card Grid (Feed)

```
 16pt 16pt 
 
 Card 180pt 
 
 
 16pt 
 
 Card 180pt 
 
 16pt 
 
 Card 180pt 
 
 

Spacing:
- Left/Right margin: 16pt
- Inter-card gap: 16pt
- Card corner radius: 24pt
```

---

## Design Principles

### 1. Playful yet Professional
- Use rounded corners (24pt cards)
- Friendly copy ("On My Way" vs "Claim")
- Confetti celebrations
- BUT: Clear hierarchy, readable text

### 2. Fast by Default
- Lazy loading (LazyVStack)
- Image placeholder fades
- Instant haptic feedback
- Optimistic UI updates

### 3. Accessible First
- VoiceOver on every element
- Dynamic Type respected
- 44pt minimum hit areas
- High contrast modes

### 4. Motion with Purpose
- Every animation explains state
- Reduce Motion honored
- No gratuitous effects
- Physics feels natural

---

## Responsive Behavior

### iPhone SE (Small Screen)
```
Adjustments:
- Cards: 160pt tall (vs 180pt)
- Text: Scale down slightly
- Map pins: 32pt max (vs 48pt)
- Sheet peek: 80pt (vs 96pt)
```

### iPhone 15 Pro Max (Large Screen)
```
Adjustments:
- Cards: 200pt tall (vs 180pt)
- More cards visible at once
- Map pins: 56pt max (vs 48pt)
- Sheet peek: 112pt (vs 96pt)
```

### iPad (Tablet)
```
Adjustments:
- 2-column layout in Feed
- Larger map takes more space
- Side-by-side detail views
- Floating filter panels
```

---

## Component Usage Guidelines

### Do's
- Use DietaryChip for all dietary info
- Use StatusPill for availability states
- Use FoodCard for list items
- Use BottomSheet for modal content
- Use FTHaptics for all feedback
- Use FTAnimation constants

### Don'ts 
- Don't hardcode colors (use tokens)
- Don't use system buttons (use custom)
- Don't mix animation timings
- Don't skip accessibility labels
- Don't add emojis without semantic meaning
- Don't override system fonts

---

**End of Component Showcase**

For implementation details, see respective `.swift` files in the Components/ directory.

