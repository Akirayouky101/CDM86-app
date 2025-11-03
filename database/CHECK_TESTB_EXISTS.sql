-- Verifica se User B esiste
SELECT 
  'AUTH.USERS' as tabella,
  email,
  created_at,
  email_confirmed_at IS NOT NULL as confermata
FROM auth.users
WHERE email = 'testb@cdm86.com';

SELECT 
  'PUBLIC.USERS' as tabella,
  email,
  referral_code,
  created_at
FROM users
WHERE email = 'testb@cdm86.com';

-- Tutti gli utenti test in auth.users
SELECT 
  'TUTTI TEST in AUTH.USERS' as info,
  email,
  created_at
FROM auth.users
WHERE email LIKE '%test%@cdm86.com'
ORDER BY created_at;

-- Tutti gli utenti test in public.users
SELECT 
  'TUTTI TEST in PUBLIC.USERS' as info,
  email,
  referral_code,
  created_at
FROM users
WHERE email LIKE '%test%@cdm86.com'
ORDER BY created_at;
