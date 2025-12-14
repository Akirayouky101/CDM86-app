-- ============================================
-- QUERY DEFINITIVE CON STRUTTURA REALE
-- ============================================

-- 📊 STRUTTURA REFERRAL_NETWORK:
-- - user_id: l'utente che è stato riferito
-- - referral_id: l'utente che ha fatto il referral
-- - level: livello referral (1=diretto, 2=secondo livello)
-- - points_awarded: punti assegnati
-- - referral_type: tipo ('user', 'organization', etc)

-- ============================================

-- 1️⃣ DETTAGLI REFERRAL NETWORK (CORRETTA AL 100%)
SELECT 
    rn.id,
    rn.user_id as referred_user_id,
    referred.email as referred_email,
    referred.referral_code as referred_code,
    rn.referral_id as referrer_user_id,
    referrer.email as referrer_email,
    referrer.referral_code as referrer_code,
    rn.level,
    rn.points_awarded,
    rn.referral_type,
    rn.created_at
FROM referral_network rn
LEFT JOIN users referred ON rn.user_id = referred.id
LEFT JOIN users referrer ON rn.referral_id = referrer.id
ORDER BY rn.created_at DESC;

-- ============================================

-- 2️⃣ ALBERO REFERRAL COMPLETO (Chi ha portato chi)
WITH RECURSIVE referral_tree AS (
    -- Livello 0: Admin/utenti senza referrer
    SELECT 
        id,
        email,
        referral_code,
        referred_by_id,
        0 as tree_level,
        email as path,
        0 as total_referrals
    FROM users
    WHERE referred_by_id IS NULL
    
    UNION ALL
    
    -- Livelli successivi
    SELECT 
        u.id,
        u.email,
        u.referral_code,
        u.referred_by_id,
        rt.tree_level + 1,
        rt.path || ' → ' || u.email,
        0
    FROM users u
    JOIN referral_tree rt ON u.referred_by_id = rt.id
)
SELECT 
    tree_level,
    email,
    referral_code,
    path as referral_chain
FROM referral_tree
ORDER BY tree_level, email;

-- ============================================

-- 3️⃣ STATISTICHE REFERRAL PER UTENTE
SELECT 
    u.email,
    u.referral_code,
    u.points as punti_utente,
    COUNT(CASE WHEN rn.level = 1 THEN 1 END) as diretti_lv1,
    COUNT(CASE WHEN rn.level = 2 THEN 1 END) as indiretti_lv2,
    SUM(CASE WHEN rn.level = 1 THEN rn.points_awarded ELSE 0 END) as punti_da_lv1,
    SUM(CASE WHEN rn.level = 2 THEN rn.points_awarded ELSE 0 END) as punti_da_lv2,
    SUM(rn.points_awarded) as punti_totali_referral
FROM users u
LEFT JOIN referral_network rn ON u.id = rn.referral_id
GROUP BY u.id, u.email, u.referral_code, u.points
HAVING COUNT(rn.id) > 0
ORDER BY punti_totali_referral DESC, diretti_lv1 DESC;

-- ============================================

-- 4️⃣ VERIFICA INTEGRITÀ REFERRAL SYSTEM
SELECT 
    u.email,
    u.referral_code,
    u.referred_by_id,
    ref.email as referred_by_email,
    rn.id as referral_network_id,
    rn.level as referral_level,
    CASE 
        WHEN u.referred_by_id IS NOT NULL AND rn.id IS NULL THEN '❌ Referral mancante in referral_network'
        WHEN u.referred_by_id IS NULL THEN '✅ Utente root (nessun referrer)'
        ELSE '✅ OK'
    END as status
FROM users u
LEFT JOIN users ref ON u.referred_by_id = ref.id
LEFT JOIN referral_network rn ON u.id = rn.user_id
ORDER BY u.created_at DESC;

-- ============================================

-- 5️⃣ TRANSAZIONI PUNTI (Struttura da verificare)
SELECT 
    pt.id,
    pt.user_id,
    u.email,
    pt.type,
    pt.amount,
    pt.description,
    pt.created_at
FROM points_transactions pt
JOIN users u ON pt.user_id = u.id
ORDER BY pt.created_at DESC
LIMIT 20;

-- ============================================

-- 6️⃣ USER POINTS - Dettaglio punti per utente
SELECT 
    up.user_id,
    u.email,
    u.referral_code,
    up.total_points,
    up.available_points,
    up.pending_points,
    up.lifetime_earned,
    up.lifetime_spent,
    u.points as points_in_users_table
FROM user_points up
JOIN users u ON up.user_id = u.id
ORDER BY up.total_points DESC;

-- ============================================

-- 7️⃣ REWARDS - Sistema premi
SELECT 
    r.id,
    r.user_id,
    u.email,
    r.type,
    r.amount,
    r.status,
    r.created_at
FROM rewards r
JOIN users u ON r.user_id = u.id
ORDER BY r.created_at DESC;

-- ============================================

-- 8️⃣ VERIFICA COERENZA PUNTI
-- Confronta punti in users vs user_points vs somma rewards
SELECT 
    u.email,
    u.points as punti_in_users,
    up.total_points as punti_in_user_points,
    up.available_points,
    up.pending_points,
    COALESCE(SUM(r.amount), 0) as totale_rewards,
    COALESCE(SUM(CASE WHEN r.status = 'completed' THEN r.amount ELSE 0 END), 0) as rewards_completati
FROM users u
LEFT JOIN user_points up ON u.id = up.user_id
LEFT JOIN rewards r ON u.id = r.user_id
GROUP BY u.id, u.email, u.points, up.total_points, up.available_points, up.pending_points
ORDER BY u.points DESC;

-- ============================================

-- 9️⃣ PROMOTION REDEMPTIONS
SELECT 
    pr.id,
    u.email as user_email,
    p.title as promotion_title,
    pr.points_spent,
    pr.status,
    pr.created_at
FROM promotion_redemptions pr
JOIN users u ON pr.user_id = u.id
JOIN promotions p ON pr.promotion_id = p.id
ORDER BY pr.created_at DESC;

-- ============================================

-- 🔟 STRUTTURA POINTS_TRANSACTIONS
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
    AND table_name = 'points_transactions'
ORDER BY ordinal_position;

-- ============================================

-- 1️⃣1️⃣ STRUTTURA USER_POINTS
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
    AND table_name = 'user_points'
ORDER BY ordinal_position;

-- ============================================

-- 1️⃣2️⃣ STRUTTURA REWARDS
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
    AND table_name = 'rewards'
ORDER BY ordinal_position;
