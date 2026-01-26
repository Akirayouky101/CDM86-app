-- =====================================================
-- DEBUG REGISTRAZIONE: diegomarruchi@gmail.com
-- =====================================================

-- 1. Verifica utente in auth.users
SELECT 
    '1 AUTH.USERS' as check_step,
    id as auth_id,
    email,
    created_at,
    email_confirmed_at,
    raw_user_meta_data
FROM auth.users
WHERE email = 'diegomarruchi@gmail.com';

-- 2. Verifica utente in public.users
SELECT 
    '2 PUBLIC.USERS' as check_step,
    id as user_id,
    auth_user_id,
    email,
    first_name,
    last_name,
    referral_code,
    referred_by_id,
    referred_by_organization_id,
    referral_type,
    points,
    created_at
FROM public.users
WHERE email = 'diegomarruchi@gmail.com' 
   OR auth_user_id = (SELECT id FROM auth.users WHERE email = 'diegomarruchi@gmail.com');

-- 3. Verifica se e in organizations
SELECT 
    '3 ORGANIZATIONS' as check_step,
    id as org_id,
    auth_user_id,
    name,
    email,
    referral_code_employees,
    referral_code_external
FROM organizations
WHERE email = 'diegomarruchi@gmail.com'
   OR auth_user_id = (SELECT id FROM auth.users WHERE email = 'diegomarruchi@gmail.com');

-- 4. Verifica trigger function esiste
SELECT 
    '4 TRIGGER FUNCTION' as check_step,
    proname as function_name,
    prosrc as function_code
FROM pg_proc
WHERE proname = 'handle_new_user';

-- 5. Verifica trigger esiste su auth.users
SELECT 
    '5 TRIGGER' as check_step,
    tgname as trigger_name,
    tgenabled as enabled
FROM pg_trigger
WHERE tgname = 'on_auth_user_created';

-- 6. Verifica colonna auth_user_id esiste in public.users
SELECT 
    '6 SCHEMA' as check_step,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'users' 
  AND column_name = 'auth_user_id';

-- 7. Verifica ultimi utenti creati in public.users
SELECT 
    '7 ULTIMI UTENTI' as check_step,
    email,
    auth_user_id,
    referral_code,
    created_at
FROM public.users
ORDER BY created_at DESC
LIMIT 5;

-- =====================================================
-- RIASSUNTO
-- =====================================================
SELECT 
    'RIASSUNTO' as status,
    (SELECT COUNT(*) FROM auth.users WHERE email = 'diegomarruchi@gmail.com') as in_auth_users,
    (SELECT COUNT(*) FROM public.users WHERE email = 'diegomarruchi@gmail.com') as in_public_users,
    (SELECT COUNT(*) FROM organizations WHERE email = 'diegomarruchi@gmail.com') as in_organizations,
    CASE 
        WHEN (SELECT COUNT(*) FROM auth.users WHERE email = 'diegomarruchi@gmail.com') = 0 
        THEN 'Non registrato in auth.users'
        WHEN (SELECT COUNT(*) FROM public.users WHERE email = 'diegomarruchi@gmail.com') = 0 
        THEN 'In auth.users MA non in public.users (trigger fallito)'
        ELSE 'Tutto OK'
    END as diagnosis;
