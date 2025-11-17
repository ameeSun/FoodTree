# FoodTree Backend - Quick Start Guide

## 🚀 Get Running in 15 Minutes

This guide will get your FoodTree backend up and running as quickly as possible.

---

## Prerequisites Checklist

- [ ] Supabase account (free tier is fine)
- [ ] Supabase CLI installed: `brew install supabase/tap/supabase`
- [ ] Xcode 15.0+ installed
- [ ] macOS with Swift 5.9+

---

## Step 1: Deploy Database (5 minutes)

```bash
# Navigate to project
cd /Users/sanmaysarada/ASES-FoodTree

# Link to your Supabase project
supabase link --project-ref duluhjkiqoahshxhiyqz

# Push the database schema
supabase db push

# Seed with Stanford buildings
supabase db execute --file supabase/seed/seed_foodtree.sql
```

**Verify**: Go to Supabase Dashboard > Table Editor. You should see 12 tables.

---

## Step 2: Configure Storage (2 minutes)

### Via Supabase Dashboard:

1. Go to **Storage** > **New Bucket**
2. Name: `food-images`
3. **Public**: Off (unchecked)
4. **File size limit**: 5MB
5. Click **Create**
6. Click on `food-images` > **Policies** > **New Policy**
7. Create 3 policies:

**Policy 1**: "Authenticated users can view images"
```sql
Operation: SELECT
Policy: bucket_id = 'food-images' AND auth.role() = 'authenticated'
```

**Policy 2**: "Authenticated users can upload"
```sql
Operation: INSERT  
Policy: bucket_id = 'food-images' AND auth.role() = 'authenticated'
```

**Policy 3**: "Creators can delete their images"
```sql
Operation: DELETE
Policy: bucket_id = 'food-images' 
       AND (storage.foldername(name))[1] = 'post'
       AND auth.uid()::text = (storage.foldername(name))[2]
```

---

## Step 3: Deploy Edge Functions (3 minutes)

```bash
# Deploy all three functions
supabase functions deploy expire_posts
supabase functions deploy notify_users  
supabase functions deploy analytics_daily
```

### Set up Cron Jobs

Go to **Dashboard > SQL Editor** and run:

```sql
-- Enable pg_cron extension
create extension if not exists pg_cron;

-- Schedule expire_posts every 5 minutes
select cron.schedule(
  'expire-posts-every-5-minutes',
  '*/5 * * * *',
  $$
  select net.http_post(
    url := 'https://duluhjkiqoahshxhiyqz.supabase.co/functions/v1/expire_posts',
    headers := '{"Authorization": "Bearer ' || current_setting('app.settings.service_role_key') || '"}'::jsonb
  ) as request_id;
  $$
);

-- Schedule analytics_daily at midnight
select cron.schedule(
  'analytics-daily-at-midnight',
  '0 0 * * *',
  $$
  select net.http_post(
    url := 'https://duluhjkiqoahshxhiyqz.supabase.co/functions/v1/analytics_daily',
    headers := '{"Authorization": "Bearer ' || current_setting('app.settings.service_role_key') || '"}'::jsonb
  ) as request_id;
  $$
);
```

---

## Step 4: Configure Auth (2 minutes)

### Via Supabase Dashboard:

1. Go to **Auth** > **Providers**
2. Enable **Email** provider
3. Set **Confirm email**: Off (for development)
4. Go to **Auth** > **URL Configuration**
5. Add redirect URL: `foodtree://auth/callback`

### Optional: Add Stanford Email Restriction

Go to **Dashboard > SQL Editor**:

```sql
-- Add a check constraint to profiles table
alter table profiles 
  add constraint email_must_be_stanford 
  check (email like '%@stanford.edu');
```

---

## Step 5: iOS Setup (3 minutes)

### A. Add Supabase Swift SDK

1. Open `FoodTree.xcodeproj` in Xcode
2. File > Add Packages...
3. Enter: `https://github.com/supabase-community/supabase-swift`
4. Version: 2.0.0 or later
5. Add to target: FoodTree

### B. Update Info.plist

Open `FoodTree/FoodTree/Info.plist` (or create it) and add:

```xml
<key>SUPABASE_URL</key>
<string>https://duluhjkiqoahshxhiyqz.supabase.co</string>
<key>SUPABASE_ANON_KEY</key>
<string>eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR1bHVoamtpcW9haHNoeGhpeXF6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5MDg3NjQsImV4cCI6MjA3ODQ4NDc2NH0.x8HqNSpYojZ6iEds6IDZyQtOTx4eswEgqWOA7mFphjg</string>
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>foodtree</string>
        </array>
    </dict>
</array>
```

### C. Add Networking Files

Copy these 3 files into your Xcode project:

1. `FoodTree/FoodTree/Networking/SupabaseConfig.swift` ✅ Already created
2. `FoodTree/FoodTree/Networking/AuthManager.swift` ✅ Already created
3. `FoodTree/FoodTree/Networking/Repositories/FoodPostRepository.swift` ✅ Already created

Drag and drop them into Xcode, ensuring "Copy items if needed" is checked.

---

## Step 6: Test It! (2 minutes)

### Test 1: Database Query

In **Dashboard > SQL Editor**:

```sql
-- Should return 8 Stanford buildings
select code, name from campus_buildings order by name;

-- Should show all tables
select table_name from information_schema.tables 
where table_schema = 'public' 
order by table_name;
```

### Test 2: Auth Flow (iOS)

Build and run the app in Xcode. Try the email auth flow:

```swift
// In a test view
Task {
    try await AuthManager.shared.signInWithEmail("your-email@stanford.edu")
    print("Magic link sent!")
}
```

Check your email for the magic link.

### Test 3: Fetch Posts (iOS)

```swift
// In MapViewModel or a test
Task {
    let repo = FoodPostRepository()
    let posts = try await repo.fetchNearbyPosts(
        center: CLLocationCoordinate2D(latitude: 37.4275, longitude: -122.1697),
        radiusMeters: 5000
    )
    print("Fetched \(posts.count) posts")
}
```

---

## ✅ You're Done!

Your backend is now fully operational. Here's what you have:

- ✅ PostgreSQL database with 12 tables
- ✅ Row Level Security protecting all data
- ✅ Storage for images (5MB limit)
- ✅ Edge functions running on schedule
- ✅ Auth system configured
- ✅ iOS app can connect to backend

---

## 📚 Next Steps

Now that the backend is running, proceed with iOS integration:

1. **Refactor MapViewModel** to use `FoodPostRepository` instead of `MockData`
2. **Refactor FeedViewModel** similarly
3. **Update PostComposerViewModel** to create real posts
4. **Add NotificationRepository** (see integration guide)
5. **Add OrganizerRepository** (see integration guide)

**Full guide**: See `backend/docs/IOS_INTEGRATION_GUIDE.md`

---

## 🐛 Troubleshooting

### "supabase: command not found"

```bash
brew install supabase/tap/supabase
```

### "Failed to push migration"

Check that you're linked to the correct project:

```bash
supabase link --project-ref duluhjkiqoahshxhiyqz
```

### "Unauthorized" errors in iOS

1. Check that `SUPABASE_ANON_KEY` is in Info.plist
2. Verify user is logged in: `AuthManager.shared.isAuthenticated`
3. Check RLS policies in Supabase Dashboard

### "Module 'Supabase' not found" in Xcode

1. Clean build folder: Cmd+Shift+K
2. File > Packages > Reset Package Cache
3. Rebuild

### Posts not appearing in iOS

1. Seed some test posts manually via Dashboard > Table Editor
2. Check post status is "available" or "low"
3. Verify location is within search radius
4. Check console for error messages

---

## 📞 Need Help?

- **Backend docs**: `backend/README.md`
- **iOS integration**: `backend/docs/IOS_INTEGRATION_GUIDE.md`
- **Full summary**: `BACKEND_IMPLEMENTATION_SUMMARY.md`
- **Supabase Discord**: https://discord.supabase.com

---

## 🎉 Success!

You've successfully deployed a production-ready Supabase backend in under 15 minutes!

**Status**: 🟢 Backend Operational
**Next**: Start integrating with iOS ViewModels

---

**Built for Stanford with ❤️**

