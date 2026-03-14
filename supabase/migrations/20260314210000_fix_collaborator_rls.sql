-- ═══════════════════════════════════════════════════════════
-- FIX RLS: permetti ai collaboratori di aggiornare il proprio
-- profilo e di leggere le impostazioni
-- Esegui nel Supabase SQL Editor
-- ═══════════════════════════════════════════════════════════

-- 1. Permetti ai collaboratori di aggiornare il proprio record
--    (nome, cognome, telefono — non lo status)
CREATE POLICY "Collaborator updates own data"
    ON collaborators FOR UPDATE
    USING (auth_user_id = auth.uid())
    WITH CHECK (auth_user_id = auth.uid());

-- 2. Permetti a tutti i collaboratori autenticati di leggere
--    le impostazioni (tabella pubblica di configurazione)
CREATE POLICY "Collaborator reads settings"
    ON collaborator_settings FOR SELECT
    USING (auth.uid() IS NOT NULL);
