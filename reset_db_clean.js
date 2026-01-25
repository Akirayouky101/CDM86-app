#!/usr/bin/env node

/**
 * 🧹 RESET COMPLETO DATABASE - MANTIENE SOLO ADMIN E MARIO ROSSI
 * 
 * Cancella TUTTO TUTTO TUTTO tranne:
 * ✅ Admin (admin@cdm86.com)
 * ✅ Mario Rossi (mario.rossi@email.com)
 * 
 * Usage: node reset_db_clean.js
 */

const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_KEY;

const supabase = createClient(supabaseUrl, supabaseKey);

async function resetDatabase() {
    console.log('\n🧹 INIZIO RESET COMPLETO DATABASE...\n');
    
    try {
        // 1️⃣ Trova IDs da mantenere
        console.log('📋 Recupero IDs da preservare...');
        
        const { data: adminUser } = await supabase
            .from('users')
            .select('id, auth_user_id, email')
            .eq('email', 'admin@cdm86.com')
            .single();
        
        const { data: marioUser } = await supabase
            .from('users')
            .select('id, auth_user_id, email')
            .eq('email', 'mario.rossi@email.com')
            .single();
        
        if (!adminUser || !marioUser) {
            console.error('❌ ERRORE: Non trovo Admin o Mario Rossi!');
            process.exit(1);
        }
        
        const keepUserIds = [adminUser.id, marioUser.id];
        
        console.log('✅ Admin ID:', adminUser.id);
        console.log('✅ Mario ID:', marioUser.id);
        console.log('');
        
        // 2️⃣ CANCELLA TRANSACTIONS
        console.log('🗑️  Cancello transactions...');
        const { error: txError } = await supabase
            .from('transactions')
            .delete()
            .not('user_id', 'in', `(${keepUserIds.join(',')})`);
        
        if (txError && txError.code !== 'PGRST116') console.error('⚠️ Transactions:', txError.message);
        else console.log('   ✅ Transactions cancellate');
        
        // 3️⃣ CANCELLA REFERRALS
        console.log('🗑️  Cancello referrals...');
        const { error: refError } = await supabase
            .from('referrals')
            .delete()
            .not('referrer_id', 'in', `(${keepUserIds.join(',')})`);
        
        if (refError && refError.code !== 'PGRST116') console.error('⚠️ Referrals:', refError.message);
        else console.log('   ✅ Referrals cancellati');
        
        // 4️⃣ CANCELLA FAVORITES
        console.log('🗑️  Cancello favorites...');
        const { error: favError } = await supabase
            .from('favorites')
            .delete()
            .not('user_id', 'in', `(${keepUserIds.join(',')})`);
        
        if (favError && favError.code !== 'PGRST116') console.error('⚠️ Favorites:', favError.message);
        else console.log('   ✅ Favorites cancellati');
        
        // 5️⃣ CANCELLA USER_PROMOTIONS
        console.log('🗑️  Cancello user_promotions...');
        const { error: upError } = await supabase
            .from('user_promotions')
            .delete()
            .not('user_id', 'in', `(${keepUserIds.join(',')})`);
        
        if (upError && upError.code !== 'PGRST116') console.error('⚠️ User Promotions:', upError.message);
        else console.log('   ✅ User Promotions cancellati');
        
        // 6️⃣ CANCELLA COMPANY_REPORTS
        console.log('🗑️  Cancello company_reports...');
        const { error: crError } = await supabase
            .from('company_reports')
            .delete()
            .not('reported_by_user_id', 'in', `(${keepUserIds.join(',')})`);
        
        if (crError && crError.code !== 'PGRST116') console.error('⚠️ Company Reports:', crError.message);
        else console.log('   ✅ Company Reports cancellati');
        
        // 7️⃣ CANCELLA ORGANIZATION_REQUESTS (TUTTI)
        console.log('🗑️  Cancello organization_requests (TUTTI)...');
        const { error: orError } = await supabase
            .from('organization_requests')
            .delete()
            .neq('id', 0); // Delete all
        
        if (orError && orError.code !== 'PGRST116') console.error('⚠️ Organization Requests:', orError.message);
        else console.log('   ✅ Organization Requests cancellati TUTTI');
        
        // 8️⃣ CANCELLA TEMP_PASSWORDS (TUTTE)
        console.log('🗑️  Cancello temp_passwords (TUTTE)...');
        const { error: tpError } = await supabase
            .from('temp_passwords')
            .delete()
            .neq('id', 0); // Delete all
        
        if (tpError && tpError.code !== 'PGRST116') console.error('⚠️ Temp Passwords:', tpError.message);
        else console.log('   ✅ Temp Passwords cancellate TUTTE');
        
        // 9️⃣ CANCELLA ORGANIZATIONS (TUTTE)
        console.log('🗑️  Cancello organizations (TUTTE)...');
        const { error: orgError } = await supabase
            .from('organizations')
            .delete()
            .neq('id', 0); // Delete all
        
        if (orgError && orgError.code !== 'PGRST116') console.error('⚠️ Organizations:', orgError.message);
        else console.log('   ✅ Organizations cancellate TUTTE');
        
        // 🔟 CANCELLA PROMOTIONS (TUTTE)
        console.log('🗑️  Cancello promotions (TUTTE)...');
        const { error: promoError } = await supabase
            .from('promotions')
            .delete()
            .neq('id', 0); // Delete all
        
        if (promoError && promoError.code !== 'PGRST116') console.error('⚠️ Promotions:', promoError.message);
        else console.log('   ✅ Promotions cancellate TUTTE');
        
        // 1️⃣1️⃣ CANCELLA USERS (tranne Admin e Mario)
        console.log('🗑️  Cancello users (tranne Admin e Mario)...');
        const { error: userError } = await supabase
            .from('users')
            .delete()
            .not('id', 'in', `(${keepUserIds.join(',')})`);
        
        if (userError && userError.code !== 'PGRST116') console.error('⚠️ Users:', userError.message);
        else console.log('   ✅ Users cancellati (Admin e Mario preservati)');
        
        // 1️⃣2️⃣ RESET PUNTI Admin e Mario
        console.log('🔄 Reset punti Admin e Mario a 0...');
        await supabase
            .from('users')
            .update({ points: 0 })
            .in('id', keepUserIds);
        
        console.log('   ✅ Punti resettati');
        
        // 1️⃣3️⃣ VERIFICA FINALE
        console.log('\n📊 VERIFICA FINALE:');
        console.log('================================');
        
        const { count: userCount } = await supabase
            .from('users')
            .select('*', { count: 'exact', head: true });
        
        const { count: orgCount } = await supabase
            .from('organizations')
            .select('*', { count: 'exact', head: true });
        
        const { count: promoCount } = await supabase
            .from('promotions')
            .select('*', { count: 'exact', head: true });
        
        const { count: reportCount } = await supabase
            .from('company_reports')
            .select('*', { count: 'exact', head: true });
        
        console.log('👥 Users rimasti:', userCount);
        console.log('🏢 Organizations:', orgCount);
        console.log('🎁 Promotions:', promoCount);
        console.log('📝 Company Reports:', reportCount);
        console.log('================================');
        
        if (userCount !== 2) {
            console.log('\n⚠️  ATTENZIONE: Dovrebbero esserci esattamente 2 users!');
        }
        
        console.log('\n✅ RESET COMPLETATO!\n');
        console.log('Database pulito con SOLO:');
        console.log('  ✅ admin@cdm86.com (punti: 0)');
        console.log('  ✅ mario.rossi@email.com (punti: 0)\n');
        
    } catch (error) {
        console.error('\n❌ ERRORE DURANTE IL RESET:', error);
        process.exit(1);
    }
}

resetDatabase();
