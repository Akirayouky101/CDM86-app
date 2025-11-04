-- =====================================================
-- VERIFICA SISTEMA MLM E TRIGGER PUNTI REFERRAL
-- =====================================================

-- 1. Verifica che la funzione MLM esista
SELECT 
    proname as function_name,
    'EXISTS' as status
FROM pg_proc 
WHERE proname = 'award_referral_points_mlm';

-- 2. Verifica che il trigger MLM sia attivo
SELECT 
    tgname as trigger_name,
    tgenabled as enabled,
    tgrelid::regclass as table_name
FROM pg_trigger 
WHERE tgname = 'trigger_award_referral_points_mlm';

-- 3. Mostra tutti i trigger sulla tabella users
SELECT 
    tgname as trigger_name,
    tgenabled as enabled,
    tgtype as trigger_type,
    pg_get_triggerdef(oid) as definition
FROM pg_trigger 
WHERE tgrelid = 'users'::regclass
ORDER BY tgname;

-- 4. Verifica se esiste la tabella user_points
SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'user_points'
) as user_points_table_exists;

-- 5. Verifica se esiste la tabella referral_network  
SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'referral_network'
) as referral_network_table_exists;

-- 6. Mostra la struttura della tabella users per vedere se ha campo points
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'users' 
AND table_schema = 'public'
AND column_name IN ('points', 'total_points_earned', 'referral_count');