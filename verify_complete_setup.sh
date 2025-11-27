#!/bin/bash

# Complete verification of backend setup

SUPABASE_URL="https://duluhjkiqoahshxhiyqz.supabase.co"
SERVICE_ROLE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR1bHVoamtpcW9haHNoeGhpeXF6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MjkwODc2NCwiZXhwIjoyMDc4NDg0NzY0fQ.501EJ2AqZzbbRcA6qryZWC0yNLOisrzgqeklOZvYexo"

echo "🔍 Verifying complete backend setup..."
echo ""

# Check storage bucket
echo "📦 Checking storage bucket..."
BUCKET_CHECK=$(curl -s -X GET \
  "${SUPABASE_URL}/storage/v1/bucket/food-images" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  -H "apikey: ${SERVICE_ROLE_KEY}")

if echo "$BUCKET_CHECK" | grep -q "food-images"; then
  echo "✅ Storage bucket 'food-images' exists"
else
  echo "❌ Storage bucket 'food-images' not found"
fi

# Check edge functions
echo ""
echo "🔧 Checking edge functions..."

for func in expire_posts notify_users analytics_daily; do
  FUNC_CHECK=$(curl -s -w "%{http_code}" -X POST \
    "${SUPABASE_URL}/functions/v1/${func}" \
    -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
    -H "Content-Type: application/json" \
    -d '{}' -o /dev/null)
  
  HTTP_CODE="${FUNC_CHECK: -3}"
  if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "400" ] || [ "$HTTP_CODE" = "401" ]; then
    echo "✅ Function '${func}' is deployed (HTTP ${HTTP_CODE})"
  else
    echo "⚠️  Function '${func}' returned HTTP ${HTTP_CODE}"
  fi
done

# Check database extensions and cron jobs via SQL
echo ""
echo "🗄️  Checking database setup..."
echo "   (Run this SQL in Dashboard to verify:)"
echo "   SELECT extname FROM pg_extension WHERE extname IN ('pg_cron', 'pg_net', 'postgis', 'earthdistance');"
echo "   SELECT jobname, schedule FROM cron.job WHERE jobname IN ('expire-posts-every-5-minutes', 'analytics-daily-at-midnight');"

echo ""
echo "✅ Verification complete!"
echo ""
echo "📋 To verify database components, run in Supabase Dashboard > SQL Editor:"
echo "   SELECT * FROM cron.job;"
echo "   SELECT * FROM storage.buckets WHERE id = 'food-images';"
echo "   SELECT policyname FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects';"

