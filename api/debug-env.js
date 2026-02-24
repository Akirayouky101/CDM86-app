// Endpoint temporaneo di diagnostica — DA RIMUOVERE dopo il debug
import { createClient } from '@supabase/supabase-js';

export default async function handler(req, res) {
    res.setHeader('Access-Control-Allow-Origin', '*');

    const supabaseUrl = process.env.SUPABASE_URL;
    const serviceKey = process.env.SUPABASE_SERVICE_KEY;
    const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
    const anonKey = process.env.SUPABASE_ANON_KEY;
    const siteUrl = process.env.SITE_URL;

    // Prova tutte le chiavi disponibili
    const keyToUse = serviceKey || serviceRoleKey;

    // Testa connessione Supabase
    let supabaseTest = 'not tested';
    try {
        if (supabaseUrl && keyToUse) {
            const sb = createClient(supabaseUrl, keyToUse);
            const { data, error } = await sb.from('promotions').select('id').limit(1);
            supabaseTest = error ? 'ERROR: ' + error.message : 'OK (rows: ' + (data?.length ?? 0) + ')';
        } else {
            supabaseTest = 'MISSING ENV VARS';
        }
    } catch (e) {
        supabaseTest = 'EXCEPTION: ' + e.message;
    }

    // Testa tabella redemption_tokens
    let tokensTest = 'not tested';
    try {
        if (supabaseUrl && keyToUse) {
            const sb = createClient(supabaseUrl, keyToUse);
            const { data, error } = await sb.from('redemption_tokens').select('id').limit(1);
            tokensTest = error ? 'ERROR: ' + error.message : 'OK (rows: ' + (data?.length ?? 0) + ')';
        }
    } catch (e) {
        tokensTest = 'EXCEPTION: ' + e.message;
    }

    return res.status(200).json({
        env: {
            SUPABASE_URL: supabaseUrl ? supabaseUrl.substring(0, 40) + '...' : 'MISSING',
            SUPABASE_SERVICE_KEY: serviceKey ? 'SET (len:' + serviceKey.length + ')' : 'MISSING',
            SUPABASE_SERVICE_ROLE_KEY: serviceRoleKey ? 'SET (len:' + serviceRoleKey.length + ')' : 'MISSING',
            SUPABASE_ANON_KEY: anonKey ? 'SET (len:' + anonKey.length + ')' : 'MISSING',
            SITE_URL: siteUrl || 'MISSING',
            key_used: keyToUse ? 'service_key_or_role_key' : 'NONE',
        },
        tests: {
            supabase_promotions: supabaseTest,
            supabase_redemption_tokens: tokensTest,
        },
        node_version: process.version,
    });
}
