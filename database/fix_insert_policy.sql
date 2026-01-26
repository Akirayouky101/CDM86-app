-- RIMUOVI LA POLICY SBAGLIATA
DROP POLICY IF EXISTS "Users can be created via trigger" ON public.users;

-- CREA NUOVA POLICY CORRETTA PER IL TRIGGER
-- Il trigger usa SECURITY DEFINER quindi ha permessi di postgres
-- Non serve controllare auth.uid() perché il trigger gira come postgres
CREATE POLICY "Allow trigger insert users"
ON public.users
FOR INSERT
TO authenticated
WITH CHECK (true); -- Il trigger è SECURITY DEFINER, quindi bypassa RLS comunque

-- VERIFICA
SELECT 
    schemaname,
    tablename,
    policyname,
    cmd,
    with_check
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'users' AND cmd = 'INSERT';
