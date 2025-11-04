-- =====================================================
-- FIX PROMOTIONS TABLE PERMISSIONS
-- =====================================================
-- Questo script sistema i permessi della tabella promotions
-- per permettere al pannello admin di gestire le promozioni

-- 1. Drop existing restrictive policies
DROP POLICY IF EXISTS "Public can read active promotions" ON promotions;
DROP POLICY IF EXISTS "Authenticated users can manage promotions" ON promotions;

-- 2. Create permissive policies for admin panel
-- (In produzione, dovresti usare auth.uid() per verificare se l'utente è admin)

-- Lettura: tutti possono leggere le promozioni
CREATE POLICY "Anyone can read promotions" ON promotions
    FOR SELECT USING (true);

-- Update: permetti aggiornamenti (per toggle attiva/disattiva)
CREATE POLICY "Anyone can update promotions" ON promotions
    FOR UPDATE USING (true);

-- Insert: permetti inserimento (per creare nuove promozioni)
CREATE POLICY "Anyone can insert promotions" ON promotions
    FOR INSERT WITH CHECK (true);

-- Delete: permetti eliminazione
CREATE POLICY "Anyone can delete promotions" ON promotions
    FOR DELETE USING (true);

-- =====================================================
-- VERIFICA
-- =====================================================
-- Dopo aver eseguito questo script, verifica con:
-- SELECT * FROM promotions;
-- UPDATE promotions SET is_active = NOT is_active WHERE id = (SELECT id FROM promotions LIMIT 1);
