-- Verifica transazioni User B, C, D
SELECT 
  u.email,
  u.referral_code,
  pt.points,
  pt.transaction_type,
  pt.description,
  pt.created_at
FROM points_transactions pt
JOIN users u ON pt.user_id = u.id
WHERE u.referral_code IN ('ADMIN001', '7ED64438', '0D54BEC9', '79AC703E')
ORDER BY pt.created_at;

-- Verifica punti finali
SELECT 
  u.email,
  u.referral_code,
  COALESCE(up.points_total, 0) as punti_totali,
  COALESCE(up.points_available, 0) as punti_disponibili,
  COALESCE(up.referrals_count, 0) as num_referrals
FROM users u
LEFT JOIN user_points up ON u.id = up.user_id
WHERE u.referral_code IN ('ADMIN001', '7ED64438', '0D54BEC9', '79AC703E')
ORDER BY u.created_at;
