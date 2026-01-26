-- TROVA REFERRAL CODE DI ADMIN
SELECT 
    email,
    referral_code,
    id,
    auth_user_id
FROM public.users
WHERE email = 'admin@cdm86.com';
