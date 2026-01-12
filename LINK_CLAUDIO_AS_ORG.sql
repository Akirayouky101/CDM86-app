-- ============================================
-- LINKA CLAUDIO.MURA1967@GMAIL.COM COME ORGANIZZAZIONE
-- ============================================

DO $$
DECLARE
    v_auth_user_id UUID;
    v_org_id UUID;
    v_org_name TEXT := 'Claudio Mura'; -- Cambia questo con il nome reale dell'organizzazione
BEGIN
    -- 1. Trova l'ID dell'utente auth
    SELECT id INTO v_auth_user_id
    FROM auth.users
    WHERE email = 'claudio.mura1967@gmail.com';

    IF v_auth_user_id IS NULL THEN
        RAISE EXCEPTION '❌ Utente con email claudio.mura1967@gmail.com non trovato!';
    END IF;

    RAISE NOTICE '✅ Utente trovato: %', v_auth_user_id;

    -- 2. Controlla se esiste già un'organizzazione con questa email
    SELECT id INTO v_org_id
    FROM organizations
    WHERE email = 'claudio.mura1967@gmail.com';

    IF v_org_id IS NOT NULL THEN
        -- Organizzazione esiste: aggiorna il campo auth_user_id
        UPDATE organizations
        SET auth_user_id = v_auth_user_id
        WHERE id = v_org_id;
        
        RAISE NOTICE '✅ Organizzazione esistente aggiornata: %', v_org_id;
        RAISE NOTICE '   Nome: %', (SELECT name FROM organizations WHERE id = v_org_id);
        RAISE NOTICE '   Ora linkata all''utente auth!';
    ELSE
        -- 3. Crea nuova organizzazione
        INSERT INTO organizations (
            id,
            name,
            email,
            organization_type,
            auth_user_id,
            created_at
        ) VALUES (
            gen_random_uuid(),
            v_org_name,
            'claudio.mura1967@gmail.com',
            'company', -- Può essere: 'company' o 'association'
            v_auth_user_id,
            NOW()
        )
        RETURNING id INTO v_org_id;

        RAISE NOTICE '✅ Organizzazione creata: %', v_org_id;
        RAISE NOTICE '   Nome: %', v_org_name;
    END IF;

    RAISE NOTICE '';
    RAISE NOTICE '🎉 COMPLETATO!';
    RAISE NOTICE '   Email: claudio.mura1967@gmail.com';
    RAISE NOTICE '   Ora può fare login e accedere alla organization-dashboard!';

END $$;

-- Verifica il risultato
SELECT 
    o.id as org_id,
    o.name as org_name,
    o.auth_user_id,
    u.email,
    u.email_confirmed_at IS NOT NULL as email_confermata,
    o.created_at
FROM organizations o
JOIN auth.users u ON u.id = o.auth_user_id
WHERE u.email = 'claudio.mura1967@gmail.com';
