-- ═══════════════════════════════════════════════════════════
-- FIX RLS: collaborator_notes / tasks / calls
-- Ricrea le policy usando auth_user_id direttamente
-- Esegui nel Supabase SQL Editor
-- ═══════════════════════════════════════════════════════════

-- ── NOTE ────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Collaborator manages own notes" ON public.collaborator_notes;

CREATE POLICY "Collaborator manages own notes"
    ON public.collaborator_notes
    FOR ALL
    TO authenticated
    USING (
        collaborator_id IN (
            SELECT id FROM public.collaborators
            WHERE auth_user_id = auth.uid()
        )
    )
    WITH CHECK (
        collaborator_id IN (
            SELECT id FROM public.collaborators
            WHERE auth_user_id = auth.uid()
        )
    );

-- ── TASK ────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Collaborator manages own tasks" ON public.collaborator_tasks;

CREATE POLICY "Collaborator manages own tasks"
    ON public.collaborator_tasks
    FOR ALL
    TO authenticated
    USING (
        collaborator_id IN (
            SELECT id FROM public.collaborators
            WHERE auth_user_id = auth.uid()
        )
    )
    WITH CHECK (
        collaborator_id IN (
            SELECT id FROM public.collaborators
            WHERE auth_user_id = auth.uid()
        )
    );

-- ── CHIAMATE ────────────────────────────────────────────────
DROP POLICY IF EXISTS "Collaborator manages own calls" ON public.collaborator_calls;

CREATE POLICY "Collaborator manages own calls"
    ON public.collaborator_calls
    FOR ALL
    TO authenticated
    USING (
        collaborator_id IN (
            SELECT id FROM public.collaborators
            WHERE auth_user_id = auth.uid()
        )
    )
    WITH CHECK (
        collaborator_id IN (
            SELECT id FROM public.collaborators
            WHERE auth_user_id = auth.uid()
        )
    );
