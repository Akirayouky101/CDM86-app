-- =====================================================
-- RESET COMPLETO DATABASE - Mantiene solo Mario Rossi e Admin
-- =====================================================
-- Questo script cancella TUTTO tranne:
-- - Mario Rossi (utente normale)
-- - admin@cdm86.com (admin)
-- =====================================================

BEGIN;

-- 1. Cancella reward_redemptions
DELETE FROM reward_redemptions;

-- 2. Cancella rewards
DELETE FROM rewards;

-- 3. Cancella promotion_redemptions (tranne Mario e Admin)
DELETE FROM promotion_redemptions
WHERE user_id NOT IN (
    SELECT id FROM users WHERE email IN ('mario.rossi@cdm86.com', 'admin@cdm86.com')
);

-- 4. Cancella points_transactions (tranne Mario e Admin)
DELETE FROM points_transactions
WHERE user_id NOT IN (
    SELECT id FROM users WHERE email IN ('mario.rossi@cdm86.com', 'admin@cdm86.com')
);

-- 5. Cancella user_points (tranne Mario e Admin)
DELETE FROM user_points
WHERE user_id NOT IN (
    SELECT id FROM users WHERE email IN ('mario.rossi@cdm86.com', 'admin@cdm86.com')
);

-- 6. Cancella favorites (tranne Mario e Admin)
DELETE FROM favorites
WHERE user_id NOT IN (
    SELECT id FROM users WHERE email IN ('mario.rossi@cdm86.com', 'admin@cdm86.com')
);

-- 7. Cancella messages
DELETE FROM messages;

-- 8. Cancella conversations
DELETE FROM conversations;

-- 9. Cancella referral_network (tranne Mario e Admin)
DELETE FROM referral_network
WHERE user_id NOT IN (
    SELECT id FROM users WHERE email IN ('mario.rossi@cdm86.com', 'admin@cdm86.com')
);

-- 10. Cancella subscriptions
DELETE FROM subscriptions;

-- 11. Cancella subscription_plans
DELETE FROM subscription_plans;

-- 12. Cancella payments
DELETE FROM payments;

-- 13. Cancella organization_temp_passwords
DELETE FROM organization_temp_passwords;

-- 14. Cancella organization_benefits
DELETE FROM organization_benefits;

-- 15. Cancella organization_pages
DELETE FROM organization_pages;

-- 16. Cancella company_reports (tranne Mario e Admin)
DELETE FROM company_reports
WHERE reported_by_user_id NOT IN (
    SELECT id FROM users WHERE email IN ('mario.rossi@cdm86.com', 'admin@cdm86.com')
);

-- 17. Cancella organization_requests (tranne Mario e Admin)
DELETE FROM organization_requests
WHERE referred_by_id NOT IN (
    SELECT id FROM users WHERE email IN ('mario.rossi@cdm86.com', 'admin@cdm86.com')
);

-- 18. Cancella contracts
DELETE FROM contracts;

-- 19. Cancella promotions
DELETE FROM promotions;

-- 20. Cancella organizations
DELETE FROM organizations;

-- 21. Cancella utenti (tranne Mario e Admin)
DELETE FROM users
WHERE email NOT IN ('mario.rossi@cdm86.com', 'admin@cdm86.com');

-- 22. Reset punti di Mario Rossi
UPDATE users
SET points = 0
WHERE email = 'mario.rossi@cdm86.com';

-- 23. Reset punti di Admin
UPDATE users
SET points = 0
WHERE email = 'admin@cdm86.com';

COMMIT;

-- =====================================================
-- VERIFICA RISULTATI
-- =====================================================

SELECT 'UTENTI RIMANENTI:' as info;
SELECT id, email, first_name, last_name, role, points FROM users;

SELECT 'ORGANIZATIONS:' as info;
SELECT COUNT(*) as total FROM organizations;

SELECT 'PROMOTIONS:' as info;
SELECT COUNT(*) as total FROM promotions;

SELECT 'REFERRAL_NETWORK:' as info;
SELECT COUNT(*) as total FROM referral_network;

SELECT 'COMPANY_REPORTS:' as info;
SELECT COUNT(*) as total FROM company_reports;

SELECT 'ORGANIZATION_REQUESTS:' as info;
SELECT COUNT(*) as total FROM organization_requests;

SELECT 'FAVORITES:' as info;
SELECT COUNT(*) as total FROM favorites;

SELECT 'POINTS_TRANSACTIONS:' as info;
SELECT COUNT(*) as total FROM points_transactions;

SELECT '✅ RESET COMPLETATO!' as status;
