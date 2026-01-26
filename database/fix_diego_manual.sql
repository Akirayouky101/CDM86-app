-- =====================================================
-- FIX MANUALE: Crea Diego in public.users
-- =====================================================

-- 1. Crea manualmente il record per Diego
INSERT INTO public.users (
    auth_user_id,
    email,
    first_name,
    last_name,
    referral_code
)
SELECT 
    au.id,
    au.email,
    COALESCE(au.raw_user_meta_data->>'first_name', SPLIT_PART(au.email, '@', 1)),
    COALESCE(au.raw_user_meta_data->>'last_name', ''),
    UPPER(SUBSTRING(MD5(RANDOM()::TEXT || CLOCK_TIMESTAMP()::TEXT) FROM 1 FOR 8))
FROM auth.users au
WHERE au.email = 'diegomarruchi@gmail.com'
AND NOT EXISTS (
    SELECT 1 FROM public.users pu WHERE pu.auth_user_id = au.id
);

-- 2. Verifica creazione
SELECT 
    'DIEGO CREATO' as status,
    id,
    auth_user_id,
    email,
    first_name,
    last_name,
    referral_code,
    points,
    created_at
FROM public.users
WHERE email = 'diegomarruchi@gmail.com';

-- 3. Verifica che ora possa fare login
SELECT 
    'VERIFICA LOGIN' as check_type,
    au.id as auth_id,
    au.email,
    pu.id as user_id,
    pu.referral_code,
    CASE 
        WHEN pu.id IS NOT NULL THEN 'OK - Puo fare login'
        ELSE 'ERRORE - Manca record in public.users'
    END as login_status
FROM auth.users au
LEFT JOIN public.users pu ON pu.auth_user_id = au.id
WHERE au.email = 'diegomarruchi@gmail.com';
