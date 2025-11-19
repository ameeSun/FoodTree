# Quick Clone Instructions for Xcode

## Step 1: Clone the Repository

### In Xcode:
1. Open **Xcode**
2. Go to **File** → **Clone Repository...**
3. Enter URL: `https://github.com/SanmaySarada/FoodTree.git`
4. Choose a location (or use default)
5. Click **Clone**
6. Xcode will automatically open the project

**OR** via Terminal:
```bash
git clone https://github.com/SanmaySarada/FoodTree.git
cd FoodTree
open FoodTree/FoodTree.xcodeproj
```

## Step 2: Add Supabase Swift Package (REQUIRED)

The project uses Supabase but the package needs to be added:

1. In Xcode, go to **File** → **Add Packages...**
2. Enter this URL: `https://github.com/supabase-community/supabase-swift`
3. Click **Add Package**
4. Select version: **Up to Next Major Version** with `2.0.0` or later
5. Make sure **FoodTree** target is checked
6. Click **Add Package**
7. Wait for the package to download (may take 30-60 seconds)

## Step 3: Verify Info.plist

The project should have `Info.plist` with Supabase keys already configured. If you see build errors about missing keys:

1. Check that `Info.plist` is in the project navigator
2. Verify it contains:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`

If missing, the root `Info.plist` file has the correct values - make sure it's included in the Xcode project.

## Step 4: Build & Run

1. Select **FoodTree** scheme (top toolbar)
2. Select an **iPhone Simulator** (e.g., iPhone 17)
3. Press **⌘R** (or click the Play button)
4. The app should build and launch!

## Troubleshooting

### "No such module 'Supabase'"
- Make sure you completed **Step 2** above
- Go to **File** → **Packages** → **Resolve Package Versions**
- Wait for packages to download

### Build Errors
- Clean: **Product** → **Clean Build Folder** (⌘⇧K)
- Rebuild: **Product** → **Build** (⌘B)

### Info.plist Not Found
- Right-click on the project in navigator
- **Add Files to "FoodTree"...**
- Select `Info.plist` from the root directory
- Make sure "Copy items if needed" is checked

## That's It!

Once you've added the Supabase package, the project should build and run. All source files, assets, and configuration are already in the repository.

