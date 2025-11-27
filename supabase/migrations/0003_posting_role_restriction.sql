-- =====================================================
-- Posting Role Restriction Migration
-- =====================================================
-- This migration restricts food post creation to only
-- organizers and administrators. Students cannot create posts.
-- =====================================================

-- Helper function to check if user is organizer or admin
create or replace function public.is_organizer_or_admin()
returns boolean
language sql
stable
security definer
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() 
    and role in ('organizer', 'admin')
  );
$$;

-- Drop the existing policy that allows all authenticated users to create posts
drop policy if exists "Authenticated users can create posts" on public.food_posts;

-- Create new policy that only allows organizers and admins to create posts
create policy "Only organizers and admins can create posts"
  on public.food_posts for insert
  with check (
    auth.uid() = creator_id
    and auth.role() = 'authenticated'
    and public.is_organizer_or_admin()
  );

