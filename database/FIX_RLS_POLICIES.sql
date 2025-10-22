-- =====================================================
-- FIX RLS POLICIES - User Points
-- Esegui questo per permettere ai trigger di funzionare
-- =====================================================

-- 1. DROP vecchie policy troppo restrittive
DROP POLICY IF EXISTS "Users can view own points" ON user_points;
DROP POLICY IF EXISTS "Users can view all points for leaderboard" ON user_points;

-- 2. CREA policy corrette che permettono ai trigger di funzionare

-- Policy per SELECT (visualizzazione)
CREATE POLICY "Users can view all points"
    ON user_points FOR SELECT
    TO authenticated, anon
    USING (true);

-- Policy per INSERT (creazione nuovi record via trigger)
CREATE POLICY "System can insert points"
    ON user_points FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Policy per UPDATE (aggiornamento punti via trigger)
CREATE POLICY "System can update points"
    ON user_points FOR UPDATE
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- 3. Verifica policy attive
SELECT 
    schemaname, 
    tablename, 
    policyname, 
    permissive,
    roles,
    cmd
FROM pg_policies 
WHERE tablename = 'user_points';

SELECT '✅ RLS Policies aggiornate! I trigger ora possono funzionare.' as status;
