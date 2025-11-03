-- ============================================================================
-- RESET TOTALE (SENZA RICOSTRUZIONE)
-- ============================================================================

DO $$ 
DECLARE
  v_admin_id UUID;
  v_testb_id UUID;
  v_testc_id UUID;
  v_testd_id UUID;
BEGIN
  SELECT id INTO v_admin_id FROM users WHERE referral_code = 'ADMIN001';
  SELECT id INTO v_testb_id FROM users WHERE referral_code = '7ED64438';
  SELECT id INTO v_testc_id FROM users WHERE referral_code = '0D54BEC9';
  SELECT id INTO v_testd_id FROM users WHERE referral_code = '79AC703E';
  
  RAISE NOTICE '🔄 RESET TOTALE...';
  
  -- Cancella referral_network
  DELETE FROM referral_network 
  WHERE user_id IN (v_admin_id, v_testb_id, v_testc_id, v_testd_id);
  
  -- Cancella transazioni
  DELETE FROM points_transactions 
  WHERE user_id IN (v_admin_id, v_testb_id, v_testc_id, v_testd_id)
  AND transaction_type = 'referral_completed';
  
  -- Reset user_points
  UPDATE user_points 
  SET points_total = 0, points_available = 0, referrals_count = 0
  WHERE user_id IN (v_admin_id, v_testb_id, v_testc_id, v_testd_id);
  
  -- Reset referred_by_id
  UPDATE users SET referred_by_id = NULL 
  WHERE id IN (v_testb_id, v_testc_id, v_testd_id);
  
  RAISE NOTICE '✅ Reset completato!';
  RAISE NOTICE '';
  RAISE NOTICE 'Ora esegui manualmente gli UPDATE uno alla volta:';
  RAISE NOTICE '1. UPDATE users SET referred_by_id = (Akirayouky ID) WHERE id = (User B ID)';
  RAISE NOTICE '2. UPDATE users SET referred_by_id = (User B ID) WHERE id = (User C ID)';  
  RAISE NOTICE '3. UPDATE users SET referred_by_id = (User C ID) WHERE id = (User D ID)';
END $$;

-- Verifica reset
SELECT 
  u.email,
  u.referral_code,
  u.referred_by_id,
  COALESCE(up.points_total, 0) as punti
FROM users u
LEFT JOIN user_points up ON u.id = up.user_id
WHERE u.referral_code IN ('ADMIN001', '7ED64438', '0D54BEC9', '79AC703E')
ORDER BY u.created_at;
