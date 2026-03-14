-- ═══════════════════════════════════════════════════════════
-- MOSTRA il codice attuale della funzione handle_new_user
-- Esegui nel Supabase SQL Editor
-- ═══════════════════════════════════════════════════════════
SELECT pg_get_functiondef(oid)
FROM pg_proc
WHERE proname = 'handle_new_user';
