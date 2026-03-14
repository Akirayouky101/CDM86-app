-- FIX URGENTE: rimuove la policy che causa infinite recursion su users
-- La policy "Collaborators can read their referred users" fa subquery su collaborators
-- che a sua volta potrebbe fare subquery su users → loop infinito
-- Esegui SUBITO nel Supabase SQL Editor

-- 1. Rimuovi la policy problematica
DROP POLICY IF EXISTS "Collaborators can read their referred users" ON public.users;

-- 2. Rimuovi anche la view (non necessaria)
DROP VIEW IF EXISTS public.collaborator_referred_users;

-- 3. Crea una funzione SECURITY DEFINER per ottenere il collaborator_id dal token
--    senza toccare la tabella users (evita la ricorsione)
CREATE OR REPLACE FUNCTION public.get_my_collaborator_id()
RETURNS UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $func$
    SELECT id FROM public.collaborators WHERE auth_user_id = auth.uid() LIMIT 1;
$func$;

-- 4. Ricrea la policy usando la funzione (nessuna subquery su users → nessuna ricorsione)
CREATE POLICY "Collaborators can read their referred users"
    ON public.users
    FOR SELECT
    TO authenticated
    USING (
        referred_by_collaborator_id = public.get_my_collaborator_id()
    );
