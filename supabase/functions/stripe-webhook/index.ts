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

// Calcola data scadenza a 1 anno da adesso
function oneYearFromNow(): string {
  const d = new Date();
  d.setFullYear(d.getFullYear() + 1);
  return d.toISOString();
}

Deno.serve(async (req) => {
  const signature = req.headers.get('stripe-signature');
  const body = await req.text();

  let event: Stripe.Event;

  // Se non c'è webhook secret configurato, accettiamo senza verifica (solo per test)
  const webhookSecret = Deno.env.get('STRIPE_WEBHOOK_SECRET');
  if (webhookSecret && signature) {
    try {
      event = stripe.webhooks.constructEvent(body, signature, webhookSecret);
    } catch (err) {
      console.error('Webhook signature verification failed:', err);
      return new Response('Webhook Error', { status: 400 });
    }
  } else {
    try {
      event = JSON.parse(body) as Stripe.Event;
      console.warn('⚠️ Webhook running without signature verification');
    } catch {
      return new Response('Invalid JSON', { status: 400 });
    }
  }

  console.log('Stripe event:', event.type);

  switch (event.type) {

    // ── Checkout completato via Payment Link ─────────────────────────
    case 'checkout.session.completed': {
      const session       = event.data.object as Stripe.Checkout.Session;
      const customerId    = session.customer as string;
      const customerEmail = session.customer_details?.email || session.customer_email || '';
      const orgId         = session.metadata?.organization_id;
      const plan          = session.metadata?.plan_type;
      const now           = new Date().toISOString();
      const expiresAt     = oneYearFromNow();

      // ── Aggiorna UTENTE normale (abbonamento annuale) ──
      if (customerEmail) {
        const { data: authData } = await supabase.auth.admin.listUsers();
        const matchedAuth = authData?.users?.find(
          (u) => u.email?.toLowerCase() === customerEmail.toLowerCase()
        );

        if (matchedAuth) {
          const { error: userErr } = await supabase
            .from('users')
            .update({
              subscription_status:     'active',
              subscription_started_at: now,
              subscription_expires_at: expiresAt,
              stripe_customer_id:      customerId,
            })
            .eq('auth_user_id', matchedAuth.id);

          if (userErr) {
            console.error('Error updating user subscription:', userErr);
          } else {
            console.log(`✅ User subscription activated for ${customerEmail} — expires ${expiresAt}`);
          }
        }
      }

      // ── Aggiorna ORGANIZZAZIONE (se metadata presente) ──
      if (orgId) {
        await supabase
          .from('organizations')
          .update({
            subscription_status:    'active',
            subscription_plan:      plan,
            subscription_start:     now,
            stripe_customer_id:     customerId,
            stripe_subscription_id: session.subscription as string,
          })
          .eq('id', orgId);
        console.log(`✅ Org subscription activated for org ${orgId}`);
      }

      break;
    }

    // ── Abbonamento rinnovato automaticamente ────────────────────────
    case 'invoice.payment_succeeded': {
      const invoice    = event.data.object as Stripe.Invoice;
      const customerId = invoice.customer as string;
      const expiresAt  = oneYearFromNow();

      await supabase
        .from('users')
        .update({
          subscription_status:     'active',
          subscription_expires_at: expiresAt,
        })
        .eq('stripe_customer_id', customerId);

      await supabase
        .from('organizations')
        .update({
          subscription_status:       'active',
          subscription_last_payment: new Date().toISOString(),
        })
        .eq('stripe_customer_id', customerId);

      console.log(`✅ Renewal for customer ${customerId} — new expiry ${expiresAt}`);
      break;
    }

    // ── Pagamento fallito ────────────────────────────────────────────
    case 'invoice.payment_failed': {
      const invoice    = event.data.object as Stripe.Invoice;
      const customerId = invoice.customer as string;

      await supabase
        .from('users')
        .update({ subscription_status: 'past_due' })
        .eq('stripe_customer_id', customerId);

      await supabase
        .from('organizations')
        .update({ subscription_status: 'past_due' })
        .eq('stripe_customer_id', customerId);

      console.warn(`⚠️ Payment failed for customer ${customerId}`);
      break;
    }

    // ── Abbonamento cancellato ───────────────────────────────────────
    case 'customer.subscription.deleted': {
      const sub        = event.data.object as Stripe.Subscription;
      const customerId = sub.customer as string;

      await supabase
        .from('users')
        .update({ subscription_status: 'cancelled' })
        .eq('stripe_customer_id', customerId);

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
