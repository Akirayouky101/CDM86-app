-- ============================================================================
-- VERIFICA TRIGGER MLM
-- ============================================================================

-- 1. Lista TUTTI i trigger sulla tabella users
SELECT 
  t.tgname as trigger_name,
  t.tgenabled as enabled,
  p.proname as function_name,
  CASE t.tgtype::integer & 66
    WHEN 2 THEN 'BEFORE'
    WHEN 64 THEN 'INSTEAD OF'
    ELSE 'AFTER'
  END as trigger_timing,
  CASE t.tgtype::integer & cast(28 as int2)
    WHEN 16 THEN 'UPDATE'
    WHEN 8 THEN 'DELETE'
    WHEN 4 THEN 'INSERT'
    WHEN 20 THEN 'INSERT, UPDATE'
    WHEN 28 THEN 'INSERT, UPDATE, DELETE'
    WHEN 24 THEN 'UPDATE, DELETE'
    WHEN 12 THEN 'INSERT, DELETE'
  END as trigger_event
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE c.relname = 'users'
  AND t.tgisinternal = false
ORDER BY t.tgname;


-- 2. Verifica specifica per trigger MLM
SELECT 
  'TRIGGER MLM SPECIFICO' as check,
  COUNT(*) as count
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE c.relname = 'users'
  AND p.proname = 'award_referral_points_mlm';


-- 3. Mostra il codice del trigger se esiste
SELECT 
  pg_get_triggerdef(t.oid) as trigger_definition
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE c.relname = 'users'
  AND p.proname = 'award_referral_points_mlm';
