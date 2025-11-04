-- =====================================================
-- ATTIVA UTENTE vittoria@cdm86.com
-- =====================================================

-- 1. Trova e attiva l'utente nella tabella users
UPDATE users
SET 
    is_verified = true,
    is_active = true
WHERE email = 'vittoria@cdm86.com';

-- 2. Attiva anche nella tabella auth.users di Supabase (se esiste)
UPDATE auth.users
SET 
    email_confirmed_at = NOW()
WHERE email = 'vittoria@cdm86.com';

-- 3. Verifica l'attivazione
SELECT 
    id,
    email,
    first_name,
    last_name,
    referral_code,
    referred_by_id,
    points,
    is_verified,
    is_active
FROM users
WHERE email = 'vittoria@cdm86.com';

-- 4. Verifica chi ha invitato (se c'è un referred_by_id)
SELECT 
    u.email as "Utente",
    u.referral_code as "Suo Codice",
    u.referred_by_id as "Invitato da (ID)",
    r.email as "Referrer Email",
    r.referral_code as "Referrer Code",
    r.points as "Punti Referrer"
FROM users u
LEFT JOIN users r ON u.referred_by_id = r.id
WHERE u.email = 'vittoria@cdm86.com';
