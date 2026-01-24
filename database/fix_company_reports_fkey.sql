-- =====================================================
-- FIX: Correggi Foreign Key di company_reports
-- =====================================================
-- Questo script corregge la foreign key per puntare a public.users
-- invece di auth.users, risolvendo l'errore PGRST200

-- 1. Rimuovi la vecchia foreign key constraint
ALTER TABLE company_reports
DROP CONSTRAINT IF EXISTS company_reports_reported_by_user_id_fkey;

-- 2. Aggiungi la nuova foreign key che punta a public.users
ALTER TABLE company_reports
ADD CONSTRAINT company_reports_reported_by_user_id_fkey 
FOREIGN KEY (reported_by_user_id) 
REFERENCES public.users(id) 
ON DELETE CASCADE;

-- Verifica che tutto sia ok
SELECT 
    conname AS constraint_name,
    conrelid::regclass AS table_name,
    confrelid::regclass AS referenced_table
FROM pg_constraint
WHERE conname = 'company_reports_reported_by_user_id_fkey';
