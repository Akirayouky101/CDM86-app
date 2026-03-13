// Edge Function: invia email di benvenuto all'azienda appena creata
// con credenziali di accesso e codici referral

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const {
      organizationName,
      organizationEmail,
      password,
      referralCode,
      referralCodeExternal,
      contractCode
    } = await req.json()

    if (!organizationEmail || !organizationName || !password) {
      throw new Error('Campi obbligatori mancanti: organizationEmail, organizationName, password')
    }

    const loginUrl = 'https://www.cdm86.it/public/promotions.html'
    const registerBaseUrl = 'https://www.cdm86.it/register.html'

    const emailHtml = `
<!DOCTYPE html>
<html lang="it">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; background: #f5f5f5; margin: 0; padding: 0; }
    .wrapper { max-width: 620px; margin: 30px auto; background: white; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.1); }
    .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 40px 30px; text-align: center; }
    .header h1 { margin: 0 0 8px 0; font-size: 28px; }
    .header p { margin: 0; opacity: 0.9; font-size: 16px; }
    .content { padding: 35px 30px; }
    .greeting { font-size: 18px; margin-bottom: 20px; }
    .credentials-box { background: #f8f9ff; border: 2px solid #667eea; border-radius: 10px; padding: 20px 25px; margin: 25px 0; }
    .credentials-box h3 { margin: 0 0 15px 0; color: #667eea; font-size: 16px; }
    .credential-row { display: flex; justify-content: space-between; align-items: center; padding: 8px 0; border-bottom: 1px solid #e5e7eb; }
    .credential-row:last-child { border-bottom: none; }
    .credential-label { color: #666; font-size: 14px; }
    .credential-value { font-weight: bold; color: #1a1a2e; font-size: 15px; font-family: monospace; background: #fff; padding: 4px 10px; border-radius: 6px; border: 1px solid #ddd; }
    .password-value { color: #dc2626; font-size: 17px; letter-spacing: 1px; }
    .referral-section { margin: 30px 0; }
    .referral-section h3 { color: #374151; margin-bottom: 15px; }
    .referral-card { border-radius: 10px; padding: 20px; margin-bottom: 15px; text-align: center; color: white; }
    .referral-card.green { background: linear-gradient(135deg, #10b981 0%, #059669 100%); }
    .referral-card.orange { background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%); }
    .referral-card h4 { margin: 0 0 8px 0; font-size: 14px; opacity: 0.9; text-transform: uppercase; letter-spacing: 1px; }
    .referral-code-display { font-size: 26px; font-weight: bold; letter-spacing: 3px; background: rgba(255,255,255,0.2); border: 2px dashed rgba(255,255,255,0.6); border-radius: 8px; padding: 10px 20px; display: inline-block; margin: 8px 0; }
    .referral-card p { margin: 8px 0 0 0; font-size: 13px; opacity: 0.9; }
    .qr-row { display: flex; justify-content: center; gap: 30px; margin: 20px 0; flex-wrap: wrap; }
    .qr-item { text-align: center; }
    .qr-item img { width: 130px; height: 130px; border: 3px solid #667eea; border-radius: 8px; padding: 5px; background: white; }
    .qr-item p { font-size: 12px; color: #666; margin: 5px 0 0 0; }
    .steps { background: #f0fdf4; border-left: 4px solid #10b981; padding: 20px 25px; border-radius: 0 8px 8px 0; margin: 25px 0; }
    .steps h3 { margin: 0 0 12px 0; color: #065f46; }
    .steps ol { margin: 0; padding-left: 20px; }
    .steps li { margin-bottom: 6px; color: #374151; }
    .warning { background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px 20px; border-radius: 0 8px 8px 0; margin: 20px 0; font-size: 14px; }
    .cta-btn { display: block; text-align: center; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; text-decoration: none; padding: 15px 40px; border-radius: 10px; font-size: 17px; font-weight: bold; margin: 30px auto; width: fit-content; }
    .footer { background: #f8f9fa; padding: 20px 30px; text-align: center; font-size: 12px; color: #888; border-top: 1px solid #e5e7eb; }
    ${contractCode ? `.contract { background: #e0f2fe; border: 1px solid #0284c7; border-radius: 8px; padding: 12px 20px; margin: 15px 0; text-align: center; }
    .contract span { font-size: 20px; font-weight: bold; color: #0284c7; letter-spacing: 2px; }` : ''}
  </style>
</head>
<body>
  <div class="wrapper">
    <div class="header">
      <h1>🎉 Benvenuto su CDM86!</h1>
      <p>La tua azienda è stata registrata con successo</p>
    </div>
    <div class="content">
      <p class="greeting">Ciao <strong>${organizationName}</strong>,</p>
      <p>Siamo lieti di comunicarti che la tua azienda è stata <strong>registrata e attivata</strong> sulla piattaforma CDM86. Di seguito trovi tutto il necessario per iniziare.</p>

      ${contractCode ? `
      <div class="contract">
        <p style="margin:0 0 5px 0; color:#0369a1; font-size:13px; text-transform:uppercase; letter-spacing:1px;">Codice Contratto</p>
        <span>${contractCode}</span>
      </div>` : ''}

      <!-- CREDENZIALI -->
      <div class="credentials-box">
        <h3>🔑 Le tue credenziali di accesso</h3>
        <div class="credential-row">
          <span class="credential-label">Email</span>
          <span class="credential-value">${organizationEmail}</span>
        </div>
        <div class="credential-row">
          <span class="credential-label">Password temporanea</span>
          <span class="credential-value password-value">${password}</span>
        </div>
      </div>

      <div class="warning">
        ⚠️ <strong>Importante:</strong> Questa è una password temporanea. Ti consigliamo di cambiarla al primo accesso dalla sezione impostazioni del tuo profilo.
      </div>

      <!-- CODICI REFERRAL -->
      ${(referralCode || referralCodeExternal) ? `
      <div class="referral-section">
        <h3>🎫 I tuoi codici referral</h3>
        <p style="color:#666; font-size:14px; margin-bottom:15px;">Condividi questi codici per permettere ai tuoi collaboratori e clienti di registrarsi su CDM86 collegati alla tua azienda.</p>

        ${referralCode ? `
        <div class="referral-card green">
          <h4>👥 Codice Dipendenti & Collaboratori</h4>
          <div class="referral-code-display">${referralCode}</div>
          <p>Condividi con dipendenti e collaboratori interni</p>
        </div>` : ''}

        ${referralCodeExternal ? `
        <div class="referral-card orange">
          <h4>🌍 Codice Clienti Esterni</h4>
          <div class="referral-code-display">${referralCodeExternal}</div>
          <p>Condividi con clienti e partner esterni</p>
        </div>` : ''}

        ${(referralCode || referralCodeExternal) ? `
        <div class="qr-row">
          ${referralCode ? `
          <div class="qr-item">
            <img src="https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${encodeURIComponent(registerBaseUrl + '?ref=' + referralCode)}" alt="QR Dipendenti" />
            <p>QR Dipendenti</p>
          </div>` : ''}
          ${referralCodeExternal ? `
          <div class="qr-item">
            <img src="https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${encodeURIComponent(registerBaseUrl + '?ref=' + referralCodeExternal)}" alt="QR Clienti" />
            <p>QR Clienti Esterni</p>
          </div>` : ''}
        </div>` : ''}
      </div>` : ''}

      <!-- PROSSIMI PASSI -->
      <div class="steps">
        <h3>📋 Prossimi passi</h3>
        <ol>
          <li>Accedi con le credenziali qui sopra</li>
          <li>Cambia la password temporanea</li>
          <li>Completa il profilo della tua azienda</li>
          <li>Inizia a creare promozioni per i tuoi clienti</li>
          <li>Condividi i codici referral con i tuoi collaboratori</li>
        </ol>
      </div>

      <a href="${loginUrl}" class="cta-btn">Accedi ora →</a>

      <p style="color:#666; font-size:14px; margin-top:25px;">Se hai domande o hai bisogno di assistenza, contattaci a <a href="mailto:web@cdm86.it" style="color:#667eea;">web@cdm86.it</a>.</p>
      <p style="color:#666; font-size:14px;">Benvenuto nella community CDM86! 🚀</p>
    </div>
    <div class="footer">
      <p>© ${new Date().getFullYear()} CDM86 - Tutti i diritti riservati</p>
      <p>Questa email è stata inviata automaticamente al momento della registrazione della tua azienda.</p>
    </div>
  </div>
</body>
</html>`

    console.log(`📧 Invio email di benvenuto a: ${organizationEmail}`)

    const resendResponse = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${RESEND_API_KEY}`
      },
      body: JSON.stringify({
        from: 'CDM86 <web@cdm86.it>',
        to: [organizationEmail],
        subject: `🎉 Benvenuto su CDM86 - ${organizationName} - Credenziali di accesso`,
        html: emailHtml
      })
    })

    const resendData = await resendResponse.json()

    if (!resendResponse.ok) {
      console.error('Resend error:', resendData)
      throw new Error(`Errore invio email: ${JSON.stringify(resendData)}`)
    }

    console.log(`✅ Email inviata con successo. ID: ${resendData.id}`)

    return new Response(
      JSON.stringify({ success: true, emailId: resendData.id }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )

  } catch (error) {
    console.error('❌ Errore send-welcome-organization:', error)
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : 'Errore sconosciuto' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
    )
  }
})
