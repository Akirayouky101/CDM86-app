-- ============================================================================
-- VERIFICA: Diego ha user_points?
-- ============================================================================

-- 1. Trova Diego
SELECT 'DIEGO IN USERS' as check, 
       id, 
       email, 
       referral_code, 
       first_name, 
       last_name
FROM users 
WHERE referral_code = 'ADMIN001';

-- 2. Verifica se Diego ha user_points
SELECT 'DIEGO IN USER_POINTS' as check,
       up.*
FROM users u
LEFT JOIN user_points up ON u.id = up.user_id
WHERE u.referral_code = 'ADMIN001';

-- 3. Controlla TUTTI i user_points
SELECT 'TUTTI USER_POINTS' as check,
       u.email,
       up.user_id,
       up.points_total,
       up.referrals_count
FROM user_points up
LEFT JOIN users u ON up.user_id = u.id;

-- 4. Trova utenti SENZA user_points
SELECT 'UTENTI SENZA USER_POINTS' as check,
       u.email,
       u.id,
       u.referral_code
FROM users u
LEFT JOIN user_points up ON u.id = up.user_id
WHERE up.user_id IS NULL;
