-- ============================================================
-- CDM86 — RLS: admin può leggere tutti i redemption_tokens
-- Necessario per il tab Scansioni nel pannello admin
-- Esegui nel SQL Editor di Supabase
-- ============================================================

-- Policy: gli utenti con role='admin' possono leggere tutti i token
CREATE POLICY "Admins read all redemption tokens"
    ON redemption_tokens FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
              AND users.role = 'admin'
        )
    );
