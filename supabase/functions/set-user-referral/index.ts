import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
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
    // Verifica JWT del utente
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      throw new Error('Missing authorization header')
    }

    // Crea client per verificare il JWT
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: authHeader }
        }
      }
    )

    // Verifica che il token sia valido
    const { data: { user }, error: authError } = await supabaseClient.auth.getUser()
    
    if (authError || !user) {
      console.error('❌ Auth error:', authError)
      return new Response(
        JSON.stringify({ 
          code: 401,
          message: 'Invalid JWT' 
        }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 401 
        }
      )
    }

    const { userId, referrerId, organizationId, collaboratorId, referralType } = await req.json()

    if (!userId) {
      throw new Error('userId è richiesto')
    }

    // Verifica che l'utente stia aggiornando il proprio profilo
    if (userId !== user.id) {
      throw new Error('Non puoi aggiornare il profilo di un altro utente')
    }

    console.log('🔄 Aggiornamento referral per user:', userId)
    console.log('👤 Referrer ID:', referrerId)
    console.log('🏢 Organization ID:', organizationId)
    console.log('🤝 Collaborator ID:', collaboratorId)
    console.log('📋 Referral Type:', referralType)

    // Crea client Supabase con Service Role Key per bypassare RLS
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

    // Aggiorna il record utente con il referral
    const updateData: any = {}
    
    if (referrerId) {
      updateData.referred_by_id = referrerId
      updateData.referral_type = 'user'
    }
    
    if (organizationId) {
      updateData.referred_by_organization_id = organizationId
      // referralType può essere 'org_employee' o 'org_external'
      updateData.referral_type = referralType || 'org_employee'
    }

    if (collaboratorId) {
      updateData.referred_by_collaborator_id = collaboratorId
      updateData.referral_type = 'collaborator'
    }

    const { error: updateError } = await supabaseAdmin
      .from('users')
      .update(updateData)
      .eq('auth_user_id', userId)  // Usa auth_user_id invece di id

    if (updateError) {
      console.error('❌ Errore aggiornamento:', updateError)
      throw updateError
    }

    // Se il referral è di un collaboratore, incrementa il contatore users_count
    if (collaboratorId) {
      const { error: incrError } = await supabaseAdmin.rpc('increment_collaborator_users_count', {
        collab_id: collaboratorId
      })
      if (incrError) {
        // Non blocchiamo la registrazione per questo errore, ma lo logghiamo
        console.error('⚠️ Errore incremento users_count collaboratore:', incrError)
      }
    }

    console.log('✅ Referral aggiornato con successo')

    return new Response(
      JSON.stringify({ 
        success: true,
        message: 'Referral aggiornato con successo'
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200 
      }
    )

  } catch (error) {
    console.error('❌ Errore:', error)
    return new Response(
      JSON.stringify({ 
        success: false,
        error: error.message 
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400 
      }
    )
  }
})
