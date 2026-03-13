-- ============================================================
-- AGGIUNGE: is_verified alla tabella public.users
-- Permette all'admin di verificare manualmente gli utenti
-- Esegui nel Supabase Dashboard → SQL Editor
-- ============================================================

ALTER TABLE public.users
    ADD COLUMN IF NOT EXISTS is_verified BOOLEAN NOT NULL DEFAULT FALSE;

-- Indice per query veloci sugli utenti verificati
CREATE INDEX IF NOT EXISTS idx_users_is_verified ON public.users (is_verified);

-- RLS policy: solo service_role può aggiornare is_verified
-- (l'admin panel usa la service_role key tramite Edge Function o direttamente)

-- Verifica
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name   = 'users'
  AND column_name  = 'is_verified';
