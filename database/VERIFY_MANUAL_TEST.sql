-- ============================================================================
-- VERIFICA RISULTATI TEST MANUALE MLM
-- ============================================================================

-- 1. PUNTI TOTALI PER UTENTE
SELECT 
  u.email,
  u.first_name || ' ' || u.last_name as nome,
  u.referral_code,
  COALESCE(up.points_total, 0) as punti_totali,
  COALESCE(up.referrals_count, 0) as num_referrals
FROM users u
LEFT JOIN user_points up ON u.id = up.user_id
WHERE u.email IN (
  'akirayouky@cdm86.com',
  'testb@cdm86.com',
  'testc@cdm86.com',
  'testd@cdm86.com'
)
ORDER BY u.created_at;


-- 2. RETE REFERRAL COMPLETA
SELECT 
  u_receiver.email as "Chi riceve punti",
  rn.level as "Livello",
  u_referral.email as "Da chi viene il referral",
  rn.points_awarded as "Punti assegnati",
  rn.referral_type as "Tipo"
FROM referral_network rn
JOIN users u_receiver ON rn.user_id = u_receiver.id
JOIN users u_referral ON rn.referral_id = u_referral.id
WHERE u_receiver.email IN (
  'akirayouky@cdm86.com',
  'testb@cdm86.com',
  'testc@cdm86.com',
  'testd@cdm86.com'
)
ORDER BY u_receiver.email, rn.level;


-- 3. TRANSAZIONI PUNTI
SELECT 
  u.email,
  pt.points as "Punti",
  pt.transaction_type as "Tipo",
  pt.description as "Descrizione",
  pt.created_at as "Data"
FROM points_transactions pt
JOIN users u ON pt.user_id = u.id
WHERE u.email IN (
  'akirayouky@cdm86.com',
  'testb@cdm86.com',
  'testc@cdm86.com',
  'testd@cdm86.com'
)
ORDER BY pt.created_at;


-- 4. RIEPILOGO FINALE
SELECT 
  'Akirayouky' as utente,
  (SELECT COALESCE(points_total, 0) FROM user_points WHERE user_id = (SELECT id FROM users WHERE referral_code = 'ADMIN001')) as punti_attuali,
  2 as punti_attesi
UNION ALL
SELECT 
  'User B',
  (SELECT COALESCE(points_total, 0) FROM user_points WHERE user_id = (SELECT id FROM users WHERE email = 'testb@cdm86.com')),
  2
UNION ALL
SELECT 
  'User C',
  (SELECT COALESCE(points_total, 0) FROM user_points WHERE user_id = (SELECT id FROM users WHERE email = 'testc@cdm86.com')),
  1
UNION ALL
SELECT 
  'User D',
  (SELECT COALESCE(points_total, 0) FROM user_points WHERE user_id = (SELECT id FROM users WHERE email = 'testd@cdm86.com')),
  0;
