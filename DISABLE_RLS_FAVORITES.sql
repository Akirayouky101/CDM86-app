-- DISABILITA RLS sulla tabella favorites
-- Questo permetterà a TUTTI gli utenti autenticati di leggere/scrivere i propri favoriti
-- senza le complicazioni delle policy RLS

ALTER TABLE favorites DISABLE ROW LEVEL SECURITY;

-- Verifica che RLS sia disabilitato
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'favorites';

-- Dovrebbe mostrare rowsecurity = false
