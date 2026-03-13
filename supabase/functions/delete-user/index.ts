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
      .eq('auth_user_id', user.id)
      .single()

    if (userError || userData?.role !== 'admin') {
      throw new Error('Permessi insufficienti: solo admin può eliminare utenti')
    }

    // Verifica se è un utente normale o un'organizzazione
    console.log(`🔍 Verifica tipo account: ${userId}`)
    
    const { data: userRecord } = await supabaseAdmin
      .from('users')
      .select('id, auth_user_id')
      .eq('auth_user_id', userId)
      .single()
    
    const { data: orgRecord } = await supabaseAdmin
      .from('organizations')
      .select('id, auth_user_id')
      .eq('auth_user_id', userId)
      .single()

    // STEP 1: Gestisci referral e punti PRIMA di cancellare l'utente
    if (userRecord) {
      console.log('🔗 Controllo referral collegati...')
      
      // Cerca se questo utente è stato invitato da qualcuno
      const { data: referralData } = await supabaseAdmin
        .from('referrals')
        .select('id, referrer_id, points_earned_referrer, status')
        .eq('referred_user_id', userId)
        .maybeSingle()

      if (referralData && referralData.points_earned_referrer > 0) {
        // Avvolto in try/catch: se fallisce non blocca la cancellazione
        try {
          console.log(`💰 Trovato referral con ${referralData.points_earned_referrer} punti guadagnati`)
          const pointsToRemove = -Math.abs(referralData.points_earned_referrer)

          // Aggiorna il saldo punti del referrer (colonna 'points')
          const { data: currentBalance } = await supabaseAdmin
            .from('users')
            .select('points')
            .eq('id', referralData.referrer_id)
            .maybeSingle()

          if (currentBalance) {
            const newBalance = Math.max(0, (currentBalance.points || 0) + pointsToRemove)
            await supabaseAdmin
              .from('users')
              .update({ points: newBalance })
              .eq('id', referralData.referrer_id)
            console.log(`✅ Punti referrer aggiornati: ${currentBalance.points} → ${newBalance}`)
          }
        } catch (pointsErr) {
          console.error('⚠️ Errore gestione punti referral (non bloccante):', pointsErr)
        }
      } else {
        console.log('ℹ️ Nessun referral con punti trovato per questo utente')
      }
    }

    // STEP 2: Cancella commissioni collegate (non bloccante)
    if (userRecord) {
      try {
        const { error: c1 } = await supabaseAdmin.from('commissions').delete().eq('organization_id', userRecord.id)
        if (c1) console.error('⚠️ commissions organization_id:', c1.message)
        const { error: c2 } = await supabaseAdmin.from('commissions').delete().eq('referred_user_id', userRecord.id)
        if (c2) console.error('⚠️ commissions referred_user_id:', c2.message)
        const { error: c3 } = await supabaseAdmin.from('commissions').delete().eq('referred_organization_id', userRecord.id)
        if (c3) console.error('⚠️ commissions referred_organization_id:', c3.message)
        console.log('✅ Commissioni cancellate')
      } catch (commErr) {
        console.error('⚠️ Errore cancellazione commissioni (non bloccante):', commErr)
      }
    }

    // STEP 3: Cancella i dati del database
    console.log(`🗑️ Cancellazione dati database per: ${userId}`)
    
    try {
      if (userRecord) {
        // È un utente normale - cancella prima i dati collegati, poi l'utente
        console.log('👤 Cancellazione utente normale...')

        // Cancella referrals collegati (non bloccante)
        const { error: refErr1 } = await supabaseAdmin.from('referrals').delete().eq('referred_user_id', userRecord.id)
        if (refErr1) console.error('⚠️ referrals referred_user_id:', refErr1.message)
        const { error: refErr2 } = await supabaseAdmin.from('referrals').delete().eq('referrer_id', userRecord.id)
        if (refErr2) console.error('⚠️ referrals referrer_id:', refErr2.message)
        const { error: favErr } = await supabaseAdmin.from('favorites').delete().eq('user_id', userRecord.id)
        if (favErr) console.error('⚠️ favorites user_id:', favErr.message)

        const { error: dbError } = await supabaseAdmin
          .from('users')
          .delete()
          .eq('auth_user_id', userId)
        
        if (dbError) {
          console.error('⚠️ Errore cancellazione users:', dbError)
          throw new Error(`Database error: ${dbError.message}`)
        }
      } else if (orgRecord) {
        // È un'organizzazione - cancella tutto in cascata
        console.log('🏢 Cancellazione organizzazione e tutti i dati collegati...')
        const orgId = orgRecord.id

        // 1. Cancella organization_pages (card + landing)
        const { error: pagesError } = await supabaseAdmin
          .from('organization_pages')
          .delete()
          .eq('organization_id', orgId)
        if (pagesError) console.error('⚠️ Errore cancellazione organization_pages:', pagesError)
        else console.log('✅ organization_pages cancellate')

        // 2. Cancella promotions collegate
        const { error: promoError } = await supabaseAdmin
          .from('promotions')
          .delete()
          .eq('organization_id', orgId)
        if (promoError) console.error('⚠️ Errore cancellazione promotions:', promoError)
        else console.log('✅ promotions cancellate')

        // 3. Cancella commissioni collegate all'organizzazione
        const { error: commOrgError } = await supabaseAdmin
          .from('commissions')
          .delete()
          .eq('organization_id', orgId)
        if (commOrgError) console.error('⚠️ Errore cancellazione commissioni org:', commOrgError)

        // 4. Cancella referrals collegati
        const { error: refError } = await supabaseAdmin
          .from('referrals')
          .delete()
          .eq('referred_organization_id', orgId)
        if (refError) console.error('⚠️ Errore cancellazione referrals org:', refError)

        // 5. Cancella favorites collegati
        const { error: favError } = await supabaseAdmin
          .from('favorites')
          .delete()
          .eq('organization_id', orgId)
        if (favError) console.error('⚠️ Errore cancellazione favorites org:', favError)

        // 6. Infine cancella l'organizzazione
        const { error: orgError } = await supabaseAdmin
          .from('organizations')
          .delete()
          .eq('id', orgId)
        if (orgError) {
          console.error('⚠️ Errore cancellazione organization:', orgError)
          throw new Error(`Database error: ${orgError.message}`)
        }
        console.log('✅ Organizzazione e tutti i dati collegati cancellati')
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
