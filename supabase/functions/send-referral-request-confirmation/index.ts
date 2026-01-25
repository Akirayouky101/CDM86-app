import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

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
    const { requestId } = await req.json()

    if (!requestId) {
      throw new Error('requestId è richiesto')
    }

    // Crea client Supabase
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

    // Ottieni dati richiesta
    const { data: request, error: requestError } = await supabaseAdmin
      .from('user_referral_requests')
      .select('*')
      .eq('id', requestId)
      .single()

    if (requestError || !request) {
      throw new Error('Richiesta non trovata')
    }

    console.log(`📧 Invio email conferma richiesta a: ${request.email}`)

    // Template email
    const emailHtml = `
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Richiesta Ricevuta - CDM86</title>
</head>
<body style="margin: 0; padding: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f3f4f6;">
    <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f3f4f6; padding: 40px 20px;">
        <tr>
            <td align="center">
                <table width="600" cellpadding="0" cellspacing="0" style="background-color: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
                    
                    <!-- Header blu -->
                    <tr>
                        <td style="background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%); padding: 40px 30px; text-align: center;">
                            <h1 style="margin: 0; color: #ffffff; font-size: 32px; font-weight: 700;">
                                📬 Richiesta Ricevuta!
                            </h1>
                        </td>
                    </tr>

                    <!-- Corpo -->
                    <tr>
                        <td style="padding: 40px 30px;">
                            <p style="font-size: 18px; color: #1f2937; margin: 0 0 20px 0; line-height: 1.6;">
                                Ciao <strong>${request.first_name}</strong>,
                            </p>
                            
                            <p style="font-size: 16px; color: #4b5563; margin: 0 0 20px 0; line-height: 1.6;">
                                Grazie per l'interesse in <strong>CDM86</strong>! ✨
                            </p>

                            <p style="font-size: 16px; color: #4b5563; margin: 0 0 30px 0; line-height: 1.6;">
                                Abbiamo ricevuto la tua richiesta di codice referral e il nostro team la prenderà in esame al più presto.
                            </p>

                            <!-- Box informativo -->
                            <div style="background-color: #eff6ff; border-left: 4px solid #3b82f6; padding: 20px; margin: 30px 0; border-radius: 8px;">
                                <p style="margin: 0; color: #1e40af; font-size: 15px; line-height: 1.6;">
                                    <strong>📞 Cosa succede ora?</strong><br><br>
                                    Sarai ricontattato a breve tramite uno dei nostri canali (email o telefono) per completare la procedura.
                                </p>
                            </div>

                            <!-- Dati richiesta -->
                            <div style="background-color: #f9fafb; padding: 25px; border-radius: 12px; margin: 30px 0;">
                                <h3 style="margin: 0 0 15px 0; color: #374151; font-size: 16px; font-weight: 600;">
                                    📋 Riepilogo Richiesta
                                </h3>
                                <table width="100%" cellpadding="8" cellspacing="0" style="font-size: 14px;">
                                    <tr>
                                        <td style="color: #6b7280; padding: 8px 0;">Nome:</td>
                                        <td style="color: #1f2937; font-weight: 600; padding: 8px 0; text-align: right;">
                                            ${request.first_name} ${request.last_name}
                                        </td>
                                    </tr>
                                    <tr>
                                        <td style="color: #6b7280; padding: 8px 0;">Email:</td>
                                        <td style="color: #1f2937; font-weight: 600; padding: 8px 0; text-align: right;">
                                            ${request.email}
                                        </td>
                                    </tr>
                                    ${request.phone ? `
                                    <tr>
                                        <td style="color: #6b7280; padding: 8px 0;">Telefono:</td>
                                        <td style="color: #1f2937; font-weight: 600; padding: 8px 0; text-align: right;">
                                            ${request.phone}
                                        </td>
                                    </tr>
                                    ` : ''}
                                    <tr>
                                        <td style="color: #6b7280; padding: 8px 0;">Data richiesta:</td>
                                        <td style="color: #1f2937; font-weight: 600; padding: 8px 0; text-align: right;">
                                            ${new Date(request.created_at).toLocaleDateString('it-IT', {
                                              day: '2-digit',
                                              month: 'long',
                                              year: 'numeric',
                                              hour: '2-digit',
                                              minute: '2-digit'
                                            })}
                                        </td>
                                    </tr>
                                </table>
                            </div>

                            <p style="font-size: 14px; color: #6b7280; margin: 30px 0 0 0; line-height: 1.6; text-align: center;">
                                Ti aspettiamo presto nella community CDM86! 🎉
                            </p>
                        </td>
                    </tr>

                    <!-- Footer -->
                    <tr>
                        <td style="background-color: #f9fafb; padding: 30px; text-align: center; border-top: 1px solid #e5e7eb;">
                            <p style="margin: 0 0 10px 0; color: #6b7280; font-size: 13px;">
                                © ${new Date().getFullYear()} CDM86 - Castel di Mezzo 86
                            </p>
                            <p style="margin: 0; color: #9ca3af; font-size: 12px;">
                                Questa è una email automatica, non rispondere.
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

    // Invia email via Resend
    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${RESEND_API_KEY}`,
      },
      body: JSON.stringify({
        from: 'CDM86 <noreply@cdm86.com>',
        to: [request.email],
        subject: '✅ Richiesta Codice Referral Ricevuta - CDM86',
        html: emailHtml,
      }),
    })

    if (!res.ok) {
      const error = await res.text()
      throw new Error(`Errore Resend: ${error}`)
    }

    const data = await res.json()
    console.log('✅ Email inviata con successo:', data)

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: 'Email inviata con successo',
        emailId: data.id 
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
        success: false, 
        error: error.message 
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400 
      }
    )
  }
})
