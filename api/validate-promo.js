// POST /api/validate-promo
// Body: { promo_id, validated_by }
// Chiamato dall'app Partner quando scansiona un QR statico "CDM86:PROMO:<UUID>"
// Returns: { valid, promo_title, message, promo_id } or { error }

const { createClient } = require('@supabase/supabase-js');

module.exports = async function handler(req, res) {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') return res.status(200).end();
    if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

    const supabaseUrl = process.env.SUPABASE_URL;
    const supabaseKey = process.env.SUPABASE_SERVICE_KEY || process.env.SUPABASE_SERVICE_ROLE_KEY;

    if (!supabaseUrl || !supabaseKey) {
        return res.status(500).json({ error: 'Configurazione server mancante.' });
    }

    const supabase = createClient(supabaseUrl, supabaseKey);

    try {
        const { promo_id, validated_by } = req.body || {};
        if (!promo_id) return res.status(400).json({ error: 'promo_id obbligatorio' });

        // 1. Leggi la promozione
        const { data: promo, error: promoErr } = await supabase
            .from('promotions')
            .select('id, title, is_active, partner_email, partner_name, discount_type, discount_value')
            .eq('id', promo_id)
            .maybeSingle();

        if (promoErr || !promo) {
            return res.status(404).json({ valid: false, message: 'Promozione non trovata.' });
        }

        if (!promo.is_active) {
            return res.status(403).json({ valid: false, message: 'Questa promozione non e\' piu\' attiva.' });
        }

        // 2. Controlla partner_email (solo se impostata sulla promo)
        if (validated_by && promo.partner_email) {
            const promoPartnerEmail = promo.partner_email.toLowerCase().trim();
            const validatorEmail = validated_by.toLowerCase().trim();
            if (promoPartnerEmail !== validatorEmail) {
                return res.status(403).json({
                    valid: false,
                    message: `Questa promo appartiene a un altro locale (${promo.partner_name || 'altro partner'}). Non puoi validarla.`
                });
            }
        }

        // 3. Registra la validazione in redemption_tokens (senza scadenza, status used)
        const token = crypto.randomUUID();
        const { error: insertErr } = await supabase
            .from('redemption_tokens')
            .insert({
                token,
                promo_id,
                user_id: null,        // QR statico: non sappiamo l'utente
                status: 'used',
                expires_at: new Date(Date.now() + 60 * 60 * 1000).toISOString(),
                used_at: new Date().toISOString(),
                validated_by: validated_by || null
            });

        if (insertErr) {
            console.error('[validate-promo] insert error:', insertErr.message);
            // Non bloccare per errore di log
        }

        return res.status(200).json({
            valid: true,
            message: 'Promo validata con successo.',
            promo_title: promo.title,
            promo_id: promo.id,
            discount_type: promo.discount_type,
            discount_value: promo.discount_value,
            validated_at: new Date().toISOString()
        });

    } catch (err) {
        console.error('[validate-promo] error:', err.message);
        return res.status(500).json({ error: err.message || 'Errore interno' });
    }
};
