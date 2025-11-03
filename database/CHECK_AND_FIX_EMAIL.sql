-- Verifica stato email confirmation
SELECT 
  email,
  email_confirmed_at,
  confirmed_at,
  CASE 
    WHEN email_confirmed_at IS NOT NULL THEN '✅ Confermata'
    ELSE '❌ NON confermata'
  END as stato
FROM auth.users
WHERE email = 'testb@cdm86test.com';

-- Se NON è confermata, forza la conferma
UPDATE auth.users 
SET email_confirmed_at = NOW()
WHERE email = 'testb@cdm86test.com'
AND email_confirmed_at IS NULL;

-- Verifica di nuovo
SELECT 
  email,
  email_confirmed_at,
  confirmed_at,
  CASE 
    WHEN email_confirmed_at IS NOT NULL THEN '✅ Confermata'
    ELSE '❌ NON confermata'
  END as stato
FROM auth.users
WHERE email = 'testb@cdm86test.com';
