-- VERIFICA SE L'UTENTE È STATO CREATO
SELECT 
    'auth.users' AS tabella,
    email,
    id,
    created_at
FROM auth.users
WHERE id = 'd1e14259-356c-46a1-95cc-633da3fa488f'

UNION ALL

SELECT 
    'public.users' AS tabella,
    email,
    id::text,
    created_at
FROM public.users
WHERE auth_user_id = 'd1e14259-356c-46a1-95cc-633da3fa488f';
