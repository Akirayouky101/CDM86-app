-- INSERT MANUALE PER DIEGO (d1e14259-356c-46a1-95cc-633da3fa488f)
INSERT INTO public.users (
    auth_user_id,
    email,
    first_name,
    last_name,
    referral_code,
    referred_by_id,
    referral_type
) VALUES (
    'd1e14259-356c-46a1-95cc-633da3fa488f',
    'diegomarruchi@gmail.com',
    'Diego',
    'Marruchi',
    UPPER(SUBSTRING(MD5(RANDOM()::TEXT || CLOCK_TIMESTAMP()::TEXT) FROM 1 FOR 8)),
    '68e617b6-1735-4779-ab1c-7571df9c27e9', -- ID admin (B8920326)
    'external'
);

-- VERIFICA
SELECT 
    email,
    referral_code,
    referred_by_id,
    referral_type,
    auth_user_id
FROM public.users
WHERE email = 'diegomarruchi@gmail.com';
