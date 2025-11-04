-- =====================================================
-- VERIFICA SE ID auth.users = ID public.users per Martina
-- =====================================================

-- 1. ID di Martina in public.users
SELECT 
    'public.users' as tabella,
    id,
    email
FROM users
WHERE email = 'serviziomail1@gmail.com';

-- 2. ID di Martina in auth.users
SELECT 
    'auth.users' as tabella,
    id,
    email
FROM auth.users
WHERE email = 'serviziomail1@gmail.com';

-- 3. CONFRONTO
SELECT 
    CASE 
        WHEN au.id = pu.id THEN '✅ ID UGUALI - Il problema è altrove'
        ELSE '❌ ID DIVERSI - Questo è il problema!'
    END as risultato,
    au.id as "ID auth.users",
    pu.id as "ID public.users"
FROM auth.users au
CROSS JOIN users pu
WHERE au.email = 'serviziomail1@gmail.com'
AND pu.email = 'serviziomail1@gmail.com';