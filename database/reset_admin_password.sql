-- Reset password per akirayouky@cdm86.com
-- IMPORTANTE: Questo richiede che tu vada su Supabase Dashboard → Authentication → Users
-- Cerca akirayouky@cdm86.com, clicca sui tre puntini, "Send password recovery email"

-- OPPURE usa questo per verificare quale email è registrata come admin:
SELECT 
    id,
    email,
    email_confirmed_at,
    created_at,
    last_sign_in_at
FROM auth.users
WHERE email IN ('akirayouky@cdm86.com', 'diegomarruchi@outlook.it')
ORDER BY created_at;

-- Per fare login come admin senza password (SOLO PER SVILUPPO):
-- Vai su Supabase Dashboard → Authentication → Users
-- Clicca sull'utente akirayouky@cdm86.com
-- Clicca "Send magic link" per ricevere un link di login via email
