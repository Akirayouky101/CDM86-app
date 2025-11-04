-- =====================================================
-- ATTIVA SOLO EMAIL giuseppe@cdm86.com
-- =====================================================

-- Attiva email in auth.users
UPDATE auth.users
SET email_confirmed_at = NOW()
WHERE email = 'giuseppe@cdm86.com';

-- Verifica attivazione
SELECT 
    email,
    email_confirmed_at,
    created_at
FROM auth.users
WHERE email = 'giuseppe@cdm86.com';