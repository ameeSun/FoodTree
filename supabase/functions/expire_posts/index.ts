// =====================================================
// FoodTree Edge Function: expire_posts
// =====================================================
// Runs on a schedule (every 5 minutes via cron)
// Automatically expires posts that have passed their expiry time
// and sends notifications to relevant users
// =====================================================

import { serve } from "https://deno.land/std@0.177.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Create Supabase client with service_role key
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    
    const supabase = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false
      }
    })

    console.log('🕐 Starting post expiration check...')

    // Find posts that should be expired
    const { data: expiredPosts, error: fetchError } = await supabase
      .from('food_posts')
      .select(`
        id,
        title,
        creator_id,
        building_name,
        expires_at,
        status
      `)
      .eq('auto_expires', true)
      .not('expires_at', 'is', null)
      .lt('expires_at', new Date().toISOString())
      .in('status', ['available', 'low'])

    if (fetchError) {
      throw new Error(`Failed to fetch expired posts: ${fetchError.message}`)
    }

    if (!expiredPosts || expiredPosts.length === 0) {
      console.log('✅ No posts to expire')
      return new Response(
        JSON.stringify({ 
          success: true, 
          expired_count: 0,
          message: 'No posts to expire'
        }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200 
        }
      )
    }

    console.log(`📦 Found ${expiredPosts.length} posts to expire`)

    // Update posts to expired status
    const postIds = expiredPosts.map(p => p.id)
    const { error: updateError } = await supabase
      .from('food_posts')
      .update({ status: 'expired' })
      .in('id', postIds)

    if (updateError) {
      throw new Error(`Failed to update posts: ${updateError.message}`)
    }

    console.log(`✅ Updated ${postIds.length} posts to expired status`)

    // Create notifications for each expired post
    const notifications = []

    for (const post of expiredPosts) {
      // Notification to creator
      notifications.push({
        user_id: post.creator_id,
        type: 'post_expired',
        title: 'Post Expired',
        body: `${post.title} at ${post.building_name} has expired`,
        post_id: post.id,
        data: {}
      })

      // Get users who marked "on my way" for this post
      const { data: onMyWayUsers } = await supabase
        .from('on_my_way')
        .select('user_id')
        .eq('post_id', post.id)

      if (onMyWayUsers && onMyWayUsers.length > 0) {
        for (const user of onMyWayUsers) {
          // Don't notify the creator twice
          if (user.user_id !== post.creator_id) {
            notifications.push({
              user_id: user.user_id,
              type: 'post_expired',
              title: 'Post No Longer Available',
              body: `${post.title} has expired`,
              post_id: post.id,
              data: {}
            })
          }
        }
      }

      // Get users who saved this post
      const { data: savedUsers } = await supabase
        .from('saved_posts')
        .select('user_id')
        .eq('post_id', post.id)

      if (savedUsers && savedUsers.length > 0) {
        for (const user of savedUsers) {
          // Don't notify the same user twice
          if (user.user_id !== post.creator_id && 
              !notifications.some(n => n.user_id === user.user_id && n.post_id === post.id)) {
            notifications.push({
              user_id: user.user_id,
              type: 'post_expired',
              title: 'Saved Post Expired',
              body: `${post.title} is no longer available`,
              post_id: post.id,
              data: {}
            })
          }
        }
      }
    }

    // Insert all notifications
    if (notifications.length > 0) {
      const { error: notifError } = await supabase
        .from('notifications')
        .insert(notifications)

      if (notifError) {
        console.error('⚠️  Failed to create notifications:', notifError.message)
      } else {
        console.log(`📬 Created ${notifications.length} notifications`)
      }
    }

    // TODO: Send push notifications via APNs/FCM
    // For each user with notifications, fetch their push_tokens and send
    // This is stubbed for now - implement when push is ready

    console.log('✅ Post expiration completed successfully')

    return new Response(
      JSON.stringify({ 
        success: true,
        expired_count: postIds.length,
        notifications_sent: notifications.length,
        expired_post_ids: postIds
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200 
      }
    )

  } catch (error) {
    console.error('❌ Error in expire_posts function:', error)
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

/* 
 * DEPLOYMENT INSTRUCTIONS:
 * 
 * 1. Deploy function:
 *    supabase functions deploy expire_posts
 * 
 * 2. Set up cron trigger (via Supabase Dashboard > Database > Extensions > pg_cron):
 *    
 *    select cron.schedule(
 *      'expire-posts-every-5-minutes',
 *      '*/5 * * * *',  -- Every 5 minutes
 *      $$
 *      select net.http_post(
 *        url := 'https://duluhjkiqoahshxhiyqz.supabase.co/functions/v1/expire_posts',
 *        headers := '{"Authorization": "Bearer ' || current_setting('app.settings.service_role_key') || '"}'::jsonb
 *      ) as request_id;
 *      $$
 *    );
 * 
 * 3. Alternative: Call manually for testing:
 *    curl -X POST https://duluhjkiqoahshxhiyqz.supabase.co/functions/v1/expire_posts \
 *      -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY"
 */

