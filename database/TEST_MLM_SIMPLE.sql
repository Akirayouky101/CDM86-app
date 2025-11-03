-- ============================================================================
-- TEST MLM COMPLETO CON TRIGGER CORRETTO
-- ============================================================================
-- Questo test usa gli user ID reali di auth.users invece di creare nuovi utenti
-- ============================================================================

DO $$ 
DECLARE
  v_diego_id UUID;
  v_claudio_id UUID;
  v_test_email_b VARCHAR(100) := 'mlmtest-b-' || FLOOR(RANDOM() * 100000)::TEXT || '@test.com';
  v_test_email_c VARCHAR(100) := 'mlmtest-c-' || FLOOR(RANDOM() * 100000)::TEXT || '@test.com';
  v_test_email_d VARCHAR(100) := 'mlmtest-d-' || FLOOR(RANDOM() * 100000)::TEXT || '@test.com';
BEGIN
  
  -- Trova Diego
  SELECT id INTO v_diego_id FROM users WHERE referral_code = 'ADMIN001';
  
  IF v_diego_id IS NULL THEN
    RAISE EXCEPTION 'Diego (ADMIN001) non trovato!';
  END IF;
  
  RAISE NOTICE '';
  RAISE NOTICE '🎯 TEST MLM - VERSIONE CORRETTA';
  RAISE NOTICE '================================';
  RAISE NOTICE 'Diego ID: %', v_diego_id;
  RAISE NOTICE '';
  RAISE NOTICE '⚠️  NOTA: Questo test usa email di test, non crea utenti Auth reali';
  RAISE NOTICE '⚠️  Per test completo, registra 3 utenti veri con frontend';
  RAISE NOTICE '';
  
  -- ========================================================================
  -- VERIFICA PUNTI INIZIALI DIEGO
  -- ========================================================================
  
  RAISE NOTICE 'Punti Diego PRIMA del test: %', 
    COALESCE((SELECT points_total FROM user_points WHERE user_id = v_diego_id), 0);
  
  -- ========================================================================
  -- SIMULA User B (referral diretto di Diego)
  -- ========================================================================
  
  RAISE NOTICE '';
  RAISE NOTICE '1️⃣  Creazione User B (referral di Diego)...';
  
  INSERT INTO users (email, first_name, last_name, referral_code, referred_by_id, account_type)
  VALUES (
    v_test_email_b,
    'Test',
    'User B',
    'TESTB' || FLOOR(RANDOM() * 1000)::TEXT,
    v_diego_id,
    'user'
  );
  
  RAISE NOTICE '   ✅ User B creato: %', v_test_email_b;
  
  -- Attendi
  PERFORM pg_sleep(0.3);
  
  -- ========================================================================
  -- VERIFICA PUNTI DIEGO DOPO USER B
  -- ========================================================================
  
  RAISE NOTICE '';
  RAISE NOTICE '📊 RISULTATI DOPO USER B:';
  RAISE NOTICE '   Diego: % punti (atteso: punti iniziali + 1)', 
    COALESCE((SELECT points_total FROM user_points WHERE user_id = v_diego_id), 0);
  
  -- ========================================================================
  -- VERIFICA REFERRAL_NETWORK
  -- ========================================================================
  
  RAISE NOTICE '';
  RAISE NOTICE '🌐 REFERRAL NETWORK:';
  RAISE NOTICE '   Record creati: %', 
    (SELECT COUNT(*) FROM referral_network WHERE user_id = v_diego_id);
  
  -- ========================================================================
  -- VERIFICA TRANSACTIONS
  -- ========================================================================
  
  RAISE NOTICE '';
  RAISE NOTICE '💸 TRANSACTIONS:';
  RAISE NOTICE '   Ultime transazioni Diego:';
  
  FOR rec IN (
    SELECT points, transaction_type, description, created_at
    FROM points_transactions
    WHERE user_id = v_diego_id
    ORDER BY created_at DESC
    LIMIT 3
  ) LOOP
    RAISE NOTICE '   - % punti | % | % | %', 
      rec.points, rec.transaction_type, rec.description, rec.created_at;
  END LOOP;
  
  RAISE NOTICE '';
  RAISE NOTICE '✅ Test completato!';
  RAISE NOTICE '';
  RAISE NOTICE '📌 PROSSIMO PASSO:';
  RAISE NOTICE '   1. Verifica che Diego abbia ricevuto +1 punto';
  RAISE NOTICE '   2. Verifica referral_network abbia 1 record';
  RAISE NOTICE '   3. Verifica points_transactions abbia 1 transazione "referral_completed"';
  RAISE NOTICE '';
  
END $$;


-- ============================================================================
-- QUERY DI VERIFICA DETTAGLIATA
-- ============================================================================

SELECT '📊 PUNTI DIEGO' as check;
SELECT 
  points_total,
  referrals_count,
  level,
  updated_at
FROM user_points
WHERE user_id = (SELECT id FROM users WHERE referral_code = 'ADMIN001');


SELECT '🌐 REFERRAL NETWORK' as check;
SELECT 
  rn.level,
  u_referral.email as referral_email,
  rn.points_awarded,
  rn.referral_type,
  rn.created_at
FROM referral_network rn
JOIN users u_receiver ON rn.user_id = u_receiver.id
JOIN users u_referral ON rn.referral_id = u_referral.id
WHERE u_receiver.referral_code = 'ADMIN001'
ORDER BY rn.created_at DESC
LIMIT 5;


SELECT '💸 TRANSACTIONS RECENTI DIEGO' as check;
SELECT 
  points,
  transaction_type,
  description,
  created_at
FROM points_transactions
WHERE user_id = (SELECT id FROM users WHERE referral_code = 'ADMIN001')
ORDER BY created_at DESC
LIMIT 5;
