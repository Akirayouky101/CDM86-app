-- =====================================================
-- 🧹 RESET COMPLETO DATABASE - MANTIENE SOLO ADMIN E MARIO ROSSI
-- =====================================================
-- Questo script cancella TUTTO TUTTO TUTTO tranne:
-- ✅ Admin (admin@cdm86.com)
-- ✅ Mario Rossi (mario.rossi@email.com)
-- =====================================================

BEGIN;

-- 1️⃣ BACKUP IDs da mantenere
DO $$
DECLARE
    admin_id UUID;
    mario_id UUID;
    admin_auth_id UUID;
    mario_auth_id UUID;
BEGIN
    -- Trova l'ID di Admin
    SELECT id, auth_user_id INTO admin_id, admin_auth_id
    FROM users 
    WHERE email = 'admin@cdm86.com';
    
    -- Trova l'ID di Mario Rossi
    SELECT id, auth_user_id INTO mario_id, mario_auth_id
    FROM users 
    WHERE email = 'mario.rossi@email.com';
    
    RAISE NOTICE '📋 IDs da preservare:';
    RAISE NOTICE '  Admin ID: %, Auth: %', admin_id, admin_auth_id;
    RAISE NOTICE '  Mario ID: %, Auth: %', mario_id, mario_auth_id;
    
    -- Store in temp table
    CREATE TEMP TABLE IF NOT EXISTS keep_users AS
    SELECT id, auth_user_id FROM users WHERE id IN (admin_id, mario_id);
END $$;

-- 2️⃣ CANCELLA TRANSACTIONS (tranne Admin e Mario)
DELETE FROM transactions
WHERE user_id NOT IN (SELECT id FROM keep_users);

RAISE NOTICE '✅ Transactions cancellate';

-- 3️⃣ CANCELLA REFERRALS (tranne Admin e Mario)
DELETE FROM referrals
WHERE referrer_id NOT IN (SELECT id FROM keep_users)
   OR referred_id NOT IN (SELECT id FROM keep_users);

RAISE NOTICE '✅ Referrals cancellati';

-- 4️⃣ CANCELLA FAVORITES (tranne Admin e Mario)
DELETE FROM favorites
WHERE user_id NOT IN (SELECT id FROM keep_users);

RAISE NOTICE '✅ Favorites cancellati';

-- 5️⃣ CANCELLA USER_PROMOTIONS (tranne Admin e Mario)
DELETE FROM user_promotions
WHERE user_id NOT IN (SELECT id FROM keep_users);

RAISE NOTICE '✅ User Promotions cancellati';

-- 6️⃣ CANCELLA COMPANY_REPORTS (tranne quelli creati da Admin e Mario)
DELETE FROM company_reports
WHERE reported_by_user_id NOT IN (SELECT id FROM keep_users);

RAISE NOTICE '✅ Company Reports cancellati';

-- 7️⃣ CANCELLA ORGANIZATION_REQUESTS (tutto)
DELETE FROM organization_requests;

RAISE NOTICE '✅ Organization Requests cancellati TUTTI';

-- 8️⃣ CANCELLA TEMP_PASSWORDS (tutto)
DELETE FROM temp_passwords;

RAISE NOTICE '✅ Temp Passwords cancellate TUTTE';

-- 9️⃣ CANCELLA ORGANIZATIONS (tutto)
DELETE FROM organizations;

RAISE NOTICE '✅ Organizations cancellate TUTTE';

-- 🔟 CANCELLA PROMOTIONS (tutto)
DELETE FROM promotions;

RAISE NOTICE '✅ Promotions cancellate TUTTE';

-- 1️⃣1️⃣ CANCELLA USERS (tranne Admin e Mario)
DELETE FROM users
WHERE id NOT IN (SELECT id FROM keep_users);

RAISE NOTICE '✅ Users cancellati (tranne Admin e Mario)';

-- 1️⃣2️⃣ RESET PUNTI Admin e Mario a 0
UPDATE users
SET points = 0
WHERE id IN (SELECT id FROM keep_users);

RAISE NOTICE '✅ Punti Admin e Mario resettati a 0';

-- 1️⃣3️⃣ RESET SEQUENCES (auto-increment)
ALTER SEQUENCE IF EXISTS users_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS promotions_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS organizations_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS referrals_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS transactions_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS favorites_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS user_promotions_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS company_reports_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS organization_requests_id_seq RESTART WITH 1;

RAISE NOTICE '✅ Sequences resettate';

-- 1️⃣4️⃣ VERIFICA FINALE
DO $$
DECLARE
    user_count INT;
    org_count INT;
    promo_count INT;
    report_count INT;
BEGIN
    SELECT COUNT(*) INTO user_count FROM users;
    SELECT COUNT(*) INTO org_count FROM organizations;
    SELECT COUNT(*) INTO promo_count FROM promotions;
    SELECT COUNT(*) INTO report_count FROM company_reports;
    
    RAISE NOTICE '';
    RAISE NOTICE '📊 STATO FINALE DATABASE:';
    RAISE NOTICE '================================';
    RAISE NOTICE '👥 Users rimasti: %', user_count;
    RAISE NOTICE '🏢 Organizations: %', org_count;
    RAISE NOTICE '🎁 Promotions: %', promo_count;
    RAISE NOTICE '📝 Company Reports: %', report_count;
    RAISE NOTICE '================================';
    
    IF user_count != 2 THEN
        RAISE WARNING '⚠️ ATTENZIONE: Dovrebbero esserci esattamente 2 users (Admin + Mario)!';
    END IF;
END $$;

COMMIT;

-- =====================================================
-- 🎉 RESET COMPLETATO!
-- =====================================================
-- Database pulito con SOLO:
-- ✅ admin@cdm86.com (punti: 0)
-- ✅ mario.rossi@email.com (punti: 0)
-- =====================================================
