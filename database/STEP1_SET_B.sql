-- STEP 1: Imposta User B → Akirayouky
UPDATE users 
SET referred_by_id = (SELECT id FROM users WHERE referral_code = 'ADMIN001')
WHERE referral_code = '7ED64438';

-- Verifica
SELECT 'DOPO STEP 1' as step;
SELECT u.email, COALESCE(up.points_total, 0) as punti
FROM users u
LEFT JOIN user_points up ON u.id = up.user_id
WHERE u.referral_code IN ('ADMIN001', '7ED64438')
ORDER BY u.created_at;
