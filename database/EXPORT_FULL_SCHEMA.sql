-- ============================================================================
-- EXPORT COMPLETO SCHEMA DATABASE
-- ============================================================================
-- Questa query esporta TUTTA la struttura del database per debug accurato
-- ============================================================================

-- ============================================================================
-- 1. TUTTE LE TABELLE
-- ============================================================================
SELECT '📋 TABELLE ESISTENTI' as section;
SELECT 
  table_name,
  table_type
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;


-- ============================================================================
-- 2. TUTTE LE COLONNE DI OGNI TABELLA (STRUTTURA COMPLETA)
-- ============================================================================
SELECT '📊 STRUTTURA COMPLETA TABELLE' as section;
SELECT 
  table_name,
  column_name,
  data_type,
  character_maximum_length,
  is_nullable,
  column_default,
  ordinal_position
FROM information_schema.columns
WHERE table_schema = 'public'
ORDER BY table_name, ordinal_position;


-- ============================================================================
-- 3. TUTTI I CONSTRAINT (PRIMARY KEY, FOREIGN KEY, CHECK, UNIQUE)
-- ============================================================================
SELECT '🔐 TUTTI I CONSTRAINT' as section;
SELECT 
  tc.table_name,
  tc.constraint_name,
  tc.constraint_type,
  pg_get_constraintdef(pgc.oid) as constraint_definition
FROM information_schema.table_constraints tc
JOIN pg_constraint pgc ON tc.constraint_name = pgc.conname
WHERE tc.table_schema = 'public'
ORDER BY tc.table_name, tc.constraint_type;


-- ============================================================================
-- 4. FOREIGN KEYS (DETTAGLIO RELAZIONI)
-- ============================================================================
SELECT '🔗 FOREIGN KEYS (RELAZIONI TRA TABELLE)' as section;
SELECT 
  tc.table_name as from_table,
  kcu.column_name as from_column,
  ccu.table_name AS to_table,
  ccu.column_name AS to_column,
  tc.constraint_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
  AND tc.table_schema = 'public'
ORDER BY tc.table_name, kcu.column_name;


-- ============================================================================
-- 5. TUTTI I TRIGGER
-- ============================================================================
SELECT '⚡ TUTTI I TRIGGER' as section;
SELECT 
  trigger_name,
  event_object_table as table_name,
  event_manipulation as event_type,
  action_timing as timing,
  action_statement
FROM information_schema.triggers
WHERE trigger_schema = 'public'
ORDER BY event_object_table, trigger_name;


-- ============================================================================
-- 6. TUTTE LE FUNZIONI/PROCEDURE
-- ============================================================================
SELECT '🔧 TUTTE LE FUNZIONI' as section;
SELECT 
  routine_name,
  routine_type,
  data_type as return_type
FROM information_schema.routines
WHERE routine_schema = 'public'
ORDER BY routine_name;


-- ============================================================================
-- 7. STRUTTURA TABELLA users (DETTAGLIO COMPLETO)
-- ============================================================================
SELECT '👤 TABELLA users - DETTAGLIO' as section;
SELECT 
  column_name,
  data_type,
  character_maximum_length,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'users'
ORDER BY ordinal_position;


-- ============================================================================
-- 8. STRUTTURA TABELLA user_points (DETTAGLIO COMPLETO)
-- ============================================================================
SELECT '💰 TABELLA user_points - DETTAGLIO' as section;
SELECT 
  column_name,
  data_type,
  character_maximum_length,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'user_points'
ORDER BY ordinal_position;


-- ============================================================================
-- 9. STRUTTURA TABELLA points_transactions (DETTAGLIO COMPLETO)
-- ============================================================================
SELECT '💸 TABELLA points_transactions - DETTAGLIO' as section;
SELECT 
  column_name,
  data_type,
  character_maximum_length,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'points_transactions'
ORDER BY ordinal_position;


-- ============================================================================
-- 10. STRUTTURA TABELLA referral_network (DETTAGLIO COMPLETO)
-- ============================================================================
SELECT '🌐 TABELLA referral_network - DETTAGLIO' as section;
SELECT 
  column_name,
  data_type,
  character_maximum_length,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'referral_network'
ORDER BY ordinal_position;


-- ============================================================================
-- 11. CODICE COMPLETO FUNZIONE award_referral_points_mlm
-- ============================================================================
SELECT '📜 CODICE FUNZIONE award_referral_points_mlm' as section;
SELECT pg_get_functiondef(oid) as function_definition
FROM pg_proc
WHERE proname = 'award_referral_points_mlm'
  AND pronamespace = 'public'::regnamespace;


-- ============================================================================
-- 12. INDICI ESISTENTI
-- ============================================================================
SELECT '📑 INDICI' as section;
SELECT 
  tablename,
  indexname,
  indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;


-- ============================================================================
-- 13. DATI ESISTENTI (SAMPLE)
-- ============================================================================
SELECT '👥 USERS ESISTENTI (primi 20)' as section;
SELECT 
  id,
  email,
  first_name,
  last_name,
  referral_code,
  referred_by_id,
  account_type,
  created_at
FROM users
ORDER BY created_at DESC
LIMIT 20;

SELECT '💰 USER_POINTS ESISTENTI' as section;
SELECT 
  user_id,
  points_total,
  referrals_count,
  level,
  created_at,
  updated_at
FROM user_points
ORDER BY created_at DESC
LIMIT 20;

SELECT '💸 POINTS_TRANSACTIONS RECENTI' as section;
SELECT 
  id,
  user_id,
  points,
  transaction_type,
  description,
  created_at
FROM points_transactions
ORDER BY created_at DESC
LIMIT 30;

SELECT '🌐 REFERRAL_NETWORK ESISTENTE' as section;
SELECT 
  id,
  user_id,
  referral_id,
  level,
  points_awarded,
  referral_type,
  created_at
FROM referral_network
ORDER BY created_at DESC
LIMIT 30;


-- ============================================================================
-- 14. CHECK SPECIFICI PER IL DEBUG
-- ============================================================================
SELECT '🔍 VERIFICA TRIGGER SU users' as section;
SELECT 
  tgname as trigger_name,
  tgtype,
  tgenabled as enabled,
  pg_get_triggerdef(oid) as trigger_definition
FROM pg_trigger
WHERE tgrelid = 'users'::regclass
  AND tgisinternal = false;


-- ============================================================================
-- FINE EXPORT
-- ============================================================================
SELECT '✅ Export completo - copia TUTTI i risultati e mandameli!' as message;
