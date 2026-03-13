// Supabase Edge Function per creare utenti normali dall'admin panel
// Deploy: supabase functions deploy create-admin-user

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Client con service role per operazioni admin
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { autoRefreshToken: false, persistSession: false } }
    )

    // Verifica che la richiesta venga da un admin autenticato
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) throw new Error('Missing authorization header')

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? ''
    )

    const { data: { user }, error: userError } = await supabaseClient.auth.getUser(
      authHeader.replace('Bearer ', '')
    )

    if (userError || !user) throw new Error('Unauthorized')

    // Verifica che sia admin
    const { data: callerData, error: roleError } = await supabaseAdmin
      .from('users')
      .select('role')
      .eq('auth_user_id', user.id)
      .single()

    if (roleError || callerData?.role !== 'admin') {
      throw new Error('Admin privileges required')
    }

    // Leggi i dati dalla richiesta
    const { email, password, firstName, lastName, phone, referralCode } = await req.json()

    if (!email || !password) throw new Error('Missing required fields: email, password')

    // Cerca referrer se codice fornito
    let referrerId = null
    if (referralCode) {
      const { data: referrer } = await supabaseAdmin
        .from('users')
        .select('id')
        .eq('referral_code', referralCode)
        .single()
      if (referrer) referrerId = referrer.id
    }

    // Crea utente auth con service role
    const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
    })

    if (authError) throw authError

    const authUserId = authData.user.id

    // Crea record in public.users
    const { error: insertError } = await supabaseAdmin
      .from('users')
      .insert({
        auth_user_id: authUserId,
        email,
        first_name: firstName || '',
        last_name: lastName || '',
        phone: phone || null,
        role: 'user',
        points: 100,
        referred_by_id: referrerId || null,
      })

    if (insertError) {
      // Rollback: elimina utente auth se insert fallisce
      await supabaseAdmin.auth.admin.deleteUser(authUserId)
      throw insertError
    }

    // Assegna punti al referrer
    if (referrerId) {
      await supabaseAdmin.rpc('add_points_to_user', {
        p_user_id: referrerId,
        p_points: 50,
        p_description: `Bonus referral per invito di ${email}`
      })
    }

    return new Response(
      JSON.stringify({ success: true, userId: authUserId, referralApplied: !!referrerId }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )

  } catch (error) {
    console.error('create-admin-user error:', error)
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }
})
