-- =====================================================
-- FIX POINTS SYSTEM - Create Views for User Data
-- =====================================================
-- Problema: Non possiamo usare auth.admin.listUsers() dal browser
-- Soluzione: Creare viste che fanno JOIN con auth.users
-- =====================================================

-- 1. VISTA: User Points con Email
-- Combina user_points con auth.users per avere l'email
CREATE OR REPLACE VIEW user_points_with_email AS
SELECT 
    up.id,
    up.user_id,
    up.points_total,
    up.points_used,
    up.points_available,
    up.referrals_count,
    up.approved_reports_count,
    up.rejected_reports_count,
    up.level,
    up.created_at,
    up.updated_at,
    au.email,
    au.created_at as user_created_at
FROM user_points up
LEFT JOIN auth.users au ON up.user_id = au.id;

-- 2. VISTA: Redemptions con Dettagli Completi
-- Combina redemptions con rewards e auth.users
CREATE OR REPLACE VIEW redemptions_with_details AS
SELECT 
    rr.id,
    rr.user_id,
    rr.reward_id,
    rr.points_spent,
    rr.status,
    rr.notes,
    rr.redeemed_at,
    rr.updated_at,
    au.email as user_email,
    r.title as reward_title,
    r.description as reward_description,
    r.points_required as reward_points,
    r.image_url as reward_image
FROM reward_redemptions rr
LEFT JOIN auth.users au ON rr.user_id = au.id
LEFT JOIN rewards r ON rr.reward_id = r.id;

-- 3. Grant permissions per le viste
GRANT SELECT ON user_points_with_email TO authenticated;
GRANT SELECT ON redemptions_with_details TO authenticated;

-- 4. RLS Policies per le viste
ALTER VIEW user_points_with_email SET (security_invoker = true);
ALTER VIEW redemptions_with_details SET (security_invoker = true);

-- =====================================================
-- ISTRUZIONI
-- =====================================================
-- 1. Esegui questo SQL su Supabase SQL Editor
-- 2. Modifica admin-panel.html per usare le viste invece delle query dirette
-- 3. Testa il pannello admin
-- =====================================================
