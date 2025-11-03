-- ============================================================================
-- CHECK RAPIDO: Verifica se referral system sta già funzionando
-- ============================================================================

-- Query 1: Verifica utenti con referral già registrati
SELECT 
  'Utenti con referral già impostato' as check_type,
  u.id,
  u.email,
  u.referred_by_id,
  ref.email as referred_by_email,
  ref.referral_code as referred_by_code,
  u.created_at
FROM users u
LEFT JOIN users ref ON u.referred_by_id = ref.id
WHERE u.referred_by_id IS NOT NULL
ORDER BY u.created_at DESC
LIMIT 10;

-- Query 2: Verifica se ci sono già punti assegnati in referral_network
SELECT 
  'Punti già assegnati nel sistema MLM' as check_type,
  COUNT(*) as total_assignments,
  SUM(CASE WHEN level = 1 THEN 1 ELSE 0 END) as level_1_assignments,
  SUM(CASE WHEN level = 2 THEN 1 ELSE 0 END) as level_2_assignments
FROM referral_network;

-- Query 3: Verifica punti admin attuali
SELECT 
  'Punti admin attuali' as check_type,
  u.email,
  u.referral_code,
  COALESCE(up.points_total, 0) as points_total,
  COALESCE(up.referrals_count, 0) as referrals_count
FROM users u
LEFT JOIN user_points up ON u.id = up.user_id
WHERE u.referral_code IN ('ADMIN001', 'ADMIN002')
ORDER BY u.referral_code;
