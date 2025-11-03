-- STEP 2: Imposta User C → User B
UPDATE users 
SET referred_by_id = (SELECT id FROM users WHERE referral_code = '7ED64438')
WHERE referral_code = '0D54BEC9';

-- Verifica
SELECT 'DOPO STEP 2' as step;
SELECT u.email, COALESCE(up.points_total, 0) as punti
FROM users u
LEFT JOIN user_points up ON u.id = up.user_id
WHERE u.referral_code IN ('ADMIN001', '7ED64438', '0D54BEC9')
ORDER BY u.created_at;
