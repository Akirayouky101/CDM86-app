-- =====================================================
-- VERIFICA: Sistema Compensi Aziende
-- =====================================================
-- Esegui questo script per verificare che tutto sia configurato correttamente
-- =====================================================

-- 1. Verifica colonna compensation_euros esiste in points_transactions
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'points_transactions' 
AND column_name = 'compensation_euros';

-- Se vuoto, la colonna non esiste ancora!

-- 2. Verifica constraint transaction_type
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint
WHERE conname = 'points_transactions_transaction_type_check';

-- Dovrebbe contenere tutti i nuovi tipi: company_report_approved, company_compensation, mlm_compensation_level1, mlm_compensation_level2

-- 3. Verifica trigger esiste
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers
WHERE trigger_name = 'trigger_company_report_approval';

-- 4. Verifica ultima segnalazione approvata
SELECT 
    id,
    company_name,
    company_type,
    status,
    compensation_amount,
    points_awarded,
    created_at,
    updated_at
FROM company_reports
WHERE status = 'approved'
ORDER BY updated_at DESC
LIMIT 5;

-- 5. Verifica transazioni create per l'ultima approvazione
-- (sostituisci 'COMPANY_ID' con id dalla query sopra)
SELECT 
    id,
    user_id,
    transaction_type,
    points,
    compensation_euros,
    description,
    created_at
FROM points_transactions
WHERE reference_id = 'COMPANY_ID_QUI'  -- ⚠️ Sostituisci con l'ID vero
ORDER BY created_at DESC;

-- 6. Verifica utente ha referred_by_id (per MLM)
SELECT 
    id,
    email,
    referred_by_id,
    referral_code
FROM users
WHERE id = (
    SELECT reported_by_user_id 
    FROM company_reports 
    WHERE status = 'approved' 
    ORDER BY updated_at DESC 
    LIMIT 1
);

-- Se referred_by_id è NULL, l'utente NON ha un referrer quindi MLM non parte!

-- =====================================================
-- DIAGNOSTICA RAPIDA
-- =====================================================

SELECT 
    'compensation_euros exists' as check_name,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'points_transactions' 
        AND column_name = 'compensation_euros'
    ) THEN '✅ SI' ELSE '❌ NO - ESEGUI company_reports_approval_trigger.sql' END as status

UNION ALL

SELECT 
    'trigger exists',
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.triggers 
        WHERE trigger_name = 'trigger_company_report_approval'
    ) THEN '✅ SI' ELSE '❌ NO - ESEGUI company_reports_approval_trigger.sql' END

UNION ALL

SELECT 
    'new transaction types in constraint',
    CASE WHEN EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'points_transactions_transaction_type_check'
        AND pg_get_constraintdef(oid) LIKE '%company_compensation%'
    ) THEN '✅ SI' ELSE '❌ NO - ESEGUI fix_transaction_type_constraint.sql' END;
