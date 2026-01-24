-- =====================================================
-- RESET COMPLETO: Cancella tutte le segnalazioni e punti
-- =====================================================
-- USA QUESTA QUERY PER RICOMINCIARE DA ZERO DURANTE I TEST
-- ⚠️ ATTENZIONE: Cancella TUTTI i dati! Non usare in produzione!
-- =====================================================

-- 1. Cancella tutte le organizations create automaticamente
DELETE FROM organizations 
WHERE referred_by_user_id IS NOT NULL;

-- 2. Cancella tutte le segnalazioni aziende
DELETE FROM company_reports;

-- 3. Cancella tutte le transazioni punti
DELETE FROM points_transactions;

-- 4. Reset punti utenti a 0
UPDATE user_points 
SET 
  points_total = 0,
  points_available = 0,
  approved_reports_count = 0,
  rejected_reports_count = 0,
  updated_at = NOW();

-- 5. Verifica reset
SELECT 'Reset completato!' as status;

SELECT 
  (SELECT COUNT(*) FROM organizations WHERE referred_by_user_id IS NOT NULL) as organizations_create,
  (SELECT COUNT(*) FROM company_reports) as segnalazioni,
  (SELECT COUNT(*) FROM points_transactions) as transazioni,
  (SELECT SUM(points_total) FROM user_points) as punti_totali;

-- Dovresti vedere tutti 0 o NULL
