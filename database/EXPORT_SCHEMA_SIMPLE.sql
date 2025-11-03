-- ============================================================================
-- EXPORT SCHEMA SEMPLIFICATO (tutto in un risultato)
-- ============================================================================

-- ESEGUI QUESTE QUERY UNA ALLA VOLTA E COPIAMI I RISULTATI DI OGNUNA
-- Oppure esporta come CSV/JSON da Supabase

-- ============================================================================
-- QUERY 1: STRUTTURA TABELLA users
-- ============================================================================
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
-- QUERY 2: STRUTTURA TABELLA user_points
-- ============================================================================
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
-- QUERY 3: STRUTTURA TABELLA points_transactions
-- ============================================================================
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
-- QUERY 4: TUTTI I CONSTRAINT
-- ============================================================================
SELECT 
  tc.table_name,
  tc.constraint_name,
  tc.constraint_type,
  pg_get_constraintdef(pgc.oid) as constraint_definition
FROM information_schema.table_constraints tc
JOIN pg_constraint pgc ON tc.constraint_name = pgc.conname
WHERE tc.table_schema = 'public'
  AND tc.table_name IN ('users', 'user_points', 'points_transactions', 'referral_network')
ORDER BY tc.table_name, tc.constraint_type;


-- ============================================================================
-- QUERY 5: FOREIGN KEYS
-- ============================================================================
SELECT 
  tc.table_name as from_table,
  kcu.column_name as from_column,
  ccu.table_name AS to_table,
  ccu.column_name AS to_column,
  tc.constraint_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
  AND tc.table_schema = 'public'
ORDER BY tc.table_name;


-- ============================================================================
-- QUERY 6: CODICE FUNZIONE award_referral_points_mlm
-- ============================================================================
SELECT pg_get_functiondef(oid) as function_code
FROM pg_proc
WHERE proname = 'award_referral_points_mlm';


-- ============================================================================
-- QUERY 7: TRIGGER SU users
-- ============================================================================
SELECT 
  tgname as trigger_name,
  tgenabled as enabled,
  pg_get_triggerdef(oid) as trigger_definition
FROM pg_trigger
WHERE tgrelid = 'users'::regclass
  AND tgisinternal = false;


-- ============================================================================
-- QUERY 8: SAMPLE DATI users (ultimi 5)
-- ============================================================================
SELECT 
  id,
  email,
  referral_code,
  referred_by_id,
  account_type,
  created_at
FROM users
ORDER BY created_at DESC
LIMIT 5;


-- ============================================================================
-- QUERY 9: SAMPLE DATI user_points
-- ============================================================================
SELECT *
FROM user_points
ORDER BY created_at DESC
LIMIT 5;
