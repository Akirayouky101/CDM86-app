-- ============================================
-- QUERY CORRETTE CON NOMI TABELLE REALI
-- ============================================

-- 1️⃣ CONTEGGIO RECORD PER OGNI TABELLA
SELECT 
    'users' as table_name,
    COUNT(*) as total_records
FROM users
UNION ALL
SELECT 
    'promotions',
    COUNT(*)
FROM promotions
UNION ALL
SELECT 
    'organizations',
    COUNT(*)
FROM organizations
UNION ALL
SELECT 
    'organization_requests',
    COUNT(*)
FROM organization_requests
UNION ALL
SELECT 
    'referral_network',
    COUNT(*)
FROM referral_network
UNION ALL
SELECT 
    'points_transactions',
    COUNT(*)
FROM points_transactions
UNION ALL
SELECT 
    'promotion_redemptions',
    COUNT(*)
FROM promotion_redemptions
UNION ALL
SELECT 
    'contracts',
    COUNT(*)
FROM contracts
UNION ALL
SELECT 
    'user_points',
    COUNT(*)
FROM user_points
UNION ALL
SELECT 
    'favorites',
    COUNT(*)
FROM favorites
UNION ALL
SELECT 
    'rewards',
    COUNT(*)
FROM rewards
UNION ALL
SELECT 
    'reward_redemptions',
    COUNT(*)
FROM reward_redemptions
ORDER BY table_name;

-- ============================================

-- 2️⃣ DETTAGLI REFERRAL NETWORK
SELECT 
    rn.id,
    rn.referrer_id,
    ref.email as referrer_email,
    ref.referral_code as referrer_code,
    rn.referred_user_id,
    referred.email as referred_email,
    referred.referral_code as referred_code,
    rn.status,
    rn.points_earned_referrer,
    rn.points_earned_referred,
    rn.created_at
FROM referral_network rn
LEFT JOIN users ref ON rn.referrer_id = ref.id
LEFT JOIN users referred ON rn.referred_user_id = referred.id
ORDER BY rn.created_at DESC;

-- ============================================

-- 3️⃣ TRANSAZIONI PUNTI
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
LIMIT 50;

-- ============================================

-- 4️⃣ VERIFICA INTEGRITÀ REFERRAL SYSTEM
-- Controlla se ci sono incoerenze tra users.referred_by_id e referral_network
SELECT 
    u.email,
    u.referral_code,
    u.referred_by_id,
    ref.email as referred_by_email,
    CASE 
        WHEN u.referred_by_id IS NOT NULL AND rn.id IS NULL THEN '❌ Referral mancante in referral_network'
        WHEN u.referred_by_id IS NULL THEN '✅ Utente root (nessun referrer)'
        ELSE '✅ OK'
    END as status
FROM users u
LEFT JOIN users ref ON u.referred_by_id = ref.id
LEFT JOIN referral_network rn ON u.id = rn.referred_user_id
ORDER BY u.created_at DESC;

-- ============================================

-- 5️⃣ ALBERO REFERRAL COMPLETO
WITH RECURSIVE referral_tree AS (
    -- Livello 0: Admin/utenti senza referrer
    SELECT 
        id,
        email,
        referral_code,
        referred_by_id,
        0 as level,
        email as path
    FROM users
    WHERE referred_by_id IS NULL
    
    UNION ALL
    
    -- Livelli successivi
    SELECT 
        u.id,
        u.email,
        u.referral_code,
        u.referred_by_id,
        rt.level + 1,
        rt.path || ' → ' || u.email
    FROM users u
    JOIN referral_tree rt ON u.referred_by_id = rt.id
)
SELECT 
    level,
    email,
    referral_code,
    path as referral_chain
FROM referral_tree
ORDER BY level, email;

-- ============================================

-- 6️⃣ STATISTICHE REFERRAL PER UTENTE
SELECT 
    u.email,
    u.referral_code,
    COUNT(DISTINCT rn.referred_user_id) as total_referrals,
    u.points as punti_totali,
    SUM(rn.points_earned_referrer) as punti_guadagnati_referral
FROM users u
LEFT JOIN referral_network rn ON u.id = rn.referrer_id
GROUP BY u.id, u.email, u.referral_code, u.points
HAVING COUNT(DISTINCT rn.referred_user_id) > 0
ORDER BY total_referrals DESC, punti_guadagnati_referral DESC;

-- ============================================

-- 7️⃣ PROMOTION REDEMPTIONS
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

-- 8️⃣ USER POINTS (se esiste tabella separata)
SELECT 
    up.user_id,
    u.email,
    up.total_points,
    up.available_points,
    up.pending_points,
    up.lifetime_earned,
    up.lifetime_spent
FROM user_points up
JOIN users u ON up.user_id = u.id
ORDER BY up.total_points DESC
LIMIT 20;

-- ============================================

-- 9️⃣ STRUTTURA TABELLA REFERRAL_NETWORK
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
    AND table_name = 'referral_network'
ORDER BY ordinal_position;

-- ============================================

-- 🔟 STRUTTURA TABELLA POINTS_TRANSACTIONS
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
    AND table_name = 'points_transactions'
ORDER BY ordinal_position;
