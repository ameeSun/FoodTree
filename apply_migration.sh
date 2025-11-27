#!/bin/bash

# Script to apply the migration via Supabase API
# Alternative: Apply via Dashboard > SQL Editor

SUPABASE_URL="https://duluhjkiqoahshxhiyqz.supabase.co"
SERVICE_ROLE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR1bHVoamtpcW9haHNoeGhpeXF6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MjkwODc2NCwiZXhwIjoyMDc4NDg0NzY0fQ.501EJ2AqZzbbRcA6qryZWC0yNLOisrzgqeklOZvYexo"

echo "📝 Applying migration for storage policies and cron jobs..."

# Read migration file
MIGRATION_SQL=$(cat supabase/migrations/0002_storage_and_cron_setup.sql)

# Apply via REST API (PostgREST)
RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST \
  "${SUPABASE_URL}/rest/v1/rpc/exec_sql" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  -H "apikey: ${SERVICE_ROLE_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"sql\": $(echo "$MIGRATION_SQL" | jq -Rs .)}" 2>&1)

HTTP_CODE=$(echo "$RESPONSE" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
  echo "✅ Migration applied successfully"
else
  echo "⚠️  API method may not be available. Please apply migration manually:"
  echo "   1. Go to Supabase Dashboard > SQL Editor"
  echo "   2. Copy contents of supabase/migrations/0002_storage_and_cron_setup.sql"
  echo "   3. Paste and execute"
fi

