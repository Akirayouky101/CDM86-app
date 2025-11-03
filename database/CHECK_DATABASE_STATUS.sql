-- ============================================================================
-- VERIFICA STATO DATABASE
-- ============================================================================

-- 1. Controlla quanti utenti ci sono
SELECT 'TOTALE UTENTI' as check, COUNT(*) as count FROM users;

-- 2. Controlla Diego
SELECT 'DIEGO ADMIN' as check, * FROM users WHERE referral_code = 'ADMIN001';

-- 3. Controlla utenti test
SELECT 'UTENTI TEST' as check, COUNT(*) as count FROM users WHERE email LIKE '%mlmtest%';

-- 4. Controlla user_points
SELECT 'USER POINTS' as check, COUNT(*) as count FROM user_points;

-- 5. Controlla referral_network
SELECT 'REFERRAL NETWORK' as check, COUNT(*) as count FROM referral_network;

-- 6. Controlla points_transactions
SELECT 'POINTS TRANSACTIONS' as check, COUNT(*) as count FROM points_transactions;

-- 7. Verifica se ci sono record orfani in referral_network
SELECT 'REFERRAL ORFANI' as check, COUNT(*) as count 
FROM referral_network rn
LEFT JOIN users u ON rn.user_id = u.id
WHERE u.id IS NULL;

-- 8. Verifica trigger esistente
SELECT 'TRIGGER MLM' as check, 
       t.tgname as trigger_name, 
       c.relname as table_name,
       p.proname as function_name
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE t.tgname LIKE '%mlm%' OR p.proname LIKE '%mlm%';

-- 9. Verifica funzione award_referral_points_mlm esiste
SELECT 'FUNZIONE MLM' as check, 
       proname as function_name, 
       prosrc as function_source
FROM pg_proc 
WHERE proname = 'award_referral_points_mlm';
