// Edge Function per eliminare un utente (solo admin)
// Usa Service Role Key per avere i permessi necessari

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
    // Crea client Supabase con Service Role Key (permessi admin)
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

    const { userId } = await req.json()
    
    if (!userId) {
      throw new Error('userId è richiesto')
    }

    console.log(`🗑️ Eliminazione utente: ${userId}`)

    // Verifica che l'utente richiedente sia admin
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      throw new Error('Authorization header mancante')
    }

    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabaseAdmin.auth.getUser(token)
    
    if (authError || !user) {
      throw new Error('Utente non autenticato')
    }

    // Verifica che sia admin
    const { data: userData, error: userError } = await supabaseAdmin
      .from('users')
      .select('role')
      .eq('id', user.id)
      .single()

    if (userError || userData?.role !== 'admin') {
      throw new Error('Permessi insufficienti: solo admin può eliminare utenti')
    }

    // Verifica se è un utente normale o un'organizzazione
    console.log(`🔍 Verifica tipo account: ${userId}`)
    
    const { data: userRecord } = await supabaseAdmin
      .from('users')
      .select('id')
      .eq('id', userId)
      .single()
    
    const { data: orgRecord } = await supabaseAdmin
      .from('organizations')
      .select('id, auth_user_id')
      .eq('auth_user_id', userId)
      .single()

    // Prima cancella i dati del database
    console.log(`🗑️ Cancellazione dati database per: ${userId}`)
    
    try {
      if (userRecord) {
        // È un utente normale - cancella dalla tabella users
        console.log('👤 Cancellazione utente normale...')
        const { error: dbError } = await supabaseAdmin
          .from('users')
          .delete()
          .eq('id', userId)
        
        if (dbError) {
          console.error('⚠️ Errore cancellazione users:', dbError)
          throw new Error(`Database error: ${dbError.message}`)
        }
      } else if (orgRecord) {
        // È un'organizzazione - cancella dalla tabella organizations
        console.log('🏢 Cancellazione organizzazione...')
        const { error: orgError } = await supabaseAdmin
          .from('organizations')
          .delete()
          .eq('auth_user_id', userId)
        
        if (orgError) {
          console.error('⚠️ Errore cancellazione organization:', orgError)
          throw new Error(`Database error: ${orgError.message}`)
        }
      } else {
        console.log('⚠️ Nessun record trovato nel database, procedo solo con auth')
      }
      
      console.log('✅ Dati database cancellati')
    } catch (dbErr) {
      console.error('❌ Errore database:', dbErr)
      throw dbErr
    }

    // Poi cancella l'utente dalla auth usando Service Role
    console.log(`🔐 Cancellazione account auth: ${userId}`)
    const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(userId)

    if (deleteError) {
      console.error('❌ Errore eliminazione auth:', deleteError)
      throw deleteError
    }

    console.log(`✅ Account ${userId} eliminato con successo`)

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Utente eliminato con successo'
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
        error: error.message || 'Errore sconosciuto'
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500 
      }
    )
  }
})
