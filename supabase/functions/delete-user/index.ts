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

    // Prima cancella i dati del database collegati all'utente
    console.log(`🗑️ Cancellazione dati database per utente: ${userId}`)
    
    try {
      // Cancella dalla tabella users (questo cancellerà a cascata molte altre tabelle)
      const { error: dbError } = await supabaseAdmin
        .from('users')
        .delete()
        .eq('id', userId)
      
      if (dbError) {
        console.error('⚠️ Errore cancellazione database:', dbError)
        throw new Error('Database error deleting user')
      }
      
      console.log('✅ Dati database cancellati')
    } catch (dbErr) {
      console.error('❌ Errore database:', dbErr)
      throw new Error('Database error deleting user')
    }

    // Poi cancella l'utente dalla auth usando Service Role
    const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(userId)

    if (deleteError) {
      console.error('❌ Errore eliminazione auth:', deleteError)
      throw deleteError
    }

    console.log(`✅ Utente ${userId} eliminato con successo`)

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
