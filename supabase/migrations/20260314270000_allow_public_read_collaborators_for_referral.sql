-- Permette la lettura pubblica (anon) dei collaboratori attivi
-- SOLO per validazione codice referral durante la registrazione
-- Esegui nel Supabase SQL Editor

CREATE POLICY "Public can read active collaborator referral codes"
    ON public.collaborators
    FOR SELECT
    TO anon, authenticated
    USING (status = 'active');
