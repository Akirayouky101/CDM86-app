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
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    // Get authenticated user
    const {
      data: { user },
    } = await supabaseClient.auth.getUser()

    if (!user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 401,
      })
    }

    // Get organization for this user
    const { data: organization, error: orgError } = await supabaseClient
      .from('organizations')
      .select('id, name')
      .eq('user_id', user.id)
      .single()

    if (orgError || !organization) {
      return new Response(
        JSON.stringify({ error: 'Organization not found for this user' }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 404,
        }
      )
    }

    const body = await req.json()
    const { page_data, page_title, page_description, meta_image, status } = body

    if (!page_data) {
      return new Response(JSON.stringify({ error: 'page_data is required' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      })
    }

    // Generate slug from organization name
    const { data: slugData, error: slugError } = await supabaseClient.rpc(
      'generate_organization_slug',
      { org_name: organization.name }
    )

    if (slugError) {
      console.error('Error generating slug:', slugError)
      return new Response(JSON.stringify({ error: 'Failed to generate slug' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      })
    }

    const slug = slugData

    // Check if page already exists for this organization
    const { data: existingPage } = await supabaseClient
      .from('organization_pages')
      .select('id')
      .eq('organization_id', organization.id)
      .maybeSingle()

    let result

    if (existingPage) {
      // Update existing page
      const { data, error } = await supabaseClient
        .from('organization_pages')
        .update({
          page_data,
          page_title: page_title || organization.name,
          page_description: page_description || '',
          meta_image: meta_image || null,
          status: status || 'draft',
        })
        .eq('id', existingPage.id)
        .select()
        .single()

      if (error) throw error
      result = data
    } else {
      // Create new page
      const { data, error } = await supabaseClient
        .from('organization_pages')
        .insert({
          organization_id: organization.id,
          slug,
          page_data,
          page_title: page_title || organization.name,
          page_description: page_description || '',
          meta_image: meta_image || null,
          status: status || 'draft',
        })
        .select()
        .single()

      if (error) throw error
      result = data
    }

    return new Response(
      JSON.stringify({
        success: true,
        page: result,
        public_url: `/azienda/${result.slug}`,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )
  } catch (error) {
    console.error('Error saving page:', error)
    return new Response(
      JSON.stringify({ error: error.message || 'Internal server error' }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    )
  }
})
