-- CANCELLA DIEGO DA AUTH.USERS
-- ATTENZIONE: Questo cancellerà definitivamente l'utente Diego

DELETE FROM auth.users 
WHERE email = 'diegomarruchi@gmail.com';

-- VERIFICA CANCELLAZIONE
SELECT 
    'auth.users' AS tabella,
    COUNT(*) AS conteggio
FROM auth.users
WHERE email = 'diegomarruchi@gmail.com'

UNION ALL

SELECT 
    'public.users' AS tabella,
    COUNT(*) AS conteggio
FROM public.users
WHERE email = 'diegomarruchi@gmail.com';
