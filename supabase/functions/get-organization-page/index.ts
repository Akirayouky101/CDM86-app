import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const url = new URL(req.url)
    const slug = url.searchParams.get('slug')

    if (!slug) {
      return new Response(JSON.stringify({ error: 'slug parameter is required' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      })
    }

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? ''
    )

    // Get published page with organization data
    const { data: page, error } = await supabaseClient
      .from('organization_pages')
      .select(`
        *,
        organization:organizations(
          id,
          name,
          description,
          logo_url,
          cover_url,
          website,
          social_links,
          email,
          phone,
          city,
          referral_code
        )
      `)
      .eq('slug', slug)
      .eq('status', 'published')
      .single()

    if (error || !page) {
      return new Response(
        JSON.stringify({ error: 'Page not found or not published' }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 404,
        }
      )
    }

    // Increment views count
    await supabaseClient
      .from('organization_pages')
      .update({
        views_count: (page.views_count || 0) + 1,
        last_viewed_at: new Date().toISOString(),
      })
      .eq('id', page.id)

    return new Response(JSON.stringify({ success: true, page }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })
  } catch (error) {
    console.error('Error loading page:', error)
    return new Response(
      JSON.stringify({ error: error.message || 'Internal server error' }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    )
  }
})
