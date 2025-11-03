-- ============================================================================
-- TEST DIRETTO MLM - Senza aspettare API
-- ============================================================================
-- Simula registrazione di 3 utenti e assegna punti MLM direttamente
--
-- SCENARIO:
-- 1. Crea User B con referred_by = Diego (ADMIN001)
-- 2. Crea User C con referred_by = User B  
-- 3. Crea User D con referred_by = User C
--
-- RISULTATI ATTESI:
-- Diego: +2 punti (1 da B livello 1, 1 da C livello 2)
-- User B: +2 punti (1 da C livello 1, 1 da D livello 2)
-- User C: +1 punto (1 da D livello 1)
-- User D: 0 punti
-- ============================================================================

-- Salva ID admin Diego per usarlo dopo
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
  
  RAISE NOTICE '🎯 Inizio test MLM con Diego (ADMIN001): %', v_diego_id;
  
  -- ========================================================================
  -- STEP 1: Crea User B con referral Diego
  -- ========================================================================
  
  -- Genera referral code univoco per User B
  v_user_b_code := 'TEST' || FLOOR(RANDOM() * 10000)::TEXT;
  
  -- Inserisci User B (trigger MLM si attiva automaticamente!)
  INSERT INTO users (
    email,
    first_name,
    last_name,
    referral_code,
    referred_by_id,
    account_type
  ) VALUES (
    'test-user-b-' || FLOOR(RANDOM() * 1000)::TEXT || '@mlmtest.com',
    'Test',
    'User B',
    v_user_b_code,
    v_diego_id,  -- ← Referral Diego
    'user'
  ) RETURNING id INTO v_user_b_id;
  
  RAISE NOTICE '✅ User B creato: % (referral code: %)', v_user_b_id, v_user_b_code;
  RAISE NOTICE '   → Trigger dovrebbe aver assegnato +1 punto a Diego (livello 1)';
  
  -- Pausa per vedere i log
  PERFORM pg_sleep(1);
  
  
  -- ========================================================================
  -- STEP 2: Crea User C con referral User B
  -- ========================================================================
  
  v_user_c_code := 'TEST' || FLOOR(RANDOM() * 10000)::TEXT;
  
  INSERT INTO users (
    email,
    first_name,
    last_name,
    referral_code,
    referred_by_id,
    account_type
  ) VALUES (
    'test-user-c-' || FLOOR(RANDOM() * 1000)::TEXT || '@mlmtest.com',
    'Test',
    'User C',
    v_user_c_code,
    v_user_b_id,  -- ← Referral User B
    'user'
  ) RETURNING id INTO v_user_c_id;
  
  RAISE NOTICE '✅ User C creato: % (referral code: %)', v_user_c_id, v_user_c_code;
  RAISE NOTICE '   → Trigger dovrebbe aver assegnato:';
  RAISE NOTICE '      - +1 punto a User B (livello 1)';
  RAISE NOTICE '      - +1 punto a Diego (livello 2)';
  
  PERFORM pg_sleep(1);
  
  
  -- ========================================================================
  -- STEP 3: Crea User D con referral User C
  -- ========================================================================
  
  v_user_d_code := 'TEST' || FLOOR(RANDOM() * 10000)::TEXT;
  
  INSERT INTO users (
    email,
    first_name,
    last_name,
    referral_code,
    referred_by_id,
    account_type
  ) VALUES (
    'test-user-d-' || FLOOR(RANDOM() * 1000)::TEXT || '@mlmtest.com',
    'Test',
    'User D',
    v_user_d_code,
    v_user_c_id,  -- ← Referral User C
    'user'
  ) RETURNING id INTO v_user_d_id;
  
  RAISE NOTICE '✅ User D creato: % (referral code: %)', v_user_d_id, v_user_d_code;
  RAISE NOTICE '   → Trigger dovrebbe aver assegnato:';
  RAISE NOTICE '      - +1 punto a User C (livello 1)';
  RAISE NOTICE '      - +1 punto a User B (livello 2)';
  RAISE NOTICE '      - +0 punti a Diego (livello 3 = stop)';
  
  
  -- ========================================================================
  -- VERIFICA RISULTATI
  -- ========================================================================
  
  RAISE NOTICE '';
  RAISE NOTICE '📊 VERIFICA PUNTI ASSEGNATI:';
  RAISE NOTICE '================================';
  
  -- Diego
  RAISE NOTICE 'Diego (ADMIN001): % punti (atteso: 2)', 
    COALESCE((SELECT points_total FROM user_points WHERE user_id = v_diego_id), 0);
  
  -- User B
  RAISE NOTICE 'User B: % punti (atteso: 2)', 
    COALESCE((SELECT points_total FROM user_points WHERE user_id = v_user_b_id), 0);
  
  -- User C
  RAISE NOTICE 'User C: % punti (atteso: 1)', 
    COALESCE((SELECT points_total FROM user_points WHERE user_id = v_user_c_id), 0);
  
  -- User D
  RAISE NOTICE 'User D: % punti (atteso: 0)', 
    COALESCE((SELECT points_total FROM user_points WHERE user_id = v_user_d_id), 0);
  
  RAISE NOTICE '';
  RAISE NOTICE '🎉 Test MLM completato!';
  RAISE NOTICE 'Esegui le query di verifica qui sotto per vedere i dettagli';
  
END $$;


-- ============================================================================
-- QUERY VERIFICA 1: Punti finali di tutti
-- ============================================================================
SELECT 
  '📊 PUNTI FINALI' as section,
  u.email,
  u.referral_code,
  COALESCE(up.points_total, 0) as points_total,
  COALESCE(up.referrals_count, 0) as direct_referrals_count,
  (SELECT COUNT(*) FROM referral_network WHERE user_id = u.id AND level = 1) as level_1_count,
  (SELECT COUNT(*) FROM referral_network WHERE user_id = u.id AND level = 2) as level_2_count
FROM users u
LEFT JOIN user_points up ON u.id = up.user_id
WHERE u.referral_code = 'ADMIN001' 
   OR u.email LIKE '%@mlmtest.com'
ORDER BY 
  CASE 
    WHEN u.referral_code = 'ADMIN001' THEN 0
    ELSE 1
  END,
  u.created_at;


-- ============================================================================
-- QUERY VERIFICA 2: Dettaglio referral_network
-- ============================================================================
SELECT 
  '🌐 RETE REFERRAL' as section,
  u_receiver.email as chi_riceve_punti,
  rn.level as livello,
  u_referral.email as da_chi_si_e_registrato,
  rn.points_awarded as punti_assegnati,
  rn.created_at
FROM referral_network rn
JOIN users u_receiver ON rn.user_id = u_receiver.id
JOIN users u_referral ON rn.referral_id = u_referral.id
WHERE u_receiver.referral_code = 'ADMIN001' 
   OR u_receiver.email LIKE '%@mlmtest.com'
   OR u_referral.email LIKE '%@mlmtest.com'
ORDER BY rn.created_at;


-- ============================================================================
-- QUERY VERIFICA 3: Transazioni punti
-- ============================================================================
SELECT 
  '💰 TRANSAZIONI PUNTI' as section,
  u.email,
  pt.type,
  pt.points,
  pt.description,
  pt.created_at
FROM points_transactions pt
JOIN users u ON pt.user_id = u.id
WHERE pt.type IN ('referral_level_1', 'referral_level_2')
  AND pt.created_at > NOW() - INTERVAL '5 minutes'
ORDER BY pt.created_at;


-- ============================================================================
-- QUERY VERIFICA 4: Catena referral completa
-- ============================================================================
WITH RECURSIVE referral_chain AS (
  SELECT 
    id,
    email,
    referral_code,
    referred_by_id,
    0 as level,
    email as chain
  FROM users
  WHERE referral_code = 'ADMIN001'
  
  UNION ALL
  
  SELECT 
    u.id,
    u.email,
    u.referral_code,
    u.referred_by_id,
    rc.level + 1,
    rc.chain || ' → ' || u.email
  FROM users u
  INNER JOIN referral_chain rc ON u.referred_by_id = rc.id
  WHERE rc.level < 5
)
SELECT 
  '🔗 CATENA REFERRAL' as section,
  level as livello,
  email,
  chain as catena_completa,
  CASE 
    WHEN level = 0 THEN '👤 ROOT'
    WHEN level = 1 THEN '⭐ LIVELLO 1 (+1 punto a root)'
    WHEN level = 2 THEN '🌟 LIVELLO 2 (+1 punto a root)'
    WHEN level = 3 THEN '❌ LIVELLO 3 (nessun punto a root)'
    ELSE '❌ LIVELLO 4+ (nessun punto)'
  END as distribuzione_punti
FROM referral_chain
ORDER BY level;


-- ============================================================================
-- QUERY VERIFICA 5: Test integrità
-- ============================================================================
SELECT 
  '✅ TEST INTEGRITÀ' as section,
  u.email,
  COALESCE(SUM(rn.points_awarded), 0) as punti_calcolati,
  COALESCE(up.points_total, 0) as punti_registrati,
  CASE 
    WHEN COALESCE(SUM(rn.points_awarded), 0) = COALESCE(up.points_total, 0) THEN '✅ MATCH'
    ELSE '❌ MISMATCH!'
  END as verifica
FROM users u
LEFT JOIN referral_network rn ON u.id = rn.user_id
LEFT JOIN user_points up ON u.id = up.user_id
WHERE u.referral_code = 'ADMIN001' OR u.email LIKE '%@mlmtest.com'
GROUP BY u.email, up.points_total
ORDER BY 
  CASE WHEN u.referral_code = 'ADMIN001' THEN 0 ELSE 1 END,
  u.created_at;


-- ============================================================================
-- RISULTATO ATTESO
-- ============================================================================
SELECT 
  '🎯 RISULTATI ATTESI' as section,
  'Diego (ADMIN001)' as utente,
  '2 punti' as punti_attesi,
  '1 da User B (livello 1) + 1 da User C (livello 2)' as breakdown
UNION ALL
SELECT 
  '🎯 RISULTATI ATTESI',
  'User B',
  '2 punti',
  '1 da User C (livello 1) + 1 da User D (livello 2)'
UNION ALL
SELECT 
  '🎯 RISULTATI ATTESI',
  'User C',
  '1 punto',
  '1 da User D (livello 1)'
UNION ALL
SELECT 
  '🎯 RISULTATI ATTESI',
  'User D',
  '0 punti',
  'Nessuno invitato';


-- ============================================================================
-- CLEANUP (Opzionale)
-- ============================================================================
-- Decommenta per eliminare gli utenti di test
/*
DELETE FROM users WHERE email LIKE '%@mlmtest.com';
*/
