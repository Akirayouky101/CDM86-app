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
        console.log(`💰 Trovato referral con ${referralData.points_earned_referrer} punti guadagnati`)
        console.log(`👤 Referrer: ${referralData.referrer_id}`)

        // Ottieni info dell'utente eliminato per il messaggio
        const { data: deletedUserInfo } = await supabaseAdmin
          .from('users')
          .select('email, first_name, last_name')
          .eq('auth_user_id', userId)
          .maybeSingle()

        const deletedUserName = deletedUserInfo 
          ? `${deletedUserInfo.first_name || ''} ${deletedUserInfo.last_name || ''}`.trim() || deletedUserInfo.email
          : 'Utente eliminato'

        // Rimuovi i punti dal referrer
        const pointsToRemove = -Math.abs(referralData.points_earned_referrer)
        
        console.log(`⚖️ Rimozione ${Math.abs(pointsToRemove)} punti da referrer...`)
        
        // Crea transazione di rimozione punti
        const { error: transactionError } = await supabaseAdmin
          .from('points_transactions')
          .insert({
            user_id: referralData.referrer_id,
            points: pointsToRemove,
            transaction_type: 'admin_adjustment',
            reference_id: referralData.id,
            description: `Rimossi punti per eliminazione utente invitato: ${deletedUserName}`
          })

        if (transactionError) {
          console.error('⚠️ Errore creazione transazione rimozione punti:', transactionError)
        } else {
          console.log('✅ Transazione di rimozione punti creata')
        }

        // Aggiorna il saldo punti del referrer
        const { data: currentBalance } = await supabaseAdmin
          .from('users')
          .select('total_points')
          .eq('id', referralData.referrer_id)
          .maybeSingle()

        if (currentBalance) {
          const newBalance = Math.max(0, currentBalance.total_points + pointsToRemove)
          
          const { error: updateError } = await supabaseAdmin
            .from('users')
            .update({ total_points: newBalance })
            .eq('id', referralData.referrer_id)

          if (updateError) {
            console.error('⚠️ Errore aggiornamento saldo:', updateError)
          } else {
            console.log(`✅ Saldo aggiornato: ${currentBalance.total_points} → ${newBalance}`)
          }
        }
      } else {
        console.log('ℹ️ Nessun referral con punti trovato per questo utente')
      }
    }

    // STEP 2: Cancella commissioni collegate
    if (userRecord) {
      console.log('💰 Cancellazione commissioni collegate...')
      
      // Cancella commissioni dove l'utente è organization_id
      const { error: commError1 } = await supabaseAdmin
        .from('commissions')
        .delete()
        .eq('organization_id', userRecord.id)
      
      if (commError1) {
        console.error('⚠️ Errore cancellazione commissioni (organization_id):', commError1)
      }
      
      // Cancella commissioni dove l'utente è referred_user_id
      const { error: commError2 } = await supabaseAdmin
        .from('commissions')
        .delete()
        .eq('referred_user_id', userRecord.id)
      
      if (commError2) {
        console.error('⚠️ Errore cancellazione commissioni (referred_user_id):', commError2)
      }
      
      // Cancella commissioni dove l'utente è referred_organization_id
      const { error: commError3 } = await supabaseAdmin
        .from('commissions')
        .delete()
        .eq('referred_organization_id', userRecord.id)
      
      if (commError3) {
        console.error('⚠️ Errore cancellazione commissioni (referred_organization_id):', commError3)
      }
      
      console.log('✅ Commissioni cancellate')
    }

    // STEP 3: Cancella i dati del database
    console.log(`🗑️ Cancellazione dati database per: ${userId}`)
    
    try {
      if (userRecord) {
        // È un utente normale - cancella dalla tabella users
        console.log('👤 Cancellazione utente normale...')
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
