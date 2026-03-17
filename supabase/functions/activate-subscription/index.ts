import { createClient } from 'https://esm.sh/@supabase/supabase-js@2?target=deno';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
);

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const { uid, token } = await req.json();

    if (!uid) {
      return new Response(JSON.stringify({ error: 'uid mancante' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // Verifica che il token JWT appartenga all'utente uid (sicurezza)
    if (token) {
      const { data: { user }, error } = await supabase.auth.getUser(token);
      if (error || !user || user.id !== uid) {
        console.error('Token non valido o uid non corrisponde', error);
        return new Response(JSON.stringify({ error: 'Non autorizzato' }), {
          status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        });
      }
    }

    const now       = new Date().toISOString();
    const expiresAt = new Date();
    expiresAt.setFullYear(expiresAt.getFullYear() + 1);

    const { data, error: updateErr } = await supabase
      .from('users')
      .update({
        subscription_status:     'active',
        subscription_started_at: now,
        subscription_expires_at: expiresAt.toISOString(),
      })
      .eq('auth_user_id', uid)
      .select('subscription_status, subscription_expires_at');

    if (updateErr) {
      console.error('Update error:', updateErr);
      return new Response(JSON.stringify({ error: updateErr.message }), {
        status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    console.log(`✅ Abbonamento attivato per uid ${uid} — scade ${expiresAt.toISOString()}`);
    return new Response(JSON.stringify({ success: true, data }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (err) {
    console.error('activate-subscription error:', err);
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});
