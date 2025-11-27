-- =====================================================
-- Storage Bucket and Cron Jobs Setup
-- =====================================================
-- This migration creates the storage bucket, policies,
-- enables required extensions, and sets up cron jobs
-- =====================================================

-- Enable required extensions for cron jobs
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

-- =====================================================
-- STORAGE BUCKET SETUP
-- =====================================================

-- Note: Storage bucket creation via SQL requires Supabase-specific functions
-- If this doesn't work, create bucket via Dashboard or CLI:
-- supabase storage create food-images --public false

-- Create storage bucket (if it doesn't exist)
-- This uses Supabase's storage management functions
DO $$
BEGIN
  -- Check if bucket exists, if not create it
  IF NOT EXISTS (
    SELECT 1 FROM storage.buckets WHERE id = 'food-images'
  ) THEN
    INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
    VALUES (
      'food-images',
      'food-images',
      false,
      5242880, -- 5MB in bytes
      ARRAY['image/jpeg', 'image/png', 'image/webp']
    );
  END IF;
END $$;

-- =====================================================
-- STORAGE POLICIES
-- =====================================================

-- Policy 1: Authenticated users can view images
CREATE POLICY "Authenticated users can view images"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'food-images');

-- Policy 2: Authenticated users can upload images
CREATE POLICY "Authenticated users can upload images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'food-images' 
  AND auth.role() = 'authenticated'
);

-- Policy 3: Post creators can delete their images
-- Path structure: post/<creator_id>/<post_id>/<image_uuid>.jpg
CREATE POLICY "Post creators can delete their images"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'food-images'
  AND (
    -- Extract creator_id from path: post/<creator_id>/...
    (string_to_array(name, '/'))[1] = 'post'
    AND (string_to_array(name, '/'))[2] = auth.uid()::text
  )
  OR EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  )
);

-- =====================================================
-- STORE SERVICE ROLE KEY FOR CRON JOBS
-- =====================================================

-- Store service role key in database settings for cron job authentication
-- This allows cron jobs to authenticate when calling edge functions
-- Replace YOUR_SERVICE_ROLE_KEY with actual key in production
DO $$
BEGIN
  -- Set the service role key in a custom configuration
  -- Note: In production, this should be set via Supabase Dashboard > Settings > Database
  -- or via environment variable SUPABASE_SERVICE_ROLE_KEY
  PERFORM set_config('app.settings.service_role_key', 
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR1bHVoamtpcW9haHNoeGhpeXF6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MjkwODc2NCwiZXhwIjoyMDc4NDg0NzY0fQ.501EJ2AqZzbbRcA6qryZWC0yNLOisrzgqeklOZvYexo',
    false);
END $$;

-- =====================================================
-- CRON JOB SETUP
-- =====================================================

-- Remove existing cron jobs if they exist (to avoid duplicates)
SELECT cron.unschedule('expire-posts-every-5-minutes') WHERE EXISTS (
  SELECT 1 FROM cron.job WHERE jobname = 'expire-posts-every-5-minutes'
);

SELECT cron.unschedule('analytics-daily-at-midnight') WHERE EXISTS (
  SELECT 1 FROM cron.job WHERE jobname = 'analytics-daily-at-midnight'
);

-- Cron Job 1: Expire posts every 5 minutes
SELECT cron.schedule(
  'expire-posts-every-5-minutes',
  '*/5 * * * *',  -- Every 5 minutes (SQL allows */5 syntax)
  $$
  SELECT net.http_post(
    url := 'https://duluhjkiqoahshxhiyqz.supabase.co/functions/v1/expire_posts',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true)
    ),
    body := '{}'::jsonb
  ) AS request_id;
  $$
);

-- Cron Job 2: Analytics daily at midnight UTC
SELECT cron.schedule(
  'analytics-daily-at-midnight',
  '0 0 * * *',  -- Daily at midnight UTC
  $$
  SELECT net.http_post(
    url := 'https://duluhjkiqoahshxhiyqz.supabase.co/functions/v1/analytics_daily',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true)
    ),
    body := '{}'::jsonb
  ) AS request_id;
  $$
);

-- =====================================================
-- VERIFICATION QUERIES (for manual checking)
-- =====================================================

-- Check if extensions are enabled
-- SELECT * FROM pg_extension WHERE extname IN ('pg_cron', 'pg_net');

-- Check if bucket exists
-- SELECT * FROM storage.buckets WHERE id = 'food-images';

-- Check storage policies
-- SELECT * FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects';

-- Check cron jobs
-- SELECT * FROM cron.job;

