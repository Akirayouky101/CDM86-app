// POST /api/redeem-promo
// Body: { promo_id, user_id }
// Returns: { token, qr_data, expires_at } or { error }

import { createClient } from '@supabase/supabase-js';
import { randomUUID } from 'crypto';

const supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_KEY  // service role — bypasses RLS
);

export default async function handler(req, res) {
    // CORS
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') return res.status(200).end();
    if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

    try {
        const { promo_id, user_id } = req.body || {};
        if (!promo_id || !user_id) {
            return res.status(400).json({ error: 'promo_id e user_id obbligatori' });
        }

        // 1️⃣ Leggi la promozione e max_uses
        const { data: promo, error: promoErr } = await supabase
            .from('promotions')
            .select('id, title, max_uses_per_user, is_active, landing_slug')
            .eq('id', promo_id)
            .maybeSingle();

        if (promoErr || !promo) {
            return res.status(404).json({ error: 'Promozione non trovata' });
        }
        if (!promo.is_active) {
            return res.status(403).json({ error: 'Promozione non attiva' });
        }

        const maxUses = promo.max_uses_per_user ?? 1;

        // 2️⃣ Conta quante volte l'utente ha già riscattato (token usati)
        const { count: usedCount } = await supabase
            .from('redemption_tokens')
            .select('id', { count: 'exact', head: true })
            .eq('promo_id', promo_id)
            .eq('user_id', user_id)
            .eq('status', 'used');

        if ((usedCount ?? 0) >= maxUses) {
            return res.status(403).json({
                error: `Hai già riscattato questa promo il massimo di ${maxUses} volta/e consentita/e.`
            });
        }

        // 3️⃣ Invalida eventuali token pending già esistenti per questo utente+promo
        await supabase
            .from('redemption_tokens')
            .update({ status: 'expired' })
            .eq('promo_id', promo_id)
            .eq('user_id', user_id)
            .eq('status', 'pending');

        // 4️⃣ Genera nuovo token
        const token = randomUUID();
        const expiresAt = new Date(Date.now() + 5 * 60 * 1000).toISOString(); // +5 min

        const { error: insertErr } = await supabase
            .from('redemption_tokens')
            .insert({
                token,
                promo_id,
                user_id,
                status: 'pending',
                expires_at: expiresAt,
                created_at: new Date().toISOString()
            });

        if (insertErr) throw insertErr;

        // Il QR code conterrà l'URL di validazione che il gestore scansiona
        const validateUrl = `${process.env.SITE_URL || 'https://cdm86.com'}/public/validate-qr.html?token=${token}`;

        return res.status(200).json({
            token,
            qr_data: validateUrl,
            expires_at: expiresAt,
            promo_title: promo.title,
            max_uses: maxUses,
            used_count: usedCount ?? 0
        });

    } catch (err) {
        console.error('[redeem-promo] error:', err);
        return res.status(500).json({ error: err.message || 'Errore interno' });
    }
}
