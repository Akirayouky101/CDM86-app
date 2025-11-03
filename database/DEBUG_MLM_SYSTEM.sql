-- ============================================================================
-- DEBUG: Verifica trigger e catena referral
-- ============================================================================

-- 1. Verifica che il trigger esista e sia abilitato
SELECT 
  '🔧 TRIGGER STATUS' as check,
  tgname as trigger_name,
  tgenabled as enabled,
  pg_get_triggerdef(oid) as definition
FROM pg_trigger
WHERE tgname = 'trigger_award_referral_points_mlm';


-- 2. Verifica la catena di referral (chi ha invitato chi)
SELECT 
  '👥 CATENA REFERRAL' as check,
  u.email,
  u.referral_code,
  r.email as referrer_email,
  r.referral_code as referrer_code,
  u.referred_by_id IS NOT NULL as ha_referrer
FROM users u
LEFT JOIN users r ON u.referred_by_id = r.id
WHERE u.email IN (
  'akirayouky@cdm86.com',
  'testb@cdm86.com',
  'testc@cdm86.com',
  'testd@cdm86.com'
)
ORDER BY u.created_at;


-- 3. Verifica tabella referral_network (dovrebbe contenere i record delle assegnazioni)
SELECT 
  '🌐 REFERRAL_NETWORK TABLE' as check,
  COUNT(*) as total_records
FROM referral_network;

SELECT 
  u_receiver.email as chi_riceve_punti,
  rn.level,
  u_referral.email as da_chi,
  rn.points_awarded
FROM referral_network rn
JOIN users u_receiver ON rn.user_id = u_receiver.id
JOIN users u_referral ON rn.referral_id = u_referral.id
ORDER BY rn.created_at;


-- 4. Verifica points_transactions
SELECT 
  '💸 POINTS_TRANSACTIONS TABLE' as check,
  COUNT(*) as total_records
FROM points_transactions
WHERE transaction_type = 'referral_completed';

SELECT 
  u.email,
  pt.points,
  pt.description
FROM points_transactions pt
JOIN users u ON pt.user_id = u.id
WHERE transaction_type = 'referral_completed'
ORDER BY pt.created_at;


-- 5. Verifica user_points per tutti e 4 gli utenti
SELECT 
  '📊 USER_POINTS TABLE' as check,
  u.email,
  COALESCE(up.points_total, 0) as points,
  up.referrals_count
FROM users u
LEFT JOIN user_points up ON u.id = up.user_id
WHERE u.email IN (
  'akirayouky@cdm86.com',
  'testb@cdm86.com',
  'testc@cdm86.com',
  'testd@cdm86.com'
)
ORDER BY u.created_at;
