-- =====================================================
-- Create admin user: treebites@stanford.edu
-- =====================================================
-- This migration creates the profile for the admin user
-- Note: The auth user must be created first via Dashboard or API
-- =====================================================

-- Function to create/update admin profile
CREATE OR REPLACE FUNCTION create_admin_profile()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  user_id uuid;
BEGIN
  -- Find user by email in auth.users
  SELECT id INTO user_id
  FROM auth.users
  WHERE email = 'treebites@stanford.edu'
  LIMIT 1;
  
  IF user_id IS NULL THEN
    RAISE EXCEPTION 'User treebites@stanford.edu does not exist in auth.users. Please create the user first via Supabase Dashboard > Authentication > Add User';
  END IF;
  
  -- Check if profile exists
  IF EXISTS (SELECT 1 FROM public.profiles WHERE id = user_id) THEN
    -- Update existing profile to admin
    UPDATE public.profiles
    SET 
      role = 'admin',
      is_verified_organizer = true,
      updated_at = now()
    WHERE id = user_id;
    
    RAISE NOTICE 'Profile updated to admin role for user: %', user_id;
  ELSE
    -- Create new profile with admin role
    INSERT INTO public.profiles (
      id,
      email,
      full_name,
      role,
      is_verified_organizer,
      created_at,
      updated_at
    ) VALUES (
      user_id,
      'treebites@stanford.edu',
      'TreeBites Admin',
      'admin',
      true,
      now(),
      now()
    );
    
    RAISE NOTICE 'Profile created with admin role for user: %', user_id;
  END IF;
END;
$$;

-- Execute the function
SELECT create_admin_profile();

-- Clean up
DROP FUNCTION IF EXISTS create_admin_profile();

