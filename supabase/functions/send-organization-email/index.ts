// =====================================================
// SUPABASE EDGE FUNCTION: Invio Email Organizzazione Approvata
// =====================================================
// Path: supabase/functions/send-organization-email/index.ts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')

serve(async (req) => {
  try {
    const { organizationId } = await req.json()

    // Connetti a Supabase
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Ottieni dati organizzazione e password
    const { data: orgData, error: orgError } = await supabaseClient
      .from('organizations')
      .select(`
        id,
        name,
        email,
        referral_code,
        organization_temp_passwords (
          temp_password,
          email_sent
        )
      `)
      .eq('id', organizationId)
      .single()

    if (orgError || !orgData) {
      throw new Error('Organization not found')
    }

    const tempPassword = orgData.organization_temp_passwords[0]?.temp_password
    
    if (!tempPassword) {
      throw new Error('No temporary password found')
    }

    // Invia email con Resend
    const emailHtml = `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
          .content { background: white; padding: 30px; border: 1px solid #e5e7eb; }
          .credentials { background: #f3f4f6; padding: 20px; border-radius: 8px; margin: 20px 0; }
          .button { display: inline-block; padding: 12px 30px; background: #667eea; color: white; text-decoration: none; border-radius: 8px; margin: 20px 0; }
          .footer { background: #f8f9fa; padding: 20px; text-align: center; font-size: 12px; color: #666; border-radius: 0 0 10px 10px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>🎉 Benvenuto su CDM86!</h1>
          </div>
          <div class="content">
            <p>Ciao <strong>${orgData.name}</strong>,</p>
            
            <p>La tua organizzazione è stata <strong>approvata e registrata</strong> sulla piattaforma CDM86!</p>
            
            <div class="credentials">
              <h3>🔑 Le tue credenziali di accesso:</h3>
              <p><strong>Email:</strong> ${orgData.email}</p>
              <p><strong>Password temporanea:</strong> <code style="background:#fff;padding:5px 10px;border-radius:4px;font-size:16px;font-weight:bold;">${tempPassword}</code></p>
              <p><strong>Codice Referral:</strong> ${orgData.referral_code}</p>
            </div>
            
            <p>⚠️ <strong>Importante:</strong> Al primo accesso ti consigliamo di cambiare la password temporanea con una tua personale.</p>
            
            <a href="https://www.cdm86.com/login" class="button">Accedi ora →</a>
            
            <h3>📋 Prossimi passi:</h3>
            <ol>
              <li>Accedi alla piattaforma con le credenziali sopra</li>
              <li>Completa il tuo profilo organizzazione</li>
              <li>Inizia a creare promozioni per i tuoi clienti</li>
              <li>Gestisci le tue campagne dalla dashboard</li>
            </ol>
            
            <p>Se hai domande o hai bisogno di assistenza, non esitare a contattarci.</p>
            
            <p>Benvenuto nella community CDM86! 🚀</p>
          </div>
          <div class="footer">
            <p>© ${new Date().getFullYear()} CDM86 - Tutti i diritti riservati</p>
            <p>Questa email è stata inviata automaticamente. Per favore non rispondere.</p>
          </div>
        </div>
      </body>
      </html>
    `

    // Invia email tramite Resend
    const resendResponse = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${RESEND_API_KEY}`
      },
      body: JSON.stringify({
        from: 'CDM86 <noreply@cdm86.com>',
        to: [orgData.email],
        subject: '🎉 Benvenuto su CDM86 - Credenziali di accesso',
        html: emailHtml
      })
    })

    if (!resendResponse.ok) {
      throw new Error(`Resend API error: ${await resendResponse.text()}`)
    }

    // Marca email come inviata
    await supabaseClient
      .from('organization_temp_passwords')
      .update({ email_sent: true })
      .eq('organization_id', organizationId)

    return new Response(
      JSON.stringify({ success: true, message: 'Email sent successfully' }),
      { headers: { 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
