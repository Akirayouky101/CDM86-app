-- ============================================================================
-- CREA DIEGO ADMIN
-- ============================================================================
-- Crea l'utente admin Diego con email e password specificati
-- ============================================================================

DO $$ 
DECLARE
  v_diego_auth_id UUID;
  v_diego_id UUID;
BEGIN
  
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
    '{"first_name":"Diego","last_name":"Marruchi"}'::jsonb,
    'authenticated',
    'authenticated'
  ) RETURNING id INTO v_diego_auth_id;
  
  -- 2. Crea in public.users
  INSERT INTO users (
    id,
    email,
    first_name,
    last_name,
    referral_code,
    role,
    is_verified,
    is_active
  ) VALUES (
    v_diego_auth_id,
    'diegomarruchi@outlook.it',
    'Diego',
    'Marruchi',
    'ADMIN001',
    'admin',
    true,
    true
  ) RETURNING id INTO v_diego_id;
  
  -- 3. Crea in user_points
  INSERT INTO user_points (
    user_id,
    points_total,
    points_available,
    referrals_count,
    level
  ) VALUES (
    v_diego_auth_id,
    0,
    0,
    0,
    'platinum'
  );
  
  RAISE NOTICE '✅ Diego Admin creato con successo!';
  RAISE NOTICE '   Email: diegomarruchi@outlook.it';
  RAISE NOTICE '   Password: Criogenia2025!';
  RAISE NOTICE '   Referral Code: ADMIN001';
  RAISE NOTICE '   ID: %', v_diego_auth_id;
  RAISE NOTICE '';
  RAISE NOTICE '🎯 Puoi ora eseguire TEST_MLM_COMPLETE_FULL.sql';
  
END $$;

-- Verifica
SELECT 
  id,
  email,
  referral_code,
  role,
  is_verified
FROM users 
WHERE email = 'diegomarruchi@outlook.it';
