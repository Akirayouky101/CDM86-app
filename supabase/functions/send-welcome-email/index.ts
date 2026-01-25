import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

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
    const { email, firstName, lastName, referredBy } = await req.json()

    if (!email) {
      throw new Error('Email è richiesta')
    }

    console.log('📧 Invio email di benvenuto a:', email)

    const referralMessage = referredBy 
      ? `<p style="margin: 20px 0; color: #059669; font-size: 16px;">
           🎉 Sei stato invitato da <strong>${referredBy}</strong>!
         </p>`
      : ''

    const html = `
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
        </head>
        <body style="margin: 0; padding: 0; font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh;">
          <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="margin: 0; padding: 40px 20px;">
            <tr>
              <td align="center">
                <!-- Container principale -->
                <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="600" style="margin: 0; background: #ffffff; border-radius: 24px; box-shadow: 0 20px 60px rgba(0,0,0,0.3); overflow: hidden;">
                  
                  <!-- Header con gradiente -->
                  <tr>
                    <td style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 60px 40px; text-align: center;">
                      <div style="background: rgba(255,255,255,0.2); backdrop-filter: blur(10px); border-radius: 50%; width: 100px; height: 100px; margin: 0 auto 24px; display: flex; align-items: center; justify-content: center; border: 4px solid rgba(255,255,255,0.3);">
                        <span style="font-size: 48px;">🎉</span>
                      </div>
                      <h1 style="margin: 0; color: #ffffff; font-size: 36px; font-weight: 800; text-shadow: 0 2px 10px rgba(0,0,0,0.2);">
                        Benvenuto su CDM86!
                      </h1>
                      <p style="margin: 16px 0 0; color: rgba(255,255,255,0.95); font-size: 18px; font-weight: 500;">
                        ${firstName ? `Ciao ${firstName}!` : 'Ciao!'} 👋
                      </p>
                    </td>
                  </tr>

                  <!-- Contenuto -->
                  <tr>
                    <td style="padding: 48px 40px;">
                      <p style="margin: 0 0 24px; color: #1f2937; font-size: 18px; line-height: 1.6;">
                        Grazie per esserti registrato a <strong style="color: #667eea;">CDM86</strong>, la piattaforma che ti connette con le migliori promozioni e opportunità! 🚀
                      </p>

                      ${referralMessage}

                      <div style="background: linear-gradient(135deg, #f3f4f6 0%, #e5e7eb 100%); border-radius: 16px; padding: 24px; margin: 32px 0;">
                        <h2 style="margin: 0 0 16px; color: #1f2937; font-size: 20px; font-weight: 700;">
                          🎯 Cosa puoi fare ora:
                        </h2>
                        <ul style="margin: 0; padding: 0 0 0 20px; color: #4b5563; font-size: 16px; line-height: 1.8;">
                          <li style="margin-bottom: 12px;">
                            <strong>Esplora le promozioni</strong> disponibili sulla piattaforma
                          </li>
                          <li style="margin-bottom: 12px;">
                            <strong>Salva i tuoi preferiti</strong> per accedere rapidamente alle offerte
                          </li>
                          <li style="margin-bottom: 12px;">
                            <strong>Invita amici</strong> e guadagna punti con il tuo codice referral
                          </li>
                          <li>
                            <strong>Contatta le organizzazioni</strong> direttamente per maggiori informazioni
                          </li>
                        </ul>
                      </div>

                      <div style="text-align: center; margin: 40px 0 24px;">
                        <a href="https://www.cdm86.com" style="display: inline-block; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: #ffffff; text-decoration: none; padding: 16px 48px; border-radius: 12px; font-size: 18px; font-weight: 700; box-shadow: 0 10px 30px rgba(102, 126, 234, 0.3); transition: all 0.3s;">
                          🚀 Inizia subito!
                        </a>
                      </div>

                      <p style="margin: 32px 0 0; color: #6b7280; font-size: 14px; line-height: 1.6; text-align: center;">
                        Hai domande? Contattaci a 
                        <a href="mailto:support@cdm86.com" style="color: #667eea; text-decoration: none; font-weight: 600;">
                          support@cdm86.com
                        </a>
                      </p>
                    </td>
                  </tr>

                  <!-- Footer -->
                  <tr>
                    <td style="background: #f9fafb; padding: 32px 40px; text-align: center; border-top: 1px solid #e5e7eb;">
                      <p style="margin: 0 0 12px; color: #6b7280; font-size: 14px;">
                        © ${new Date().getFullYear()} CDM86 - La tua piattaforma di promozioni
                      </p>
                      <p style="margin: 0; color: #9ca3af; font-size: 12px;">
                        Hai ricevuto questa email perché ti sei registrato su CDM86
                      </p>
                    </td>
                  </tr>

                </table>
              </td>
            </tr>
          </table>
        </body>
      </html>
    `

    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${RESEND_API_KEY}`,
      },
      body: JSON.stringify({
        from: 'CDM86 <noreply@cdm86.com>',
        to: [email],
        subject: '🎉 Benvenuto su CDM86!',
        html,
      }),
    })

    if (!res.ok) {
      const error = await res.text()
      console.error('❌ Errore Resend:', error)
      throw new Error(`Resend error: ${error}`)
    }

    const data = await res.json()
    console.log('✅ Email benvenuto inviata:', data)

    return new Response(JSON.stringify(data), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })

  } catch (error) {
    console.error('❌ Errore:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})
