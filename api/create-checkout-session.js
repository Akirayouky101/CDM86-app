// =====================================================
// STRIPE CHECKOUT SESSION - Vercel Serverless Function
// =====================================================

const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_KEY
);

module.exports = async (req, res) => {
    // CORS headers
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

    if (req.method === 'OPTIONS') {
        return res.status(200).end();
    }

    if (req.method !== 'POST') {
        return res.status(405).json({ error: 'Method not allowed' });
    }

    try {
        const { userId, planId, successUrl, cancelUrl } = req.body;

        // Valida input
        if (!userId || !planId) {
            return res.status(400).json({ error: 'userId e planId richiesti' });
        }

        // 1. Ottieni dati utente
        const { data: user, error: userError } = await supabase
            .from('users')
            .select('email, first_name, last_name')
            .eq('id', userId)
            .single();

        if (userError || !user) {
            return res.status(404).json({ error: 'Utente non trovato' });
        }

        // 2. Ottieni piano selezionato
        const { data: plan, error: planError } = await supabase
            .from('subscription_plans')
            .select('*')
            .eq('id', planId)
            .single();

        if (planError || !plan) {
            return res.status(404).json({ error: 'Piano non trovato' });
        }

        // 3. Crea o recupera Stripe customer
        let customerId;
        const { data: existingPayments } = await supabase
            .from('payments')
            .select('stripe_customer_id')
            .eq('user_id', userId)
            .not('stripe_customer_id', 'is', null)
            .limit(1);

        if (existingPayments && existingPayments.length > 0) {
            customerId = existingPayments[0].stripe_customer_id;
        } else {
            const customer = await stripe.customers.create({
                email: user.email,
                name: `${user.first_name} ${user.last_name}`,
                metadata: { userId }
            });
            customerId = customer.id;
        }

        // 4. Crea Checkout Session
        const session = await stripe.checkout.sessions.create({
            customer: customerId,
            payment_method_types: ['card'],
            line_items: [
                {
                    price_data: {
                        currency: plan.currency.toLowerCase(),
                        product_data: {
                            name: plan.name,
                            description: plan.description,
                        },
                        unit_amount: Math.round(plan.price * 100), // Converti in centesimi
                        recurring: plan.billing_period === 'monthly' 
                            ? { interval: 'month' }
                            : { interval: 'year' }
                    },
                    quantity: 1,
                },
            ],
            mode: 'subscription',
            success_url: successUrl || `${process.env.FRONTEND_URL}/dashboard?session_id={CHECKOUT_SESSION_ID}`,
            cancel_url: cancelUrl || `${process.env.FRONTEND_URL}/dashboard?canceled=true`,
            metadata: {
                userId,
                planId,
                planName: plan.name
            },
            client_reference_id: userId
        });

        // 5. Salva pagamento pending
        await supabase.from('payments').insert({
            user_id: userId,
            stripe_customer_id: customerId,
            amount: plan.price,
            currency: plan.currency,
            status: 'pending',
            payment_type: 'subscription',
            description: `Abbonamento ${plan.name}`,
            metadata: {
                sessionId: session.id,
                planId: planId
            }
        });

        return res.status(200).json({
            sessionId: session.id,
            url: session.url
        });

    } catch (error) {
        console.error('Errore creazione checkout session:', error);
        return res.status(500).json({ 
            error: 'Errore durante la creazione della sessione di pagamento',
            details: error.message 
        });
    }
};
