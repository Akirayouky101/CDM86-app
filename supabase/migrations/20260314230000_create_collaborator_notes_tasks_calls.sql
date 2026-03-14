-- ═══════════════════════════════════════════════════════════
-- Crea tabelle: collaborator_notes, collaborator_tasks,
--               collaborator_calls
-- Esegui nel Supabase SQL Editor
-- ═══════════════════════════════════════════════════════════

-- ── NOTE ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.collaborator_notes (
    id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    collaborator_id UUID NOT NULL REFERENCES public.collaborators(id) ON DELETE CASCADE,
    title           TEXT NOT NULL,
    content         TEXT,
    color           TEXT NOT NULL DEFAULT 'yellow'
                        CHECK (color IN ('yellow','blue','green','pink','purple','orange')),
    is_pinned       BOOLEAN NOT NULL DEFAULT false,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_collab_notes_collaborator
    ON public.collaborator_notes(collaborator_id);

ALTER TABLE public.collaborator_notes ENABLE ROW LEVEL SECURITY;

-- Il collaboratore legge/scrive solo le proprie note
CREATE POLICY "Collaborator manages own notes"
    ON public.collaborator_notes
    FOR ALL
    USING (
        collaborator_id = (
            SELECT id FROM public.collaborators
            WHERE auth_user_id = auth.uid()
            LIMIT 1
        )
    )
    WITH CHECK (
        collaborator_id = (
            SELECT id FROM public.collaborators
            WHERE auth_user_id = auth.uid()
            LIMIT 1
        )
    );

-- ── TASK ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.collaborator_tasks (
    id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    collaborator_id UUID NOT NULL REFERENCES public.collaborators(id) ON DELETE CASCADE,
    title           TEXT NOT NULL,
    description     TEXT,
    due_date        DATE,
    priority        TEXT NOT NULL DEFAULT 'medium'
                        CHECK (priority IN ('low','medium','high')),
    status          TEXT NOT NULL DEFAULT 'todo'
                        CHECK (status IN ('todo','in_progress','done')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_collab_tasks_collaborator
    ON public.collaborator_tasks(collaborator_id);

ALTER TABLE public.collaborator_tasks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Collaborator manages own tasks"
    ON public.collaborator_tasks
    FOR ALL
    USING (
        collaborator_id = (
            SELECT id FROM public.collaborators
            WHERE auth_user_id = auth.uid()
            LIMIT 1
        )
    )
    WITH CHECK (
        collaborator_id = (
            SELECT id FROM public.collaborators
            WHERE auth_user_id = auth.uid()
            LIMIT 1
        )
    );

-- ── CHIAMATE ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.collaborator_calls (
    id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    collaborator_id UUID NOT NULL REFERENCES public.collaborators(id) ON DELETE CASCADE,
    contact_name    TEXT NOT NULL,
    phone           TEXT,
    email           TEXT,
    outcome         TEXT NOT NULL DEFAULT 'pending'
                        CHECK (outcome IN ('pending','interested','not_interested','callback','converted')),
    notes           TEXT,
    called_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_collab_calls_collaborator
    ON public.collaborator_calls(collaborator_id);

ALTER TABLE public.collaborator_calls ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Collaborator manages own calls"
    ON public.collaborator_calls
    FOR ALL
    USING (
        collaborator_id = (
            SELECT id FROM public.collaborators
            WHERE auth_user_id = auth.uid()
            LIMIT 1
        )
    )
    WITH CHECK (
        collaborator_id = (
            SELECT id FROM public.collaborators
            WHERE auth_user_id = auth.uid()
            LIMIT 1
        )
    );

-- ── Trigger updated_at ───────────────────────────────────────
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notes_updated_at  ON public.collaborator_notes;
DROP TRIGGER IF EXISTS trg_tasks_updated_at  ON public.collaborator_tasks;

CREATE TRIGGER trg_notes_updated_at
    BEFORE UPDATE ON public.collaborator_notes
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_tasks_updated_at
    BEFORE UPDATE ON public.collaborator_tasks
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
