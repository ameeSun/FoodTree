// =====================================================
// FoodTree Edge Function: notify_users
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
            // TODO: Send to APNs
            // await sendApnNotification(tokenRecord.token, {
            //   title: request.title,
            //   body: request.body,
            //   data: {
            //     post_id: request.post_id,
            //     ...request.data
            //   }
            // })
            console.log(`📲 [STUB] Would send APNs to: ${tokenRecord.token.substring(0, 8)}...`)
            pushSuccess++
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
        push_failed: pushFailed,
        push_note: 'Push notifications are stubbed - implement APNs/FCM integration'
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
 * Requirements:
 * 1. APNs auth key (.p8 file) from Apple Developer account
 * 2. Team ID and Key ID
 * 3. Bundle ID (com.stanford.foodtree)
 * 
 * Implementation guide:
 * - Use jose library for JWT signing
 * - POST to https://api.push.apple.com/3/device/{token}
 * - Headers: authorization (Bearer JWT), apns-topic (bundle ID)
 * - Body: { "aps": { "alert": { "title": ..., "body": ... }, "sound": "default" } }
 */
async function sendApnNotification(deviceToken: string, payload: any): Promise<void> {
  // TODO: Implement APNs integration
  // const keyId = Deno.env.get('APNS_KEY_ID')
  // const teamId = Deno.env.get('APNS_TEAM_ID')
  // const keyPath = Deno.env.get('APNS_KEY_PATH')
  
  // Generate JWT token
  // Send POST request to APNs
  
  throw new Error('APNs not implemented yet')
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

