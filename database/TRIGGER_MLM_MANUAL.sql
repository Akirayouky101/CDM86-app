-- ============================================================================
-- TRIGGER MANUALE MLM PER UTENTI ESISTENTI
-- ============================================================================
-- Dopo aver fixato il trigger, aggiorniamo manualmente i 3 utenti test
-- per far partire il sistema MLM retroattivamente
-- ============================================================================

-- IMPORTANTE: Sostituisci questi ID con quelli reali!
-- Puoi trovarli con: SELECT id, email, referral_code FROM users WHERE email LIKE '%test%';

-- Trova gli ID
DO $$ 
DECLARE
  v_admin_id UUID;
  v_testb_id UUID;
  v_testc_id UUID;
  v_testd_id UUID;
  v_testb_code VARCHAR(20);
  v_testc_code VARCHAR(20);
BEGIN
  -- Trova gli utenti
  SELECT id INTO v_admin_id FROM users WHERE referral_code = 'ADMIN001';
  SELECT id, referral_code INTO v_testb_id, v_testb_code FROM users WHERE email = 'testb@cdm86.com';
  SELECT id, referral_code INTO v_testc_id, v_testc_code FROM users WHERE email = 'testc@cdm86.com';
  SELECT id INTO v_testd_id FROM users WHERE email = 'testd@cdm86.com';
  
  RAISE NOTICE 'Admin ID: %', v_admin_id;
  RAISE NOTICE 'User B ID: % (code: %)', v_testb_id, v_testb_code;
  RAISE NOTICE 'User C ID: % (code: %)', v_testc_id, v_testc_code;
  RAISE NOTICE 'User D ID: %', v_testd_id;
  
  -- Imposta le relazioni referral
  -- User B → referito da Akirayouky
  UPDATE users 
  SET referred_by_id = v_admin_id 
  WHERE id = v_testb_id;
  
  -- User C → referito da User B
  UPDATE users 
  SET referred_by_id = v_testb_id 
  WHERE id = v_testc_id;
  
  -- User D → referito da User C
  UPDATE users 
  SET referred_by_id = v_testc_id 
  WHERE id = v_testd_id;
  
  RAISE NOTICE '✅ Relazioni referral impostate!';
END $$;

-- Verifica risultati
SELECT 
  u.email,
  u.referral_code,
  COALESCE(up.points_total, 0) as punti,
  r.email as referrer
FROM users u
LEFT JOIN user_points up ON u.id = up.user_id
LEFT JOIN users r ON u.referred_by_id = r.id
WHERE u.email IN (
  'akirayouky@cdm86.com',
  'testb@cdm86.com',
  'testc@cdm86.com',
  'testd@cdm86.com'
)
ORDER BY u.created_at;
