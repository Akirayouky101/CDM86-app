-- =====================================================
-- CREA GIOVANNI MANUALMENTE IN PUBLIC.USERS
-- =====================================================

-- Prima esegui questa query per vedere i dati di giovanni
SELECT 
    id,
    email,
    created_at,
    raw_user_meta_data->>'first_name' as first_name,
    raw_user_meta_data->>'last_name' as last_name,
    raw_user_meta_data->>'referral_code_used' as referral_code_used
FROM auth.users
WHERE email = 'giovanni@cdm86.com';

-- Poi esegui questa per trovare l'ID di Vittoria (DCA3F142)
SELECT 
    id,
    email,
    referral_code,
    first_name,
    last_name
FROM users
WHERE referral_code = 'DCA3F142';

-- Infine, INSERISCI giovanni manualmente
-- (Sostituisci <GIOVANNI_ID> con l'ID dalla prima query)
-- (Sostituisci <VITTORIA_ID> con l'ID dalla seconda query)

INSERT INTO users (
    id,
    email,
    first_name,
    last_name,
    referral_code,
    referred_by_id,
    role,
    is_verified,
    is_active,
    points
)
SELECT 
    au.id,  -- ID di giovanni da auth.users
    au.email,
    COALESCE(au.raw_user_meta_data->>'first_name', 'Giovanni'),
    COALESCE(au.raw_user_meta_data->>'last_name', 'Rossi'),
    UPPER(SUBSTRING(MD5(RANDOM()::TEXT), 1, 8)),  -- Genera codice random
    (SELECT id FROM users WHERE referral_code = 'DCA3F142'),  -- ID di Vittoria
    'user',
    false,
    true,
    100
FROM auth.users au
WHERE au.email = 'giovanni@cdm86.com';

-- Attiva email
UPDATE auth.users
SET email_confirmed_at = NOW()
WHERE email = 'giovanni@cdm86.com';

-- Verifica risultato finale
SELECT 
    u.id,
    u.email,
    u.first_name,
    u.last_name,
    u.referral_code as "Codice Giovanni",
    u.referred_by_id as "ID Referrer",
    r.email as "Email Referrer",
    r.referral_code as "Codice Referrer (dovrebbe essere DCA3F142)",
    u.points,
    u.is_verified,
    u.is_active
FROM users u
LEFT JOIN users r ON u.referred_by_id = r.id
WHERE u.email = 'giovanni@cdm86.com';

-- Mostra tutta la catena referral
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
