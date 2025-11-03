-- ============================================================================
-- FIX DIEGO - Sincronizza auth.users con public.users
-- ============================================================================

DO $$ 
DECLARE
  v_diego_auth_id UUID;
BEGIN
  
  -- Trova ID da auth.users
  SELECT id INTO v_diego_auth_id 
  FROM auth.users 
  WHERE email = 'diegomarruchi@outlook.it';
  
  IF v_diego_auth_id IS NULL THEN
    RAISE EXCEPTION '❌ Diego non trovato in auth.users!';
  END IF;
  
  -- Inserisci in public.users se non esiste
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
  )
  ON CONFLICT (id) DO UPDATE SET
    referral_code = 'ADMIN001',
    role = 'admin',
    is_verified = true;
  
  -- Crea user_points se non esiste
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
  )
  ON CONFLICT (user_id) DO NOTHING;
  
  RAISE NOTICE '✅ Diego sincronizzato!';
  RAISE NOTICE '   ID: %', v_diego_auth_id;
  RAISE NOTICE '   Email: diegomarruchi@outlook.it';
  RAISE NOTICE '   Referral Code: ADMIN001';
  
END $$;

-- Verifica
SELECT 
  id,
  email,
  referral_code,
  role
FROM users 
WHERE email = 'diegomarruchi@outlook.it';
