-- ============================================================
-- CDM86 — Sistema QR Riscatto Promozioni
-- Esegui questo SQL nel SQL Editor di Supabase
-- ============================================================

-- 1️⃣ Aggiungi campo max_uses_per_user alla tabella promotions
ALTER TABLE promotions
    ADD COLUMN IF NOT EXISTS max_uses_per_user INTEGER NOT NULL DEFAULT 1;

-- 1b️⃣ Aggiungi campo max_uses_per_user alla tabella organization_pages
ALTER TABLE organization_pages
    ADD COLUMN IF NOT EXISTS max_uses_per_user INTEGER NOT NULL DEFAULT 1;

-- 2️⃣ Crea tabella redemption_tokens
CREATE TABLE IF NOT EXISTS redemption_tokens (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    token         UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    promo_id      UUID NOT NULL REFERENCES promotions(id) ON DELETE CASCADE,
    user_id       UUID NOT NULL,                       -- auth user id
    status        TEXT NOT NULL DEFAULT 'pending'      -- pending | used | expired
                  CHECK (status IN ('pending','used','expired')),
    expires_at    TIMESTAMPTZ NOT NULL,
    used_at       TIMESTAMPTZ,
    validated_by  TEXT,                                -- email/id del gestore che ha validato
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indici per query veloci
CREATE INDEX IF NOT EXISTS idx_redemption_tokens_token     ON redemption_tokens(token);
CREATE INDEX IF NOT EXISTS idx_redemption_tokens_user_promo ON redemption_tokens(user_id, promo_id);
CREATE INDEX IF NOT EXISTS idx_redemption_tokens_status    ON redemption_tokens(status);

-- 3️⃣ Auto-scadenza: job che marca i token scaduti ogni minuto
-- (Supabase non ha cron nativo nei free plan, la logica di scadenza
--  è gestita anche lato API. Questa function è un'opzione aggiuntiva.)
CREATE OR REPLACE FUNCTION expire_old_tokens()
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
    UPDATE redemption_tokens
    SET status = 'expired'
    WHERE status = 'pending'
      AND expires_at < now();
END;
$$;

-- 4️⃣ RLS: gli utenti vedono solo i propri token
ALTER TABLE redemption_tokens ENABLE ROW LEVEL SECURITY;

-- Utente può leggere i propri token
CREATE POLICY "Users read own tokens"
    ON redemption_tokens FOR SELECT
    USING (auth.uid() = user_id);

-- Utente può inserire token per se stesso
CREATE POLICY "Users insert own tokens"
    ON redemption_tokens FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Service role può fare tutto (per le API functions)
-- (il service role bypassa RLS per default, nessuna policy necessaria)

-- 5️⃣ Vista comoda per statistiche riscatti (accessibile alle org)
CREATE OR REPLACE VIEW redemption_stats AS
SELECT
    rt.promo_id,
    p.title          AS promo_title,
    p.partner_email,
    COUNT(*)         AS total_tokens,
    COUNT(*) FILTER (WHERE rt.status = 'used')    AS total_used,
    COUNT(*) FILTER (WHERE rt.status = 'pending') AS total_pending,
    COUNT(*) FILTER (WHERE rt.status = 'expired') AS total_expired
FROM redemption_tokens rt
JOIN promotions p ON p.id = rt.promo_id
GROUP BY rt.promo_id, p.title, p.partner_email;
