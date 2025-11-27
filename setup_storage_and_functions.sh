#!/bin/bash

# Direct API-based setup for Storage and verification
# Edge functions need to be deployed via Supabase CLI or Dashboard

set -e

SUPABASE_URL="https://duluhjkiqoahshxhiyqz.supabase.co"
SERVICE_ROLE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR1bHVoamtpcW9haHNoeGhpeXF6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MjkwODc2NCwiZXhwIjoyMDc4NDg0NzY0fQ.501EJ2AqZzbbRcA6qryZWC0yNLOisrzgqeklOZvYexo"

echo "🚀 Setting up FoodTree backend components..."

# Create storage bucket
echo ""
echo "📦 Creating storage bucket 'food-images'..."
BUCKET_RESULT=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST \
  "${SUPABASE_URL}/storage/v1/bucket" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  -H "apikey: ${SERVICE_ROLE_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "food-images",
    "name": "food-images",
    "public": false,
    "file_size_limit": 5242880,
    "allowed_mime_types": ["image/jpeg", "image/png", "image/webp"]
  }')

HTTP_CODE=$(echo "$BUCKET_RESULT" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)
BUCKET_BODY=$(echo "$BUCKET_RESULT" | sed 's/HTTP_CODE:[0-9]*$//')

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
  echo "✅ Storage bucket created successfully"
elif echo "$BUCKET_BODY" | grep -qi "already exists\|duplicate"; then
  echo "✅ Storage bucket already exists"
else
  echo "⚠️  Storage bucket creation: HTTP $HTTP_CODE"
  echo "   Response: $BUCKET_BODY"
  echo "   You may need to create it manually via Dashboard"
fi

echo ""
echo "✅ Storage setup completed!"
echo ""
echo "📝 Next steps:"
echo "   1. Deploy edge functions using: supabase functions deploy <function-name>"
echo "   2. Apply SQL migration (0002_storage_and_cron_setup.sql) via Dashboard"
echo "   3. Verify storage policies are created correctly"

