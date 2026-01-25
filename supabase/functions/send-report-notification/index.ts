// Edge Function per inviare email quando viene creata una segnalazione
// Invia 2 email:
// 1. All'utente che ha fatto la segnalazione
// 2. All'azienda segnalata (se ha dato consenso email)

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
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { reportId } = await req.json()
    
    if (!reportId) {
      throw new Error('reportId mancante')
    }

    console.log(`📋 Elaborazione segnalazione ID: ${reportId}`)

    // Get report data with user info
    const { data: report, error: reportError } = await supabase
      .from('company_reports')
      .select(`
        *,
        users:reported_by_user_id (
          id,
          first_name,
          last_name,
          email
        )
      `)
      .eq('id', reportId)
      .single()

    if (reportError) {
      console.error('❌ Errore recupero segnalazione:', reportError)
      throw reportError
    }

    if (!report) {
      throw new Error('Segnalazione non trovata')
    }

    const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')
    if (!RESEND_API_KEY) {
      throw new Error('RESEND_API_KEY non configurata')
    }

    const userName = `${report.users.first_name} ${report.users.last_name}`
    const userEmail = report.users.email

    // 📧 EMAIL 1: All'utente che ha fatto la segnalazione
    const userEmailHtml = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
      </head>
      <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
        <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; text-align: center; border-radius: 10px 10px 0 0;">
          <h1 style="color: white; margin: 0; font-size: 28px;">✅ Segnalazione Inviata</h1>
        </div>
        
        <div style="background: #f9fafb; padding: 30px; border-radius: 0 0 10px 10px;">
          <p style="font-size: 16px; margin-bottom: 20px;">Ciao <strong>${userName}</strong>,</p>
          
          <p>Grazie per aver segnalato <strong>${report.company_name}</strong> su CDM86!</p>
          
          <div style="background: white; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #10b981;">
            <h3 style="margin-top: 0; color: #10b981;">📋 Dettagli Segnalazione</h3>
            <p style="margin: 8px 0;"><strong>Azienda:</strong> ${report.company_name}</p>
            <p style="margin: 8px 0;"><strong>Tipo:</strong> ${report.company_type === 'company' ? 'Azienda' : 'Associazione'}</p>
            <p style="margin: 8px 0;"><strong>Contatto:</strong> ${report.contact_name}</p>
            <p style="margin: 8px 0;"><strong>Email:</strong> ${report.email}</p>
            <p style="margin: 8px 0;"><strong>Settore:</strong> ${report.sector}</p>
            <p style="margin: 8px 0;"><strong>Indirizzo:</strong> ${report.address}</p>
          </div>
          
          <div style="background: #eff6ff; padding: 15px; border-radius: 8px; margin: 20px 0;">
            <p style="margin: 0; color: #1e40af;">
              <strong>📌 Stato:</strong> In attesa di approvazione da parte dell'amministratore
            </p>
          </div>
          
          ${report.email_consent ? `
          <div style="background: #f0fdf4; padding: 15px; border-radius: 8px; margin: 20px 0;">
            <p style="margin: 0; color: #15803d;">
              ✅ Email di notifica inviata all'azienda
            </p>
          </div>
          ` : `
          <div style="background: #fef3c7; padding: 15px; border-radius: 8px; margin: 20px 0;">
            <p style="margin: 0; color: #92400e;">
              ⚠️ Email non inviata all'azienda (consenso non dato)
            </p>
          </div>
          `}
          
          <p style="margin-top: 30px;">Ti aggiorneremo quando la segnalazione verrà approvata!</p>
          
          <p style="margin-top: 20px; color: #64748b; font-size: 14px;">
            A presto,<br>
            <strong>Il Team CDM86</strong>
          </p>
        </div>
      </body>
      </html>
    `

    console.log(`📧 Invio email di conferma a: ${userEmail}`)
    
    const userEmailResponse = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${RESEND_API_KEY}`
      },
      body: JSON.stringify({
        from: 'CDM86 <noreply@cdm86.com>',
        to: [userEmail],
        subject: `✅ Segnalazione ricevuta - ${report.company_name}`,
        html: userEmailHtml
      })
    })

    const userEmailResult = await userEmailResponse.json()
    
    if (!userEmailResponse.ok) {
      console.error('❌ Errore invio email utente:', userEmailResult)
      throw new Error(`Errore invio email utente: ${JSON.stringify(userEmailResult)}`)
    }

    console.log('✅ Email utente inviata:', userEmailResult.id)

    // 📧 EMAIL 2: All'azienda segnalata (solo se ha dato consenso)
    let companyEmailResult = null
    
    if (report.email_consent && report.email) {
      const companyEmailHtml = `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
        </head>
        <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
          <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; text-align: center; border-radius: 10px 10px 0 0;">
            <h1 style="color: white; margin: 0; font-size: 28px;">🎯 Nuova Opportunità CDM86</h1>
          </div>
          
          <div style="background: #f9fafb; padding: 30px; border-radius: 0 0 10px 10px;">
            <p style="font-size: 16px; margin-bottom: 20px;">Gentile <strong>${report.contact_name}</strong>,</p>
            
            <p>Siamo lieti di informarvi che <strong>${report.company_name}</strong> è stata segnalata sulla piattaforma CDM86!</p>
            
            <div style="background: white; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #667eea;">
              <h3 style="margin-top: 0; color: #667eea;">👤 Segnalato da</h3>
              <p style="margin: 8px 0;"><strong>Nome:</strong> ${userName}</p>
              <p style="margin: 8px 0;"><strong>Codice referral:</strong> ${report.reported_by_referral_code}</p>
            </div>
            
            <div style="background: #eff6ff; padding: 20px; border-radius: 8px; margin: 20px 0;">
              <h3 style="margin-top: 0; color: #1e40af;">🎁 Cos'è CDM86?</h3>
              <p>CDM86 è una piattaforma che premia gli utenti per le loro segnalazioni e offre vantaggi esclusivi alle aziende partner.</p>
              
              <p style="margin-top: 15px;"><strong>Perché vi contatteremo:</strong></p>
              <ul style="margin: 10px 0; padding-left: 20px;">
                <li>Presentarvi i nostri servizi</li>
                <li>Discutere possibili collaborazioni</li>
                <li>Offrirvi l'accesso alla nostra rete di utenti</li>
              </ul>
            </div>
            
            ${report.preferred_call_time ? `
            <div style="background: #f0fdf4; padding: 15px; border-radius: 8px; margin: 20px 0;">
              <p style="margin: 0; color: #15803d;">
                <strong>📞 Orario preferito per essere contattati:</strong> ${report.preferred_call_time}
              </p>
            </div>
            ` : ''}
            
            <p style="margin-top: 30px;">Un nostro consulente vi contatterà a breve per maggiori informazioni.</p>
            
            <div style="text-align: center; margin: 30px 0;">
              <a href="https://cdm86.com" style="display: inline-block; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 15px 30px; text-decoration: none; border-radius: 8px; font-weight: bold;">
                Scopri CDM86
              </a>
            </div>
            
            <p style="margin-top: 20px; color: #64748b; font-size: 14px;">
              Cordiali saluti,<br>
              <strong>Il Team CDM86</strong>
            </p>
            
            <hr style="border: none; border-top: 1px solid #e5e7eb; margin: 30px 0;">
            
            <p style="color: #9ca3af; font-size: 12px; margin: 0;">
              Hai ricevuto questa email perché la tua azienda è stata segnalata su CDM86.
              Se non desideri essere contattato, ignora questa email.
            </p>
          </div>
        </body>
        </html>
      `

      console.log(`📧 Invio email di notifica a: ${report.email}`)
      
      const companyEmailResponse = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${RESEND_API_KEY}`
        },
        body: JSON.stringify({
          from: 'CDM86 <noreply@cdm86.com>',
          to: [report.email],
          subject: `🎯 ${report.company_name} - Nuova opportunità CDM86`,
          html: companyEmailHtml,
          reply_to: 'info@cdm86.com'
        })
      })

      companyEmailResult = await companyEmailResponse.json()
      
      if (!companyEmailResponse.ok) {
        console.error('❌ Errore invio email azienda:', companyEmailResult)
        // Non blocchiamo l'esecuzione se fallisce l'email all'azienda
      } else {
        console.log('✅ Email azienda inviata:', companyEmailResult.id)
      }
    } else {
      console.log('⚠️ Email azienda non inviata (consenso non dato o email mancante)')
    }

    return new Response(
      JSON.stringify({
        success: true,
        userEmail: userEmailResult.id,
        companyEmail: companyEmailResult?.id || null,
        message: 'Email inviate con successo'
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200 
      }
    )

  } catch (error) {
    console.error('❌ Errore:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500 
      }
    )
  }
})
