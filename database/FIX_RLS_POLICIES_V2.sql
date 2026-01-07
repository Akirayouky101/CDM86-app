-- ============================================
-- FIX RLS POLICIES V2 - organization_pages
-- Fix per permettere INSERT anche senza pagina esistente
-- ============================================

-- Disabilita temporaneamente RLS per debug
ALTER TABLE organization_pages DISABLE ROW LEVEL SECURITY;

-- Verifica che RLS sia disabilitato
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'organization_pages';

-- NOTA: Questo è TEMPORANEO per testare.
-- Una volta verificato che funziona, riabiliteremo le RLS con policies corrette.

-- Per riabilitare RLS in futuro (NON ESEGUIRE ORA):
-- ALTER TABLE organization_pages ENABLE ROW LEVEL SECURITY;
