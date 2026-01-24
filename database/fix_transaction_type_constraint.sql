-- =====================================================
-- FIX: Aggiungi nuovi transaction_type al CHECK constraint
-- =====================================================
-- Il trigger company_reports_approval usa transaction_type che non sono
-- nel CHECK constraint esistente. Questo script li aggiunge.
-- =====================================================

-- 1. Rimuovi il vecchio constraint
ALTER TABLE points_transactions
DROP CONSTRAINT IF EXISTS points_transactions_transaction_type_check;

-- 2. Crea nuovo constraint con tutti i tipi
ALTER TABLE points_transactions
ADD CONSTRAINT points_transactions_transaction_type_check
CHECK (transaction_type IN (
    'referral_completed',
    'report_approved',
    'report_rejected',
    'reward_redeemed',
    'admin_adjustment',
    'bonus',
    -- ⭐ NUOVI TIPI PER COMPANY REPORTS
    'company_report_approved',
    'company_report_rejected',
    'company_compensation',
    'mlm_compensation_level1',
    'mlm_compensation_level2'
));

-- Log successo
SELECT '✅ CHECK constraint aggiornato con nuovi transaction_type!' as status;
SELECT '📊 Nuovi tipi aggiunti:' as info;
SELECT '   - company_report_approved (punti per segnalazione approvata)' as tipo;
SELECT '   - company_report_rejected (segnalazione rifiutata)' as tipo;
SELECT '   - company_compensation (compenso 30€ inserzionista)' as tipo;
SELECT '   - mlm_compensation_level1 (MLM livello 1: 15€)' as tipo;
SELECT '   - mlm_compensation_level2 (MLM livello 2: 9€)' as tipo;
