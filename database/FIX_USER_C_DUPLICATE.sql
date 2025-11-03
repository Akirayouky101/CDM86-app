-- ============================================================================
-- RESET E RICALCOLO PUNTI
-- ============================================================================

DO $$ 
DECLARE
  v_testc_id UUID;
  v_testd_id UUID;
BEGIN
  SELECT id INTO v_testc_id FROM users WHERE referral_code = '0D54BEC9';
  SELECT id INTO v_testd_id FROM users WHERE referral_code = '79AC703E';
  
  RAISE NOTICE 'Resetting User C e User D...';
  
  -- Cancella i record duplicati per User C e User D
  DELETE FROM referral_network WHERE referral_id = v_testd_id;
  DELETE FROM points_transactions WHERE user_id IN (v_testc_id) AND transaction_type = 'referral_completed';
  
  -- Reset punti User C
  UPDATE user_points 
  SET points_total = 0, points_available = 0, referrals_count = 0
  WHERE user_id = v_testc_id;
  
  -- Forza re-trigger: Togli e rimetti referred_by_id di User D
  UPDATE users SET referred_by_id = NULL WHERE id = v_testd_id;
  
  RAISE NOTICE 'Reset completato, ora ri-imposto User D...';
  
  -- Ri-imposta User D (trigger si attiverà)
  UPDATE users SET referred_by_id = v_testc_id WHERE id = v_testd_id;
  
  RAISE NOTICE '✅ Fatto!';
END $$;

-- Verifica
SELECT 
  u.email,
  COALESCE(up.points_total, 0) as punti
FROM users u
LEFT JOIN user_points up ON u.id = up.user_id
WHERE u.referral_code IN ('0D54BEC9', '79AC703E')
ORDER BY u.created_at;
