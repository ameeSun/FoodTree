#!/bin/bash

# Backend Setup Script for FoodTree
# This script configures storage bucket, deploys edge functions, and sets up cron jobs

set -e

# Configuration
SUPABASE_URL="https://duluhjkiqoahshxhiyqz.supabase.co"
SERVICE_ROLE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR1bHVoamtpcW9haHNoeGhpeXF6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MjkwODc2NCwiZXhwIjoyMDc4NDg0NzY0fQ.501EJ2AqZzbbRcA6qryZWC0yNLOisrzgqeklOZvYexo"
PROJECT_REF="duluhjkiqoahshxhiyqz"

echo "🚀 Starting FoodTree backend setup..."

# Step 1: Create storage bucket via API
echo ""
echo "📦 Step 1: Creating storage bucket 'food-images'..."
BUCKET_RESPONSE=$(curl -s -X POST \
  "${SUPABASE_URL}/storage/v1/bucket" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "food-images",
    "name": "food-images",
    "public": false,
    "file_size_limit": 5242880,
    "allowed_mime_types": ["image/jpeg", "image/png", "image/webp"]
  }' 2>&1)

if echo "$BUCKET_RESPONSE" | grep -q "already exists\|duplicate\|exists"; then
  echo "✅ Storage bucket 'food-images' already exists"
elif echo "$BUCKET_RESPONSE" | grep -q "error\|Error"; then
  echo "⚠️  Storage bucket creation response: $BUCKET_RESPONSE"
  echo "   (Bucket may already exist or need to be created via Dashboard)"
else
  echo "✅ Storage bucket 'food-images' created successfully"
fi

# Step 2: Deploy edge functions
echo ""
echo "🔧 Step 2: Deploying edge functions..."

# Set service role key as environment variable for Supabase CLI
export SUPABASE_ACCESS_TOKEN="${SERVICE_ROLE_KEY}"

# Try to link project first (may fail if not logged in, but we'll try deployment anyway)
supabase link --project-ref "${PROJECT_REF}" 2>/dev/null || echo "   (Project linking skipped, using direct deployment)"

# Deploy functions
echo "   Deploying expire_posts..."
cd supabase/functions/expire_posts
supabase functions deploy expire_posts --project-ref "${PROJECT_REF}" --no-verify-jwt || {
  echo "   ⚠️  Direct deployment failed, will need manual deployment"
}

echo "   Deploying notify_users..."
cd ../notify_users
supabase functions deploy notify_users --project-ref "${PROJECT_REF}" --no-verify-jwt || {
  echo "   ⚠️  Direct deployment failed, will need manual deployment"
}

echo "   Deploying analytics_daily..."
cd ../analytics_daily
supabase functions deploy analytics_daily --project-ref "${PROJECT_REF}" --no-verify-jwt || {
  echo "   ⚠️  Direct deployment failed, will need manual deployment"
}

cd ../../..

echo ""
echo "✅ Backend setup script completed!"
echo ""
echo "📝 Next steps:"
echo "   1. Apply migration: Run the SQL migration file (0002_storage_and_cron_setup.sql) via Supabase Dashboard"
echo "   2. Verify storage bucket exists in Dashboard > Storage"
echo "   3. Verify edge functions are deployed in Dashboard > Edge Functions"
echo "   4. Check cron jobs in Dashboard > Database > Extensions > pg_cron"

