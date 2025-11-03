-- ============================================================================
-- CLEANUP COMPLETO + TEST MLM FRESCO
-- ============================================================================
-- Elimina TUTTI i test precedenti e riparte da zero
-- ============================================================================

-- STEP 1: Elimina tutti i dati di test precedenti
DELETE FROM referral_network WHERE referral_type = 'user' AND user_id IN (
  SELECT id FROM users WHERE email LIKE '%@mlmtest.com'
);

DELETE FROM points_transactions WHERE user_id IN (
  SELECT id FROM users WHERE email LIKE '%@mlmtest.com'
);

DELETE FROM user_points WHERE user_id IN (
  SELECT id FROM users WHERE email LIKE '%@mlmtest.com'
);

DELETE FROM users WHERE email LIKE '%@mlmtest.com';

-- Resetta anche i punti di Diego se esistono test precedenti
DELETE FROM referral_network WHERE user_id = (SELECT id FROM users WHERE referral_code = 'ADMIN001');
DELETE FROM points_transactions WHERE user_id = (SELECT id FROM users WHERE referral_code = 'ADMIN001') AND description LIKE '%Test%';
UPDATE user_points SET points_total = 0, referrals_count = 0 WHERE user_id = (SELECT id FROM users WHERE referral_code = 'ADMIN001');

SELECT '✅ Cleanup completato - Database pulito' as status;


-- ============================================================================
-- STEP 2: TEST MLM FRESCO
-- ============================================================================

DO $$ 
DECLARE
  v_diego_id UUID;
  v_user_b_id UUID;
  v_user_c_id UUID;
  v_user_d_id UUID;
  v_user_b_code VARCHAR(20);
  v_user_c_code VARCHAR(20);
  v_user_d_code VARCHAR(20);
BEGIN
  -- Trova ID Diego
  SELECT id INTO v_diego_id FROM users WHERE referral_code = 'ADMIN001';
  
  RAISE NOTICE '';
  RAISE NOTICE '🎯 INIZIO TEST MLM FRESCO';
  RAISE NOTICE '========================';
  RAISE NOTICE 'Diego (ADMIN001): %', v_diego_id;
  RAISE NOTICE '';
  
  -- ========================================================================
  -- STEP 1: Crea User B
  -- ========================================================================
  
  v_user_b_code := 'TESTB' || FLOOR(RANDOM() * 1000)::TEXT;
  
  INSERT INTO users (
    email,
    first_name,
    last_name,
    referral_code,
    referred_by_id,
    account_type
  ) VALUES (
    'test-b@mlmtest.com',
    'Test',
    'User B',
    v_user_b_code,
    v_diego_id,
    'user'
  ) RETURNING id INTO v_user_b_id;
  
  RAISE NOTICE '✅ User B creato: % (code: %)', v_user_b_id, v_user_b_code;
  PERFORM pg_sleep(0.5);
  
  -- ========================================================================
  -- STEP 2: Crea User C
  -- ========================================================================
  
  v_user_c_code := 'TESTC' || FLOOR(RANDOM() * 1000)::TEXT;
  
  INSERT INTO users (
    email,
    first_name,
    last_name,
    referral_code,
    referred_by_id,
    account_type
  ) VALUES (
    'test-c@mlmtest.com',
    'Test',
    'User C',
    v_user_c_code,
    v_user_b_id,
    'user'
  ) RETURNING id INTO v_user_c_id;
  
  RAISE NOTICE '✅ User C creato: % (code: %)', v_user_c_id, v_user_c_code;
  PERFORM pg_sleep(0.5);
  
  -- ========================================================================
  -- STEP 3: Crea User D
  -- ========================================================================
  
  v_user_d_code := 'TESTD' || FLOOR(RANDOM() * 1000)::TEXT;
  
  INSERT INTO users (
    email,
    first_name,
    last_name,
    referral_code,
    referred_by_id,
    account_type
  ) VALUES (
    'test-d@mlmtest.com',
    'Test',
    'User D',
    v_user_d_code,
    v_user_c_id,
    'user'
  ) RETURNING id INTO v_user_d_id;
  
  RAISE NOTICE '✅ User D creato: % (code: %)', v_user_d_id, v_user_d_code;
  
  -- ========================================================================
  -- VERIFICA RISULTATI
  -- ========================================================================
  
  RAISE NOTICE '';
  RAISE NOTICE '📊 RISULTATI:';
  RAISE NOTICE '=============';
  RAISE NOTICE 'Diego: % punti (atteso: 2)', 
    COALESCE((SELECT points_total FROM user_points WHERE user_id = v_diego_id), 0);
  RAISE NOTICE 'User B: % punti (atteso: 2)', 
    COALESCE((SELECT points_total FROM user_points WHERE user_id = v_user_b_id), 0);
  RAISE NOTICE 'User C: % punti (atteso: 1)', 
    COALESCE((SELECT points_total FROM user_points WHERE user_id = v_user_c_id), 0);
  RAISE NOTICE 'User D: % punti (atteso: 0)', 
    COALESCE((SELECT points_total FROM user_points WHERE user_id = v_user_d_id), 0);
  RAISE NOTICE '';
  RAISE NOTICE '🎉 Test completato!';
  
END $$;


-- ============================================================================
-- VERIFICA DETTAGLIATA
-- ============================================================================

SELECT '📊 PUNTI FINALI' as check;
SELECT 
  u.email,
  u.referral_code,
  COALESCE(up.points_total, 0) as points,
  COALESCE(up.referrals_count, 0) as referrals
FROM users u
LEFT JOIN user_points up ON u.id = up.user_id
WHERE u.referral_code = 'ADMIN001' OR u.email LIKE '%@mlmtest.com'
ORDER BY u.created_at;

SELECT '🌐 RETE REFERRAL' as check;
SELECT 
  u_receiver.email as chi_riceve,
  rn.level,
  u_referral.email as da_chi
FROM referral_network rn
JOIN users u_receiver ON rn.user_id = u_receiver.id
JOIN users u_referral ON rn.referral_id = u_referral.id
WHERE u_receiver.referral_code = 'ADMIN001' OR u_receiver.email LIKE '%@mlmtest.com'
ORDER BY rn.created_at;
