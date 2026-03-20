-- ═══════════════════════════════════════════════════════════════════
-- FIX: Aggiunge referred_by_id alla admin_collaborators_view
-- Necessario per il pulsante "Abbandona Ruolo" che deve passare
-- l'id del collaboratore alla funzione RPC
-- ═══════════════════════════════════════════════════════════════════

CREATE OR REPLACE VIEW admin_collaborators_view AS
SELECT
    c.id,
    c.user_id,
    c.auth_user_id,
    c.email,
    c.first_name,
    c.last_name,
    c.referral_code,
    c.status,
    c.notes,
    c.registered_at,
    c.approved_at,
    c.rate_user,
    c.rate_azienda,
    c.total_earned,
    c.total_pending,
    c.total_paid,
    c.users_count,
    c.aziende_count,
    c.referred_by_id   -- aggiunto per Abbandona Ruolo e Approva
FROM collaborators c;
