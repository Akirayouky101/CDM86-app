-- ============================================================================
-- IMPOSTA RELAZIONI REFERRAL MANUALMENTE
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
  RAISE NOTICE '📋 UTENTI TROVATI:';
  RAISE NOTICE '═══════════════════════════════════════';
  RAISE NOTICE 'Akirayouky: %', v_admin_id;
  RAISE NOTICE 'User B:     %', v_testb_id;
  RAISE NOTICE 'User C:     %', v_testc_id;
  RAISE NOTICE 'User D:     %', v_testd_id;
  RAISE NOTICE '';
  
  -- Verifica stato PRIMA
  RAISE NOTICE '📊 STATO PRIMA:';
  RAISE NOTICE 'User B referred_by_id: %', (SELECT referred_by_id FROM users WHERE id = v_testb_id);
  RAISE NOTICE 'User C referred_by_id: %', (SELECT referred_by_id FROM users WHERE id = v_testc_id);
  RAISE NOTICE 'User D referred_by_id: %', (SELECT referred_by_id FROM users WHERE id = v_testd_id);
  RAISE NOTICE '';
  
  -- Imposta le relazioni (il trigger si attiverà automaticamente)
  RAISE NOTICE '🔄 AGGIORNAMENTO RELAZIONI...';
  
  -- User B → referito da Akirayouky
  UPDATE users 
  SET referred_by_id = v_admin_id 
  WHERE id = v_testb_id 
  AND referred_by_id IS NULL;
  RAISE NOTICE '✅ User B → Akirayouky';
  
  -- User C → referito da User B
  UPDATE users 
  SET referred_by_id = v_testb_id 
  WHERE id = v_testc_id
  AND referred_by_id IS NULL;
  RAISE NOTICE '✅ User C → User B';
  
  -- User D → referito da User C (già impostato)
  UPDATE users 
  SET referred_by_id = v_testc_id 
  WHERE id = v_testd_id
  AND (referred_by_id IS NULL OR referred_by_id != v_testc_id);
  RAISE NOTICE '✅ User D → User C';
  
  RAISE NOTICE '';
  RAISE NOTICE '═══════════════════════════════════════';
  RAISE NOTICE '✅ RELAZIONI IMPOSTATE!';
  RAISE NOTICE '═══════════════════════════════════════';
  RAISE NOTICE '';
END $$;


-- ============================================================================
-- VERIFICA RISULTATI
-- ============================================================================

SELECT 
  '👥 CATENA REFERRAL' as info,
  u.email,
  u.referral_code,
  r.email as referrer_email,
  r.referral_code as referrer_code
FROM users u
LEFT JOIN users r ON u.referred_by_id = r.id
WHERE u.referral_code IN ('ADMIN001', '7ED64438', '0D54BEC9', '79AC703E')
ORDER BY u.created_at;


SELECT 
  '📊 PUNTI FINALI' as info,
  u.email,
  COALESCE(up.points_total, 0) as punti_totali,
  COALESCE(up.referrals_count, 0) as num_referrals
FROM users u
LEFT JOIN user_points up ON u.id = up.user_id
WHERE u.referral_code IN ('ADMIN001', '7ED64438', '0D54BEC9', '79AC703E')
ORDER BY u.created_at;


SELECT 
  '🌐 REFERRAL NETWORK' as info,
  u_receiver.email as chi_riceve,
  rn.level,
  u_referral.email as da_chi,
  rn.points_awarded as punti
FROM referral_network rn
JOIN users u_receiver ON rn.user_id = u_receiver.id
JOIN users u_referral ON rn.referral_id = u_referral.id
WHERE u_receiver.referral_code IN ('ADMIN001', '7ED64438', '0D54BEC9', '79AC703E')
ORDER BY u_receiver.created_at, rn.level;
