-- ============================================================================
-- DEBUG: Verifica cosa c'è realmente nel database
-- ============================================================================

-- 1. Tutti gli utenti in auth.users (ultimi 10)
SELECT 
  '👥 UTENTI IN AUTH.USERS' as tipo,
  email,
  created_at,
  email_confirmed_at IS NOT NULL as email_confermata
FROM auth.users
ORDER BY created_at DESC
LIMIT 10;

-- 2. Tutti gli utenti in public.users (ultimi 10)
SELECT 
  '👤 UTENTI IN PUBLIC.USERS' as tipo,
  email,
  referral_code,
  referred_by_id,
  created_at
FROM users
ORDER BY created_at DESC
LIMIT 10;

-- 3. Cerca testb in entrambe le tabelle
SELECT 
  '🔍 RICERCA TESTB in auth.users' as tipo,
  email,
  created_at
FROM auth.users
WHERE email LIKE '%testb%'
ORDER BY created_at DESC;

SELECT 
  '🔍 RICERCA TESTB in public.users' as tipo,
  email,
  referral_code,
  created_at
FROM users
WHERE email LIKE '%testb%'
ORDER BY created_at DESC;
