-- ═══════════════════════════════════════════════════════════════════
-- RLS policies per collaborator_calls
-- Ogni collaboratore può fare SELECT/INSERT/UPDATE/DELETE solo sui
-- propri record (collaborator_id = id del proprio record in collaborators)
-- ═══════════════════════════════════════════════════════════════════

-- Abilita RLS se non già abilitato
ALTER TABLE public.collaborator_calls ENABLE ROW LEVEL SECURITY;

-- Rimuovi eventuali policy precedenti
DROP POLICY IF EXISTS "Collaborators manage own calls" ON public.collaborator_calls;
DROP POLICY IF EXISTS "Collaborators can read own calls" ON public.collaborator_calls;
DROP POLICY IF EXISTS "Collaborators can insert own calls" ON public.collaborator_calls;
DROP POLICY IF EXISTS "Collaborators can update own calls" ON public.collaborator_calls;
DROP POLICY IF EXISTS "Collaborators can delete own calls" ON public.collaborator_calls;

-- SELECT: può vedere solo le proprie chiamate
CREATE POLICY "Collaborators can read own calls"
    ON public.collaborator_calls
    FOR SELECT
    TO authenticated
    USING (
        collaborator_id = public.get_my_collaborator_id()
    );

-- INSERT: può inserire solo con il proprio collaborator_id
CREATE POLICY "Collaborators can insert own calls"
    ON public.collaborator_calls
    FOR INSERT
    TO authenticated
    WITH CHECK (
        collaborator_id = public.get_my_collaborator_id()
    );

-- UPDATE: può modificare solo le proprie chiamate
CREATE POLICY "Collaborators can update own calls"
    ON public.collaborator_calls
    FOR UPDATE
    TO authenticated
    USING (
        collaborator_id = public.get_my_collaborator_id()
    );

-- DELETE: può eliminare solo le proprie chiamate
CREATE POLICY "Collaborators can delete own calls"
    ON public.collaborator_calls
    FOR DELETE
    TO authenticated
    USING (
        collaborator_id = public.get_my_collaborator_id()
    );

-- Service role bypass (admin può sempre accedere)
-- Non serve una policy esplicita: il service_role bypassa RLS per default.
