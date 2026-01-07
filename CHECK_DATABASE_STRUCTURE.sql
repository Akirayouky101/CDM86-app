-- =====================================================
-- VERIFICA COMPLETA STRUTTURA DATABASE SUPABASE
-- =====================================================

-- 1. LISTA TUTTE LE TABELLE
-- =====================================================
SELECT 
    table_name as "Tabella",
    table_type as "Tipo"
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

-- 2. DETTAGLIO COLONNE PER OGNI TABELLA
-- =====================================================

-- USERS
SELECT 
    'users' as tabella,
    column_name as colonna,
    data_type as tipo,
    is_nullable as nullable,
    column_default as default_value
FROM information_schema.columns
WHERE table_name = 'users'
ORDER BY ordinal_position;

-- ORGANIZATIONS
SELECT 
    'organizations' as tabella,
    column_name as colonna,
    data_type as tipo,
    is_nullable as nullable,
    column_default as default_value
FROM information_schema.columns
WHERE table_name = 'organizations'
ORDER BY ordinal_position;

-- PROMOTIONS
SELECT 
    'promotions' as tabella,
    column_name as colonna,
    data_type as tipo,
    is_nullable as nullable,
    column_default as default_value
FROM information_schema.columns
WHERE table_name = 'promotions'
ORDER BY ordinal_position;

-- FAVORITES
SELECT 
    'favorites' as tabella,
    column_name as colonna,
    data_type as tipo,
    is_nullable as nullable,
    column_default as default_value
FROM information_schema.columns
WHERE table_name = 'favorites'
ORDER BY ordinal_position;

-- TRANSACTIONS
SELECT 
    'transactions' as tabella,
    column_name as colonna,
    data_type as tipo,
    is_nullable as nullable,
    column_default as default_value
FROM information_schema.columns
WHERE table_name = 'transactions'
ORDER BY ordinal_position;

-- REFERRALS
SELECT 
    'referrals' as tabella,
    column_name as colonna,
    data_type as tipo,
    is_nullable as nullable,
    column_default as default_value
FROM information_schema.columns
WHERE table_name = 'referrals'
ORDER BY ordinal_position;

-- ORGANIZATION_REQUESTS
SELECT 
    'organization_requests' as tabella,
    column_name as colonna,
    data_type as tipo,
    is_nullable as nullable,
    column_default as default_value
FROM information_schema.columns
WHERE table_name = 'organization_requests'
ORDER BY ordinal_position;

-- ORGANIZATION_BENEFITS
SELECT 
    'organization_benefits' as tabella,
    column_name as colonna,
    data_type as tipo,
    is_nullable as nullable,
    column_default as default_value
FROM information_schema.columns
WHERE table_name = 'organization_benefits'
ORDER BY ordinal_position;

-- 3. VERIFICA INDICI
-- =====================================================
SELECT
    tablename as "Tabella",
    indexname as "Indice",
    indexdef as "Definizione"
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- 4. VERIFICA FOREIGN KEYS
-- =====================================================
SELECT
    tc.table_name as "Tabella", 
    kcu.column_name as "Colonna", 
    ccu.table_name AS "Tabella Riferita",
    ccu.column_name AS "Colonna Riferita"
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND tc.table_schema = 'public'
ORDER BY tc.table_name;

-- 5. VERIFICA TRIGGERS
-- =====================================================
SELECT 
    trigger_name as "Trigger",
    event_manipulation as "Evento",
    event_object_table as "Tabella",
    action_statement as "Azione"
FROM information_schema.triggers
WHERE trigger_schema = 'public'
ORDER BY event_object_table, trigger_name;

-- 6. VERIFICA FUNCTIONS
-- =====================================================
SELECT 
    routine_name as "Funzione",
    routine_type as "Tipo",
    data_type as "Return Type"
FROM information_schema.routines
WHERE routine_schema = 'public'
    AND routine_type = 'FUNCTION'
ORDER BY routine_name;

-- 7. VERIFICA VIEWS
-- =====================================================
SELECT 
    table_name as "View"
FROM information_schema.views
WHERE table_schema = 'public'
ORDER BY table_name;

-- 8. CONTA RECORD PER TABELLA
-- =====================================================
SELECT 
    'users' as tabella,
    COUNT(*) as totale_record
FROM users
UNION ALL
SELECT 
    'organizations',
    COUNT(*)
FROM organizations
UNION ALL
SELECT 
    'promotions',
    COUNT(*)
FROM promotions
UNION ALL
SELECT 
    'favorites',
    COUNT(*)
FROM favorites
UNION ALL
SELECT 
    'transactions',
    COUNT(*)
FROM transactions
UNION ALL
SELECT 
    'referrals',
    COUNT(*)
FROM referrals
UNION ALL
SELECT 
    'organization_requests',
    COUNT(*)
FROM organization_requests
UNION ALL
SELECT 
    'organization_benefits',
    COUNT(*)
FROM organization_benefits;

-- 9. VERIFICA RLS (Row Level Security)
-- =====================================================
SELECT 
    schemaname,
    tablename,
    rowsecurity as "RLS Attivo"
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- 10. VERIFICA RLS POLICIES
-- =====================================================
SELECT 
    schemaname,
    tablename,
    policyname as "Policy",
    permissive as "Permissive",
    roles as "Ruoli",
    cmd as "Comando",
    qual as "Condizione"
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
