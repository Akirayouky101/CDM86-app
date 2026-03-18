// POST /api/validate-promo
// Body: { promo_id, validated_by, customer_id? }
// customer_id = auth.user.id del cliente CDM86 (UUID)
// validated_by = email del partner che scansiona
// Chiamato dall'app Partner quando scansiona un QR statico "CDM86:PROMO:<UUID>:USER:<UUID>"
// Returns: { valid, promo_title, image_url, discount_type, discount_value, message, promo_id } or { error }

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

    // Helper: risposta errore con info promo incluse (per mostrare la card anche su errore)
    const errorWithPromo = (status, promo, message) => res.status(status).json({
        valid: false,
        message,
        promo_id:       promo?.id            || null,
        promo_title:    promo?.title          || null,
        image_url:      promo?.image_url      || null,
        discount_type:  promo?.discount_type  || null,
        discount_value: promo?.discount_value ?? null,
        partner_name:   promo?.partner_name   || null,
    });

    try {
        const { promo_id, validated_by, customer_id } = req.body || {};
        if (!promo_id) return res.status(400).json({ error: 'promo_id obbligatorio' });

        // 1. Leggi la promozione (inclusi campi limite e immagine)
        const { data: promo, error: promoErr } = await supabase
            .from('promotions')
            .select('id, title, is_active, partner_email, partner_name, discount_type, discount_value, image_url, max_redemptions, current_redemptions, per_user_limit, end_date')
            .eq('id', promo_id)
            .maybeSingle();

        if (promoErr || !promo) {
            return res.status(404).json({ valid: false, message: 'Promozione non trovata.' });
        }

        // 2. Promo attiva?
        if (!promo.is_active) {
            return errorWithPromo(403, promo, 'Questa promozione non è più attiva.');
        }

        // 3. Scadenza temporale
        if (promo.end_date && new Date(promo.end_date) < new Date()) {
            return errorWithPromo(410, promo, 'Questa promozione è scaduta.');
        }

        // 4. Controlla partner_email (solo se impostata sulla promo)
        if (validated_by && promo.partner_email) {
            const promoPartnerEmail = promo.partner_email.toLowerCase().trim();
            const validatorEmail    = validated_by.toLowerCase().trim();
            if (promoPartnerEmail !== validatorEmail) {
                return errorWithPromo(403, promo,
                    `Questa promo appartiene a un altro locale (${promo.partner_name || 'altro partner'}). Non puoi validarla.`
                );
            }
        }

        // 5. Limite totale (max_redemptions globale)
        if (promo.max_redemptions !== null && promo.current_redemptions >= promo.max_redemptions) {
            return errorWithPromo(409, promo,
                `Limite raggiunto: questa promozione ha esaurito tutti i ${promo.max_redemptions} posti disponibili.`
            );
        }

        // 6. Limite per CLIENTE (per_user_limit): quante volte questo customer_id ha già usato questa promo
        //    Se customer_id non è disponibile (QR vecchio formato), fallback su validated_by
        if (promo.per_user_limit !== null) {
            let countQuery = supabase
                .from('redemption_tokens')
                .select('id', { count: 'exact', head: true })
                .eq('promo_id', promo_id)
                .eq('status', 'used');

            if (customer_id) {
                // Nuovo formato QR: limita per cliente (user_id)
                countQuery = countQuery.eq('user_id', customer_id);
            } else if (validated_by) {
                // Fallback vecchio formato: limita per partner (meno preciso)
                countQuery = countQuery.eq('validated_by', validated_by);
            }

            const { count: alreadyUsed, error: countErr } = await countQuery;

            if (!countErr && alreadyUsed >= promo.per_user_limit) {
                const subject = customer_id ? 'Il cliente ha' : 'Hai';
                return errorWithPromo(409, promo,
                    promo.per_user_limit === 1
                        ? `${subject} già utilizzato questa promozione. Non è più disponibile.`
                        : `${subject} già usato questa promozione ${alreadyUsed} volte (limite: ${promo.per_user_limit}).`
                );
            }
        }

        // 7. Registra la validazione
        const token = crypto.randomUUID();
        const { error: insertErr } = await supabase
            .from('redemption_tokens')
            .insert({
                token,
                promo_id,
                user_id:      customer_id || null,   // UUID del cliente (per per_user_limit)
                status:       'used',
                expires_at:   new Date(Date.now() + 60 * 60 * 1000).toISOString(),
                used_at:      new Date().toISOString(),
                validated_by: validated_by || null    // email del partner (per audit)
            });

        if (insertErr) {
            console.error('[validate-promo] insert error:', insertErr.message);
        }

        // 8. Incrementa current_redemptions
        await supabase
            .from('promotions')
            .update({ current_redemptions: (promo.current_redemptions || 0) + 1 })
            .eq('id', promo_id);

        return res.status(200).json({
            valid:          true,
            message:        'Promo validata con successo.',
            promo_title:    promo.title,
            promo_id:       promo.id,
            image_url:      promo.image_url,
            discount_type:  promo.discount_type,
            discount_value: promo.discount_value,
            partner_name:   promo.partner_name,
            validated_at:   new Date().toISOString(),
            remaining:      promo.max_redemptions !== null
                                ? promo.max_redemptions - promo.current_redemptions - 1
                                : null,
        });

    } catch (err) {
        console.error('[validate-promo] error:', err.message);
        return res.status(500).json({ error: err.message || 'Errore interno' });
    }
};
