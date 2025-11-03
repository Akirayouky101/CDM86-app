-- ============================================================================
-- RESET COMPLETO E RICALCOLO MLM
-- ============================================================================

DO $$ 
DECLARE
  v_admin_id UUID;
  v_testb_id UUID;
  v_testc_id UUID;
  v_testd_id UUID;
BEGIN
  -- Trova gli ID
  SELECT id INTO v_admin_id FROM users WHERE referral_code = 'ADMIN001';
  SELECT id INTO v_testb_id FROM users WHERE referral_code = '7ED64438';
  SELECT id INTO v_testc_id FROM users WHERE referral_code = '0D54BEC9';
  SELECT id INTO v_testd_id FROM users WHERE referral_code = '79AC703E';
  
  RAISE NOTICE '';
  RAISE NOTICE '═══════════════════════════════════════';
  RAISE NOTICE '🔄 RESET COMPLETO PUNTI MLM';
  RAISE NOTICE '═══════════════════════════════════════';
  
  -- 1. CANCELLA TUTTO
  RAISE NOTICE '1️⃣  Cancellazione dati esistenti...';
  
  DELETE FROM referral_network 
  WHERE user_id IN (v_admin_id, v_testb_id, v_testc_id, v_testd_id);
  
  DELETE FROM points_transactions 
  WHERE user_id IN (v_admin_id, v_testb_id, v_testc_id, v_testd_id)
  AND transaction_type = 'referral_completed';
  
  UPDATE user_points 
  SET points_total = 0, points_available = 0, referrals_count = 0
  WHERE user_id IN (v_admin_id, v_testb_id, v_testc_id, v_testd_id);
  
  RAISE NOTICE '   ✅ Dati cancellati';
  
  -- 2. RESET REFERRED_BY_ID
  RAISE NOTICE '2️⃣  Reset referred_by_id...';
  
  UPDATE users SET referred_by_id = NULL 
  WHERE id IN (v_testb_id, v_testc_id, v_testd_id);
  
  RAISE NOTICE '   ✅ Reset completato';
  
  -- Pausa per sicurezza
  PERFORM pg_sleep(0.5);
  
  -- 3. RICOSTRUZIONE CATENA (il trigger si attiverà automaticamente)
  RAISE NOTICE '3️⃣  Ricostruzione catena referral...';
  RAISE NOTICE '';
  
  -- User B → referito da Akirayouky
  RAISE NOTICE '   📌 User B → Akirayouky';
  UPDATE users SET referred_by_id = v_admin_id WHERE id = v_testb_id;
  PERFORM pg_sleep(0.3);
  
  -- User C → referito da User B
  RAISE NOTICE '   📌 User C → User B';
  UPDATE users SET referred_by_id = v_testb_id WHERE id = v_testc_id;
  PERFORM pg_sleep(0.3);
  
  -- User D → referito da User C
  RAISE NOTICE '   📌 User D → User C';
  UPDATE users SET referred_by_id = v_testc_id WHERE id = v_testd_id;
  PERFORM pg_sleep(0.3);
  
  RAISE NOTICE '';
  RAISE NOTICE '═══════════════════════════════════════';
  RAISE NOTICE '✅ RICALCOLO COMPLETATO!';
  RAISE NOTICE '═══════════════════════════════════════';
  RAISE NOTICE '';
END $$;


-- ============================================================================
-- VERIFICA RISULTATI FINALI
-- ============================================================================

-- 1. PUNTI TOTALI
SELECT 
  '📊 PUNTI FINALI' as check,
  u.email,
  u.referral_code,
  COALESCE(up.points_total, 0) as punti_totali,
  CASE u.referral_code
    WHEN 'ADMIN001' THEN 2
    WHEN '7ED64438' THEN 2
    WHEN '0D54BEC9' THEN 1
    WHEN '79AC703E' THEN 0
  END as punti_attesi
FROM users u
LEFT JOIN user_points up ON u.id = up.user_id
WHERE u.referral_code IN ('ADMIN001', '7ED64438', '0D54BEC9', '79AC703E')
ORDER BY u.created_at;


-- 2. CATENA REFERRAL
SELECT 
  '👥 CATENA REFERRAL' as check,
  u.email,
  r.email as referrer
FROM users u
LEFT JOIN users r ON u.referred_by_id = r.id
WHERE u.referral_code IN ('ADMIN001', '7ED64438', '0D54BEC9', '79AC703E')
ORDER BY u.created_at;


-- 3. RETE COMPLETA
SELECT 
  '🌐 REFERRAL NETWORK' as check,
  u_receiver.email as chi_riceve,
  rn.level,
  u_referral.email as da_chi,
  rn.points_awarded as punti
FROM referral_network rn
JOIN users u_receiver ON rn.user_id = u_receiver.id
JOIN users u_referral ON rn.referral_id = u_referral.id
WHERE u_receiver.referral_code IN ('ADMIN001', '7ED64438', '0D54BEC9', '79AC703E')
ORDER BY u_receiver.created_at, rn.level;
