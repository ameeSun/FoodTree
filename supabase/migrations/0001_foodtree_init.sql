-- =====================================================
-- FoodTree Database Schema - Initial Migration
-- =====================================================
-- This migration creates all tables, enums, functions, and policies
-- for the FoodTree application.
--
-- Prerequisites:
-- 1. Row Level Security (RLS) must be enabled globally
-- 2. Auth Email provider configured for stanford.edu domain
-- 3. Realtime enabled for public schema
-- 4. Storage bucket 'food-images' created
-- =====================================================

-- Enable required extensions
create extension if not exists "uuid-ossp";
create extension if not exists "postgis";
create extension if not exists "pg_trgm";

-- =====================================================
-- 1. ENUMS
-- =====================================================

create type user_role as enum ('student', 'organizer', 'admin');
create type post_status as enum ('available', 'low', 'gone', 'expired');
create type perishability_level as enum ('low', 'medium', 'high');
create type dietary_tag as enum (
  'vegan',
  'vegetarian',
  'halal',
  'kosher',
  'glutenfree',
  'dairyfree',
  'contains_nuts'
);
create type notification_type as enum (
  'new_post_nearby',
  'post_low',
  'post_gone',
  'post_expired',
  'post_extended',
  'generic'
);
create type verification_status as enum ('pending', 'approved', 'rejected');
create type report_reason as enum ('unsafe_food', 'misleading', 'spam', 'other');

-- =====================================================
-- 2. PROFILES TABLE
-- =====================================================

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text unique not null,
  full_name text,
  role user_role not null default 'student',
  is_verified_organizer boolean not null default false,
  avatar_url text,
  dietary_preferences dietary_tag[] default '{}',
  search_radius_miles numeric(4,2) default 1.0 check (search_radius_miles > 0 and search_radius_miles <= 10),
  notification_preferences jsonb default '{"new_posts": true, "running_low": true, "post_updates": true}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Index for faster lookups
create index idx_profiles_role on public.profiles(role);
create index idx_profiles_verified on public.profiles(is_verified_organizer) where is_verified_organizer = true;
create index idx_profiles_email on public.profiles(email);

-- Trigger to update updated_at
create or replace function update_updated_at_column()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger update_profiles_updated_at
  before update on public.profiles
  for each row
  execute function update_updated_at_column();

-- =====================================================
-- 3. CAMPUS BUILDINGS TABLE
-- =====================================================

create table public.campus_buildings (
  id bigserial primary key,
  code text unique not null,
  name text not null,
  latitude double precision not null,
  longitude double precision not null,
  notes text,
  created_at timestamptz not null default now()
);

-- GiST index for spatial queries
create index idx_buildings_location on public.campus_buildings using gist(ll_to_earth(latitude, longitude));

-- =====================================================
-- 4. FOOD POSTS TABLE
-- =====================================================

create table public.food_posts (
  id uuid primary key default gen_random_uuid(),
  creator_id uuid not null references public.profiles(id) on delete cascade,
  title text not null check (length(title) >= 3 and length(title) <= 200),
  description text,
  tags text[] default '{}',
  dietary dietary_tag[] default '{}',
  perishability perishability_level not null default 'medium',
  quantity_estimate integer not null default 20 check (quantity_estimate >= 0 and quantity_estimate <= 1000),
  status post_status not null default 'available',
  expires_at timestamptz,
  auto_expires boolean not null default true,
  location_lat double precision not null,
  location_lng double precision not null,
  building_id bigint references public.campus_buildings(id),
  building_name text,
  pickup_instructions text,
  views_count integer not null default 0 check (views_count >= 0),
  on_my_way_count integer not null default 0 check (on_my_way_count >= 0),
  saves_count integer not null default 0 check (saves_count >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Indexes for common queries
create index idx_posts_creator on public.food_posts(creator_id);
create index idx_posts_status on public.food_posts(status);
create index idx_posts_expires on public.food_posts(expires_at) where expires_at is not null;
create index idx_posts_created on public.food_posts(created_at desc);
create index idx_posts_location on public.food_posts using gist(ll_to_earth(location_lat, location_lng));

-- Composite index for nearby available posts
create index idx_posts_nearby_available on public.food_posts(status, created_at desc)
  where status in ('available', 'low');

-- Trigger for updated_at
create trigger update_posts_updated_at
  before update on public.food_posts
  for each row
  execute function update_updated_at_column();

-- =====================================================
-- 5. FOOD POST IMAGES TABLE
-- =====================================================

create table public.food_post_images (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.food_posts(id) on delete cascade,
  storage_path text not null,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create index idx_images_post on public.food_post_images(post_id, sort_order);

-- =====================================================
-- 6. ON MY WAY TABLE
-- =====================================================

create table public.on_my_way (
  post_id uuid not null references public.food_posts(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  eta_minutes integer check (eta_minutes > 0 and eta_minutes <= 120),
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

-- Trigger to maintain on_my_way_count
create or replace function update_on_my_way_count()
returns trigger as $$
begin
  if tg_op = 'INSERT' then
    update public.food_posts
    set on_my_way_count = on_my_way_count + 1
    where id = new.post_id;
  elsif tg_op = 'DELETE' then
    update public.food_posts
    set on_my_way_count = greatest(0, on_my_way_count - 1)
    where id = old.post_id;
  end if;
  return null;
end;
$$ language plpgsql;

create trigger on_my_way_insert_trigger
  after insert on public.on_my_way
  for each row execute function update_on_my_way_count();

create trigger on_my_way_delete_trigger
  after delete on public.on_my_way
  for each row execute function update_on_my_way_count();

-- =====================================================
-- 7. SAVED POSTS TABLE
-- =====================================================

create table public.saved_posts (
  post_id uuid not null references public.food_posts(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create index idx_saved_posts_user on public.saved_posts(user_id, created_at desc);

-- Trigger to maintain saves_count
create or replace function update_saves_count()
returns trigger as $$
begin
  if tg_op = 'INSERT' then
    update public.food_posts
    set saves_count = saves_count + 1
    where id = new.post_id;
  elsif tg_op = 'DELETE' then
    update public.food_posts
    set saves_count = greatest(0, saves_count - 1)
    where id = old.post_id;
  end if;
  return null;
end;
$$ language plpgsql;

create trigger saved_posts_insert_trigger
  after insert on public.saved_posts
  for each row execute function update_saves_count();

create trigger saved_posts_delete_trigger
  after delete on public.saved_posts
  for each row execute function update_saves_count();

-- =====================================================
-- 8. NOTIFICATIONS TABLE
-- =====================================================

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  type notification_type not null,
  title text not null check (length(title) >= 1),
  body text,
  post_id uuid references public.food_posts(id) on delete set null,
  data jsonb default '{}'::jsonb,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index idx_notifications_user_read on public.notifications(user_id, is_read);
create index idx_notifications_created on public.notifications(created_at desc);

-- =====================================================
-- 9. PUSH TOKENS TABLE
-- =====================================================

create table public.push_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  platform text not null check (platform in ('ios', 'android')),
  token text not null,
  created_at timestamptz not null default now(),
  unique(user_id, token)
);

create index idx_push_tokens_user on public.push_tokens(user_id);

-- =====================================================
-- 10. ORGANIZER VERIFICATION REQUESTS TABLE
-- =====================================================

create table public.organizer_verification_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  org_name text not null check (length(org_name) >= 2),
  org_description text,
  proof_url text,
  status verification_status not null default 'pending',
  admin_id uuid references public.profiles(id),
  admin_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_verification_user on public.organizer_verification_requests(user_id);
create index idx_verification_status on public.organizer_verification_requests(status);

create trigger update_verification_updated_at
  before update on public.organizer_verification_requests
  for each row
  execute function update_updated_at_column();

-- =====================================================
-- 11. REPORTS TABLE
-- =====================================================

create table public.reports (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.food_posts(id) on delete cascade,
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  reason report_reason not null,
  comment text,
  created_at timestamptz not null default now()
);

create index idx_reports_post on public.reports(post_id);
create index idx_reports_created on public.reports(created_at desc);

-- =====================================================
-- 12. ANALYTICS DAILY SUMMARY TABLE
-- =====================================================

create table public.analytics_daily_summary (
  id uuid primary key default gen_random_uuid(),
  date date unique not null,
  posts_created integer not null default 0,
  avg_minutes_to_low numeric(8,2),
  avg_minutes_to_gone numeric(8,2),
  top_organizer_ids uuid[] default '{}',
  data jsonb default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index idx_analytics_date on public.analytics_daily_summary(date desc);

-- =====================================================
-- 13. HELPER FUNCTIONS
-- =====================================================

-- Check if user is admin
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

-- Get post creator ID (for RLS policies)
create or replace function public.get_post_creator(post_uuid uuid)
returns uuid
language sql
stable
security definer
as $$
  select creator_id from public.food_posts where id = post_uuid;
$$;

-- Calculate distance between two points (in meters)
create or replace function public.calculate_distance(
  lat1 double precision,
  lng1 double precision,
  lat2 double precision,
  lng2 double precision
)
returns double precision
language sql
immutable
as $$
  select earth_distance(
    ll_to_earth(lat1, lng1),
    ll_to_earth(lat2, lng2)
  );
$$;

-- Increment post views (called from client)
create or replace function public.increment_post_views(post_uuid uuid)
returns void
language plpgsql
security definer
as $$
begin
  update public.food_posts
  set views_count = views_count + 1
  where id = post_uuid;
end;
$$;

-- =====================================================
-- 14. ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS on all tables
alter table public.profiles enable row level security;
alter table public.campus_buildings enable row level security;
alter table public.food_posts enable row level security;
alter table public.food_post_images enable row level security;
alter table public.on_my_way enable row level security;
alter table public.saved_posts enable row level security;
alter table public.notifications enable row level security;
alter table public.push_tokens enable row level security;
alter table public.organizer_verification_requests enable row level security;
alter table public.reports enable row level security;
alter table public.analytics_daily_summary enable row level security;

-- ========== PROFILES POLICIES ==========

-- Users can view basic info of all profiles
create policy "Users can view all profiles"
  on public.profiles for select
  using (true);

-- Users can insert their own profile
create policy "Users can insert own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

-- Users can update their own profile (non-sensitive fields)
create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Admins can update any profile
create policy "Admins can update any profile"
  on public.profiles for update
  using (public.is_admin());

-- ========== CAMPUS BUILDINGS POLICIES ==========

-- Anyone can view buildings
create policy "Anyone can view buildings"
  on public.campus_buildings for select
  using (true);

-- Only admins can insert/update/delete buildings
create policy "Only admins can modify buildings"
  on public.campus_buildings for all
  using (public.is_admin());

-- ========== FOOD POSTS POLICIES ==========

-- Anyone authenticated can view all posts
create policy "Authenticated users can view posts"
  on public.food_posts for select
  using (auth.role() = 'authenticated');

-- Authenticated users can create posts
create policy "Authenticated users can create posts"
  on public.food_posts for insert
  with check (
    auth.uid() = creator_id
    and auth.role() = 'authenticated'
  );

-- Creators and admins can update their posts
create policy "Creators can update own posts"
  on public.food_posts for update
  using (auth.uid() = creator_id or public.is_admin())
  with check (auth.uid() = creator_id or public.is_admin());

-- Creators and admins can delete their posts
create policy "Creators can delete own posts"
  on public.food_posts for delete
  using (auth.uid() = creator_id or public.is_admin());

-- ========== FOOD POST IMAGES POLICIES ==========

-- Anyone authenticated can view images
create policy "Authenticated users can view images"
  on public.food_post_images for select
  using (auth.role() = 'authenticated');

-- Post creators can insert images for their posts
create policy "Post creators can insert images"
  on public.food_post_images for insert
  with check (
    exists (
      select 1 from public.food_posts
      where id = post_id and creator_id = auth.uid()
    )
  );

-- Post creators can delete images from their posts
create policy "Post creators can delete images"
  on public.food_post_images for delete
  using (
    exists (
      select 1 from public.food_posts
      where id = post_id and creator_id = auth.uid()
    )
    or public.is_admin()
  );

-- ========== ON MY WAY POLICIES ==========

-- Anyone authenticated can view on_my_way records
create policy "Authenticated users can view on_my_way"
  on public.on_my_way for select
  using (auth.role() = 'authenticated');

-- Users can insert their own on_my_way
create policy "Users can insert own on_my_way"
  on public.on_my_way for insert
  with check (auth.uid() = user_id);

-- Users can delete their own on_my_way
create policy "Users can delete own on_my_way"
  on public.on_my_way for delete
  using (auth.uid() = user_id);

-- ========== SAVED POSTS POLICIES ==========

-- Users can only view their own saved posts
create policy "Users can view own saved posts"
  on public.saved_posts for select
  using (auth.uid() = user_id);

-- Users can save posts
create policy "Users can save posts"
  on public.saved_posts for insert
  with check (auth.uid() = user_id);

-- Users can unsave posts
create policy "Users can unsave posts"
  on public.saved_posts for delete
  using (auth.uid() = user_id);

-- ========== NOTIFICATIONS POLICIES ==========

-- Users can only view their own notifications
create policy "Users can view own notifications"
  on public.notifications for select
  using (auth.uid() = user_id);

-- Users can update their own notifications (mark as read)
create policy "Users can update own notifications"
  on public.notifications for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Only service role can insert notifications (via edge functions)
-- This is handled via service_role key, not RLS

-- ========== PUSH TOKENS POLICIES ==========

-- Users can view their own tokens
create policy "Users can view own tokens"
  on public.push_tokens for select
  using (auth.uid() = user_id);

-- Users can insert their own tokens
create policy "Users can insert own tokens"
  on public.push_tokens for insert
  with check (auth.uid() = user_id);

-- Users can delete their own tokens
create policy "Users can delete own tokens"
  on public.push_tokens for delete
  using (auth.uid() = user_id);

-- ========== ORGANIZER VERIFICATION POLICIES ==========

-- Users can view their own requests; admins can view all
create policy "Users can view own verification requests"
  on public.organizer_verification_requests for select
  using (auth.uid() = user_id or public.is_admin());

-- Users can insert their own requests
create policy "Users can insert own verification requests"
  on public.organizer_verification_requests for insert
  with check (auth.uid() = user_id);

-- Users can update their pending requests; admins can update any
create policy "Users can update own pending requests"
  on public.organizer_verification_requests for update
  using (
    (auth.uid() = user_id and status = 'pending')
    or public.is_admin()
  );

-- ========== REPORTS POLICIES ==========

-- Only admins can view reports
create policy "Only admins can view reports"
  on public.reports for select
  using (public.is_admin());

-- Authenticated users can submit reports
create policy "Authenticated users can submit reports"
  on public.reports for insert
  with check (
    auth.uid() = reporter_id
    and auth.role() = 'authenticated'
  );

-- ========== ANALYTICS POLICIES ==========

-- Only admins can view analytics
create policy "Only admins can view analytics"
  on public.analytics_daily_summary for select
  using (public.is_admin());

-- =====================================================
-- 15. REALTIME PUBLICATION
-- =====================================================

-- Enable realtime for key tables
alter publication supabase_realtime add table public.food_posts;
alter publication supabase_realtime add table public.on_my_way;
alter publication supabase_realtime add table public.notifications;

-- =====================================================
-- 16. STORAGE SETUP INSTRUCTIONS
-- =====================================================

-- NOTE: Storage bucket 'food-images' must be created manually via Supabase Dashboard
-- or CLI with these settings:
--
-- Bucket: food-images
-- Public: false
-- File size limit: 5MB
-- Allowed MIME types: image/jpeg, image/png, image/webp
--
-- Required Storage Policies (create via Dashboard > Storage > food-images > Policies):
--
-- 1. "Authenticated users can view images"
--    Operation: SELECT
--    Policy: (bucket_id = 'food-images')
--
-- 2. "Authenticated users can upload images"
--    Operation: INSERT
--    Policy: (bucket_id = 'food-images' AND auth.role() = 'authenticated')
--
-- 3. "Post creators can delete their images"
--    Operation: DELETE
--    Policy: (bucket_id = 'food-images' AND (storage.foldername(name))[1] = 'post' 
--             AND auth.uid()::text = (storage.foldername(name))[2])
--
-- Path structure: post/<creator_id>/<post_id>/<image_uuid>.jpg

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================

-- Grant necessary permissions
grant usage on schema public to postgres, anon, authenticated, service_role;
grant all on all tables in schema public to postgres, service_role;
grant select, insert, update, delete on all tables in schema public to authenticated;
grant select on all tables in schema public to anon;

-- Grant sequence permissions
grant usage, select on all sequences in schema public to authenticated, service_role;

-- Refresh schema cache
notify pgrst, 'reload schema';

