-- ============================================================
-- CLEANUP TEST USERS - Esegui nel Supabase SQL Editor
-- ============================================================
-- Cancella un utente normale + un collaboratore dal DB e dall'auth
-- Modifica le email sotto prima di eseguire
-- ============================================================

DO $$
DECLARE
    v_user_email        TEXT := 'diegomarruchizg@gmail.com';      -- <-- email utente normale
    v_collab_email      TEXT := 'diegomarruchi@outlook.it';        -- <-- email collaboratore

    v_user_auth_id      UUID;
    v_collab_auth_id    UUID;
    v_collab_id         UUID;
BEGIN

    -- ─── 1. Recupera gli ID ───────────────────────────────────────
    SELECT auth_user_id INTO v_user_auth_id
        FROM public.users WHERE email = v_user_email;

    SELECT auth_user_id, id INTO v_collab_auth_id, v_collab_id
        FROM public.collaborators WHERE email = v_collab_email;

    -- ─── 2. Cancella l'utente dalla tabella users ─────────────────
    DELETE FROM public.users WHERE email = v_user_email;
    RAISE NOTICE 'users: cancellato %', v_user_email;

    -- ─── 3. Cancella il collaboratore dalla tabella collaborators ─
    DELETE FROM public.collaborators WHERE email = v_collab_email;
    RAISE NOTICE 'collaborators: cancellato %', v_collab_email;

    -- ─── 4. Cancella entrambi dall'auth (richiede service_role) ───
    IF v_user_auth_id IS NOT NULL THEN
        DELETE FROM auth.users WHERE id = v_user_auth_id;
        RAISE NOTICE 'auth.users: cancellato utente %', v_user_auth_id;
    ELSE
        RAISE NOTICE 'auth.users: utente non trovato (già cancellato?)';
    END IF;

    IF v_collab_auth_id IS NOT NULL THEN
        DELETE FROM auth.users WHERE id = v_collab_auth_id;
        RAISE NOTICE 'auth.users: cancellato collaboratore %', v_collab_auth_id;
    ELSE
        RAISE NOTICE 'auth.users: collaboratore non trovato (già cancellato?)';
    END IF;

    RAISE NOTICE '✅ Cleanup completato!';

END $$;

-- ─── VERIFICA FINALE ─────────────────────────────────────────────
-- Esegui questo dopo per confermare che tutto è stato cancellato:
/*
SELECT 'users' AS tabella, id, email FROM public.users
    WHERE email IN ('diegomarruchizg@gmail.com', 'diegomarruchi@outlook.it')
UNION ALL
SELECT 'collaborators', id, email FROM public.collaborators
    WHERE email IN ('diegomarruchizg@gmail.com', 'diegomarruchi@outlook.it')
UNION ALL
SELECT 'auth.users', id::text, email FROM auth.users
    WHERE email IN ('diegomarruchizg@gmail.com', 'diegomarruchi@outlook.it');
*/
