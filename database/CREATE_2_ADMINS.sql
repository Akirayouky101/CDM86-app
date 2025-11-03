-- ============================================================================
-- CREA 2 ADMIN: Akirayouky e Claudio
-- ============================================================================

DO $$
DECLARE
  v_akirayouky_id UUID;
  v_claudio_id UUID;
BEGIN
  
  RAISE NOTICE '👥 Creazione amministratori...';
  RAISE NOTICE '';
  
  -- ========================================================================
  -- ADMIN 1: Akirayouky
  -- ========================================================================
  
  -- Controlla se esiste già
  SELECT id INTO v_akirayouky_id FROM auth.users WHERE email = 'akirayouky@cdm86.com';
  
  -- 1a. Crea in auth.users (solo se non esiste)
  IF v_akirayouky_id IS NULL THEN
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
      'akirayouky@cdm86.com',
      crypt('Criogenia2025!', gen_salt('bf')),
      NOW(),
      NOW(),
      NOW(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      '{"role":"admin"}'::jsonb,
      'authenticated',
      'authenticated'
    )
    RETURNING id INTO v_akirayouky_id;
  END IF;
  
  -- 1b. Crea in public.users
  INSERT INTO users (
    id,
    email,
    first_name,
    last_name,
    referral_code,
    account_type,
    role
  ) VALUES (
    v_akirayouky_id,
    'akirayouky@cdm86.com',
    'Akira',
    'Youky',
    'ADMIN001',
    'user',
    'admin'
  )
  ON CONFLICT (id) DO UPDATE
  SET referral_code = 'ADMIN001',
      role = 'admin',
      updated_at = NOW();
  
  -- 1c. Crea in user_points
  INSERT INTO user_points (
    user_id,
    points_total,
    points_available,
    referrals_count
  ) VALUES (
    v_akirayouky_id,
    0,
    0,
    0
  )
  ON CONFLICT (user_id) DO UPDATE
  SET updated_at = NOW();
  
  RAISE NOTICE '✅ Admin 1 creato:';
  RAISE NOTICE '   Nome: Akira Youky';
  RAISE NOTICE '   Email: akirayouky@cdm86.com';
  RAISE NOTICE '   Password: Criogenia2025!';
  RAISE NOTICE '   Referral Code: ADMIN001';
  RAISE NOTICE '   ID: %', v_akirayouky_id;
  RAISE NOTICE '';
  
  
  -- ========================================================================
  -- ADMIN 2: Claudio
  -- ========================================================================
  
  -- Controlla se esiste già
  SELECT id INTO v_claudio_id FROM auth.users WHERE email = 'claudio@cdm86.com';
  
  -- 2a. Crea in auth.users (solo se non esiste)
  IF v_claudio_id IS NULL THEN
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
      'claudio@cdm86.com',
      crypt('Criogenia2025!', gen_salt('bf')),
      NOW(),
      NOW(),
      NOW(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      '{"role":"admin"}'::jsonb,
      'authenticated',
      'authenticated'
    )
    RETURNING id INTO v_claudio_id;
  END IF;
  
  -- 2b. Crea in public.users
  INSERT INTO users (
    id,
    email,
    first_name,
    last_name,
    referral_code,
    account_type,
    role
  ) VALUES (
    v_claudio_id,
    'claudio@cdm86.com',
    'Claudio',
    'Admin',
    'ADMIN002',
    'user',
    'admin'
  )
  ON CONFLICT (id) DO UPDATE
  SET referral_code = 'ADMIN002',
      role = 'admin',
      updated_at = NOW();
  
  -- 2c. Crea in user_points
  INSERT INTO user_points (
    user_id,
    points_total,
    points_available,
    referrals_count
  ) VALUES (
    v_claudio_id,
    0,
    0,
    0
  )
  ON CONFLICT (user_id) DO UPDATE
  SET updated_at = NOW();
  
  RAISE NOTICE '✅ Admin 2 creato:';
  RAISE NOTICE '   Nome: Claudio Admin';
  RAISE NOTICE '   Email: claudio@cdm86.com';
  RAISE NOTICE '   Password: Criogenia2025!';
  RAISE NOTICE '   Referral Code: ADMIN002';
  RAISE NOTICE '   ID: %', v_claudio_id;
  RAISE NOTICE '';
  
  RAISE NOTICE '═══════════════════════════════════════════════════════════';
  RAISE NOTICE '🎉 2 AMMINISTRATORI CREATI CON SUCCESSO!';
  RAISE NOTICE '═══════════════════════════════════════════════════════════';
  
END $$;


-- ============================================================================
-- VERIFICA: Controlla gli admin creati
-- ============================================================================

SELECT '👥 AMMINISTRATORI CREATI' as check;
SELECT 
  u.email,
  u.first_name,
  u.last_name,
  u.referral_code,
  u.role,
  up.points_total,
  up.referrals_count
FROM users u
LEFT JOIN user_points up ON u.id = up.user_id
WHERE u.role = 'admin'
ORDER BY u.referral_code;
