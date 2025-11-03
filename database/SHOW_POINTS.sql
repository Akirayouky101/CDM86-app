-- PUNTI TOTALI PER UTENTE
SELECT 
  u.email,
  u.referral_code,
  COALESCE(up.points_total, 0) as punti_totali,
  COALESCE(up.points_available, 0) as punti_disponibili,
  COALESCE(up.referrals_count, 0) as num_referrals_diretti
FROM users u
LEFT JOIN user_points up ON u.id = up.user_id
WHERE u.referral_code IN ('ADMIN001', '7ED64438', '0D54BEC9', '79AC703E')
ORDER BY u.created_at;
