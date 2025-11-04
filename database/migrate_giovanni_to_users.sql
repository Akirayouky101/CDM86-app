-- =====================================================
-- MIGRA giovanni@cdm86.com da auth.users a public.users
-- =====================================================

-- 1. Verifica che giovanni esista in auth.users
SELECT 
    id,
    email,
    created_at,
    email_confirmed_at,
    raw_user_meta_data->>'first_name' as first_name,
    raw_user_meta_data->>'last_name' as last_name,
    raw_user_meta_data->>'referral_code_used' as referral_code_used
FROM auth.users
WHERE email = 'giovanni@cdm86.com';

-- 2. Trova l'ID del referrer (se ha usato un codice)
-- Cambia 'ADMIN001' con il codice che giovanni ha usato in registrazione
SELECT 
    id,
    email,
    referral_code
FROM users
WHERE referral_code = 'ADMIN001';  -- 👈 CAMBIA QUI se ha usato un altro codice

-- 3. Inserisci giovanni in public.users con il referral
-- NOTA: Sostituisci i valori tra <...> con quelli reali
INSERT INTO users (
    id,
    email,
    password_hash,
    first_name,
    last_name,
    referral_code,
    referred_by_id,  -- 👈 Metti l'ID del referrer trovato sopra
    role,
    is_verified,
    is_active,
    points,
    created_at
)
SELECT 
    au.id,
    au.email,
    'auth_managed',
    COALESCE(au.raw_user_meta_data->>'first_name', 'Giovanni'),
    COALESCE(au.raw_user_meta_data->>'last_name', 'Unknown'),
    UPPER(SUBSTRING(MD5(RANDOM()::TEXT), 1, 8)),  -- Genera codice referral univoco
    (SELECT id FROM users WHERE referral_code = 'ADMIN001'),  -- 👈 CAMBIA QUI se necessario
    'user',
    true,  -- is_verified
    true,  -- is_active
    100,   -- punti iniziali
    au.created_at
FROM auth.users au
WHERE au.email = 'giovanni@cdm86.com'
AND NOT EXISTS (
    SELECT 1 FROM users WHERE id = au.id
);

-- 4. Attiva l'email confirmation
UPDATE auth.users
SET email_confirmed_at = NOW()
WHERE email = 'giovanni@cdm86.com'
AND email_confirmed_at IS NULL;

-- 5. Verifica che tutto sia ok
SELECT 
    u.id,
    u.email,
    u.first_name,
    u.last_name,
    u.referral_code as "Suo Codice",
    u.referred_by_id as "Invitato da ID",
    r.email as "Email Referrer",
    r.referral_code as "Codice Referrer",
    u.points,
    u.is_verified,
    u.is_active
FROM users u
LEFT JOIN users r ON u.referred_by_id = r.id
WHERE u.email = 'giovanni@cdm86.com';

-- 6. Mostra la catena referral completa
SELECT 
    u.email,
    u.first_name,
    u.last_name,
    u.referral_code as "Codice",
    r.email as "Invitato da",
    r.referral_code as "Codice Referrer"
FROM users u
LEFT JOIN users r ON u.referred_by_id = r.id
ORDER BY u.created_at DESC;
