// Edge Function per inviare email quando cambia lo stato di una segnalazione
// Stati: contacted, approved, rejected

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

    const { reportId, newStatus } = await req.json()
    
    if (!reportId || !newStatus) {
      throw new Error('reportId e newStatus sono richiesti')
    }

    console.log(`📋 Aggiornamento stato segnalazione ${reportId} → ${newStatus}`)

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

    if (reportError || !report) {
      throw new Error('Segnalazione non trovata')
    }

    const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')
    if (!RESEND_API_KEY) {
      throw new Error('RESEND_API_KEY non configurata')
    }

    const userName = `${report.users.first_name} ${report.users.last_name}`
    const userEmail = report.users.email

    let userEmailHtml = ''
    let companyEmailHtml = ''
    let userSubject = ''
    let companySubject = ''

    // ========================================
    // STATO: CONTATTATA
    // ========================================
    if (newStatus === 'contacted') {
      
      // Email all'UTENTE
      userSubject = `📞 ${report.company_name} è stata contattata!`
      userEmailHtml = `
        <!DOCTYPE html>
        <html>
        <head><meta charset="UTF-8"></head>
        <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
          <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; text-align: center; border-radius: 10px 10px 0 0;">
            <h1 style="color: white; margin: 0; font-size: 28px;">📞 Azienda Contattata</h1>
          </div>
          
          <div style="background: #f9fafb; padding: 30px; border-radius: 0 0 10px 10px;">
            <p>Ciao <strong>${userName}</strong>,</p>
            
            <p>Abbiamo contattato <strong>${report.company_name}</strong> che hai segnalato!</p>
            
            <div style="background: white; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #10b981;">
              <h3 style="margin-top: 0; color: #10b981;">✅ Stato Aggiornato</h3>
              <p style="margin: 8px 0;"><strong>Azienda:</strong> ${report.company_name}</p>
              <p style="margin: 8px 0;"><strong>Stato:</strong> Contattata</p>
            </div>
            
            <p>Ti terremo aggiornato sugli sviluppi!</p>
            
            <p style="margin-top: 30px; color: #64748b; font-size: 14px;">
              Grazie per il tuo contributo,<br>
              <strong>Il Team CDM86</strong>
            </p>
          </div>
        </body>
        </html>
      `

      // Email all'AZIENDA
      companySubject = `Grazie per il contatto - CDM86`
      companyEmailHtml = `
        <!DOCTYPE html>
        <html>
        <head><meta charset="UTF-8"></head>
        <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
          <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; text-align: center; border-radius: 10px 10px 0 0;">
            <h1 style="color: white; margin: 0; font-size: 28px;">🤝 Grazie per il contatto</h1>
          </div>
          
          <div style="background: #f9fafb; padding: 30px; border-radius: 0 0 10px 10px;">
            <p>Gentile <strong>${report.contact_name}</strong>,</p>
            
            <p>Grazie per aver risposto al nostro contatto riguardo <strong>${report.company_name}</strong>.</p>
            
            <div style="background: white; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #667eea;">
              <h3 style="margin-top: 0; color: #667eea;">📞 I Nostri Contatti</h3>
              <p style="margin: 8px 0;"><strong>Email:</strong> web@cdm86.it</p>
              <p style="margin: 8px 0;"><strong>Sito:</strong> www.cdm86.it</p>
            </div>
            
            <p>Restiamo a disposizione per qualsiasi informazione.</p>
            
            <p style="margin-top: 30px; color: #64748b; font-size: 14px;">
              Cordiali saluti,<br>
              <strong>Il Team CDM86</strong>
            </p>
          </div>
        </body>
        </html>
      `
    }

    // ========================================
    // STATO: APPROVATA
    // ========================================
    else if (newStatus === 'approved') {
      
      // Email all'UTENTE
      userSubject = `🎉 ${report.company_name} approvata - Grazie!`
      userEmailHtml = `
        <!DOCTYPE html>
        <html>
        <head><meta charset="UTF-8"></head>
        <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
          <div style="background: linear-gradient(135deg, #10b981 0%, #059669 100%); padding: 30px; text-align: center; border-radius: 10px 10px 0 0;">
            <h1 style="color: white; margin: 0; font-size: 28px;">🎉 Segnalazione Approvata!</h1>
          </div>
          
          <div style="background: #f9fafb; padding: 30px; border-radius: 0 0 10px 10px;">
            <p>Complimenti <strong>${userName}</strong>! 🎊</p>
            
            <p>La tua segnalazione è stata approvata e <strong>${report.company_name}</strong> è stata iscritta alla piattaforma CDM86!</p>
            
            <div style="background: white; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #10b981;">
              <h3 style="margin-top: 0; color: #10b981;">✅ Azienda Iscritta</h3>
              <p style="margin: 8px 0;"><strong>Azienda:</strong> ${report.company_name}</p>
              <p style="margin: 8px 0;"><strong>Settore:</strong> ${report.sector}</p>
              <p style="margin: 8px 0;"><strong>Stato:</strong> Approvata e attiva</p>
            </div>
            
            <div style="background: linear-gradient(135deg, #fbbf24 0%, #f59e0b 100%); padding: 20px; border-radius: 8px; margin: 20px 0; text-align: center;">
              <h3 style="color: white; margin: 0 0 10px 0;">🎁 Ricompensa Aggiunta!</h3>
              <p style="color: white; margin: 0; font-size: 14px;">I tuoi punti e compensi sono stati aggiornati nel tuo profilo.</p>
            </div>
            
            <p><strong>Grazie per aver contribuito alla crescita della piattaforma CDM86!</strong></p>
            
            <p>La tua segnalazione ci aiuta a costruire una rete sempre più forte di aziende e utenti.</p>
            
            <p style="margin-top: 30px; color: #64748b; font-size: 14px;">
              Grazie ancora,<br>
              <strong>Il Team CDM86</strong>
            </p>
          </div>
        </body>
        </html>
      `

      // L'email all'azienda viene già inviata dalla funzione send-organization-email
      // quando l'organizzazione viene approvata, quindi qui non serve
    }

    // ========================================
    // STATO: RIFIUTATA
    // ========================================
    else if (newStatus === 'rejected') {
      
      // Email all'UTENTE
      userSubject = `ℹ️ Aggiornamento segnalazione ${report.company_name}`
      userEmailHtml = `
        <!DOCTYPE html>
        <html>
        <head><meta charset="UTF-8"></head>
        <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
          <div style="background: linear-gradient(135deg, #64748b 0%, #475569 100%); padding: 30px; text-align: center; border-radius: 10px 10px 0 0;">
            <h1 style="color: white; margin: 0; font-size: 28px;">ℹ️ Aggiornamento Segnalazione</h1>
          </div>
          
          <div style="background: #f9fafb; padding: 30px; border-radius: 0 0 10px 10px;">
            <p>Ciao <strong>${userName}</strong>,</p>
            
            <p>Ti informiamo che la segnalazione di <strong>${report.company_name}</strong> non è stata approvata in questa fase.</p>
            
            <div style="background: white; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #64748b;">
              <h3 style="margin-top: 0; color: #64748b;">📋 Dettagli</h3>
              <p style="margin: 8px 0;"><strong>Azienda:</strong> ${report.company_name}</p>
              <p style="margin: 8px 0;"><strong>Stato:</strong> Non approvata</p>
            </div>
            
            <p>Continua a segnalare altre aziende! Ogni segnalazione approvata ti porta punti e ricompense.</p>
            
            <p style="margin-top: 30px; color: #64748b; font-size: 14px;">
              Grazie per la tua partecipazione,<br>
              <strong>Il Team CDM86</strong>
            </p>
          </div>
        </body>
        </html>
      `

      // Email all'AZIENDA
      if (report.email) {
        companySubject = `Grazie per la disponibilità - CDM86`
        companyEmailHtml = `
          <!DOCTYPE html>
          <html>
          <head><meta charset="UTF-8"></head>
          <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
            <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; text-align: center; border-radius: 10px 10px 0 0;">
              <h1 style="color: white; margin: 0; font-size: 28px;">Grazie per la disponibilità</h1>
            </div>
            
            <div style="background: #f9fafb; padding: 30px; border-radius: 0 0 10px 10px;">
              <p>Gentile <strong>${report.contact_name}</strong>,</p>
              
              <p>Grazie per aver mostrato disponibilità nei confronti della piattaforma CDM86.</p>
              
              <p>Anche se al momento non procederemo con l'iscrizione di <strong>${report.company_name}</strong>, restiamo a disposizione per future opportunità di collaborazione.</p>
              
              <div style="background: white; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #667eea;">
                <h3 style="margin-top: 0; color: #667eea;">📞 I Nostri Contatti</h3>
                <p style="margin: 8px 0;"><strong>Email:</strong> web@cdm86.it</p>
                <p style="margin: 8px 0;"><strong>Sito:</strong> www.cdm86.it</p>
              </div>
              
              <p>Non esitate a contattarci per qualsiasi informazione.</p>
              
              <p style="margin-top: 30px; color: #64748b; font-size: 14px;">
                Cordiali saluti,<br>
                <strong>Il Team CDM86</strong>
              </p>
            </div>
          </body>
          </html>
        `
      }
    }

    // Invia email all'utente
    console.log(`📧 Invio email utente a: ${userEmail}`)
    
    const userEmailResponse = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${RESEND_API_KEY}`
      },
      body: JSON.stringify({
        from: 'CDM86 <web@cdm86.it>',
        to: [userEmail],
        subject: userSubject,
        html: userEmailHtml
      })
    })

    const userEmailResult = await userEmailResponse.json()
    
    if (!userEmailResponse.ok) {
      console.error('❌ Errore invio email utente:', userEmailResult)
    } else {
      console.log('✅ Email utente inviata:', userEmailResult.id)
    }

    // Invia email all'azienda (se presente)
    let companyEmailResult = null
    
    if (companyEmailHtml && report.email) {
      console.log(`📧 Invio email azienda a: ${report.email}`)
      
      const companyEmailResponse = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${RESEND_API_KEY}`
        },
        body: JSON.stringify({
          from: 'CDM86 <web@cdm86.it>',
          to: [report.email],
          subject: companySubject,
          html: companyEmailHtml,
          reply_to: 'web@cdm86.it'
        })
      })

      companyEmailResult = await companyEmailResponse.json()
      
      if (!companyEmailResponse.ok) {
        console.error('❌ Errore invio email azienda:', companyEmailResult)
      } else {
        console.log('✅ Email azienda inviata:', companyEmailResult.id)
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        status: newStatus,
        userEmail: userEmailResult.id,
        companyEmail: companyEmailResult?.id || null
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
