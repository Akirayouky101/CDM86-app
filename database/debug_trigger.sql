-- 1. VERIFICA TRIGGER ATTIVO
SELECT 
    t.tgname AS trigger_name,
    t.tgenabled AS enabled,
    CASE t.tgenabled
        WHEN 'O' THEN 'Enabled'
        WHEN 'D' THEN 'Disabled'
        WHEN 'R' THEN 'Replica'
        WHEN 'A' THEN 'Always'
    END AS status,
    pg_get_triggerdef(t.oid) AS trigger_definition
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
WHERE c.relname = 'users' 
  AND c.relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'auth');

-- 2. VERIFICA FUNZIONE TRIGGER
SELECT 
    p.proname AS function_name,
    pg_get_functiondef(p.oid) AS function_definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE p.proname = 'handle_new_user';

-- 3. VERIFICA RLS SU PUBLIC.USERS
SELECT 
    schemaname,
    tablename,
    rowsecurity AS rls_enabled
FROM pg_tables
WHERE schemaname = 'public' AND tablename = 'users';

-- 4. VERIFICA POLICIES SU PUBLIC.USERS
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'users';

-- 5. VERIFICA PERMESSI SULLA TABELLA
SELECT 
    grantee,
    privilege_type
FROM information_schema.table_privileges
WHERE table_schema = 'public' AND table_name = 'users';

-- 6. TEST PERMESSI FUNZIONE (verifica se può inserire)
SELECT 
    p.proname,
    p.prosecdef AS security_definer,
    pg_get_userbyid(p.proowner) AS owner
FROM pg_proc p
WHERE p.proname = 'handle_new_user';
