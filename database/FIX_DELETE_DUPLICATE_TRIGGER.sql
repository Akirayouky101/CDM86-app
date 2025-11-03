-- ============================================================================
-- ELIMINA TRIGGER DUPLICATO
-- ============================================================================

-- Elimina il trigger _on_update (duplicato)
DROP TRIGGER IF EXISTS trigger_award_referral_points_mlm_on_update ON users;

-- Elimina anche la funzione se esiste
DROP FUNCTION IF EXISTS award_referral_points_mlm_on_update();

-- Verifica che rimanga solo un trigger
SELECT 
  tgname as trigger_name,
  tgenabled as enabled,
  pg_get_triggerdef(oid) as definition
FROM pg_trigger
WHERE tgrelid = 'users'::regclass
AND tgname LIKE '%referral%'
ORDER BY tgname;
