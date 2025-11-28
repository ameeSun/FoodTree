-- =====================================================
-- Fix Post Deletion: Expiration and Reports
-- =====================================================
-- This migration:
-- 1. Improves post expiration to run every minute instead of every 5 minutes
-- 2. Adds database trigger to immediately delete posts when reported with details
-- =====================================================

-- =====================================================
-- 1. UPDATE CRON JOB TO RUN EVERY MINUTE
-- =====================================================

-- Remove old cron job
SELECT cron.unschedule('expire-posts-every-5-minutes') WHERE EXISTS (
  SELECT 1 FROM cron.job WHERE jobname = 'expire-posts-every-5-minutes'
);

-- Create new cron job that runs every minute for faster expiration
SELECT cron.schedule(
  'expire-posts-every-minute',
  '* * * * *',  -- Every minute
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

-- =====================================================
-- 2. DATABASE TRIGGER FOR IMMEDIATE POST DELETION ON REPORTS WITH COMMENTS
-- =====================================================

-- Function to delete post when report has a comment
-- Uses SECURITY DEFINER to bypass RLS and allow deletion
CREATE OR REPLACE FUNCTION delete_post_on_reported_with_comment()
RETURNS TRIGGER AS $$
BEGIN
  -- Check if the new report has a non-empty comment
  IF NEW.comment IS NOT NULL AND TRIM(NEW.comment) != '' THEN
    -- Delete the post immediately (bypasses RLS due to SECURITY DEFINER)
    DELETE FROM public.food_posts
    WHERE id = NEW.post_id;
    
    -- Log the deletion
    RAISE NOTICE 'Post % deleted due to report with comment (reporter: %)', NEW.post_id, NEW.reporter_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger that fires AFTER insert on reports
DROP TRIGGER IF EXISTS trigger_delete_post_on_reported_with_comment ON public.reports;
CREATE TRIGGER trigger_delete_post_on_reported_with_comment
  AFTER INSERT ON public.reports
  FOR EACH ROW
  EXECUTE FUNCTION delete_post_on_reported_with_comment();

-- =====================================================
-- 3. IMPROVE EXPIRATION QUERY IN EDGE FUNCTION
-- =====================================================
-- Note: The edge function will be updated to also check for posts
-- that have exactly reached expiration time (not just past it)
-- This ensures posts delete as soon as they hit 0 minutes

-- =====================================================
-- VERIFICATION
-- =====================================================

-- Check cron jobs
-- SELECT jobname, schedule, command FROM cron.job WHERE jobname LIKE '%expire%';

-- Check triggers
-- SELECT trigger_name, event_manipulation, event_object_table 
-- FROM information_schema.triggers 
-- WHERE trigger_name = 'trigger_delete_post_on_reported_with_comment';

