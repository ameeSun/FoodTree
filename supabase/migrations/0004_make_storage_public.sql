-- =====================================================
-- Make Storage Bucket Public for Read Access
-- =====================================================
-- This migration makes the food-images bucket public
-- so images can be accessed via public URLs without authentication.
-- Upload and delete operations still require authentication.
-- =====================================================

-- Update bucket to be public
UPDATE storage.buckets
SET public = true
WHERE id = 'food-images';

-- Add policy to allow public read access
-- (This allows anyone to view images, even without authentication)
-- Drop policy if it exists first, then create it
DROP POLICY IF EXISTS "Public can view images" ON storage.objects;

CREATE POLICY "Public can view images"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'food-images');

-- Note: Existing policies for authenticated users remain in place:
-- - Authenticated users can still upload (INSERT policy)
-- - Post creators can delete their images (DELETE policy)
-- - Public can now view images (new SELECT policy above)

