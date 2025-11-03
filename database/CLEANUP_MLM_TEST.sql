-- ============================================================================
-- CLEANUP COMPLETO TEST MLM
-- ============================================================================
-- Esegui questo PRIMA di TEST_MLM_COMPLETE_FULL.sql
-- ============================================================================

-- Elimina referral_network
DELETE FROM referral_network WHERE referral_id IN (
  SELECT id FROM users WHERE email LIKE '%mlmtest%'
);

DELETE FROM referral_network WHERE user_id IN (
  SELECT id FROM users WHERE email LIKE '%mlmtest%'
);

-- Elimina points_transactions
DELETE FROM points_transactions WHERE user_id IN (
  SELECT id FROM users WHERE email LIKE '%mlmtest%'
);

-- Elimina user_points
DELETE FROM user_points WHERE user_id IN (
  SELECT id FROM users WHERE email LIKE '%mlmtest%'
);

-- Elimina public.users
DELETE FROM users WHERE email LIKE '%mlmtest%';

-- Elimina auth.users
DELETE FROM auth.users WHERE email LIKE '%mlmtest%';

SELECT '✅ Cleanup completato - Puoi eseguire il test!' as status;

-- Verifica
SELECT 'Utenti test rimanenti: ' || COUNT(*)::TEXT as check
FROM users WHERE email LIKE '%mlmtest%';
