-- ============================================
-- VERIFICA TABELLA FAVORITES
-- ============================================

-- 1️⃣ STRUTTURA TABELLA FAVORITES
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
    AND table_name = 'favorites'
ORDER BY ordinal_position;

-- 2️⃣ TUTTI I PREFERITI ESISTENTI
SELECT 
    f.id,
    f.user_id,
    u.email as user_email,
    f.promotion_id,
    p.title as promotion_title,
    f.created_at
FROM favorites f
JOIN users u ON f.user_id = u.id
LEFT JOIN promotions p ON f.promotion_id = p.id
ORDER BY f.created_at DESC;

-- 3️⃣ RLS POLICIES SU FAVORITES
SELECT
    policyname,
    permissive,
    roles,
    cmd as command,
    qual as using_expression,
    with_check as with_check_expression
FROM pg_policies
WHERE schemaname = 'public'
    AND tablename = 'favorites'
ORDER BY policyname;

-- 4️⃣ FOREIGN KEYS SU FAVORITES
SELECT
    tc.constraint_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    rc.update_rule,
    rc.delete_rule
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
JOIN information_schema.referential_constraints AS rc
    ON tc.constraint_name = rc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_name = 'favorites';
