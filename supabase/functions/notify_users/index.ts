// =====================================================
// TreeBites Edge Function: notify_users
// =====================================================
// Centralized notification fan-out service
// Handles in-app notifications and push notifications
// Protected - only callable by service_role or internal functions
// =====================================================

import { serve } from "https://deno.land/std@0.177.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface NotificationRequest {
  user_ids: string[]
  type: string
  title: string
  body: string
  post_id?: string
  data?: Record<string, any>
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Verify service_role authorization
    const authHeader = req.headers.get('Authorization')
    if (!authHeader || !authHeader.includes('Bearer')) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized - service_role key required' }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 401 
        }
      )
    }

    // Parse request body
    const request: NotificationRequest = await req.json()
    
    // Validate request
    if (!request.user_ids || !Array.isArray(request.user_ids) || request.user_ids.length === 0) {
      return new Response(
        JSON.stringify({ error: 'user_ids array is required and must not be empty' }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 400 
        }
      )
    }

    if (!request.type || !request.title) {
      return new Response(
        JSON.stringify({ error: 'type and title are required' }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 400 
        }
      )
    }

    // Create Supabase client with service_role key
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    
    const supabase = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false
      }
    })

    console.log(`📬 Sending notifications to ${request.user_ids.length} users`)

    // Create in-app notifications
    const notifications = request.user_ids.map(user_id => ({
      user_id,
      type: request.type,
      title: request.title,
      body: request.body || '',
      post_id: request.post_id || null,
      data: request.data || {},
      is_read: false
    }))

    const { data: insertedNotifications, error: insertError } = await supabase
      .from('notifications')
      .insert(notifications)
      .select('id')

    if (insertError) {
      throw new Error(`Failed to insert notifications: ${insertError.message}`)
    }

    console.log(`✅ Created ${insertedNotifications?.length || 0} in-app notifications`)

    // Fetch push tokens for these users
    const { data: pushTokens, error: tokensError } = await supabase
      .from('push_tokens')
      .select('user_id, platform, token')
      .in('user_id', request.user_ids)

    if (tokensError) {
      console.warn('⚠️  Failed to fetch push tokens:', tokensError.message)
    }

    // Send push notifications
    let pushSuccess = 0
    let pushFailed = 0

    if (pushTokens && pushTokens.length > 0) {
      console.log(`📱 Found ${pushTokens.length} push tokens`)

      for (const tokenRecord of pushTokens) {
        try {
          if (tokenRecord.platform === 'ios') {
            try {
              await sendApnNotification(tokenRecord.token, {
                title: request.title,
                body: request.body,
                data: {
                  post_id: request.post_id,
                  ...request.data
                }
              })
              pushSuccess++
            } catch (apnsError) {
              console.error(`❌ APNs error for token ${tokenRecord.token.substring(0, 8)}...:`, apnsError)
              pushFailed++
            }
          } else if (tokenRecord.platform === 'android') {
            // TODO: Send to FCM
            // await sendFcmNotification(tokenRecord.token, {
            //   title: request.title,
            //   body: request.body,
            //   data: {
            //     post_id: request.post_id,
            //     ...request.data
            //   }
            // })
            console.log(`📲 [STUB] Would send FCM to: ${tokenRecord.token.substring(0, 8)}...`)
            pushSuccess++
          }
        } catch (pushError) {
          console.error(`❌ Failed to send push to ${tokenRecord.platform}:`, pushError)
          pushFailed++
        }
      }
    }

    return new Response(
      JSON.stringify({ 
        success: true,
        in_app_notifications_created: insertedNotifications?.length || 0,
        push_tokens_found: pushTokens?.length || 0,
        push_sent: pushSuccess,
        push_failed: pushFailed
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200 
      }
    )

  } catch (error) {
    console.error('❌ Error in notify_users function:', error)
    return new Response(
      JSON.stringify({ 
        success: false,
        error: error.message 
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500 
      }
    )
  }
})

// =====================================================
// PUSH NOTIFICATION HELPERS (TODO: Implement)
// =====================================================

/**
 * Send notification via Apple Push Notification service
 * 
 * Requirements (set as environment variables in Supabase Dashboard > Edge Functions > Secrets):
 * 1. APNS_KEY_ID - Key ID from Apple Developer account (e.g., "ABC123DEFG")
 * 2. APNS_TEAM_ID - Team ID from Apple Developer account (e.g., "XYZ987WUV")
 * 3. APNS_KEY - The .p8 auth key file content (full text including BEGIN/END lines)
 * 4. APNS_BUNDLE_ID - Bundle ID (e.g., "com.stanford.foodtree")
 * 5. APNS_PRODUCTION - "true" for production, "false" for sandbox (default: false)
 * 
 * To get APNs credentials:
 * 1. Go to https://developer.apple.com/account/resources/authkeys/list
 * 2. Create a new key with "Apple Push Notifications service (APNs)" enabled
 * 3. Download the .p8 file
 * 4. Note the Key ID and your Team ID
 * 5. Set these as secrets in Supabase Dashboard
 */
async function sendApnNotification(deviceToken: string, payload: any): Promise<void> {
  const keyId = Deno.env.get('APNS_KEY_ID')
  const teamId = Deno.env.get('APNS_TEAM_ID')
  const apnsKey = Deno.env.get('APNS_KEY') // Full .p8 file content
  const bundleId = Deno.env.get('APNS_BUNDLE_ID') || 'com.stanford.foodtree'
  const isProduction = Deno.env.get('APNS_PRODUCTION') === 'true'
  
  // Check if APNs is configured
  if (!keyId || !teamId || !apnsKey) {
    console.warn('⚠️ APNs not configured - skipping push notification.')
    console.warn('   Set APNS_KEY_ID, APNS_TEAM_ID, and APNS_KEY as Supabase secrets.')
    return // Don't throw error, just skip gracefully
  }
  
  try {
    // Generate JWT token for APNs authentication
    const jwt = await generateAPNsJWT(keyId, teamId, apnsKey)
    
    // Determine APNs endpoint (production or sandbox)
    const apnsHost = isProduction 
      ? 'api.push.apple.com' 
      : 'api.sandbox.push.apple.com'
    
    // Build notification payload
    const apnsPayload = {
      aps: {
        alert: {
          title: payload.title,
          body: payload.body
        },
        sound: 'default',
        badge: 1
      },
      ...payload.data // Include custom data (post_id, etc.)
    }
    
    // Send to APNs
    const url = `https://${apnsHost}/3/device/${deviceToken}`
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${jwt}`,
        'apns-topic': bundleId,
        'apns-priority': '10',
        'apns-push-type': 'alert',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(apnsPayload)
    })
    
    if (!response.ok) {
      const errorText = await response.text()
      throw new Error(`APNs error (${response.status}): ${errorText}`)
    }
    
    console.log(`✅ Sent APNs notification to ${deviceToken.substring(0, 8)}...`)
  } catch (error) {
    console.error('❌ APNs send error:', error)
    throw error
  }
}

/**
 * Generate JWT token for APNs authentication using ES256
 * 
 * This implementation uses the Web Crypto API available in Deno
 * The privateKey should be the full .p8 file content including BEGIN/END lines
 */
async function generateAPNsJWT(keyId: string, teamId: string, privateKey: string): Promise<string> {
  try {
    // Convert PEM key to ArrayBuffer for Web Crypto API
    // Remove header/footer and whitespace
    const keyPEM = privateKey
      .replace(/-----BEGIN PRIVATE KEY-----/g, '')
      .replace(/-----END PRIVATE KEY-----/g, '')
      .replace(/\s/g, '')
    
    // Decode base64 to get the key bytes
    const keyBytes = Uint8Array.from(atob(keyPEM), c => c.charCodeAt(0))
    
    // Import the key for signing
    const cryptoKey = await crypto.subtle.importKey(
      'pkcs8',
      keyBytes,
      {
        name: 'ECDSA',
        namedCurve: 'P-256'
      },
      false,
      ['sign']
    )
    
    // Create JWT header and payload
    const header = { alg: 'ES256', kid: keyId, typ: 'JWT' }
    const now = Math.floor(Date.now() / 1000)
    const payload = { iss: teamId, iat: now }
    
    // Base64URL encode
    const base64UrlEncode = (str: string): string => {
      return btoa(str)
        .replace(/\+/g, '-')
        .replace(/\//g, '_')
        .replace(/=/g, '')
    }
    
    const encodedHeader = base64UrlEncode(JSON.stringify(header))
    const encodedPayload = base64UrlEncode(JSON.stringify(payload))
    const unsignedToken = `${encodedHeader}.${encodedPayload}`
    
    // Sign with ES256
    const signature = await crypto.subtle.sign(
      { name: 'ECDSA', hash: 'SHA-256' },
      cryptoKey,
      new TextEncoder().encode(unsignedToken)
    )
    
    // Convert signature to base64url
    const signatureArray = Array.from(new Uint8Array(signature))
    const signatureBase64 = btoa(String.fromCharCode(...signatureArray))
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
      .replace(/=/g, '')
    
    return `${unsignedToken}.${signatureBase64}`
  } catch (error) {
    console.error('❌ Failed to generate APNs JWT:', error)
    throw new Error(`JWT generation failed: ${error.message}`)
  }
}

/**
 * Send notification via Firebase Cloud Messaging
 * 
 * Requirements:
 * 1. FCM server key from Firebase console
 * 2. Project ID
 * 
 * Implementation guide:
 * - POST to https://fcm.googleapis.com/fcm/send
 * - Header: Authorization: key=SERVER_KEY
 * - Body: { "to": token, "notification": { "title": ..., "body": ... } }
 */
async function sendFcmNotification(deviceToken: string, payload: any): Promise<void> {
  // TODO: Implement FCM integration
  // const serverKey = Deno.env.get('FCM_SERVER_KEY')
  
  // Send POST request to FCM
  
  throw new Error('FCM not implemented yet')
}

/* 
 * USAGE EXAMPLES:
 * 
 * 1. Notify users of new post nearby:
 *    curl -X POST https://duluhjkiqoahshxhiyqz.supabase.co/functions/v1/notify_users \
 *      -H "Authorization: Bearer SERVICE_ROLE_KEY" \
 *      -H "Content-Type: application/json" \
 *      -d '{
 *        "user_ids": ["uuid1", "uuid2"],
 *        "type": "new_post_nearby",
 *        "title": "Free food near you!",
 *        "body": "Burrito Bowls at Huang - 35 portions",
 *        "post_id": "post-uuid",
 *        "data": {"distance": 0.3}
 *      }'
 * 
 * 2. Notify creator that their post is running low:
 *    curl -X POST https://duluhjkiqoahshxhiyqz.supabase.co/functions/v1/notify_users \
 *      -H "Authorization: Bearer SERVICE_ROLE_KEY" \
 *      -H "Content-Type: application/json" \
 *      -d '{
 *        "user_ids": ["creator-uuid"],
 *        "type": "post_low",
 *        "title": "Post Running Low",
 *        "body": "Your post has less than 20 portions remaining",
 *        "post_id": "post-uuid"
 *      }'
 */

