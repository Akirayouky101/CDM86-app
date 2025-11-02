-- =====================================================
-- VERIFICA RLS POLICIES SU USERS
-- =====================================================
-- Controlla se ci sono policy che bloccano l'UPDATE di referred_by_id
-- =====================================================

-- 1. Lista tutte le policy sulla tabella users
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'users'
ORDER BY cmd, policyname;

-- 2. Verifica se RLS è abilitato
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE tablename = 'users';

-- 3. Test manuale UPDATE (esegui DOPO aver registrato un utente di test)
-- SOSTITUISCI i valori con un utente reale e un referrer reale
/*
DO $$
DECLARE
    v_test_user_id UUID := '127530d8-8f83-4649-9652-3b8ca5ad074f'; -- Ultimo Diego Marruchi
    v_referrer_id UUID := (SELECT id FROM users WHERE referral_code = '06AC519C' LIMIT 1);
BEGIN
    RAISE NOTICE 'Test User ID: %', v_test_user_id;
    RAISE NOTICE 'Referrer ID: %', v_referrer_id;
    
    -- Tenta UPDATE
    UPDATE users 
    SET referred_by_id = v_referrer_id
    WHERE id = v_test_user_id;
    
    -- Verifica risultato
    IF FOUND THEN
        RAISE NOTICE '✅ UPDATE riuscito!';
    ELSE
        RAISE NOTICE '❌ UPDATE fallito - utente non trovato o policy bloccata';
    END IF;
    
    -- Mostra stato finale
    PERFORM * FROM users WHERE id = v_test_user_id;
    
END $$;

-- Verifica il risultato
SELECT id, first_name, last_name, email, referred_by_id, created_at
FROM users 
WHERE id = '127530d8-8f83-4649-9652-3b8ca5ad074f';
*/
