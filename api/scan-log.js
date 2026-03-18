// GET /api/scan-log?promo_id=<UUID>
// Chiamato dall'admin panel per leggere il log scansioni di una promo
// Usa la service key (bypass RLS) — endpoint protetto da admin_key header

const { createClient } = require('@supabase/supabase-js');

module.exports = async function handler(req, res) {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, x-admin-key');
    if (req.method === 'OPTIONS') return res.status(200).end();
    if (req.method !== 'GET') return res.status(405).json({ error: 'Method not allowed' });

    // Protezione minima: richiede header x-admin-key
    const adminKey = req.headers['x-admin-key'];
    const expectedKey = process.env.ADMIN_SECRET_KEY || 'cdm86-admin-2026';
    if (adminKey !== expectedKey) {
        return res.status(401).json({ error: 'Unauthorized' });
    }

    const supabaseUrl = process.env.SUPABASE_URL;
    const supabaseKey = process.env.SUPABASE_SERVICE_KEY || process.env.SUPABASE_SERVICE_ROLE_KEY;

    if (!supabaseUrl || !supabaseKey) {
        return res.status(500).json({ error: 'Configurazione server mancante.' });
    }

    const { promo_id } = req.query;
    if (!promo_id) return res.status(400).json({ error: 'promo_id obbligatorio' });

    const supabase = createClient(supabaseUrl, supabaseKey);

    try {
        const { data: rows, error } = await supabase
            .from('redemption_tokens')
            .select('id, token, used_at, validated_by, user_id, status, created_at')
            .eq('promo_id', promo_id)
            .order('used_at', { ascending: false })
            .limit(200);

        if (error) throw error;

        return res.status(200).json({ rows: rows || [] });

    } catch (err) {
        console.error('[scan-log]', err.message);
        return res.status(500).json({ error: err.message });
    }
};
