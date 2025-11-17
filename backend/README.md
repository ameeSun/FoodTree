# FoodTree Backend Documentation

Complete Supabase backend setup and integration guide for the FoodTree iOS application.

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Local Development Setup](#local-development-setup)
- [Database Schema](#database-schema)
- [Edge Functions](#edge-functions)
- [Storage Configuration](#storage-configuration)
- [Security & RLS](#security--rls)
- [iOS Integration](#ios-integration)
- [Deployment](#deployment)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)

---

## 🎯 Overview

The FoodTree backend is built entirely on **Supabase**, providing:

- **PostgreSQL Database** with PostGIS for location queries
- **Row Level Security (RLS)** for data protection
- **Supabase Auth** with email magic links (Stanford domain restricted)
- **Storage** for food images with secure access
- **Realtime** subscriptions for live updates
- **Edge Functions** (Deno/TypeScript) for scheduled tasks and notifications

**No separate Node.js server required** - everything runs on Supabase infrastructure.

---

## ✅ Prerequisites

### Required Tools

1. **Supabase CLI** (v1.64.0+)
   ```bash
   brew install supabase/tap/supabase
   # or
   npm install -g supabase
   ```

2. **Deno** (for edge functions development)
   ```bash
   brew install deno
   ```

3. **PostgreSQL Client** (optional, for direct DB access)
   ```bash
   brew install postgresql
   ```

### Supabase Project

- Project URL: `https://duluhjkiqoahshxhiyqz.supabase.co`
- Access keys in `.env` file (see [Configuration](#configuration))

---

## 🚀 Local Development Setup

### 1. Clone and Configure

```bash
cd /path/to/ASES-FoodTree

# Copy environment template
cp .env.example .env

# Edit .env with your keys (already populated in .env.example)
nano .env
```

### 2. Start Local Supabase

```bash
# Initialize Supabase (first time only)
supabase init

# Start local Supabase stack (Postgres + PostgREST + Auth + Storage + Realtime)
supabase start

# This will output local URLs and keys - save these for iOS development
```

### 3. Apply Migrations

```bash
# Link to remote project
supabase link --project-ref duluhjkiqoahshxhiyqz

# Push migrations to remote database
supabase db push

# Or for local development
supabase db reset  # Applies all migrations to local DB
```

### 4. Seed Data

```bash
# Apply seed data (Stanford buildings + sample posts)
supabase db execute --file supabase/seed/seed_foodtree.sql

# Or via psql
psql postgresql://postgres:postgres@localhost:54322/postgres \
  -f supabase/seed/seed_foodtree.sql
```

### 5. Test Database Connection

```bash
# Check tables were created
supabase db list

# Query data
psql postgresql://postgres:postgres@localhost:54322/postgres \
  -c "SELECT code, name FROM campus_buildings;"
```

---

## 🗄️ Database Schema

### Core Tables

| Table | Purpose | Key Fields |
|-------|---------|------------|
| `profiles` | User profiles (1:1 with auth.users) | role, is_verified_organizer, dietary_preferences |
| `campus_buildings` | Stanford buildings | code, name, lat/lng |
| `food_posts` | Food listings | title, status, quantity_estimate, expires_at, location |
| `food_post_images` | Post images (1:many) | storage_path, sort_order |
| `on_my_way` | Users heading to pickup | post_id, user_id, eta_minutes |
| `saved_posts` | Bookmarked posts | post_id, user_id |
| `notifications` | In-app notifications | user_id, type, title, body, is_read |
| `push_tokens` | Device tokens for push | user_id, platform, token |
| `organizer_verification_requests` | Organizer verification | user_id, org_name, status |
| `reports` | User-reported posts | post_id, reporter_id, reason |
| `analytics_daily_summary` | Daily metrics | date, posts_created, avg_times, top_organizers |

### Enums

```sql
user_role: 'student' | 'organizer' | 'admin'
post_status: 'available' | 'low' | 'gone' | 'expired'
perishability_level: 'low' | 'medium' | 'high'
dietary_tag: 'vegan' | 'vegetarian' | 'halal' | 'kosher' | 'glutenfree' | 'dairyfree' | 'contains_nuts'
notification_type: 'new_post_nearby' | 'post_low' | 'post_gone' | 'post_expired' | 'post_extended' | 'generic'
```

### Key Features

- **PostGIS Extension**: Spatial queries for nearby posts using `ll_to_earth()`
- **Triggers**: Auto-maintain counts (`on_my_way_count`, `saves_count`), update timestamps
- **Indexes**: Optimized for distance queries, status filtering, creator lookups
- **Constraints**: Data validation at DB level (quantity ranges, text lengths)

---

## ⚡ Edge Functions

### 1. `expire_posts`

**Schedule**: Every 5 minutes (via pg_cron)

**Purpose**: Automatically expire posts past their `expires_at` time and notify affected users.

```bash
# Deploy
supabase functions deploy expire_posts

# Test locally
supabase functions serve expire_posts

# Test remotely
curl -X POST https://duluhjkiqoahshxhiyqz.supabase.co/functions/v1/expire_posts \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY"
```

**Cron Setup** (via Supabase Dashboard > SQL Editor):
```sql
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
```

### 2. `notify_users`

**Trigger**: Called by other functions or manually

**Purpose**: Centralized notification fan-out (in-app + push).

```bash
# Deploy
supabase functions deploy notify_users

# Example call
curl -X POST https://duluhjkiqoahshxhiyqz.supabase.co/functions/v1/notify_users \
  -H "Authorization: Bearer SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "user_ids": ["uuid1", "uuid2"],
    "type": "new_post_nearby",
    "title": "Free food near you!",
    "body": "Burrito Bowls - 35 portions",
    "post_id": "post-uuid"
  }'
```

**Push Notifications**: Currently stubbed. To implement:
- Add APNs/FCM integration in the function
- Set environment variables: `APNS_KEY_ID`, `APNS_TEAM_ID`, `FCM_SERVER_KEY`

### 3. `analytics_daily`

**Schedule**: Daily at midnight UTC

**Purpose**: Compute daily analytics summary.

```bash
# Deploy
supabase functions deploy analytics_daily

# Cron setup
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

## 📁 Storage Configuration

### Bucket: `food-images`

**Settings** (create via Dashboard > Storage):
- **Public**: No
- **File size limit**: 5MB
- **Allowed MIME types**: `image/jpeg`, `image/png`, `image/webp`
- **Path structure**: `post/<creator_id>/<post_id>/<image_uuid>.jpg`

### Storage Policies

Create these policies via Dashboard > Storage > food-images > Policies:

```sql
-- 1. View images (authenticated users)
create policy "Authenticated users can view images"
  on storage.objects for select
  using (bucket_id = 'food-images' and auth.role() = 'authenticated');

-- 2. Upload images (authenticated users)
create policy "Authenticated users can upload images"
  on storage.objects for insert
  with check (bucket_id = 'food-images' and auth.role() = 'authenticated');

-- 3. Delete images (post creators only)
create policy "Post creators can delete their images"
  on storage.objects for delete
  using (
    bucket_id = 'food-images' 
    and (storage.foldername(name))[1] = 'post'
    and auth.uid()::text = (storage.foldername(name))[2]
  );
```

### iOS Usage

```swift
// Upload image
let imageData = image.jpegData(compressionQuality: 0.8)
let path = "post/\(userId)/\(postId)/\(UUID().uuidString).jpg"
let response = try await supabase.storage
  .from("food-images")
  .upload(path: path, file: imageData)

// Get public URL
let url = try await supabase.storage
  .from("food-images")
  .getPublicURL(path: path)
```

---

## 🔒 Security & RLS

All tables have **Row Level Security (RLS) enabled** with granular policies.

### Key Principles

1. **Client uses `anon` key** with RLS enforcing access
2. **Service role key** only in Edge Functions (never in iOS)
3. **JWT authentication** required for all writes
4. **Policies use `auth.uid()`** to check user identity

### Policy Examples

```sql
-- Users can only update their own profile
create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id);

-- Users can only create posts as themselves
create policy "Authenticated users can create posts"
  on public.food_posts for insert
  with check (auth.uid() = creator_id);

-- Users can only view their own notifications
create policy "Users can view own notifications"
  on public.notifications for select
  using (auth.uid() = user_id);
```

### Admin Role

Admins can bypass some restrictions using `public.is_admin()` function:

```sql
create or replace function public.is_admin()
returns boolean as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$ language sql stable security definer;
```

---

## 📱 iOS Integration

### 1. Add Supabase Swift Client

**Package.swift** or **Xcode > Add Package**:
```
https://github.com/supabase-community/supabase-swift
```

### 2. Configure Supabase

Create `FoodTree/FoodTree/Networking/SupabaseConfig.swift`:

```swift
import Supabase

struct SupabaseConfig {
    static let shared = SupabaseConfig()
    
    let client: SupabaseClient
    
    private init() {
        // Read from Info.plist (NEVER hardcode keys)
        guard let url = URL(string: Config.supabaseURL),
              let anonKey = Config.supabaseAnonKey else {
            fatalError("Supabase configuration missing")
        }
        
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: anonKey
        )
    }
}

// Config.plist reader
struct Config {
    static var supabaseURL: String {
        Bundle.main.object(forInfoKeyPath: "SUPABASE_URL") as? String ?? ""
    }
    
    static var supabaseAnonKey: String {
        Bundle.main.object(forInfoKeyPath: "SUPABASE_ANON_KEY") as? String ?? ""
    }
}
```

### 3. Add to Info.plist

```xml
<key>SUPABASE_URL</key>
<string>https://duluhjkiqoahshxhiyqz.supabase.co</string>
<key>SUPABASE_ANON_KEY</key>
<string>eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...</string>
```

### 4. Create Repository Layer

See iOS integration section in main docs for full implementation.

---

## 🚢 Deployment

### Production Checklist

- [ ] Review all RLS policies
- [ ] Set up auth email templates (Supabase Dashboard > Auth > Email Templates)
- [ ] Configure auth redirects for magic links
- [ ] Deploy all edge functions
- [ ] Set up cron jobs for `expire_posts` and `analytics_daily`
- [ ] Create storage bucket with proper policies
- [ ] Configure custom SMTP (optional, for branded emails)
- [ ] Set up monitoring/alerts
- [ ] Add indexes for production query patterns
- [ ] Enable database backups (Supabase auto-backs up, verify schedule)

### Deploy Commands

```bash
# Deploy all functions at once
supabase functions deploy expire_posts
supabase functions deploy notify_users
supabase functions deploy analytics_daily

# Push database changes
supabase db push

# Generate TypeScript types for iOS (optional)
supabase gen types typescript --local > types/supabase.ts
```

---

## 🧪 Testing

### Database Tests

```sql
-- Test RLS policies
set role authenticated;
set request.jwt.claims.sub = 'test-user-uuid';

select * from food_posts;  -- Should work
select * from notifications;  -- Should only see own
```

### Edge Function Tests

```bash
# Local testing
supabase functions serve expire_posts &
curl http://localhost:54321/functions/v1/expire_posts

# Remote testing
curl -X POST https://duluhjkiqoahshxhiyqz.supabase.co/functions/v1/expire_posts \
  -H "Authorization: Bearer SERVICE_ROLE_KEY"
```

### iOS Integration Tests

Create unit tests in Xcode for repository layer:
- Test auth flow
- Test CRUD operations
- Test realtime subscriptions
- Test storage uploads

---

## 🔧 Troubleshooting

### Common Issues

#### 1. Migration Failed

```bash
# Reset local database
supabase db reset

# Check migration status
supabase migration list

# Manually apply specific migration
supabase db execute --file supabase/migrations/0001_foodtree_init.sql
```

#### 2. RLS Blocking Queries

```sql
-- Check policies
select * from pg_policies where tablename = 'food_posts';

-- Test as specific user
set role authenticated;
set request.jwt.claims.sub = 'user-uuid-here';
```

#### 3. Edge Function Not Working

```bash
# Check logs
supabase functions logs expire_posts

# Verify environment variables are set
supabase secrets list
```

#### 4. Storage Upload Failing

- Check bucket exists: Dashboard > Storage
- Verify policies are created
- Check file size < 5MB
- Verify MIME type is allowed
- Check auth token is valid

### Getting Help

- [Supabase Docs](https://supabase.com/docs)
- [Supabase Discord](https://discord.supabase.com)
- Check GitHub issues in this repo

---

## 📚 Additional Resources

- [Supabase Auth Guide](https://supabase.com/docs/guides/auth)
- [PostgREST API Reference](https://postgrest.org/en/stable/api.html)
- [Supabase Swift Client](https://github.com/supabase-community/supabase-swift)
- [Deno Edge Functions](https://deno.com/deploy/docs)

---

## 🎓 Stanford-Specific Notes

### Email Domain Restriction

Auth is configured for `stanford.edu` email addresses only. Configure via:
- Dashboard > Auth > Email Auth
- Add domain restriction rule

### Building Codes

The seed data includes 8 Stanford buildings. Add more via:

```sql
insert into campus_buildings (code, name, latitude, longitude) values
  ('NEW_BUILDING', 'Building Name', 37.4xxx, -122.1xxx, 'Notes');
```

### Organizer Verification

Students request organizer status via `organizer_verification_requests` table. Admins approve/reject via:

```sql
-- Approve verification
update organizer_verification_requests 
set status = 'approved', admin_id = 'admin-uuid', admin_notes = 'Verified'
where id = 'request-uuid';

-- Update profile
update profiles 
set is_verified_organizer = true, role = 'organizer'
where id = 'user-uuid';
```

---

**Need help? Check the main docs or create an issue on GitHub.**

**Built for Stanford with ❤️**

