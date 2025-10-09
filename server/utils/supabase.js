/**
 * Supabase Connection Utility
 * Gestisce la connessione a Supabase PostgreSQL
 */

const { createClient } = require('@supabase/supabase-js');

// Variabili di ambiente
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_ANON_KEY;

// Valida configurazione
if (!supabaseUrl || !supabaseKey) {
    throw new Error('❌ SUPABASE_URL e SUPABASE_ANON_KEY devono essere definiti in .env');
}

// Crea client Supabase
const supabase = createClient(supabaseUrl, supabaseKey, {
    auth: {
        autoRefreshToken: true,
        persistSession: false, // Per API server-side non serve persistenza
    },
    db: {
        schema: 'public',
    },
});

/**
 * Test connessione database
 */
const testConnection = async () => {
    try {
        const { data, error } = await supabase
            .from('users')
            .select('count')
            .limit(1);

        if (error) throw error;

        console.log('✅ Supabase connesso con successo');
        return true;
    } catch (error) {
        console.error('❌ Errore connessione Supabase:', error.message);
        return false;
    }
};

/**
 * Helper per query con gestione errori
 */
const query = async (callback) => {
    try {
        const result = await callback(supabase);
        
        if (result.error) {
            throw new Error(result.error.message);
        }

        return result.data;
    } catch (error) {
        console.error('❌ Query Error:', error.message);
        throw error;
    }
};

/**
 * Helper per transazioni
 */
const transaction = async (queries) => {
    try {
        // Supabase non ha transazioni native, ma possiamo usare RPC
        // Per ora eseguiamo queries sequenziali
        const results = [];
        
        for (const query of queries) {
            const result = await query(supabase);
            if (result.error) throw result.error;
            results.push(result.data);
        }

        return results;
    } catch (error) {
        console.error('❌ Transaction Error:', error.message);
        throw error;
    }
};

module.exports = {
    supabase,
    testConnection,
    query,
    transaction,
};
