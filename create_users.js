// ============================================
// SCRIPT PER CREARE UTENTI REALI SU CDM86
// ============================================
// Esegui questo script nella console del browser su cdm86.com
// oppure crea un file HTML temporaneo

(async function createRealUsers() {
    console.log('🚀 Inizio creazione utenti...');
    
    // Configurazione Supabase
    const SUPABASE_URL = 'https://uchrjlngfzfibcpdxtky.supabase.co';
    const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVjaHJqbG5nZnpmaWJjcGR4dGt5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAwMzEyMDYsImV4cCI6MjA3NTYwNzIwNn0.64JK3OhYJi2YtrErctNAp_sCcSHwB656NVLdooyceOM';
    
    // Inizializza Supabase
    const { createClient } = supabase;
    const supabaseClient = createClient(SUPABASE_URL, SUPABASE_KEY);
    
    // Lista utenti da creare
    const users = [
        {
            email: 'admin@cdm86.com',
            password: 'Admin123!',
            full_name: 'Mario Rossi',
            role: 'admin',
            referral_code: 'ADMIN001'
        },
        {
            email: 'pizzeria@cdm86.com',
            password: 'Pizza123!',
            full_name: 'Giuseppe Verdi',
            role: 'organization',
            organization_id: 1,
            referral_code: 'PIZZA001'
        },
        {
            email: 'palestra@cdm86.com',
            password: 'Gym123!',
            full_name: 'Laura Bianchi',
            role: 'organization',
            organization_id: 2,
            referral_code: 'GYM001'
        },
        {
            email: 'ristorante@cdm86.com',
            password: 'Rest123!',
            full_name: 'Antonio Esposito',
            role: 'organization',
            organization_id: 3,
            referral_code: 'REST001'
        },
        {
            email: 'utente1@test.com',
            password: 'User123!',
            full_name: 'Marco Ferrari',
            role: 'user'
        },
        {
            email: 'utente2@test.com',
            password: 'User123!',
            full_name: 'Sofia Romano',
            role: 'user'
        },
        {
            email: 'utente3@test.com',
            password: 'User123!',
            full_name: 'Luca Martini',
            role: 'user'
        }
    ];
    
    const results = {
        success: [],
        failed: []
    };
    
    // Crea ogni utente
    for (const user of users) {
        try {
            console.log(`\n📝 Creazione utente: ${user.email}...`);
            
            // 1. Crea utente auth
            const { data: authData, error: authError } = await supabaseClient.auth.signUp({
                email: user.email,
                password: user.password,
                options: {
                    data: {
                        full_name: user.full_name
                    }
                }
            });
            
            if (authError) {
                if (authError.message.includes('already registered')) {
                    console.warn(`⚠️ ${user.email} - Utente già registrato`);
                    results.failed.push({
                        email: user.email,
                        error: 'Already exists'
                    });
                } else {
                    throw authError;
                }
                continue;
            }
            
            console.log(`✅ Auth user creato: ${authData.user.id}`);
            
            // 2. Aspetta un momento per permettere al trigger di creare il record
            await new Promise(resolve => setTimeout(resolve, 1000));
            
            // 3. Aggiorna il record in public.users con dati aggiuntivi
            const updateData = {
                full_name: user.full_name,
                role: user.role
            };
            
            if (user.organization_id) {
                updateData.organization_id = user.organization_id;
            }
            
            if (user.referral_code) {
                updateData.referral_code = user.referral_code;
            }
            
            const { error: updateError } = await supabaseClient
                .from('users')
                .update(updateData)
                .eq('id', authData.user.id);
            
            if (updateError) {
                console.error(`❌ Errore aggiornamento user record:`, updateError);
                results.failed.push({
                    email: user.email,
                    error: updateError.message
                });
            } else {
                console.log(`✅ User record aggiornato con role: ${user.role}`);
                results.success.push({
                    email: user.email,
                    id: authData.user.id,
                    role: user.role
                });
            }
            
        } catch (error) {
            console.error(`❌ Errore per ${user.email}:`, error);
            results.failed.push({
                email: user.email,
                error: error.message
            });
        }
    }
    
    // Riepilogo
    console.log('\n\n========================================');
    console.log('📊 RIEPILOGO CREAZIONE UTENTI');
    console.log('========================================');
    console.log(`✅ Creati con successo: ${results.success.length}`);
    console.log(`❌ Falliti: ${results.failed.length}`);
    
    if (results.success.length > 0) {
        console.log('\n✅ UTENTI CREATI:');
        console.table(results.success);
    }
    
    if (results.failed.length > 0) {
        console.log('\n❌ ERRORI:');
        console.table(results.failed);
    }
    
    console.log('\n\n📋 CREDENZIALI UTENTI:');
    console.log('========================================');
    users.forEach(u => {
        console.log(`\n${u.role.toUpperCase()}: ${u.full_name}`);
        console.log(`  Email: ${u.email}`);
        console.log(`  Password: ${u.password}`);
        if (u.referral_code) {
            console.log(`  Referral Code: ${u.referral_code}`);
        }
    });
    
    console.log('\n✅ Script completato!');
    
    return results;
})();
