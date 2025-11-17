-- =====================================================
-- FoodTree Seed Data
-- =====================================================
-- This file seeds the database with Stanford campus data
-- and sample posts for local development and testing.
--
-- Run this AFTER the initial migration.
-- =====================================================

-- =====================================================
-- 1. STANFORD CAMPUS BUILDINGS
-- =====================================================

insert into public.campus_buildings (code, name, latitude, longitude, notes) values
  ('HUANG', 'Huang Engineering Center', 37.4275, -122.1770, 'Main engineering building'),
  ('GATES', 'Gates Computer Science', 37.4300, -122.1730, 'Computer Science Department'),
  ('OLD_UNION', 'Old Union', 37.4265, -122.1698, 'Historic student union building'),
  ('TRESIDDER', 'Tresidder Union', 37.4255, -122.1691, 'Student union with Starbucks'),
  ('EVGR_C', 'EVGR C Courtyard', 37.4290, -122.1750, 'Engineering courtyard'),
  ('MEMORIAL_COURT', 'Memorial Court', 37.4270, -122.1680, 'Near main quad'),
  ('Y2E2', 'Y2E2', 37.4268, -122.1735, 'Environment and Energy building'),
  ('FRAT_ROW', 'Fraternity Row', 37.4310, -122.1665, 'Greek life area')
on conflict (code) do nothing;

-- =====================================================
-- 2. SAMPLE PROFILES (for local dev only)
-- =====================================================

-- NOTE: In production, profiles are created automatically via auth trigger
-- These are just for seeding local dev environment without real auth

-- Sample organizer profile (you would normally use real auth.users id)
-- insert into public.profiles (id, email, full_name, role, is_verified_organizer) values
--   ('00000000-0000-0000-0000-000000000001', 'cs-club@stanford.edu', 'Stanford CS Club', 'organizer', true)
-- on conflict (id) do nothing;

-- Sample student profile
-- insert into public.profiles (id, email, full_name, role) values
--   ('00000000-0000-0000-0000-000000000002', 'student@stanford.edu', 'Test Student', 'student')
-- on conflict (id) do nothing;

-- =====================================================
-- 3. SAMPLE FOOD POSTS (realistic Stanford data)
-- =====================================================

-- NOTE: Uncomment and replace UUIDs with real auth.users IDs after setting up auth
-- Or use these for local Supabase development

/*
-- Get building IDs for reference
do $$
declare
  huang_id bigint;
  gates_id bigint;
  old_union_id bigint;
  tresidder_id bigint;
  evgr_id bigint;
  y2e2_id bigint;
  memorial_id bigint;
  frat_id bigint;
  creator_id uuid := '00000000-0000-0000-0000-000000000001'; -- Replace with real user ID
begin
  select id into huang_id from public.campus_buildings where code = 'HUANG';
  select id into gates_id from public.campus_buildings where code = 'GATES';
  select id into old_union_id from public.campus_buildings where code = 'OLD_UNION';
  select id into tresidder_id from public.campus_buildings where code = 'TRESIDDER';
  select id into evgr_id from public.campus_buildings where code = 'EVGR_C';
  select id into y2e2_id from public.campus_buildings where code = 'Y2E2';
  select id into memorial_id from public.campus_buildings where code = 'MEMORIAL_COURT';
  select id into frat_id from public.campus_buildings where code = 'FRAT_ROW';

  -- Post 1: Burrito Bowls
  insert into public.food_posts (
    creator_id,
    title,
    description,
    dietary,
    perishability,
    quantity_estimate,
    status,
    expires_at,
    location_lat,
    location_lng,
    building_id,
    building_name,
    pickup_instructions,
    created_at
  ) values (
    creator_id,
    'Leftover Burrito Bowls',
    'Chicken and veggie burrito bowls from our CS Club meeting. Still warm!',
    array['glutenfree', 'dairyfree']::dietary_tag[],
    'high',
    35,
    'available',
    now() + interval '40 minutes',
    37.4275,
    -122.1770,
    huang_id,
    'Huang Engineering Center',
    'Third floor lounge, near the elevators',
    now() - interval '6 minutes'
  );

  -- Post 2: Veggie Sushi
  insert into public.food_posts (
    creator_id,
    title,
    description,
    dietary,
    perishability,
    quantity_estimate,
    status,
    expires_at,
    location_lat,
    location_lng,
    building_id,
    building_name,
    pickup_instructions,
    created_at
  ) values (
    creator_id,
    'Veggie Sushi Platters',
    'Assorted veggie sushi from recruiting event. All vegetarian.',
    array['vegetarian', 'dairyfree']::dietary_tag[],
    'high',
    25,
    'available',
    now() + interval '30 minutes',
    37.4300,
    -122.1730,
    gates_id,
    'Gates Computer Science',
    'First floor commons',
    now() - interval '15 minutes'
  );

  -- Post 3: Pizza Slices (LOW status)
  insert into public.food_posts (
    creator_id,
    title,
    description,
    dietary,
    perishability,
    quantity_estimate,
    status,
    expires_at,
    location_lat,
    location_lng,
    building_id,
    building_name,
    pickup_instructions,
    created_at
  ) values (
    creator_id,
    'Pizza Slices',
    'Cheese and veggie pizza from study session.',
    array['vegetarian']::dietary_tag[],
    'medium',
    12,
    'low',
    now() + interval '60 minutes',
    37.4265,
    -122.1698,
    old_union_id,
    'Old Union',
    'Second floor lounge',
    now() - interval '30 minutes'
  );

  -- Post 4: Mediterranean Plates
  insert into public.food_posts (
    creator_id,
    title,
    description,
    dietary,
    perishability,
    quantity_estimate,
    status,
    expires_at,
    location_lat,
    location_lng,
    building_id,
    building_name,
    pickup_instructions,
    created_at
  ) values (
    creator_id,
    'Mediterranean Plates',
    'Falafel, hummus, pita, and salads. All halal and vegan options available.',
    array['vegan', 'halal', 'vegetarian', 'glutenfree']::dietary_tag[],
    'medium',
    40,
    'available',
    now() + interval '45 minutes',
    37.4290,
    -122.1750,
    evgr_id,
    'EVGR C Courtyard',
    'Outdoor tables near C wing entrance',
    now() - interval '10 minutes'
  );

  -- Post 5: Cookies & Milk
  insert into public.food_posts (
    creator_id,
    title,
    description,
    dietary,
    perishability,
    quantity_estimate,
    status,
    expires_at,
    location_lat,
    location_lng,
    building_id,
    building_name,
    pickup_instructions,
    created_at
  ) values (
    creator_id,
    'Cookies & Milk',
    'Freshly baked chocolate chip and oatmeal cookies with cold milk.',
    array['vegetarian', 'contains_nuts']::dietary_tag[],
    'low',
    60,
    'available',
    now() + interval '90 minutes',
    37.4255,
    -122.1691,
    tresidder_id,
    'Tresidder Union',
    'Main lobby, near Starbucks',
    now() - interval '5 minutes'
  );

  -- Post 6: Paneer Tikka (LOW status)
  insert into public.food_posts (
    creator_id,
    title,
    description,
    dietary,
    perishability,
    quantity_estimate,
    status,
    expires_at,
    location_lat,
    location_lng,
    building_id,
    building_name,
    pickup_instructions,
    created_at
  ) values (
    creator_id,
    'Paneer Tikka & Rice',
    'Indian vegetarian feast with paneer tikka, rice, and naan.',
    array['vegetarian', 'halal']::dietary_tag[],
    'high',
    18,
    'low',
    now() + interval '20 minutes',
    37.4268,
    -122.1735,
    y2e2_id,
    'Y2E2',
    'Ground floor atrium',
    now() - interval '20 minutes'
  );

  -- Post 7: Bagels
  insert into public.food_posts (
    creator_id,
    title,
    description,
    dietary,
    perishability,
    quantity_estimate,
    status,
    expires_at,
    location_lat,
    location_lng,
    building_id,
    building_name,
    pickup_instructions,
    created_at
  ) values (
    creator_id,
    'Bagels & Cream Cheese',
    'Assorted bagels with cream cheese and spreads.',
    array['vegetarian']::dietary_tag[],
    'low',
    30,
    'available',
    now() + interval '30 minutes',
    37.4270,
    -122.1680,
    memorial_id,
    'Memorial Court',
    'Near the fountain',
    now() - interval '40 minutes'
  );

  -- Post 8: Fruit & Cheese
  insert into public.food_posts (
    creator_id,
    title,
    description,
    dietary,
    perishability,
    quantity_estimate,
    status,
    expires_at,
    location_lat,
    location_lng,
    building_id,
    building_name,
    pickup_instructions,
    created_at
  ) values (
    creator_id,
    'Fruit & Cheese Platter',
    'Fresh fruit, cheese cubes, and crackers.',
    array['vegetarian', 'glutenfree']::dietary_tag[],
    'medium',
    45,
    'available',
    now() + interval '60 minutes',
    37.4310,
    -122.1665,
    frat_id,
    'Fraternity Row',
    'Sigma Chi house, front porch',
    now() - interval '3 minutes'
  );

end $$;
*/

-- =====================================================
-- 4. SAMPLE ON_MY_WAY RECORDS
-- =====================================================

-- NOTE: Uncomment after creating posts with real IDs
/*
-- Add some on_my_way records for realism
insert into public.on_my_way (post_id, user_id, eta_minutes) 
select 
  p.id,
  '00000000-0000-0000-0000-000000000002'::uuid, -- student user
  (random() * 15 + 5)::integer
from public.food_posts p
where p.status in ('available', 'low')
limit 3;
*/

-- =====================================================
-- 5. SAMPLE NOTIFICATIONS
-- =====================================================

-- NOTE: Uncomment after creating users
/*
insert into public.notifications (user_id, type, title, body, post_id) 
select
  '00000000-0000-0000-0000-000000000002'::uuid,
  'new_post_nearby',
  'New post near ' || building_name,
  title || ' • ' || quantity_estimate || ' portions',
  id
from public.food_posts
where created_at > now() - interval '10 minutes'
limit 3;
*/

-- =====================================================
-- SEED COMPLETE
-- =====================================================

-- Verify seed data
select 'Buildings seeded: ' || count(*)::text from public.campus_buildings;
select 'Posts seeded: ' || count(*)::text from public.food_posts;

-- Display seeded buildings
select 
  code,
  name,
  latitude,
  longitude
from public.campus_buildings
order by name;

