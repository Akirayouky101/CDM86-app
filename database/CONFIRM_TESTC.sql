-- ============================================================================
-- CONFERMA EMAIL: testc@cdm86.com
-- ============================================================================

-- Conferma l'email
UPDATE auth.users 
SET email_confirmed_at = NOW()
WHERE email = 'testc@cdm86.com'
AND email_confirmed_at IS NULL;

-- Verifica
SELECT 
  email,
  email_confirmed_at,
  confirmed_at,
  CASE 
    WHEN email_confirmed_at IS NOT NULL THEN '✅ Email confermata'
    ELSE '❌ Email NON confermata'
  END as stato,
  created_at
FROM auth.users
WHERE email = 'testc@cdm86.com';
