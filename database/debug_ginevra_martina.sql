-- =====================================================
-- DEBUG: Verifica Ginevra e punti Martina
-- =====================================================

-- 1. Verifica che Ginevra esista e abbia referred_by_id di Martina
SELECT 
    id,
    email,
    first_name,
    last_name,
    referral_code,
    referred_by_id,
    points,
    created_at
FROM users
WHERE email LIKE '%ginevra%'
ORDER BY created_at DESC;

-- 2. Trova l'ID di Martina
SELECT 
    id,
    email,
    first_name,
    referral_code,
    points
FROM users
WHERE email LIKE '%martina%';

-- 3. Verifica tutti i referral DIRETTI di Martina
SELECT 
    u.email,
    u.first_name,
    u.last_name,
    u.referral_code,
    u.referred_by_id,
    m.email as "Email Martina",
    m.id as "ID Martina"
FROM users u
JOIN users m ON u.referred_by_id = m.id
WHERE m.email LIKE '%martina%'
ORDER BY u.created_at;

-- 4. Conta i referral per livello
SELECT 
    'MARTINA' as utente,
    COUNT(*) as diretti
FROM users
WHERE referred_by_id = (SELECT id FROM users WHERE email LIKE '%martina%' LIMIT 1);

-- 5. Verifica catena completa
SELECT 
    u.email,
    u.first_name,
    u.referral_code,
    r.email as "Invitato da",
    r.referral_code as "Codice Referrer"
FROM users u
LEFT JOIN users r ON u.referred_by_id = r.id
WHERE u.email LIKE '%ginevra%' OR u.email LIKE '%martina%'
ORDER BY u.created_at;