// GET /api/scan-stats
// Restituisce statistiche scansioni aggregate per partner (anonime — nessun dato utente).
// Richiede header Authorization: Bearer <SUPABASE_SERVICE_KEY> oppure query ?admin_key=...
// Risposta:
// {
//   total_scans: number,
//   total_valid: number,
//   partners: [
//     {
//       partner_name, promo_id, promo_title, image_url, discount_type, discount_value,
//       max_redemptions, current_redemptions, per_user_limit,
//       scans_valid,        // validazioni riuscite (status='used')
//       is_active
//     },
//     ...
//   ]
// }

const { createClient } = require('@supabase/supabase-js');

module.exports = async function handler(req, res) {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') return res.status(200).end();
    if (req.method !== 'GET') return res.status(405).json({ error: 'Method not allowed' });

    const supabaseUrl = process.env.SUPABASE_URL;
    const supabaseKey = process.env.SUPABASE_SERVICE_KEY || process.env.SUPABASE_SERVICE_ROLE_KEY;
    if (!supabaseUrl || !supabaseKey) {
        return res.status(500).json({ error: 'Configurazione server mancante.' });
    }

    // Autenticazione admin semplice (passa admin_key in query o Authorization header)
    const adminKey = process.env.ADMIN_STATS_KEY || process.env.SUPABASE_SERVICE_KEY;
    const provided  = req.headers.authorization?.replace('Bearer ', '') || req.query.admin_key;
    if (provided !== adminKey) {
        return res.status(401).json({ error: 'Non autorizzato.' });
    }

    const supabase = createClient(supabaseUrl, supabaseKey);

    try {
        // 1. Carica tutte le promozioni (anche inattive per lo storico)
        const { data: promos, error: promosErr } = await supabase
            .from('promotions')
            .select('id, title, partner_name, partner_email, image_url, discount_type, discount_value, max_redemptions, current_redemptions, per_user_limit, is_active, end_date, start_date')
            .order('partner_name', { ascending: true });

        if (promosErr) throw promosErr;

        // 2. Carica redemptions aggregate per promo_id (solo status='used' = valide)
        const { data: redemptions, error: redemErr } = await supabase
            .from('redemption_tokens')
            .select('promo_id, status, validated_by, used_at')
            .eq('status', 'used')
            .order('used_at', { ascending: false });

        if (redemErr) throw redemErr;

        // 3. Conta per promo_id
        const countByPromo = {};
        const lastScanByPromo = {};
        for (const r of (redemptions || [])) {
            countByPromo[r.promo_id] = (countByPromo[r.promo_id] || 0) + 1;
            if (!lastScanByPromo[r.promo_id]) {
                lastScanByPromo[r.promo_id] = r.used_at;
            }
        }

        // 4. Costruisce risposta per promo
        const partners = (promos || []).map(p => ({
            promo_id:            p.id,
            promo_title:         p.title,
            partner_name:        p.partner_name || 'Partner sconosciuto',
            image_url:           p.image_url,
            discount_type:       p.discount_type,
            discount_value:      p.discount_value,
            max_redemptions:     p.max_redemptions,
            current_redemptions: p.current_redemptions || 0,
            per_user_limit:      p.per_user_limit,
            is_active:           p.is_active,
            end_date:            p.end_date,
            scans_valid:         countByPromo[p.id] || 0,
            last_scan:           lastScanByPromo[p.id] || null,
        }));

        const totalValid = partners.reduce((s, p) => s + p.scans_valid, 0);

        return res.status(200).json({
            total_scans: totalValid,
            total_valid: totalValid,
            partners,
        });

    } catch (err) {
        console.error('[scan-stats] error:', err.message);
        return res.status(500).json({ error: err.message || 'Errore interno' });
    }
};
