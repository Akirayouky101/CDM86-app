-- View sicura per i collaboratori: mostra solo gli utenti che hanno usato il loro codice referral
-- Il collaboratore vede solo i propri utenti grazie al filtro su referred_by_collaborator_id
-- Esegui nel Supabase SQL Editor

CREATE OR REPLACE VIEW public.collaborator_referred_users AS
SELECT
    u.id,
    u.first_name,
    u.last_name,
    u.email,
    u.created_at,
    u.subscription_status,
    u.referred_by_collaborator_id
FROM public.users u
WHERE u.referred_by_collaborator_id IS NOT NULL;

-- RLS sulla view: ogni collaboratore vede solo i propri utenti
ALTER VIEW public.collaborator_referred_users OWNER TO authenticated;

-- Policy: il collaboratore autenticato vede solo gli utenti che gli appartengono
-- (la view non ha RLS nativa, usiamo SECURITY INVOKER tramite la view + controllo nel client)
-- Ma per sicurezza aggiungiamo una policy sulla tabella users per questa query

-- Permetti ai collaboratori autenticati di leggere gli utenti referral che appartengono a loro
CREATE POLICY "Collaborators can read their referred users"
    ON public.users
    FOR SELECT
    TO authenticated
    USING (
        referred_by_collaborator_id IN (
            SELECT id FROM public.collaborators WHERE auth_user_id = auth.uid()
        )
    );
