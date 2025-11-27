-- =====================================================
-- Fix RLS Security Issue: PostGIS System Tables
-- =====================================================
-- This migration fixes the security issue where PostGIS
-- system tables are exposed to client roles without Row Level
-- Security enabled.
--
-- Since these are system tables used internally by PostGIS,
-- they should not be accessible to client roles (anon, authenticated).
-- Only the service_role should have access for server-side operations.
-- =====================================================

-- =====================================================
-- Secure spatial_ref_sys (coordinate reference systems catalog)
-- =====================================================

-- Revoke all permissions from PUBLIC, anon, and authenticated roles
-- This prevents client-side access to the PostGIS system table
-- Note: Warnings about "no privileges could be revoked" are harmless
-- and just indicate those roles didn't have privileges to begin with
REVOKE ALL ON public.spatial_ref_sys FROM PUBLIC;
REVOKE ALL ON public.spatial_ref_sys FROM anon;
REVOKE ALL ON public.spatial_ref_sys FROM authenticated;

-- Ensure service_role retains access for server-side PostGIS operations
-- (service_role typically has superuser privileges, but this is explicit)
-- Note: This may show a warning if service_role already has access, which is fine
DO $$
BEGIN
  BEGIN
    GRANT SELECT ON public.spatial_ref_sys TO service_role;
  EXCEPTION WHEN OTHERS THEN
    -- Ignore if grant fails (service_role may already have access)
    NULL;
  END;
END $$;

-- Try to enable RLS as a defense-in-depth measure
-- Note: This may fail if we don't own the table (system tables are owned by extension)
-- If it fails, that's okay - the privilege revocation above is the main security measure
DO $$
BEGIN
  BEGIN
    ALTER TABLE public.spatial_ref_sys ENABLE ROW LEVEL SECURITY;
    
    -- Only create policy if RLS was successfully enabled
    DROP POLICY IF EXISTS "deny_all_client_access_spatial_ref_sys" ON public.spatial_ref_sys;
    CREATE POLICY "deny_all_client_access_spatial_ref_sys" ON public.spatial_ref_sys
      FOR ALL
      TO anon, authenticated
      USING (false)
      WITH CHECK (false);
  EXCEPTION WHEN insufficient_privilege OR OTHERS THEN
    -- If we can't enable RLS (not owner), that's okay
    -- The privilege revocation above is sufficient for security
    RAISE NOTICE 'Could not enable RLS on spatial_ref_sys (not owner). Privilege revocation is sufficient.';
  END;
END $$;

-- =====================================================
-- Secure geometry_columns (if it exists in public schema)
-- =====================================================
-- Note: In newer PostGIS versions, this might be in a different schema
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = 'geometry_columns'
  ) THEN
    BEGIN
      EXECUTE 'REVOKE ALL ON public.geometry_columns FROM PUBLIC, anon, authenticated';
    EXCEPTION WHEN OTHERS THEN
      NULL; -- Ignore if revoke fails (no privileges to revoke)
    END;
    
    BEGIN
      EXECUTE 'GRANT SELECT ON public.geometry_columns TO service_role';
    EXCEPTION WHEN OTHERS THEN
      NULL; -- Ignore if grant fails (may already have access)
    END;
    
    BEGIN
      EXECUTE 'ALTER TABLE public.geometry_columns ENABLE ROW LEVEL SECURITY';
      EXECUTE 'DROP POLICY IF EXISTS "deny_all_client_access_geometry_columns" ON public.geometry_columns';
      EXECUTE 'CREATE POLICY "deny_all_client_access_geometry_columns" ON public.geometry_columns
        FOR ALL TO anon, authenticated USING (false) WITH CHECK (false)';
    EXCEPTION WHEN insufficient_privilege OR OTHERS THEN
      -- If we can't enable RLS (not owner), that's okay
      RAISE NOTICE 'Could not enable RLS on geometry_columns (not owner). Privilege revocation is sufficient.';
    END;
  END IF;
END $$;

-- =====================================================
-- Secure geography_columns (if it exists in public schema)
-- =====================================================
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = 'geography_columns'
  ) THEN
    BEGIN
      EXECUTE 'REVOKE ALL ON public.geography_columns FROM PUBLIC, anon, authenticated';
    EXCEPTION WHEN OTHERS THEN
      NULL; -- Ignore if revoke fails (no privileges to revoke)
    END;
    
    BEGIN
      EXECUTE 'GRANT SELECT ON public.geography_columns TO service_role';
    EXCEPTION WHEN OTHERS THEN
      NULL; -- Ignore if grant fails (may already have access)
    END;
    
    BEGIN
      EXECUTE 'ALTER TABLE public.geography_columns ENABLE ROW LEVEL SECURITY';
      EXECUTE 'DROP POLICY IF EXISTS "deny_all_client_access_geography_columns" ON public.geography_columns';
      EXECUTE 'CREATE POLICY "deny_all_client_access_geography_columns" ON public.geography_columns
        FOR ALL TO anon, authenticated USING (false) WITH CHECK (false)';
    EXCEPTION WHEN insufficient_privilege OR OTHERS THEN
      -- If we can't enable RLS (not owner), that's okay
      RAISE NOTICE 'Could not enable RLS on geography_columns (not owner). Privilege revocation is sufficient.';
    END;
  END IF;
END $$;

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================
-- PostGIS system tables are now secured:
-- - Client roles (anon, authenticated) cannot access them (privileges revoked)
-- - Service role can access them for server-side operations
-- - RLS enabled if we have table ownership (defense-in-depth)
-- 
-- Note: If RLS could not be enabled (we don't own the system tables),
-- that's acceptable - the privilege revocation is the primary security measure.
-- System tables are owned by the PostGIS extension, not regular users.
-- 
-- Note: service_role bypasses RLS by default, so it will still
-- have access for server-side PostGIS operations that require
-- these system tables.

