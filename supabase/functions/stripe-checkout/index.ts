import Stripe from 'https://esm.sh/stripe@14?target=deno';

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

    // Prezzi — aggiornali con i tuoi Price ID da Stripe Dashboard
    const PRICES: Record<string, string> = {
      base:        'price_XXXXXXXXXXXXXXXX',   // es. €29/mese
      professional: 'price_XXXXXXXXXXXXXXXX',  // es. €59/mese
      enterprise:  'price_XXXXXXXXXXXXXXXX',   // es. €99/mese
    };

    const priceId = PRICES[planType];
    if (!priceId) throw new Error(`Piano non valido: ${planType}`);

    const session = await stripe.checkout.sessions.create({
      mode: 'subscription',
      payment_method_types: ['card', 'sepa_debit'],
      line_items: [{ price: priceId, quantity: 1 }],
      customer_email: email,
      metadata: {
        organization_id: organizationId,
        organization_name: organizationName,
        plan_type: planType,
      },
      success_url: `https://www.cdm86.it/public/dashboard.html?payment=success`,
      cancel_url:  `https://www.cdm86.it/public/dashboard.html?payment=cancelled`,
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
