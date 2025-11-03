-- Conferma email per l'utente teste@cdm86.com
-- Questo script aggiorna lo stato di conferma email in Supabase Auth

-- Conferma l'utente (confirmed_at è una colonna generata, si aggiorna automaticamente)
UPDATE auth.users
SET email_confirmed_at = NOW()
WHERE email = 'teste@cdm86.com';

-- Verifica che sia stato confermato
SELECT 
    id,
    email,
    email_confirmed_at,
    confirmed_at,
    created_at
FROM auth.users
WHERE email = 'teste@cdm86.com';
