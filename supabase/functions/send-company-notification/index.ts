// =====================================================
// SUPABASE EDGE FUNCTION: Notifica Azienda Segnalata
// =====================================================
// Path: supabase/functions/send-company-notification/index.ts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

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
    const { companyEmail, companyName, referrerName, referralCode } = await req.json()

    console.log('📧 Received notification request:', { companyEmail, companyName, referrerName, referralCode });

    if (!companyEmail || !companyName || !referrerName || !referralCode) {
      throw new Error('Missing required parameters')
    }

    if (!RESEND_API_KEY) {
      console.error('❌ RESEND_API_KEY is not set!');
      throw new Error('RESEND_API_KEY is not configured');
    }

    console.log('✅ RESEND_API_KEY is configured');

    // Genera URL registrazione con codice referral
    const registrationUrl = `https://cdm86-new.vercel.app/register.html?ref=${referralCode}`

    // Template email
    const emailHtml = `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            line-height: 1.6; 
            color: #333; 
            margin: 0;
            padding: 0;
            background: #f5f5f5;
          }
          .container { 
            max-width: 600px; 
            margin: 40px auto; 
            background: white;
            border-radius: 12px;
            overflow: hidden;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
          }
          .header { 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
            color: white; 
            padding: 40px 30px; 
            text-align: center; 
          }
          .header h1 {
            margin: 0;
            font-size: 28px;
            font-weight: 700;
          }
          .header p {
            margin: 10px 0 0 0;
            font-size: 16px;
            opacity: 0.95;
          }
          .content { 
            padding: 40px 30px; 
          }
          .greeting {
            font-size: 18px;
            color: #667eea;
            font-weight: 600;
            margin-bottom: 20px;
          }
          .message {
            font-size: 16px;
            margin-bottom: 25px;
            line-height: 1.8;
          }
          .highlight-box {
            background: linear-gradient(135deg, #f3f4f6 0%, #e5e7eb 100%);
            border-left: 4px solid #667eea;
            padding: 20px;
            margin: 25px 0;
            border-radius: 8px;
          }
          .highlight-box strong {
            color: #667eea;
            font-size: 18px;
          }
          .benefits {
            background: #f9fafb;
            padding: 25px;
            border-radius: 8px;
            margin: 25px 0;
          }
          .benefits h3 {
            color: #667eea;
            margin-top: 0;
            font-size: 18px;
          }
          .benefits ul {
            margin: 15px 0;
            padding-left: 20px;
          }
          .benefits li {
            margin: 10px 0;
            color: #4b5563;
          }
          .cta-button { 
            display: block;
            width: 100%;
            max-width: 300px;
            margin: 30px auto;
            padding: 16px 32px; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white; 
            text-decoration: none; 
            border-radius: 50px; 
            text-align: center;
            font-size: 18px;
            font-weight: 600;
            box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
            transition: transform 0.2s;
          }
          .cta-button:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(102, 126, 234, 0.5);
          }
          .referral-info {
            background: #fffbeb;
            border: 2px dashed #fbbf24;
            padding: 20px;
            border-radius: 8px;
            margin: 25px 0;
            text-align: center;
          }
          .referral-code {
            font-size: 24px;
            font-weight: 700;
            color: #f59e0b;
            letter-spacing: 2px;
            margin: 10px 0;
          }
          .footer { 
            background: #f8f9fa; 
            padding: 30px; 
            text-align: center; 
            font-size: 13px; 
            color: #6b7280; 
            border-top: 1px solid #e5e7eb;
          }
          .footer a {
            color: #667eea;
            text-decoration: none;
          }
          .icon {
            font-size: 48px;
            margin-bottom: 10px;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <div class="icon">🎯</div>
            <h1>CDM86</h1>
            <p>La piattaforma di promozioni per la tua azienda</p>
          </div>
          
          <div class="content">
            <div class="greeting">
              Ciao ${companyName}! 👋
            </div>
            
            <div class="message">
              <strong>${referrerName}</strong> ti ha segnalato su <strong>CDM86</strong>, 
              la piattaforma che mette in contatto aziende e clienti attraverso promozioni esclusive 
              e un sistema di referral innovativo.
            </div>
            
            <div class="highlight-box">
              <strong>💡 Perché CDM86?</strong><br>
              Aumenta la visibilità della tua azienda, acquisisci nuovi clienti e fidelizza quelli esistenti 
              grazie al nostro sistema di promozioni geolocalizzate.
            </div>
            
            <div class="benefits">
              <h3>🎁 Vantaggi per la tua azienda:</h3>
              <ul>
                <li>✅ <strong>Visibilità locale</strong>: raggiungi clienti nella tua zona</li>
                <li>✅ <strong>Promozioni personalizzate</strong>: crea offerte su misura</li>
                <li>✅ <strong>Sistema di referral</strong>: trasforma i clienti in promoter</li>
                <li>✅ <strong>Dashboard completa</strong>: monitora le tue statistiche</li>
                <li>✅ <strong>Zero commissioni</strong>: nessun costo nascosto</li>
              </ul>
            </div>
            
            <div class="referral-info">
              <div>Codice referral di <strong>${referrerName}</strong>:</div>
              <div class="referral-code">${referralCode}</div>
              <div style="font-size: 13px; color: #92400e; margin-top: 10px;">
                Usa questo codice per associare il tuo account
              </div>
            </div>
            
            <a href="${registrationUrl}" class="cta-button">
              🚀 Iscriviti Ora
            </a>
            
            <div class="message" style="margin-top: 30px; font-size: 14px; color: #6b7280; text-align: center;">
              Registrandoti con questo codice, contribuirai al successo di ${referrerName} 
              e entrerai a far parte della community CDM86!
            </div>
          </div>
          
          <div class="footer">
            <p>
              <strong>CDM86</strong> - La piattaforma di promozioni geolocalizzate<br>
              <a href="https://cdm86-new.vercel.app">www.cdm86.com</a>
            </p>
            <p style="margin-top: 20px; font-size: 12px;">
              Hai ricevuto questa email perché ${referrerName} ti ha segnalato su CDM86.<br>
              Se non sei interessato, puoi ignorare questo messaggio.
            </p>
          </div>
        </div>
      </body>
      </html>
    `

    // Invia email con Resend
    console.log('📤 Sending email to:', companyEmail);
    
    const resendResponse = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${RESEND_API_KEY}`
      },
      body: JSON.stringify({
        from: 'CDM86 <onboarding@resend.dev>',
        to: [companyEmail],
        subject: `${referrerName} ti segnala CDM86! 🎯`,
        html: emailHtml
      })
    })

    const resendData = await resendResponse.json()
    
    console.log('📨 Resend response:', resendData);

    if (!resendResponse.ok) {
      console.error('❌ Resend API error:', resendData);
      throw new Error(`Resend API error: ${JSON.stringify(resendData)}`)
    }

    console.log('✅ Email sent successfully! ID:', resendData.id);

    return new Response(
      JSON.stringify({ 
        success: true, 
        emailId: resendData.id,
        message: 'Notification email sent successfully'
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200 
      }
    )

  } catch (error) {
    console.error('Error sending company notification:', error)
    
    return new Response(
      JSON.stringify({ 
        error: error.message || 'Unknown error',
        success: false
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500 
      }
    )
  }
})
