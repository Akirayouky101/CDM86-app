-- ============================================================================
-- FIX: Modifica trigger per attivarsi anche su UPDATE
-- ============================================================================
-- Il problema: il trigger si attiva solo su INSERT, ma referred_by_id viene
-- impostato dopo con UPDATE tramite API /set-referral
-- ============================================================================

-- 1. Elimina il trigger esistente
DROP TRIGGER IF EXISTS trigger_award_referral_points_mlm ON users;

-- 2. Ricrea il trigger che si attiva su INSERT e UPDATE (senza WHEN, controlliamo nella funzione)
CREATE TRIGGER trigger_award_referral_points_mlm
AFTER INSERT OR UPDATE OF referred_by_id ON users
FOR EACH ROW
EXECUTE FUNCTION award_referral_points_mlm();

-- Verifica
SELECT 
  tgname as trigger_name,
  tgenabled as enabled,
  pg_get_triggerdef(oid) as definition
FROM pg_trigger
WHERE tgname = 'trigger_award_referral_points_mlm';
