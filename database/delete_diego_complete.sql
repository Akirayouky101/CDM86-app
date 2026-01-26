-- CANCELLA DIEGO COMPLETAMENTE
DELETE FROM auth.users 
WHERE email = 'diegomarruchi@gmail.com';

DELETE FROM public.users
WHERE email = 'diegomarruchi@gmail.com';

-- VERIFICA CANCELLAZIONE
SELECT COUNT(*) as count_auth FROM auth.users WHERE email = 'diegomarruchi@gmail.com';
SELECT COUNT(*) as count_public FROM public.users WHERE email = 'diegomarruchi@gmail.com';
