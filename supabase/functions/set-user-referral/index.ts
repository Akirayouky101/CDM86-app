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
    const { userId, referrerId, organizationId } = await req.json()

    if (!userId) {
      throw new Error('userId è richiesto')
    }

    console.log('🔄 Aggiornamento referral per user:', userId)
    console.log('👤 Referrer ID:', referrerId)
    console.log('🏢 Organization ID:', organizationId)

    // Crea client Supabase con Service Role Key
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
    }
    
    if (organizationId) {
      updateData.referred_by_organization_id = organizationId
    }

    const { error: updateError } = await supabaseAdmin
      .from('users')
      .update(updateData)
      .eq('id', userId)

    if (updateError) {
      console.error('❌ Errore aggiornamento:', updateError)
      throw updateError
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
