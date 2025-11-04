-- =====================================================
-- VERIFICA STRUTTURA TABELLA USERS
-- =====================================================

-- Mostra tutti i campi della tabella users
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'users'
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Mostra anche alcuni record esistenti per vedere la struttura
SELECT *
FROM users
LIMIT 2;