// POST /api/validate-qr
// Body: { token, validated_by }
// Returns: { valid, promo_title, user_id, message } or { error }

const { createClient } = require('@supabase/supabase-js');

module.exports = async function handler(req, res) {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') return res.status(200).end();
    if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

    if (!process.env.SUPABASE_URL || (!process.env.SUPABASE_SERVICE_KEY && !process.env.SUPABASE_SERVICE_ROLE_KEY)) {
        return res.status(500).json({ error: 'Configurazione server mancante.' });
    }

    const supabase = createClient(
        process.env.SUPABASE_URL,
        process.env.SUPABASE_SERVICE_KEY || process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    try {
        const { token, validated_by } = req.body || {};
        if (!token) return res.status(400).json({ error: 'token obbligatorio' });

        // 1️⃣ Leggi il token
        const { data: redemption, error: fetchErr } = await supabase
            .from('redemption_tokens')
            .select('*, promotions(title, max_uses_per_user)')
            .eq('token', token)
            .maybeSingle();

        if (fetchErr || !redemption) {
            return res.status(404).json({ valid: false, message: 'Codice non trovato o non valido.' });
        }

        // 2️⃣ Controlla stato
        if (redemption.status === 'used') {
            return res.status(409).json({ valid: false, message: 'Codice già utilizzato.' });
        }
        if (redemption.status === 'expired') {
            return res.status(410).json({ valid: false, message: 'Codice scaduto.' });
        }

        // 3️⃣ Controlla scadenza temporale
        if (new Date(redemption.expires_at) < new Date()) {
            await supabase
                .from('redemption_tokens')
                .update({ status: 'expired' })
                .eq('token', token);
            return res.status(410).json({ valid: false, message: 'Codice scaduto (5 minuti superati).' });
        }

        // 4️⃣ Marca come used
        const { error: updateErr } = await supabase
            .from('redemption_tokens')
            .update({
                status: 'used',
                used_at: new Date().toISOString(),
                validated_by: validated_by || null
            })
            .eq('token', token);

        if (updateErr) throw updateErr;

        return res.status(200).json({
            valid: true,
            message: '✅ Codice valido! Promo riscattata con successo.',
            promo_title: redemption.promotions ? redemption.promotions.title : '',
            user_id: redemption.user_id,
            promo_id: redemption.promo_id,
            used_at: new Date().toISOString()
        });

    } catch (err) {
        console.error('[validate-qr] error:', err);
        return res.status(500).json({ error: err.message || 'Errore interno' });
    }
};

