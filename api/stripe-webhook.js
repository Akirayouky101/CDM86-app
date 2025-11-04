// =====================================================
// STRIPE WEBHOOK - Gestione Eventi Pagamenti
// =====================================================

const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_KEY
);

const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;

module.exports = async (req, res) => {
    if (req.method !== 'POST') {
        return res.status(405).json({ error: 'Method not allowed' });
    }

    const sig = req.headers['stripe-signature'];
    let event;

    try {
        // Verifica firma webhook
        event = stripe.webhooks.constructEvent(req.body, sig, webhookSecret);
    } catch (err) {
        console.error('⚠️ Webhook signature verification failed:', err.message);
        return res.status(400).send(`Webhook Error: ${err.message}`);
    }

    console.log('✅ Webhook ricevuto:', event.type);

    try {
        switch (event.type) {
            // Pagamento completato
            case 'checkout.session.completed':
                await handleCheckoutCompleted(event.data.object);
                break;

            // Abbonamento creato
            case 'customer.subscription.created':
                await handleSubscriptionCreated(event.data.object);
                break;

            // Abbonamento aggiornato
            case 'customer.subscription.updated':
                await handleSubscriptionUpdated(event.data.object);
                break;

            // Abbonamento cancellato
            case 'customer.subscription.deleted':
                await handleSubscriptionDeleted(event.data.object);
                break;

            // Pagamento fallito
            case 'invoice.payment_failed':
                await handlePaymentFailed(event.data.object);
                break;

            default:
                console.log(`Evento non gestito: ${event.type}`);
        }

        res.json({ received: true });
    } catch (error) {
        console.error('Errore gestione webhook:', error);
        res.status(500).json({ error: error.message });
    }
};

// =====================================================
// GESTORI EVENTI
// =====================================================

async function handleCheckoutCompleted(session) {
    const userId = session.client_reference_id || session.metadata.userId;
    const customerId = session.customer;

    console.log(`💰 Pagamento completato per user ${userId}`);

    // Aggiorna pagamento
    await supabase
        .from('payments')
        .update({
            stripe_payment_id: session.payment_intent,
            stripe_customer_id: customerId,
            status: 'completed'
        })
        .eq('user_id', userId)
        .eq('status', 'pending');

    // Attiva utente
    await supabase
        .from('users')
        .update({
            is_active: true,
            is_verified: true,
            updated_at: new Date().toISOString()
        })
        .eq('id', userId);

    console.log(`✅ Utente ${userId} attivato`);
}

async function handleSubscriptionCreated(subscription) {
    const customerId = subscription.customer;

    // Trova utente da customer ID
    const { data: payment } = await supabase
        .from('payments')
        .select('user_id')
        .eq('stripe_customer_id', customerId)
        .limit(1)
        .single();

    if (!payment) {
        console.error('❌ Utente non trovato per customer', customerId);
        return;
    }

    const userId = payment.user_id;

    // Crea abbonamento
    await supabase.from('subscriptions').insert({
        user_id: userId,
        stripe_subscription_id: subscription.id,
        stripe_customer_id: customerId,
        plan_type: subscription.items.data[0].price.recurring.interval === 'year' ? 'premium' : 'basic',
        price: subscription.items.data[0].price.unit_amount / 100,
        status: 'active',
        current_period_start: new Date(subscription.current_period_start * 1000).toISOString(),
        current_period_end: new Date(subscription.current_period_end * 1000).toISOString(),
        cancel_at_period_end: subscription.cancel_at_period_end
    });

    console.log(`✅ Abbonamento creato per user ${userId}`);
}

async function handleSubscriptionUpdated(subscription) {
    await supabase
        .from('subscriptions')
        .update({
            status: subscription.status,
            current_period_start: new Date(subscription.current_period_start * 1000).toISOString(),
            current_period_end: new Date(subscription.current_period_end * 1000).toISOString(),
            cancel_at_period_end: subscription.cancel_at_period_end,
            updated_at: new Date().toISOString()
        })
        .eq('stripe_subscription_id', subscription.id);

    console.log(`✅ Abbonamento aggiornato:`, subscription.id);
}

async function handleSubscriptionDeleted(subscription) {
    const { data: sub } = await supabase
        .from('subscriptions')
        .select('user_id')
        .eq('stripe_subscription_id', subscription.id)
        .single();

    if (sub) {
        // Aggiorna stato abbonamento
        await supabase
            .from('subscriptions')
            .update({ status: 'cancelled' })
            .eq('stripe_subscription_id', subscription.id);

        // Disattiva utente
        await supabase
            .from('users')
            .update({ is_active: false })
            .eq('id', sub.user_id);

        console.log(`❌ Abbonamento cancellato per user ${sub.user_id}`);
    }
}

async function handlePaymentFailed(invoice) {
    const customerId = invoice.customer;

    const { data: payment } = await supabase
        .from('payments')
        .select('user_id')
        .eq('stripe_customer_id', customerId)
        .limit(1)
        .single();

    if (payment) {
        await supabase.from('payments').insert({
            user_id: payment.user_id,
            stripe_customer_id: customerId,
            amount: invoice.amount_due / 100,
            currency: invoice.currency.toUpperCase(),
            status: 'failed',
            payment_type: 'subscription',
            description: 'Pagamento fallito'
        });

        console.log(`⚠️ Pagamento fallito per user ${payment.user_id}`);
    }
}
