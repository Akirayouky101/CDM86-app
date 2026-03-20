-- Migration _0016: update admin_collaborators_view to include referral_code_io
-- Must DROP + recreate because PostgreSQL won't allow adding columns via CREATE OR REPLACE VIEW

DROP VIEW IF EXISTS admin_collaborators_view;

CREATE VIEW admin_collaborators_view AS
SELECT
    c.id,
    c.user_id,
    c.auth_user_id,
    c.email,
    c.first_name,
    c.last_name,
    c.referral_code,
    c.referral_code_io,
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
    c.referred_by_id
FROM collaborators c;
