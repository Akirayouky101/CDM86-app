-- ============================================================================
-- CLEANUP DEFINITIVO - Cancella tutto tranne i 2 admin
-- ============================================================================

DELETE FROM referral_network;
DELETE FROM points_transactions WHERE user_id NOT IN (
  SELECT id FROM users WHERE referral_code IN ('ADMIN001', 'ADMIN002')
);
DELETE FROM user_points WHERE user_id NOT IN (
  SELECT id FROM users WHERE referral_code IN ('ADMIN001', 'ADMIN002')
);
DELETE FROM users WHERE referral_code NOT IN ('ADMIN001', 'ADMIN002');
DELETE FROM auth.users WHERE email NOT IN ('akirayouky@cdm86.com', 'claudio@cdm86.com');

-- Reset punti admin a 0
UPDATE user_points SET points_total = 0, points_available = 0, referrals_count = 0
WHERE user_id IN (SELECT id FROM users WHERE referral_code IN ('ADMIN001', 'ADMIN002'));

-- Verifica
SELECT 'CLEANUP COMPLETATO' as status;
SELECT COUNT(*) as totale_users FROM users;
SELECT COUNT(*) as totale_auth FROM auth.users;
