import Stripe from 'https://esm.sh/stripe@14?target=deno';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2?target=deno';

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!, {
  apiVersion: '2023-10-16',
  httpClient: Stripe.createFetchHttpClient(),
});

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
);

Deno.serve(async (req) => {
  const signature = req.headers.get('stripe-signature')!;
  const body = await req.text();

  let event: Stripe.Event;
  try {
    event = stripe.webhooks.constructEvent(
      body,
      signature,
      Deno.env.get('STRIPE_WEBHOOK_SECRET')!
    );
  } catch (err) {
    console.error('Webhook signature verification failed:', err);
    return new Response('Webhook Error', { status: 400 });
  }

  console.log('Stripe event:', event.type);

  switch (event.type) {

    // ── Pagamento completato (abbonamento attivato) ──────────────────
    case 'checkout.session.completed': {
      const session = event.data.object as Stripe.Checkout.Session;
      const orgId   = session.metadata?.organization_id;
      const plan    = session.metadata?.plan_type;

      if (!orgId) break;

      await supabase
        .from('organizations')
        .update({
          subscription_status:   'active',
          subscription_plan:     plan,
          subscription_start:    new Date().toISOString(),
          stripe_customer_id:    session.customer as string,
          stripe_subscription_id: session.subscription as string,
        })
        .eq('id', orgId);

      console.log(`✅ Subscription activated for org ${orgId} (plan: ${plan})`);
      break;
    }

    // ── Abbonamento rinnovato ────────────────────────────────────────
    case 'invoice.payment_succeeded': {
      const invoice = event.data.object as Stripe.Invoice;
      const customerId = invoice.customer as string;

      await supabase
        .from('organizations')
        .update({
          subscription_status:       'active',
          subscription_last_payment: new Date().toISOString(),
        })
        .eq('stripe_customer_id', customerId);

      console.log(`✅ Renewal payment for customer ${customerId}`);
      break;
    }

    // ── Pagamento fallito ────────────────────────────────────────────
    case 'invoice.payment_failed': {
      const invoice = event.data.object as Stripe.Invoice;
      const customerId = invoice.customer as string;

      await supabase
        .from('organizations')
        .update({ subscription_status: 'past_due' })
        .eq('stripe_customer_id', customerId);

      console.warn(`⚠️ Payment failed for customer ${customerId}`);
      break;
    }

    // ── Abbonamento cancellato ───────────────────────────────────────
    case 'customer.subscription.deleted': {
      const sub = event.data.object as Stripe.Subscription;
      const customerId = sub.customer as string;

      await supabase
        .from('organizations')
        .update({ subscription_status: 'cancelled' })
        .eq('stripe_customer_id', customerId);

      console.log(`❌ Subscription cancelled for customer ${customerId}`);
      break;
    }
  }

  return new Response(JSON.stringify({ received: true }), {
    headers: { 'Content-Type': 'application/json' },
  });
});
