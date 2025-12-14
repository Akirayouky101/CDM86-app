-- ============================================
-- ANALISI COMPLETA DATABASE SUPABASE CDM86
-- ============================================

-- 1. LISTA TUTTE LE TABELLE
SELECT 
    schemaname as schema,
    tablename as table_name,
    tableowner as owner
FROM pg_tables
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY schemaname, tablename;

-- 2. STRUTTURA COMPLETA DI OGNI TABELLA
SELECT 
    t.table_schema,
    t.table_name,
    c.column_name,
    c.ordinal_position,
    c.data_type,
    c.character_maximum_length,
    c.is_nullable,
    c.column_default,
    CASE 
        WHEN pk.constraint_type = 'PRIMARY KEY' THEN 'YES'
        ELSE 'NO'
    END as is_primary_key,
    CASE 
        WHEN fk.constraint_type = 'FOREIGN KEY' THEN 'YES'
        ELSE 'NO'
    END as is_foreign_key
FROM information_schema.tables t
JOIN information_schema.columns c 
    ON t.table_schema = c.table_schema 
    AND t.table_name = c.table_name
LEFT JOIN information_schema.key_column_usage kcu
    ON c.table_schema = kcu.table_schema
    AND c.table_name = kcu.table_name
    AND c.column_name = kcu.column_name
LEFT JOIN information_schema.table_constraints pk
    ON kcu.constraint_schema = pk.constraint_schema
    AND kcu.constraint_name = pk.constraint_name
    AND pk.constraint_type = 'PRIMARY KEY'
LEFT JOIN information_schema.table_constraints fk
    ON kcu.constraint_schema = fk.constraint_schema
    AND kcu.constraint_name = fk.constraint_name
    AND fk.constraint_type = 'FOREIGN KEY'
WHERE t.table_schema = 'public'
    AND t.table_type = 'BASE TABLE'
ORDER BY t.table_name, c.ordinal_position;

-- 3. TUTTE LE FOREIGN KEYS E RELAZIONI
SELECT
    tc.table_name as from_table,
    kcu.column_name as from_column,
    ccu.table_name AS to_table,
    ccu.column_name AS to_column,
    rc.update_rule,
    rc.delete_rule
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
JOIN information_schema.referential_constraints AS rc
    ON tc.constraint_name = rc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_schema = 'public'
ORDER BY tc.table_name;

-- 4. INDICI PRESENTI
SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- 5. RLS POLICIES (Row Level Security)
SELECT
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd as command,
    qual as using_expression,
    with_check as with_check_expression
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- 6. TRIGGERS ATTIVI
SELECT
    trigger_schema,
    trigger_name,
    event_manipulation,
    event_object_table as table_name,
    action_statement,
    action_timing
FROM information_schema.triggers
WHERE trigger_schema = 'public'
ORDER BY event_object_table, trigger_name;

-- 7. FUNCTIONS/STORED PROCEDURES
SELECT
    n.nspname as schema,
    p.proname as function_name,
    pg_get_function_identity_arguments(p.oid) as arguments,
    pg_get_functiondef(p.oid) as definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
ORDER BY p.proname;

-- 8. CONTEGGIO RECORD PER TABELLA
SELECT 
    schemaname,
    tablename,
    (SELECT COUNT(*) FROM public.users) as count
FROM pg_tables
WHERE schemaname = 'public' AND tablename = 'users'
UNION ALL
SELECT 
    schemaname,
    tablename,
    (SELECT COUNT(*) FROM public.promotions) as count
FROM pg_tables
WHERE schemaname = 'public' AND tablename = 'promotions'
UNION ALL
SELECT 
    schemaname,
    tablename,
    (SELECT COUNT(*) FROM public.organizations) as count
FROM pg_tables
WHERE schemaname = 'public' AND tablename = 'organizations'
UNION ALL
SELECT 
    schemaname,
    tablename,
    (SELECT COUNT(*) FROM public.organization_requests) as count
FROM pg_tables
WHERE schemaname = 'public' AND tablename = 'organization_requests'
UNION ALL
SELECT 
    schemaname,
    tablename,
    (SELECT COUNT(*) FROM public.referrals) as count
FROM pg_tables
WHERE schemaname = 'public' AND tablename = 'referrals'
UNION ALL
SELECT 
    schemaname,
    tablename,
    (SELECT COUNT(*) FROM public.transactions) as count
FROM pg_tables
WHERE schemaname = 'public' AND tablename = 'transactions'
UNION ALL
SELECT 
    schemaname,
    tablename,
    (SELECT COUNT(*) FROM public.redemptions) as count
FROM pg_tables
WHERE schemaname = 'public' AND tablename = 'redemptions'
UNION ALL
SELECT 
    schemaname,
    tablename,
    (SELECT COUNT(*) FROM public.contracts) as count
FROM pg_tables
WHERE schemaname = 'public' AND tablename = 'contracts';

-- 9. SAMPLE DATA - USERS (primi 5)
SELECT 
    id,
    email,
    first_name,
    last_name,
    referral_code,
    referred_by_id,
    total_points,
    role,
    created_at
FROM users
ORDER BY created_at DESC
LIMIT 5;

-- 10. SAMPLE DATA - PROMOTIONS (primi 5)
SELECT 
    id,
    title,
    category,
    points_required,
    is_active,
    created_at
FROM promotions
ORDER BY created_at DESC
LIMIT 5;

-- 11. SAMPLE DATA - ORGANIZATIONS (tutti)
SELECT 
    id,
    name,
    email,
    referral_code,
    referral_code_external,
    status,
    created_at
FROM organizations
ORDER BY created_at DESC;

-- 12. VERIFICA SISTEMA REFERRAL
SELECT 
    u.email,
    u.referral_code as my_code,
    u.referred_by_id,
    ref.email as referred_by_email,
    ref.referral_code as referred_by_code,
    u.total_points
FROM users u
LEFT JOIN users ref ON u.referred_by_id = ref.id
WHERE u.referred_by_id IS NOT NULL
ORDER BY u.created_at DESC
LIMIT 10;

-- 13. VERIFICA INTEGRITA REFERENZIALE
-- Trova users con referred_by_id che non esiste
SELECT 
    u.id,
    u.email,
    u.referred_by_id as invalid_referrer_id
FROM users u
LEFT JOIN users ref ON u.referred_by_id = ref.id
WHERE u.referred_by_id IS NOT NULL 
    AND ref.id IS NULL;

-- 14. STATISTICHE REFERRAL
SELECT 
    referrer.email as referrer_email,
    referrer.referral_code,
    COUNT(referred.id) as total_referrals,
    SUM(referred.total_points) as total_points_of_referrals
FROM users referrer
LEFT JOIN users referred ON referred.referred_by_id = referrer.id
GROUP BY referrer.id, referrer.email, referrer.referral_code
HAVING COUNT(referred.id) > 0
ORDER BY total_referrals DESC
LIMIT 10;

-- 15. VERIFICA AUTH.USERS SYNC
-- Controlla se ci sono discrepanze tra auth.users e public.users
SELECT 
    'In auth.users but not in public.users' as issue,
    au.id,
    au.email
FROM auth.users au
LEFT JOIN public.users pu ON au.id = pu.id
WHERE pu.id IS NULL
UNION ALL
SELECT 
    'In public.users but not in auth.users' as issue,
    pu.id,
    pu.email
FROM public.users pu
LEFT JOIN auth.users au ON pu.id = au.id
WHERE au.id IS NULL;
