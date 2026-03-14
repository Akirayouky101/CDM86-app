-- ═══════════════════════════════════════════════════════════
-- VERIFICA: esiste un trigger che crea righe in "users"
-- quando viene creato un nuovo auth.users?
-- Esegui nel Supabase SQL Editor e mostrami il risultato
-- ═══════════════════════════════════════════════════════════

-- 1. Tutti i trigger su auth.users
SELECT
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers
WHERE event_object_schema = 'auth'
  AND event_object_table  = 'users';

-- 2. Tutti i trigger che fanno INSERT su public.users
SELECT
    n.nspname  AS schema,
    t.tgname   AS trigger_name,
    c.relname  AS table_name,
    p.proname  AS function_name
FROM pg_trigger t
JOIN pg_class   c ON c.oid = t.tgrelid
JOIN pg_proc    p ON p.oid = t.tgfoid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname IN ('public', 'auth')
ORDER BY schema, trigger_name;
