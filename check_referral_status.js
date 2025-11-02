/**
 * Script per controllare e fixare il referral 06ac519c
 */

const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = 'https://lldsuwgdagglqzuryowl.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxsZHN1d2dkYWdnbHF6dXJ5b3dsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mjk0NDI3NDgsImV4cCI6MjA0NTAxODc0OH0.rnPYQ5KFk7aYqPpvMF8YSdlq0PNk8TW1D0xJJOsrHYQ';

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

async function checkReferral() {
    console.log('🔍 Controllo referral code: 06ac519c\n');
    
    // 1. Trova il proprietario del codice
    console.log('1️⃣ Cerco l\'utente con referral code 06ac519c...');
    const { data: referrer, error: error1 } = await supabase
        .from('users')
        .select('id, first_name, last_name, email, referral_code, created_at')
        .eq('referral_code', '06ac519c')
        .maybeSingle();
    
    if (error1) {
        console.error('❌ Errore:', error1.message);
        return;
    }
    
    if (!referrer) {
        console.log('❌ Nessun utente trovato con questo referral code');
        return;
    }
    
    console.log('✅ Trovato referrer:', referrer);
    console.log('');
    
    // 2. Trova chi ha usato questo codice
    console.log('2️⃣ Cerco utenti che hanno usato questo codice...');
    const { data: referred, error: error2 } = await supabase
        .from('users')
        .select('id, first_name, last_name, email, referred_by_code, created_at')
        .eq('referred_by_code', '06ac519c');
    
    if (error2) {
        console.error('❌ Errore:', error2.message);
    } else {
        console.log(`✅ Trovati ${referred?.length || 0} utenti referiti:`);
        referred?.forEach((u, i) => {
            console.log(`   ${i+1}. ${u.first_name} ${u.last_name} (${u.email}) - ${u.created_at}`);
        });
    }
    console.log('');
    
    // 3. Controlla i punti del referrer
    console.log('3️⃣ Controllo punti del referrer...');
    const { data: points, error: error3 } = await supabase
        .from('user_points')
        .select('*')
        .eq('user_id', referrer.id)
        .maybeSingle();
    
    if (error3) {
        console.error('❌ Errore:', error3.message);
    } else if (!points) {
        console.log('❌ Nessun record in user_points!');
    } else {
        console.log('✅ Punti attuali:', points);
    }
    console.log('');
    
    // 4. Controlla le transazioni
    console.log('4️⃣ Controllo transazioni punti...');
    const { data: transactions, error: error4 } = await supabase
        .from('points_transactions')
        .select('*')
        .eq('user_id', referrer.id)
        .order('created_at', { ascending: false });
    
    if (error4) {
        console.error('❌ Errore:', error4.message);
    } else {
        console.log(`✅ Trovate ${transactions?.length || 0} transazioni:`);
        transactions?.forEach((t, i) => {
            console.log(`   ${i+1}. ${t.transaction_type}: ${t.points_awarded} punti - ${t.description}`);
        });
    }
    console.log('');
    
    // 5. DIAGNOSTICA
    console.log('📊 DIAGNOSTICA:');
    console.log('─'.repeat(50));
    
    if (!points || points.total_points === 0) {
        if (referred && referred.length > 0) {
            console.log('⚠️  PROBLEMA IDENTIFICATO:');
            console.log(`   - Ci sono ${referred.length} utenti referiti`);
            console.log(`   - Ma il referrer ha ${points?.total_points || 0} punti`);
            console.log('');
            console.log('🔧 POSSIBILI CAUSE:');
            console.log('   1. Il trigger non si è attivato');
            console.log('   2. Gli utenti sono stati creati senza referred_by_id');
            console.log('   3. Il record user_points non esisteva');
            console.log('');
            console.log('💡 SOLUZIONE:');
            console.log('   Eseguire lo script SQL check_referral_06ac519c.sql');
            console.log('   nella sezione "SE NON CI SONO PUNTI, ESEGUI QUESTO FIX MANUALE"');
        } else {
            console.log('ℹ️  Nessun utente ha ancora usato questo codice referral');
        }
    } else {
        console.log('✅ Tutto OK! Il sistema funziona correttamente');
    }
}

checkReferral().catch(console.error);
