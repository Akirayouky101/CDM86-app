-- STEP 3: Imposta User D → User C
UPDATE users 
SET referred_by_id = (SELECT id FROM users WHERE referral_code = '0D54BEC9')
WHERE referral_code = '79AC703E';

-- Verifica finale
SELECT 'DOPO STEP 3 - FINALE' as step;
SELECT 
  u.email,
  u.referral_code,
  COALESCE(up.points_total, 0) as punti_totali,
  CASE u.referral_code
    WHEN 'ADMIN001' THEN 2
    WHEN '7ED64438' THEN 2
    WHEN '0D54BEC9' THEN 1
    WHEN '79AC703E' THEN 0
  END as punti_attesi
FROM users u
LEFT JOIN user_points up ON u.id = up.user_id
WHERE u.referral_code IN ('ADMIN001', '7ED64438', '0D54BEC9', '79AC703E')
ORDER BY u.created_at;
