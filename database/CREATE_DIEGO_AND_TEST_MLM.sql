-- ============================================================================
-- STEP 1: CREA DIEGO ADMIN
-- ============================================================================

DO $$
DECLARE
  v_diego_auth_id UUID;
  v_diego_id UUID;
  v_diego_exists BOOLEAN;
BEGIN
  
  RAISE NOTICE '🔧 Creazione Diego Admin...';
  
  -- Controlla se Diego esiste già
  SELECT EXISTS(SELECT 1 FROM auth.users WHERE email = 'diegomarruchi@outlook.it') INTO v_diego_exists;
  
  IF v_diego_exists THEN
    -- Diego esiste già, recupera l'ID
    SELECT id INTO v_diego_auth_id FROM auth.users WHERE email = 'diegomarruchi@outlook.it';
    RAISE NOTICE '⚠️  Diego già esistente, ID: %', v_diego_auth_id;
    
    -- Aggiorna public.users se necessario
    UPDATE users 
    SET referral_code = 'ADMIN001',
        role = 'admin',
        updated_at = NOW()
    WHERE id = v_diego_auth_id;
    
    -- Aggiorna user_points se necessario
    UPDATE user_points 
    SET updated_at = NOW()
    WHERE user_id = v_diego_auth_id;
    
  ELSE
    -- Diego non esiste, crealo
    
    -- 1. Crea in auth.users
    INSERT INTO auth.users (
      id,
      email,
      encrypted_password,
      email_confirmed_at,
      created_at,
      updated_at,
      raw_app_meta_data,
      raw_user_meta_data,
      aud,
      role
    ) VALUES (
      gen_random_uuid(),
      'diegomarruchi@outlook.it',
      crypt('Criogenia2025!', gen_salt('bf')),
      NOW(),
      NOW(),
      NOW(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      '{"role":"admin"}'::jsonb,
      'authenticated',
      'authenticated'
    )
    RETURNING id INTO v_diego_auth_id;
    
    -- 2. Crea in public.users
    INSERT INTO users (
      id,
      email,
      first_name,
      last_name,
      referral_code,
      account_type,
      role
    ) VALUES (
      v_diego_auth_id,
      'diegomarruchi@outlook.it',
      'Diego',
      'Marruchi',
      'ADMIN001',
      'user',
      'admin'
    )
    ON CONFLICT (id) DO UPDATE
    SET referral_code = 'ADMIN001',
        role = 'admin',
        updated_at = NOW()
    RETURNING id INTO v_diego_id;
    
    -- 3. Crea in user_points
    INSERT INTO user_points (
      user_id,
      points_total,
      points_available,
      referrals_count
    ) VALUES (
      v_diego_auth_id,
      0,
      0,
      0
    )
    ON CONFLICT (user_id) DO UPDATE
    SET updated_at = NOW();
    
    RAISE NOTICE '✅ Diego creato con successo!';
    RAISE NOTICE '   Email: diegomarruchi@outlook.it';
    RAISE NOTICE '   Password: Criogenia2025!';
    RAISE NOTICE '   Referral Code: ADMIN001';
    RAISE NOTICE '   ID: %', v_diego_auth_id;
    
  END IF;
  
END $$;


-- ============================================================================
-- STEP 2: TEST MLM COMPLETO - 3 LIVELLI
-- ============================================================================

DO $$ 
DECLARE
  v_diego_id UUID;
  v_user_b_auth_id UUID;
  v_user_c_auth_id UUID;
  v_user_d_auth_id UUID;
  v_user_b_id UUID;
  v_user_c_id UUID;
  v_user_d_id UUID;
  v_email_b VARCHAR(100) := 'mlmtest-b-' || FLOOR(RANDOM() * 100000)::TEXT || '@test.com';
  v_email_c VARCHAR(100) := 'mlmtest-c-' || FLOOR(RANDOM() * 100000)::TEXT || '@test.com';
  v_email_d VARCHAR(100) := 'mlmtest-d-' || FLOOR(RANDOM() * 100000)::TEXT || '@test.com';
  v_code_b VARCHAR(20);
  v_code_c VARCHAR(20);
  v_code_d VARCHAR(20);
  v_diego_points_before INTEGER;
  v_diego_points_after INTEGER;
BEGIN
  
  -- ========================================================================
  -- SETUP: Trova Diego
  -- ========================================================================
  
  SELECT id INTO v_diego_id FROM users WHERE referral_code = 'ADMIN001';
  
  IF v_diego_id IS NULL THEN
    RAISE EXCEPTION '❌ Diego (ADMIN001) non trovato!';
  END IF;
  
  -- Punti Diego prima del test
  SELECT COALESCE(points_total, 0) INTO v_diego_points_before
  FROM user_points WHERE user_id = v_diego_id;
  
  RAISE NOTICE '';
  RAISE NOTICE '═══════════════════════════════════════════════════════════';
  RAISE NOTICE '🎯 TEST MLM COMPLETO - 3 LIVELLI';
  RAISE NOTICE '═══════════════════════════════════════════════════════════';
  RAISE NOTICE '';
  RAISE NOTICE '📋 CONFIGURAZIONE:';
  RAISE NOTICE '   Diego ID: %', v_diego_id;
  RAISE NOTICE '   Diego punti iniziali: %', v_diego_points_before;
  RAISE NOTICE '';
  RAISE NOTICE '🎬 SCENARIO TEST:';
  RAISE NOTICE '   Diego invita User B     → Diego +1';
  RAISE NOTICE '   User B invita User C    → Diego +1, User B +1';
  RAISE NOTICE '   User C invita User D    → User B +1, User C +1 (Diego NO)';
  RAISE NOTICE '';
  RAISE NOTICE '🎯 ATTESO FINALE:';
  RAISE NOTICE '   Diego: % punti', v_diego_points_before + 2;
  RAISE NOTICE '   User B: 2 punti';
  RAISE NOTICE '   User C: 1 punto';
  RAISE NOTICE '   User D: 0 punti';
  RAISE NOTICE '';
  RAISE NOTICE '═══════════════════════════════════════════════════════════';
  RAISE NOTICE '';
  
  -- ========================================================================
  -- STEP 1: Crea User B (referral diretto di Diego)
  -- ========================================================================
  
  RAISE NOTICE '1️⃣  CREAZIONE USER B (referral di Diego)...';
  
  -- Genera referral code
  v_code_b := 'TESTB' || FLOOR(RANDOM() * 10000)::TEXT;
  
  -- 1a. Crea in auth.users
  INSERT INTO auth.users (
    id,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    raw_app_meta_data,
    raw_user_meta_data,
    aud,
    role
  ) VALUES (
    gen_random_uuid(),
    v_email_b,
    crypt('password123', gen_salt('bf')),
    NOW(),
    NOW(),
    NOW(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{}'::jsonb,
    'authenticated',
    'authenticated'
  ) RETURNING id INTO v_user_b_auth_id;
  
  -- 1b. Crea in public.users
  INSERT INTO users (
    id,
    email,
    first_name,
    last_name,
    referral_code,
    referred_by_id,
    account_type
  ) VALUES (
    v_user_b_auth_id,
    v_email_b,
    'Test',
    'User B',
    v_code_b,
    v_diego_id,
    'user'
  ) RETURNING id INTO v_user_b_id;
  
  -- 1c. Crea in user_points
  INSERT INTO user_points (
    user_id,
    points_total,
    points_available,
    referrals_count
  ) VALUES (
    v_user_b_auth_id,
    0,
    0,
    0
  );
  
  RAISE NOTICE '   ✅ User B creato:';
  RAISE NOTICE '      Email: %', v_email_b;
  RAISE NOTICE '      Code: %', v_code_b;
  RAISE NOTICE '      ID: %', v_user_b_auth_id;
  
  PERFORM pg_sleep(0.5);
  
  -- Verifica punti Diego dopo User B
  SELECT COALESCE(points_total, 0) INTO v_diego_points_after
  FROM user_points WHERE user_id = v_diego_id;
  
  RAISE NOTICE '';
  RAISE NOTICE '   📊 Diego punti: % → % (diff: +%)', 
    v_diego_points_before, 
    v_diego_points_after,
    v_diego_points_after - v_diego_points_before;
  
  
  -- ========================================================================
  -- STEP 2: Crea User C (referral di User B)
  -- ========================================================================
  
  RAISE NOTICE '';
  RAISE NOTICE '2️⃣  CREAZIONE USER C (referral di User B)...';
  
  v_code_c := 'TESTC' || FLOOR(RANDOM() * 10000)::TEXT;
  
  -- 2a. Crea in auth.users
  INSERT INTO auth.users (
    id,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    raw_app_meta_data,
    raw_user_meta_data,
    aud,
    role
  ) VALUES (
    gen_random_uuid(),
    v_email_c,
    crypt('password123', gen_salt('bf')),
    NOW(),
    NOW(),
    NOW(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{}'::jsonb,
    'authenticated',
    'authenticated'
  ) RETURNING id INTO v_user_c_auth_id;
  
  -- 2b. Crea in public.users
  INSERT INTO users (
    id,
    email,
    first_name,
    last_name,
    referral_code,
    referred_by_id,
    account_type
  ) VALUES (
    v_user_c_auth_id,
    v_email_c,
    'Test',
    'User C',
    v_code_c,
    v_user_b_id,
    'user'
  ) RETURNING id INTO v_user_c_id;
  
  -- 2c. Crea in user_points
  INSERT INTO user_points (
    user_id,
    points_total,
    points_available,
    referrals_count
  ) VALUES (
    v_user_c_auth_id,
    0,
    0,
    0
  );
  
  RAISE NOTICE '   ✅ User C creato:';
  RAISE NOTICE '      Email: %', v_email_c;
  RAISE NOTICE '      Code: %', v_code_c;
  RAISE NOTICE '      ID: %', v_user_c_auth_id;
  
  PERFORM pg_sleep(0.5);
  
  -- Verifica punti
  RAISE NOTICE '';
  RAISE NOTICE '   📊 Punti dopo User C:';
  RAISE NOTICE '      Diego: % (atteso: %)', 
    (SELECT COALESCE(points_total, 0) FROM user_points WHERE user_id = v_diego_id),
    v_diego_points_before + 2;
  RAISE NOTICE '      User B: % (atteso: 1)', 
    (SELECT COALESCE(points_total, 0) FROM user_points WHERE user_id = v_user_b_auth_id);
  
  
  -- ========================================================================
  -- STEP 3: Crea User D (referral di User C)
  -- ========================================================================
  
  RAISE NOTICE '';
  RAISE NOTICE '3️⃣  CREAZIONE USER D (referral di User C)...';
  
  v_code_d := 'TESTD' || FLOOR(RANDOM() * 10000)::TEXT;
  
  -- 3a. Crea in auth.users
  INSERT INTO auth.users (
    id,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    raw_app_meta_data,
    raw_user_meta_data,
    aud,
    role
  ) VALUES (
    gen_random_uuid(),
    v_email_d,
    crypt('password123', gen_salt('bf')),
    NOW(),
    NOW(),
    NOW(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{}'::jsonb,
    'authenticated',
    'authenticated'
  ) RETURNING id INTO v_user_d_auth_id;
  
  -- 3b. Crea in public.users
  INSERT INTO users (
    id,
    email,
    first_name,
    last_name,
    referral_code,
    referred_by_id,
    account_type
  ) VALUES (
    v_user_d_auth_id,
    v_email_d,
    'Test',
    'User D',
    v_code_d,
    v_user_c_id,
    'user'
  ) RETURNING id INTO v_user_d_id;
  
  -- 3c. Crea in user_points
  INSERT INTO user_points (
    user_id,
    points_total,
    points_available,
    referrals_count
  ) VALUES (
    v_user_d_auth_id,
    0,
    0,
    0
  );
  
  RAISE NOTICE '   ✅ User D creato:';
  RAISE NOTICE '      Email: %', v_email_d;
  RAISE NOTICE '      Code: %', v_code_d;
  RAISE NOTICE '      ID: %', v_user_d_auth_id;
  
  PERFORM pg_sleep(0.5);
  
  
  -- ========================================================================
  -- RISULTATI FINALI
  -- ========================================================================
  
  RAISE NOTICE '';
  RAISE NOTICE '═══════════════════════════════════════════════════════════';
  RAISE NOTICE '📊 RISULTATI FINALI';
  RAISE NOTICE '═══════════════════════════════════════════════════════════';
  RAISE NOTICE '';
  
  RAISE NOTICE '👤 PUNTI UTENTI:';
  RAISE NOTICE '   Diego:  % punti (atteso: %)', 
    (SELECT COALESCE(points_total, 0) FROM user_points WHERE user_id = v_diego_id),
    v_diego_points_before + 2;
  RAISE NOTICE '   User B: % punti (atteso: 2)', 
    (SELECT COALESCE(points_total, 0) FROM user_points WHERE user_id = v_user_b_auth_id);
  RAISE NOTICE '   User C: % punti (atteso: 1)', 
    (SELECT COALESCE(points_total, 0) FROM user_points WHERE user_id = v_user_c_auth_id);
  RAISE NOTICE '   User D: % punti (atteso: 0)', 
    (SELECT COALESCE(points_total, 0) FROM user_points WHERE user_id = v_user_d_auth_id);
  
  RAISE NOTICE '';
  RAISE NOTICE '🌐 RETE REFERRAL:';
  RAISE NOTICE '   Diego: % record', 
    (SELECT COUNT(*) FROM referral_network WHERE user_id = v_diego_id);
  RAISE NOTICE '   User B: % record', 
    (SELECT COUNT(*) FROM referral_network WHERE user_id = v_user_b_auth_id);
  RAISE NOTICE '   User C: % record', 
    (SELECT COUNT(*) FROM referral_network WHERE user_id = v_user_c_auth_id);
  
  RAISE NOTICE '';
  RAISE NOTICE '💸 TRANSACTIONS:';
  RAISE NOTICE '   Diego: % transazioni', 
    (SELECT COUNT(*) FROM points_transactions WHERE user_id = v_diego_id AND transaction_type = 'referral_completed');
  RAISE NOTICE '   User B: % transazioni', 
    (SELECT COUNT(*) FROM points_transactions WHERE user_id = v_user_b_auth_id AND transaction_type = 'referral_completed');
  RAISE NOTICE '   User C: % transazioni', 
    (SELECT COUNT(*) FROM points_transactions WHERE user_id = v_user_c_auth_id AND transaction_type = 'referral_completed');
  
  RAISE NOTICE '';
  RAISE NOTICE '═══════════════════════════════════════════════════════════';
  RAISE NOTICE '✅ TEST COMPLETATO!';
  RAISE NOTICE '═══════════════════════════════════════════════════════════';
  RAISE NOTICE '';
  
END $$;


-- ============================================================================
-- VERIFICA DETTAGLIATA: PUNTI
-- ============================================================================

SELECT '📊 PUNTI FINALI' as check;
SELECT 
  u.email,
  u.referral_code,
  up.points_total,
  up.referrals_count,
  up.level
FROM users u
LEFT JOIN user_points up ON u.id = up.user_id
WHERE u.email LIKE '%mlmtest%' OR u.referral_code = 'ADMIN001'
ORDER BY u.created_at;


-- ============================================================================
-- VERIFICA DETTAGLIATA: RETE REFERRAL
-- ============================================================================

SELECT '🌐 RETE REFERRAL COMPLETA' as check;
SELECT 
  u_receiver.email as chi_riceve_punti,
  rn.level,
  u_referral.email as da_chi_viene_referral,
  rn.points_awarded,
  rn.referral_type,
  rn.created_at
FROM referral_network rn
JOIN users u_receiver ON rn.user_id = u_receiver.id
JOIN users u_referral ON rn.referral_id = u_referral.id
WHERE u_receiver.email LIKE '%mlmtest%' OR u_receiver.referral_code = 'ADMIN001'
ORDER BY rn.created_at;


-- ============================================================================
-- VERIFICA DETTAGLIATA: TRANSACTIONS
-- ============================================================================

SELECT '💸 TUTTE LE TRANSACTIONS' as check;
SELECT 
  u.email,
  pt.points,
  pt.transaction_type,
  pt.description,
  pt.created_at
FROM points_transactions pt
JOIN users u ON pt.user_id = u.id
WHERE u.email LIKE '%mlmtest%' OR u.referral_code = 'ADMIN001'
ORDER BY pt.created_at;
