-- Verifica cosa c'è in referral_network dopo STEP 1
SELECT 
  u_receiver.email as chi_riceve,
  rn.level,
  u_referral.email as da_chi,
  rn.points_awarded,
  rn.created_at
FROM referral_network rn
JOIN users u_receiver ON rn.user_id = u_receiver.id
JOIN users u_referral ON rn.referral_id = u_referral.id
WHERE u_receiver.referral_code = 'ADMIN001'
ORDER BY rn.created_at;

-- Verifica transazioni Akirayouky
SELECT 
  pt.points,
  pt.description,
  pt.created_at
FROM points_transactions pt
JOIN users u ON pt.user_id = u.id
WHERE u.referral_code = 'ADMIN001'
AND pt.transaction_type = 'referral_completed'
ORDER BY pt.created_at;

-- Conta record in referral_network per tutti
SELECT 
  u.email,
  COUNT(rn.id) as num_records_network
FROM users u
LEFT JOIN referral_network rn ON rn.user_id = u.id
WHERE u.referral_code IN ('ADMIN001', '7ED64438', '0D54BEC9', '79AC703E')
GROUP BY u.email
ORDER BY u.email;
