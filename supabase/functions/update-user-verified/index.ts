// Edge Function: aggiorna is_verified di un utente (solo admin)
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
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { autoRefreshToken: false, persistSession: false } }
    )

    // Verifica che il chiamante sia admin
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) throw new Error('Authorization header mancante')

    const { data: { user }, error: authError } = await supabaseAdmin.auth.getUser(
      authHeader.replace('Bearer ', '')
    )
    if (authError || !user) throw new Error('Non autenticato')

    const { data: callerData } = await supabaseAdmin
      .from('users')
      .select('role')
      .eq('auth_user_id', user.id)
      .single()

    if (callerData?.role !== 'admin') throw new Error('Solo admin può verificare utenti')

    const { userId, isVerified } = await req.json()

    if (!userId) throw new Error('userId obbligatorio')

    const { error } = await supabaseAdmin
      .from('users')
      .update({ is_verified: isVerified })
      .eq('id', userId)

    if (error) throw error

    console.log(`✅ Utente ${userId} is_verified=${isVerified}`)

    return new Response(
      JSON.stringify({ success: true }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )
  } catch (error) {
    console.error('❌ update-user-verified:', error)
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : 'Errore sconosciuto' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
    )
  }
})
