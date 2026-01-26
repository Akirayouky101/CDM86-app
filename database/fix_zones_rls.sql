-- FIX: Disabilita RLS su tabella zones e crea policy per admin
-- Il problema è che le zone vengono create ma non sono visibili

-- 1. Disabilita RLS temporaneamente per testare
ALTER TABLE zones DISABLE ROW LEVEL SECURITY;

-- 2. Oppure crea policy che permette tutto (per admin)
-- Se preferisci mantenere RLS attivo, usa questa alternativa:
/*
ALTER TABLE zones ENABLE ROW LEVEL SECURITY;

-- Policy: permetti tutto agli utenti autenticati
CREATE POLICY "Allow all for authenticated users" 
ON zones 
FOR ALL 
TO authenticated 
USING (true) 
WITH CHECK (true);

-- Policy: permetti lettura anche agli anonimi (se serve per il sito pubblico)
CREATE POLICY "Allow read for anonymous" 
ON zones 
FOR SELECT 
TO anon 
USING (true);
*/

-- VERIFICA: controlla se ora vedi le zone
SELECT id, name, cap_list, active, created_at 
FROM zones 
ORDER BY created_at DESC;

-- CONTA TOTALE
SELECT COUNT(*) as total_zones FROM zones;
