import Stripe from 'https://esm.sh/stripe@14?target=deno';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!, {
  apiVersion: '2023-10-16',
  httpClient: Stripe.createFetchHttpClient(),
});

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const { organizationId, planType, email, organizationName } = await req.json();

    // --- Determina il Price ID ---
    // Priorità 1: variabile d'ambiente STRIPE_PRICE_ID (impostala in Supabase → Edge Functions → stripe-checkout → Secrets)
    let priceId: string | undefined = Deno.env.get('STRIPE_PRICE_ID');

    // Priorità 2: leggi dalla tabella subscription_plans
    if (!priceId) {
      const supabase = createClient(
        Deno.env.get('SUPABASE_URL')!,
        Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
      );
      const { data: plan } = await supabase
        .from('subscription_plans')
        .select('stripe_price_id')
        .eq('active', true)
        .order('created_at', { ascending: true })
        .limit(1)
        .maybeSingle();

      priceId = plan?.stripe_price_id;
    }

    if (!priceId || priceId.includes('XXXXXX')) {
      throw new Error(
        'Price ID Stripe non configurato. ' +
        'Vai su Supabase → Edge Functions → stripe-checkout → Secrets ' +
        'e aggiungi STRIPE_PRICE_ID con il tuo price_XXXXX da Stripe Dashboard.'
      );
    }

    const session = await stripe.checkout.sessions.create({
      mode: 'subscription',
      payment_method_types: ['card', 'sepa_debit'],
      line_items: [{ price: priceId, quantity: 1 }],
      customer_email: email,
      metadata: {
        organization_id: organizationId ?? '',
        organization_name: organizationName ?? '',
        plan_type: planType ?? 'base',
      },
      success_url: `https://www.cdm86.it/public/checkout.html?payment=success`,
      cancel_url:  `https://www.cdm86.it/public/checkout.html?payment=cancelled`,
      locale: 'it',
    });

    return new Response(
      JSON.stringify({ url: session.url, sessionId: session.id }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (err) {
    console.error('stripe-checkout error:', err);
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
