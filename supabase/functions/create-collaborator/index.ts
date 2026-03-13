import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { autoRefreshToken: false, persistSession: false } }
    )

    const { email, password, firstName, lastName, phone, referredByCode } = await req.json()

    if (!email || !password || !firstName || !lastName) {
      return new Response(JSON.stringify({ error: 'Campi obbligatori mancanti' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // 1. Verifica che email non sia già in collaborators
    const { data: existing } = await supabaseAdmin
      .from('collaborators')
      .select('id')
      .eq('email', email)
      .maybeSingle()

    if (existing) {
      return new Response(JSON.stringify({ error: 'Email già registrata come collaboratore' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // 2. Crea auth user
    const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: { first_name: firstName, last_name: lastName, account_type: 'collaborator' }
    })

    if (authError) {
      return new Response(JSON.stringify({ error: authError.message }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // 3. Genera referral code univoco
    const baseCode = (firstName.slice(0, 2) + lastName.slice(0, 2)).toUpperCase()
    const randomSuffix = Math.random().toString(36).substring(2, 6).toUpperCase()
    const referralCode = `C-${baseCode}${randomSuffix}`

    // 4. Trova chi ha invitato (se presente)
    let referredById = null
    if (referredByCode) {
      const { data: referrer } = await supabaseAdmin
        .from('collaborators')
        .select('id')
        .eq('referral_code', referredByCode.trim().toUpperCase())
        .maybeSingle()
      if (referrer) referredById = referrer.id
    }

    // 5. Inserisce in tabella collaborators
    const { data: collab, error: insertError } = await supabaseAdmin
      .from('collaborators')
      .insert({
        auth_user_id: authData.user.id,
        email,
        first_name: firstName,
        last_name: lastName,
        phone: phone || null,
        referral_code: referralCode,
        referred_by_id: referredById,
        status: 'pending',
        registered_at: new Date().toISOString()
      })
      .select()
      .single()

    if (insertError) {
      // Rollback auth user
      await supabaseAdmin.auth.admin.deleteUser(authData.user.id)
      return new Response(JSON.stringify({ error: insertError.message }), {
        status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    console.log('✅ Collaboratore registrato:', collab.id, email)

    return new Response(JSON.stringify({ success: true, collaboratorId: collab.id }), {
      status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })

  } catch (err) {
    console.error('Unexpected error:', err)
    return new Response(JSON.stringify({ error: (err as Error).message || 'Errore interno' }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})
