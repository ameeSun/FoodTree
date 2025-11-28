// =====================================================
// TreeBites Edge Function: analytics_daily
// =====================================================
// Runs daily to compute analytics summary
// Aggregates post metrics, organizer stats, and trends
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

    // Determine target date (yesterday)
    const targetDate = new Date()
    targetDate.setDate(targetDate.getDate() - 1)
    const dateStr = targetDate.toISOString().split('T')[0]

    console.log(`📊 Computing analytics for ${dateStr}`)

    // Check if we already have analytics for this date
    const { data: existing } = await supabase
      .from('analytics_daily_summary')
      .select('id')
      .eq('date', dateStr)
      .single()

    if (existing) {
      console.log('⚠️  Analytics already exist for this date, skipping')
      return new Response(
        JSON.stringify({ 
          success: true,
          message: 'Analytics already computed for this date',
          date: dateStr
        }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200 
        }
      )
    }

    const startOfDay = `${dateStr} 00:00:00`
    const endOfDay = `${dateStr} 23:59:59`

    // 1. Count posts created that day
    const { count: postsCreated, error: countError } = await supabase
      .from('food_posts')
      .select('*', { count: 'exact', head: true })
      .gte('created_at', startOfDay)
      .lte('created_at', endOfDay)

    if (countError) {
      throw new Error(`Failed to count posts: ${countError.message}`)
    }

    console.log(`📦 Posts created: ${postsCreated}`)

    // 2. Calculate average time to 'low' status
    const { data: lowPosts, error: lowError } = await supabase
      .from('food_posts')
      .select('created_at, updated_at, status')
      .gte('created_at', startOfDay)
      .lte('created_at', endOfDay)
      .eq('status', 'low')

    let avgMinutesToLow = null
    if (lowPosts && lowPosts.length > 0) {
      const times = lowPosts.map(p => {
        const created = new Date(p.created_at).getTime()
        const updated = new Date(p.updated_at).getTime()
        return (updated - created) / (1000 * 60) // minutes
      })
      avgMinutesToLow = times.reduce((a, b) => a + b, 0) / times.length
      console.log(`⏱️  Avg time to low: ${avgMinutesToLow.toFixed(2)} min`)
    }

    // 3. Calculate average time to 'gone' status
    const { data: gonePosts, error: goneError } = await supabase
      .from('food_posts')
      .select('created_at, updated_at, status')
      .gte('created_at', startOfDay)
      .lte('created_at', endOfDay)
      .eq('status', 'gone')

    let avgMinutesToGone = null
    if (gonePosts && gonePosts.length > 0) {
      const times = gonePosts.map(p => {
        const created = new Date(p.created_at).getTime()
        const updated = new Date(p.updated_at).getTime()
        return (updated - created) / (1000 * 60) // minutes
      })
      avgMinutesToGone = times.reduce((a, b) => a + b, 0) / times.length
      console.log(`⏱️  Avg time to gone: ${avgMinutesToGone.toFixed(2)} min`)
    }

    // 4. Find top organizers (by post count and total views)
    const { data: topOrganizers, error: orgError } = await supabase
      .from('food_posts')
      .select('creator_id, views_count, on_my_way_count')
      .gte('created_at', startOfDay)
      .lte('created_at', endOfDay)

    let topOrganizerIds: string[] = []
    if (topOrganizers && topOrganizers.length > 0) {
      // Aggregate by creator
      const organizerStats = new Map<string, { posts: number, views: number, engagement: number }>()
      
      for (const post of topOrganizers) {
        const current = organizerStats.get(post.creator_id) || { posts: 0, views: 0, engagement: 0 }
        organizerStats.set(post.creator_id, {
          posts: current.posts + 1,
          views: current.views + post.views_count,
          engagement: current.engagement + post.on_my_way_count
        })
      }

      // Sort by engagement score (posts * 10 + views + engagement * 5)
      const sorted = Array.from(organizerStats.entries())
        .map(([id, stats]) => ({
          id,
          score: stats.posts * 10 + stats.views + stats.engagement * 5
        }))
        .sort((a, b) => b.score - a.score)
        .slice(0, 5)

      topOrganizerIds = sorted.map(o => o.id)
      console.log(`👥 Top organizers: ${topOrganizerIds.length}`)
    }

    // 5. Additional metrics
    const { data: dayStats } = await supabase
      .from('food_posts')
      .select('quantity_estimate, views_count, on_my_way_count, saves_count, perishability, dietary')
      .gte('created_at', startOfDay)
      .lte('created_at', endOfDay)

    let additionalData = {}
    if (dayStats && dayStats.length > 0) {
      const totalQuantity = dayStats.reduce((sum, p) => sum + p.quantity_estimate, 0)
      const totalViews = dayStats.reduce((sum, p) => sum + p.views_count, 0)
      const totalOnMyWay = dayStats.reduce((sum, p) => sum + p.on_my_way_count, 0)
      const totalSaves = dayStats.reduce((sum, p) => sum + p.saves_count, 0)

      // Count dietary tags
      const dietaryCounts: Record<string, number> = {}
      dayStats.forEach(p => {
        if (p.dietary) {
          p.dietary.forEach((tag: string) => {
            dietaryCounts[tag] = (dietaryCounts[tag] || 0) + 1
          })
        }
      })

      // Count perishability levels
      const perishCounts: Record<string, number> = {
        low: 0,
        medium: 0,
        high: 0
      }
      dayStats.forEach(p => {
        if (p.perishability) {
          perishCounts[p.perishability] = (perishCounts[p.perishability] || 0) + 1
        }
      })

      additionalData = {
        total_quantity: totalQuantity,
        total_views: totalViews,
        total_on_my_way: totalOnMyWay,
        total_saves: totalSaves,
        avg_quantity: postsCreated ? (totalQuantity / postsCreated).toFixed(2) : 0,
        dietary_breakdown: dietaryCounts,
        perishability_breakdown: perishCounts,
        engagement_rate: totalViews > 0 ? ((totalOnMyWay / totalViews) * 100).toFixed(2) : 0
      }

      console.log(`📈 Additional metrics calculated`)
    }

    // 6. Insert summary
    const { data: inserted, error: insertError } = await supabase
      .from('analytics_daily_summary')
      .insert({
        date: dateStr,
        posts_created: postsCreated || 0,
        avg_minutes_to_low: avgMinutesToLow,
        avg_minutes_to_gone: avgMinutesToGone,
        top_organizer_ids: topOrganizerIds,
        data: additionalData
      })
      .select('id')
      .single()

    if (insertError) {
      throw new Error(`Failed to insert summary: ${insertError.message}`)
    }

    console.log(`✅ Analytics summary created: ${inserted.id}`)

    return new Response(
      JSON.stringify({ 
        success: true,
        date: dateStr,
        summary: {
          posts_created: postsCreated || 0,
          avg_minutes_to_low: avgMinutesToLow,
          avg_minutes_to_gone: avgMinutesToGone,
          top_organizer_count: topOrganizerIds.length,
          ...additionalData
        }
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200 
      }
    )

  } catch (error) {
    console.error('❌ Error in analytics_daily function:', error)
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
 *    supabase functions deploy analytics_daily
 * 
 * 2. Set up cron trigger (via Supabase Dashboard > Database > Extensions > pg_cron):
 *    
 *    select cron.schedule(
 *      'analytics-daily-at-midnight',
 *      '0 0 * * *',  // Daily at midnight UTC
 *      $$
 *      select net.http_post(
 *        url := 'https://duluhjkiqoahshxhiyqz.supabase.co/functions/v1/analytics_daily',
 *        headers := '{"Authorization": "Bearer ' || current_setting('app.settings.service_role_key') || '"}'::jsonb
 *      ) as request_id;
 *      $$
 *    );
 * 
 * 3. Alternative: Call manually for testing:
 *    curl -X POST https://duluhjkiqoahshxhiyqz.supabase.co/functions/v1/analytics_daily \
 *      -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY"
 */

