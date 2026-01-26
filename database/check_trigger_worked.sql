-- VERIFICA TRIGGER: utente in public.users?
SELECT 
    email,
    referral_code,
    referred_by_id,
    referral_type,
    auth_user_id,
    created_at
FROM public.users
WHERE auth_user_id = 'd1e14259-356c-46a1-95cc-633da3fa488f';

-- VERIFICA ANCHE IN AUTH.USERS
SELECT 
    email,
    id,
    raw_user_meta_data,
    created_at
FROM auth.users
WHERE id = 'd1e14259-356c-46a1-95cc-633da3fa488f';
