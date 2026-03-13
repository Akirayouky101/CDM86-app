import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { persistSession: false } }
    );

    const body = await req.json();
    const {
      companyName, contactName, email, phone, address,
      sector, companyAware, whoKnows, callTime,
      referralGiven, emailConsent, companyType,
      reportedByUserId, reportedByReferralCode
    } = body;

    // Validazione campi obbligatori
    if (!companyName || !contactName || !email || !phone) {
      return new Response(
        JSON.stringify({ error: 'Campi obbligatori mancanti' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Inserimento con service role (bypassa RLS)
    const { data: report, error: insertError } = await supabaseAdmin
      .from('company_reports')
      .insert({
        reported_by_user_id: reportedByUserId || null,
        reported_by_referral_code: reportedByReferralCode || null,
        company_name: companyName,
        contact_name: contactName,
        email: email,
        phone: phone,
        address: address || '',
        sector: sector || 'other',
        company_aware: companyAware === true || companyAware === 'si',
        who_knows: whoKnows || '',
        preferred_call_time: callTime || '',
        referral_given: referralGiven === true || referralGiven === 'si',
        email_consent: emailConsent === true || emailConsent === 'si',
        company_type: companyType || 'partner',
        status: 'pending'
      })
      .select()
      .single();

    if (insertError) {
      console.error('Insert error:', insertError);
      return new Response(
        JSON.stringify({ error: insertError.message }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    console.log('✅ Company report saved:', report.id);

    return new Response(
      JSON.stringify({ success: true, reportId: report.id }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (err) {
    console.error('Unexpected error:', err);
    return new Response(
      JSON.stringify({ error: (err as Error).message || 'Errore interno' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
