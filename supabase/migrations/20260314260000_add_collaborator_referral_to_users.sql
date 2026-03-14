-- Aggiunge il supporto per referral tramite collaboratori nella tabella users
-- Esegui nel Supabase SQL Editor

-- 1. Aggiungi colonna referred_by_collaborator_id
ALTER TABLE public.users
    ADD COLUMN IF NOT EXISTS referred_by_collaborator_id UUID REFERENCES public.collaborators(id) ON DELETE SET NULL;

-- 2. Aggiungi indice per performance
CREATE INDEX IF NOT EXISTS idx_users_referred_by_collaborator
    ON public.users(referred_by_collaborator_id)
    WHERE referred_by_collaborator_id IS NOT NULL;

-- 3. Aggiorna il CHECK constraint su referral_type per includere 'collaborator'
--    (se esiste già un constraint, lo droppamo e ricreamo)
ALTER TABLE public.users
    DROP CONSTRAINT IF EXISTS users_referral_type_check;

ALTER TABLE public.users
    ADD CONSTRAINT users_referral_type_check
    CHECK (referral_type IN ('user', 'org_employee', 'org_external', 'collaborator') OR referral_type IS NULL);

-- 4. Crea la funzione RPC per incrementare users_count del collaboratore
CREATE OR REPLACE FUNCTION public.increment_collaborator_users_count(collab_id UUID)
RETURNS void
LANGUAGE sql
SECURITY DEFINER
AS $$
    UPDATE public.collaborators
    SET users_count = users_count + 1,
        updated_at  = NOW()
    WHERE id = collab_id;
$$;
