-- ============================================================================
-- CONFERMA EMAIL UTENTI TEST
-- ============================================================================
-- Questo script conferma manualmente le email degli utenti test in Supabase
-- ============================================================================

UPDATE auth.users 
SET 
  email_confirmed_at = NOW()
WHERE email IN (
  'testb@cdm86test.com',
  'testc@cdm86test.com',
  'testd@cdm86test.com'
);

-- Verifica
SELECT 
  email,
  email_confirmed_at IS NOT NULL as email_confermata,
  created_at,
  email_confirmed_at
FROM auth.users
WHERE email IN (
  'testb@cdm86test.com',
  'testc@cdm86test.com',
  'testd@cdm86test.com'
)
ORDER BY created_at;
