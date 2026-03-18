// GET /api/scan-log?promo_id=<UUID>
// Chiamato dall'admin panel per leggere il log scansioni di una promo
// Usa la service key (bypass RLS) — endpoint protetto da admin_key header
// Arricchisce ogni riga con first_name + last_name del cliente (join su users)

const { createClient } = require('@supabase/supabase-js');

module.exports = async function handler(req, res) {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, x-admin-key');
    if (req.method === 'OPTIONS') return res.status(200).end();
    if (req.method !== 'GET') return res.status(405).json({ error: 'Method not allowed' });

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
        // 1. Leggi tutti i token della promo
        const { data: rows, error } = await supabase
            .from('redemption_tokens')
            .select('id, token, used_at, validated_by, user_id, status, created_at')
            .eq('promo_id', promo_id)
            .order('used_at', { ascending: false })
            .limit(200);

        if (error) throw error;

        const allRows = rows || [];

        // 2. Raccogli gli user_id unici (non null)
        const userIds = [...new Set(allRows.map(r => r.user_id).filter(Boolean))];

        // 3. Fetch nomi dalla tabella users (una sola query)
        let userMap = {};
        if (userIds.length > 0) {
            const { data: users } = await supabase
                .from('users')
                .select('id, first_name, last_name, email')
                .in('id', userIds);

            for (const u of (users || [])) {
                const name = [u.first_name, u.last_name].filter(Boolean).join(' ') || u.email || null;
                userMap[u.id] = { name, email: u.email };
            }
        }

        // 4. Arricchisci ogni riga con customer_name
        const enriched = allRows.map(r => ({
            ...r,
            customer_name:  r.user_id ? (userMap[r.user_id]?.name  || null) : null,
            customer_email: r.user_id ? (userMap[r.user_id]?.email || null) : null,
        }));

        return res.status(200).json({ rows: enriched });

    } catch (err) {
        console.error('[scan-log]', err.message);
        return res.status(500).json({ error: err.message });
    }
};
