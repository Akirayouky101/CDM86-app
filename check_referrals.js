import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://uchrjlngfzfibcpdxtky.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVjaHJqbG5nZnpmaWJjcGR4dGt5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAwMzEyMDYsImV4cCI6MjA3NTYwNzIwNn0.64JK3OhYJi2YtrErctNAp_sCcSHwB656NVLdooyceOM';

const supabase = createClient(supabaseUrl, supabaseKey);

async function checkReferrals() {
    console.log('🔍 Controllo sistema referral...\n');

    // 1. Trova l'admin
    const { data: admin, error: adminError } = await supabase
        .from('users')
        .select('*')
        .eq('referral_code', 'ADMIN001')
        .single();

    if (adminError) {
        console.log('❌ Admin con codice ADMIN001 non trovato');
        console.log('   Errore:', adminError.message);
    } else {
        console.log('✅ Admin trovato:');
        console.log('   ID:', admin.id);
        console.log('   Email:', admin.email);
        console.log('   Nome:', admin.name);
        console.log('   Referral Code:', admin.referral_code);
        console.log('   Ruolo:', admin.role);
    }

    console.log('\n📊 Statistiche referral:\n');

    // 2. Conta utenti referrati dall'admin (usando referred_by come ID)
    const { data: referredByIdUsers, count: countById } = await supabase
        .from('users')
        .select('*', { count: 'exact' })
        .eq('referred_by', admin?.id);

    console.log(`👥 Utenti referrati (tramite ID): ${countById || 0}`);
    if (referredByIdUsers && referredByIdUsers.length > 0) {
        referredByIdUsers.forEach(u => {
            console.log(`   - ${u.email} (${u.name})`);
        });
    }

    // 3. Conta utenti referrati dall'admin (usando referral_code nella tabella)
    const { data: allUsers } = await supabase
        .from('users')
        .select('*');

    console.log('\n📋 Tutti gli utenti nel sistema:');
    allUsers?.forEach(u => {
        const referredBy = u.referred_by ? 'ID: ' + u.referred_by : 'Nessuno';
        console.log(`   - ${u.email}`);
        console.log(`     Nome: ${u.name || 'N/A'}`);
        console.log(`     Referral Code: ${u.referral_code || 'N/A'}`);
        console.log(`     Referred By: ${referredBy}`);
        console.log(`     Ruolo: ${u.role || 'user'}`);
        console.log('');
    });

    // 4. Verifica se c'è un campo diverso per il referral code
    console.log('\n🔎 Struttura tabella users:');
    const { data: sample } = await supabase
        .from('users')
        .select('*')
        .limit(1)
        .single();

    if (sample) {
        console.log('   Campi disponibili:', Object.keys(sample).join(', '));
    }
}

checkReferrals();
