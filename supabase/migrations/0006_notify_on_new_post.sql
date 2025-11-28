-- =====================================================
-- New Post Notification System
-- =====================================================
-- This migration creates a database trigger that automatically
-- sends notifications to students when an organizer creates a new post.
-- Notifications are sent to students who have "new_posts" enabled
-- in their notification preferences.
-- =====================================================

-- Ensure pg_net extension is available (should already be enabled)
CREATE EXTENSION IF NOT EXISTS pg_net;

-- =====================================================
-- Function: Notify users when a new post is created
-- =====================================================

CREATE OR REPLACE FUNCTION notify_users_on_new_post()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  eligible_user_ids UUID[];
  notification_title TEXT;
  notification_body TEXT;
  building_name TEXT;
  edge_function_url TEXT;
  service_role_key TEXT;
  request_body JSONB;
  response_id BIGINT;
BEGIN
  -- Only notify for posts with status 'available'
  -- Only notify if creator is an organizer (students can't create posts, but check anyway)
  IF NEW.status != 'available' THEN
    RETURN NEW;
  END IF;

  -- Check if creator is an organizer
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = NEW.creator_id 
    AND role = 'organizer'
  ) THEN
    -- Creator is not an organizer, skip notification
    RETURN NEW;
  END IF;

  -- Find all students with "new_posts" notifications enabled
  SELECT ARRAY_AGG(id)
  INTO eligible_user_ids
  FROM public.profiles
  WHERE role = 'student'
    AND (notification_preferences->>'new_posts')::boolean = true;

  -- If no eligible users, exit early
  IF eligible_user_ids IS NULL OR array_length(eligible_user_ids, 1) = 0 THEN
    RETURN NEW;
  END IF;

  -- Prepare notification content
  notification_title := 'New Food Available!';
  
  -- Build notification body with location and quantity info
  building_name := COALESCE(NEW.building_name, 'Campus');
  notification_body := NEW.title || ' at ' || building_name || ' - ' || NEW.quantity_estimate || ' portions';

  -- Get edge function URL and service role key
  edge_function_url := current_setting('app.settings.edge_function_url', true);
  service_role_key := current_setting('app.settings.service_role_key', true);

  -- Fallback to hardcoded values if settings not found (for development)
  IF edge_function_url IS NULL OR edge_function_url = '' THEN
    edge_function_url := 'https://duluhjkiqoahshxhiyqz.supabase.co/functions/v1/notify_users';
  END IF;

  IF service_role_key IS NULL OR service_role_key = '' THEN
    service_role_key := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR1bHVoamtpcW9haHNoeGhpeXF6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MjkwODc2NCwiZXhwIjoyMDc4NDg0NzY0fQ.501EJ2AqZzbbRcA6qryZWC0yNLOisrzgqeklOZvYexo';
  END IF;

  -- Build request body for notify_users edge function
  request_body := jsonb_build_object(
    'user_ids', to_jsonb(eligible_user_ids),
    'type', 'new_post_nearby',
    'title', notification_title,
    'body', notification_body,
    'post_id', NEW.id::text,
    'data', jsonb_build_object(
      'building_name', building_name,
      'quantity', NEW.quantity_estimate,
      'title', NEW.title,
      'location_lat', NEW.location_lat,
      'location_lng', NEW.location_lng
    )
  );

  -- Call notify_users edge function via pg_net
  SELECT net.http_post(
    url := edge_function_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || service_role_key
    ),
    body := request_body
  ) INTO response_id;

  -- Log success (response_id will be set if call was queued)
  IF response_id IS NOT NULL THEN
    RAISE NOTICE 'Notification request queued for post % to % users', NEW.id, array_length(eligible_user_ids, 1);
  ELSE
    RAISE WARNING 'Failed to queue notification request for post %', NEW.id;
  END IF;

  RETURN NEW;
END;
$$;

-- =====================================================
-- Trigger: Fire notification function on new post
-- =====================================================

-- Drop trigger if it exists
DROP TRIGGER IF EXISTS trigger_notify_on_new_post ON public.food_posts;

-- Create trigger
CREATE TRIGGER trigger_notify_on_new_post
  AFTER INSERT ON public.food_posts
  FOR EACH ROW
  EXECUTE FUNCTION notify_users_on_new_post();

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================
-- The notification system is now active:
-- - When an organizer creates a new post with status 'available'
-- - All students with "new_posts" notifications enabled will receive notifications
-- - Notifications include post title, location, and quantity information
-- 
-- Note: The function uses pg_net to call the notify_users edge function
-- asynchronously, so post creation will not be blocked by notification delivery.

