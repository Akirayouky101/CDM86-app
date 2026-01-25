#!/usr/bin/env node

/**
 * RESET COMPLETO DATABASE - Mantiene solo Mario Rossi e Admin
 * 
 * Cancella TUTTO tranne:
 * - Mario Rossi (utente normale)
 * - admin@cdm86.com (admin)
 * 
 * USO:
 * node reset_test_data.js
 * oppure
 * npm run reset-test
 */

const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseKey) {
    console.error('❌ ERRORE: SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY devono essere definiti in .env');
    process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

async function resetDatabase() {
    console.log('🧹 Inizio reset database...\n');

    try {
        // 1. Get Mario Rossi and Admin IDs
        console.log('1️⃣ Recupero ID di Mario Rossi e Admin...');
        const { data: protectedUsers, error: usersError } = await supabase
            .from('users')
            .select('id, email, first_name, last_name')
            .in('email', ['mario.rossi@email.com', 'admin@cdm86.com']);

        if (usersError) throw usersError;

        const protectedUserIds = protectedUsers.map(u => u.id);
        console.log(`   ✅ Trovati ${protectedUsers.length} utenti protetti:`);
        protectedUsers.forEach(u => console.log(`      - ${u.first_name} ${u.last_name} (${u.email})`));

        // 2. Delete transactions
        console.log('\n2️⃣ Cancellazione transactions...');
        const { error: txError } = await supabase
            .from('transactions')
            .delete()
            .not('user_id', 'in', `(${protectedUserIds.join(',')})`);
        if (txError && txError.code !== 'PGRST116') console.warn('   ⚠️', txError.message);
        else console.log('   ✅ Transactions cancellate');

        // 3. Delete user_favorites
        console.log('\n3️⃣ Cancellazione user_favorites...');
        const { error: favError } = await supabase
            .from('user_favorites')
            .delete()
            .not('user_id', 'in', `(${protectedUserIds.join(',')})`);
        if (favError && favError.code !== 'PGRST116') console.warn('   ⚠️', favError.message);
        else console.log('   ✅ User favorites cancellati');

        // 4. Delete referrals
        console.log('\n4️⃣ Cancellazione referrals...');
        const { data: allReferrals } = await supabase
            .from('referrals')
            .select('id, referrer_id, referred_id');
        
        if (allReferrals) {
            const referralsToDelete = allReferrals.filter(r => 
                !protectedUserIds.includes(r.referrer_id) && !protectedUserIds.includes(r.referred_id)
            );
            
            if (referralsToDelete.length > 0) {
                const { error: refError } = await supabase
                    .from('referrals')
                    .delete()
                    .in('id', referralsToDelete.map(r => r.id));
                if (refError) console.warn('   ⚠️', refError.message);
                else console.log(`   ✅ ${referralsToDelete.length} referrals cancellati`);
            } else {
                console.log('   ✅ Nessun referral da cancellare');
            }
        }

        // 5. Delete organization_temp_passwords
        console.log('\n5️⃣ Cancellazione organization_temp_passwords...');
        const { error: tempPwdError } = await supabase
            .from('organization_temp_passwords')
            .delete()
            .neq('id', 0); // Delete all
        if (tempPwdError && tempPwdError.code !== 'PGRST116') console.warn('   ⚠️', tempPwdError.message);
        else console.log('   ✅ Organization temp passwords cancellate');

        // 6. Delete company_reports
        console.log('\n6️⃣ Cancellazione company_reports...');
        const { error: reportsError } = await supabase
            .from('company_reports')
            .delete()
            .not('reported_by_user_id', 'in', `(${protectedUserIds.join(',')})`);
        if (reportsError && reportsError.code !== 'PGRST116') console.warn('   ⚠️', reportsError.message);
        else console.log('   ✅ Company reports cancellati');

        // 7. Delete organization_requests
        console.log('\n7️⃣ Cancellazione organization_requests...');
        const { error: orgReqError } = await supabase
            .from('organization_requests')
            .delete()
            .not('user_id', 'in', `(${protectedUserIds.join(',')})`);
        if (orgReqError && orgReqError.code !== 'PGRST116') console.warn('   ⚠️', orgReqError.message);
        else console.log('   ✅ Organization requests cancellate');

        // 8. Delete all promotions
        console.log('\n8️⃣ Cancellazione promotions...');
        const { error: promoError } = await supabase
            .from('promotions')
            .delete()
            .neq('id', 0); // Delete all
        if (promoError && promoError.code !== 'PGRST116') console.warn('   ⚠️', promoError.message);
        else console.log('   ✅ Promotions cancellate');

        // 9. Delete all organizations
        console.log('\n9️⃣ Cancellazione organizations...');
        const { error: orgError } = await supabase
            .from('organizations')
            .delete()
            .neq('id', 0); // Delete all
        if (orgError && orgError.code !== 'PGRST116') console.warn('   ⚠️', orgError.message);
        else console.log('   ✅ Organizations cancellate');

        // 10. Delete users (except Mario and Admin)
        console.log('\n🔟 Cancellazione utenti (tranne Mario e Admin)...');
        const { error: deleteUsersError } = await supabase
            .from('users')
            .delete()
            .not('id', 'in', `(${protectedUserIds.join(',')})`);
        if (deleteUsersError && deleteUsersError.code !== 'PGRST116') console.warn('   ⚠️', deleteUsersError.message);
        else console.log('   ✅ Utenti cancellati');

        // 11. Reset Mario Rossi stats
        console.log('\n1️⃣1️⃣ Reset statistiche Mario Rossi...');
        const marioId = protectedUsers.find(u => u.email === 'mario.rossi@email.com')?.id;
        if (marioId) {
            const { error: resetMarioError } = await supabase
                .from('users')
                .update({
                    points: 0,
                    total_referrals: 0,
                    successful_referrals: 0
                })
                .eq('id', marioId);
            if (resetMarioError) console.warn('   ⚠️', resetMarioError.message);
            else console.log('   ✅ Statistiche Mario reset');
        }

        // 12. Reset Admin stats
        console.log('\n1️⃣2️⃣ Reset statistiche Admin...');
        const adminId = protectedUsers.find(u => u.email === 'admin@cdm86.com')?.id;
        if (adminId) {
            const { error: resetAdminError } = await supabase
                .from('users')
                .update({
                    points: 0,
                    total_referrals: 0,
                    successful_referrals: 0
                })
                .eq('id', adminId);
            if (resetAdminError) console.warn('   ⚠️', resetAdminError.message);
            else console.log('   ✅ Statistiche Admin reset');
        }

        // 13. Verify results
        console.log('\n📊 VERIFICA RISULTATI:\n');
        
        const { count: usersCount } = await supabase
            .from('users')
            .select('*', { count: 'exact', head: true });
        console.log(`   👥 Utenti: ${usersCount}`);

        const { count: orgsCount } = await supabase
            .from('organizations')
            .select('*', { count: 'exact', head: true });
        console.log(`   🏢 Organizations: ${orgsCount}`);

        const { count: promosCount } = await supabase
            .from('promotions')
            .select('*', { count: 'exact', head: true });
        console.log(`   🎁 Promotions: ${promosCount}`);

        const { count: refsCount } = await supabase
            .from('referrals')
            .select('*', { count: 'exact', head: true });
        console.log(`   🔗 Referrals: ${refsCount}`);

        const { count: reportsCount } = await supabase
            .from('company_reports')
            .select('*', { count: 'exact', head: true });
        console.log(`   📋 Company Reports: ${reportsCount}`);

        console.log('\n✅ RESET COMPLETATO CON SUCCESSO!\n');

    } catch (error) {
        console.error('\n❌ ERRORE durante il reset:', error);
        process.exit(1);
    }
}

resetDatabase();
