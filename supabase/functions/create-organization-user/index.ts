// Supabase Edge Function per creare utenti organizzazione
// Deploy: supabase functions deploy create-organization-user

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Crea client Supabase con service role (ha privilegi admin)
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false
        }
      }
    )

    // Verifica che la richiesta venga da un admin autenticato
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      throw new Error('Missing authorization header')
    }

    // Verifica il token JWT dell'admin
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? ''
    )
    
    const { data: { user }, error: userError } = await supabaseClient.auth.getUser(
      authHeader.replace('Bearer ', '')
    )
    
    if (userError || !user) {
      throw new Error('Unauthorized')
    }

    // Verifica che sia un admin
    const { data: userData, error: roleError } = await supabaseAdmin
      .from('users')
      .select('role')
      .eq('id', user.id)
      .single()

    if (roleError || userData?.role !== 'admin') {
      throw new Error('Admin privileges required')
    }

    // Leggi i dati dalla richiesta
    const { email, password, organizationId, organizationName, organizationType } = await req.json()

    if (!email || !password || !organizationId) {
      throw new Error('Missing required fields: email, password, organizationId')
    }

    // Crea l'utente auth
    const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email: email,
      password: password,
      email_confirm: true, // Auto-conferma email
      user_metadata: {
        name: organizationName,
        role: 'organization',
        organization_id: organizationId,
        organization_type: organizationType || 'company'
      }
    })

    if (authError) {
      console.error('Auth error:', authError)
      throw authError
    }

    // Aggiorna la tabella organizations con l'user_id
    const { error: updateError } = await supabaseAdmin
      .from('organizations')
      .update({ user_id: authData.user.id })
      .eq('id', organizationId)

    if (updateError) {
      console.error('Update error:', updateError)
      // Non blocchiamo, l'utente è stato creato
    }

    return new Response(
      JSON.stringify({
        success: true,
        user: authData.user,
        message: 'Organization user created successfully'
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )

  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    )
  }
})
