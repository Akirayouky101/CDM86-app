-- ============================================================================
-- CORREGGI NOMI AMMINISTRATORI
-- ============================================================================

-- Correggi Akirayouky
UPDATE users 
SET 
  first_name = 'Akirayouky',
  last_name = '',
  updated_at = NOW()
WHERE referral_code = 'ADMIN001';

-- Correggi Claudio
UPDATE users 
SET 
  first_name = 'Claudio',
  last_name = '',
  updated_at = NOW()
WHERE referral_code = 'ADMIN002';


-- ============================================================================
-- VERIFICA: Controlla i nomi corretti
-- ============================================================================

SELECT '✅ NOMI CORRETTI' as check;
SELECT 
  u.email,
  u.first_name,
  u.last_name,
  u.referral_code,
  u.role,
  up.points_total,
  up.referrals_count
FROM users u
LEFT JOIN user_points up ON u.id = up.user_id
WHERE u.role = 'admin'
ORDER BY u.referral_code;
