-- Rinomina colonna pinned → is_pinned in collaborator_notes
-- Esegui nel Supabase SQL Editor

ALTER TABLE public.collaborator_notes 
    RENAME COLUMN pinned TO is_pinned;
