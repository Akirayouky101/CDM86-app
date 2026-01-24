// =====================================================
// SUPABASE EDGE FUNCTION: Invio Email Organizzazione Approvata
// =====================================================
// Path: supabase/functions/send-organization-email/index.ts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { organization_id } = await req.json()

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
        referred_by_user_id,
        organization_temp_passwords (
          temp_password,
          email_sent
        )
      `)
      .eq('id', organization_id)
      .single()

    if (orgError || !orgData) {
      throw new Error('Organization not found')
    }

    const tempPassword = orgData.organization_temp_passwords[0]?.temp_password
    
    if (!tempPassword) {
      throw new Error('No temporary password found')
    }

    // Ottieni dati utente che ha segnalato
    let referrerName = ''
    if (orgData.referred_by_user_id) {
      const { data: userData } = await supabaseClient
        .from('users')
        .select('first_name, last_name, email')
        .eq('id', orgData.referred_by_user_id)
        .single()
      
      if (userData) {
        referrerName = `${userData.first_name} ${userData.last_name}`
      }
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
          .referral-box { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 25px; border-radius: 12px; margin: 25px 0; text-align: center; box-shadow: 0 4px 6px rgba(102, 126, 234, 0.3); }
          .referral-code { font-size: 32px; font-weight: bold; letter-spacing: 3px; margin: 15px 0; padding: 15px; background: rgba(255,255,255,0.2); border-radius: 8px; border: 2px dashed white; }
          .referrer-info { background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; border-radius: 4px; }
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
            
            ${referrerName ? `
            <div class="referrer-info">
              <h3 style="margin-top: 0; color: #856404;">👤 Segnalato da:</h3>
              <p style="margin: 5px 0; font-size: 18px; font-weight: bold; color: #856404;">${referrerName}</p>
              <p style="margin: 5px 0; font-size: 14px; color: #856404;">Grazie a ${referrerName.split(' ')[0]} per averti portato su CDM86!</p>
            </div>
            ` : ''}
            
            <div class="referral-box">
              <h2 style="margin: 0 0 10px 0; font-size: 24px;">🎫 Il Tuo Codice Referral</h2>
              <div class="referral-code">${orgData.referral_code}</div>
              <p style="margin: 10px 0 0 0; font-size: 14px; opacity: 0.9;">Condividi questo codice per far crescere la tua rete!</p>
            </div>
            
            <div class="credentials">
              <h3>🔑 Le tue credenziali di accesso:</h3>
              <p><strong>Email:</strong> ${orgData.email}</p>
              <p><strong>Password temporanea:</strong> <code style="background:#fff;padding:8px 15px;border-radius:6px;font-size:18px;font-weight:bold;color:#dc2626;">${tempPassword}</code></p>
            </div>
            
            <p>⚠️ <strong>Importante:</strong> Al primo accesso ti consigliamo di cambiare la password temporanea con una tua personale.</p>
            
            <a href="https://www.cdm86.com/login" class="button" style="color: white;">Accedi ora →</a>
            
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
        from: 'CDM86 <onboarding@resend.dev>',
        to: [orgData.email],
        subject: '🎉 Benvenuto su CDM86 - Credenziali di accesso',
        html: emailHtml
      })
    })

    if (!resendResponse.ok) {
      throw new Error(`Resend API error: ${await resendResponse.text()}`)
    }

    // Crea account Supabase Auth per l'organization
    try {
      const { data: authData, error: authError } = await supabaseClient.auth.admin.createUser({
        email: orgData.email,
        password: tempPassword,
        email_confirm: true,
        user_metadata: {
          organization_id: organization_id,
          organization_name: orgData.name,
          referral_code: orgData.referral_code,
          is_organization: true
        }
      })

      if (authError) {
        console.warn('Could not create auth user:', authError)
      } else {
        console.log('Auth user created successfully:', authData.user?.id)
      }
    } catch (authError) {
      console.warn('Auth creation failed (non-blocking):', authError)
    }

    // Marca email come inviata
    await supabaseClient
      .from('organization_temp_passwords')
      .update({ email_sent: true })
      .eq('organization_id', organization_id)

    return new Response(
      JSON.stringify({ success: true, message: 'Email sent successfully' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : 'Unknown error' }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
