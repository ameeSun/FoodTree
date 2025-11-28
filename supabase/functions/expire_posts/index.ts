// =====================================================
// TreeBites Edge Function: expire_posts
// =====================================================
// Runs on a schedule (every 5 minutes via cron)
// Automatically deletes posts that have reached 0 minutes remaining
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

    console.log('🕐 Starting post deletion check...')

    // Find posts that should be deleted (time has reached 0 or passed)
    // Include posts that are expired or have reached their expiration time
    const now = new Date().toISOString()
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
      .lte('expires_at', now)  // Changed from .lt to .lte to include posts exactly at expiration
      .in('status', ['available', 'low', 'expired'])  // Also include already expired posts

    if (fetchError) {
      throw new Error(`Failed to fetch expired posts: ${fetchError.message}`)
    }

    if (!expiredPosts || expiredPosts.length === 0) {
      console.log('✅ No posts to delete')
      return new Response(
        JSON.stringify({ 
          success: true, 
          deleted_count: 0,
          message: 'No posts to delete'
        }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200 
        }
      )
    }

    console.log(`📦 Found ${expiredPosts.length} posts to delete`)

    const postIds = expiredPosts.map(p => p.id)

    // Create notifications for each post BEFORE deleting (so we can reference post_id)
    const notifications = []

    for (const post of expiredPosts) {
      // Notification to creator
      notifications.push({
        user_id: post.creator_id,
        type: 'post_expired',
        title: 'Post Deleted',
        body: `${post.title} at ${post.building_name} has been deleted`,
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
              body: `${post.title} has been deleted`,
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
              title: 'Saved Post Deleted',
              body: `${post.title} has been deleted`,
              post_id: post.id,
              data: {}
            })
          }
        }
      }
    }

    // Insert all notifications BEFORE deleting posts
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

    // Delete posts (CASCADE will automatically delete related records)
    const { error: deleteError } = await supabase
      .from('food_posts')
      .delete()
      .in('id', postIds)

    if (deleteError) {
      throw new Error(`Failed to delete posts: ${deleteError.message}`)
    }

    console.log(`✅ Deleted ${postIds.length} posts`)

    // TODO: Send push notifications via APNs/FCM
    // For each user with notifications, fetch their push_tokens and send
    // This is stubbed for now - implement when push is ready

    console.log('✅ Post deletion completed successfully')

    return new Response(
      JSON.stringify({ 
        success: true,
        deleted_count: postIds.length,
        notifications_sent: notifications.length,
        deleted_post_ids: postIds
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
 *      '0,5,10,15,20,25,30,35,40,45,50,55 * * * *',  // Every 5 minutes
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

