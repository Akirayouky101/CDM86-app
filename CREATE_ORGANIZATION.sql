-- ============================================
-- CREA NUOVA ORGANIZZAZIONE
-- ============================================
-- 
-- ISTRUZIONI:
-- 1. Sostituisci i valori tra <...> con i dati reali
-- 2. Esegui questo script su Supabase SQL Editor
-- 3. L'organizzazione potrà fare login con email e password
--
-- ============================================

DO $$
DECLARE
    v_auth_user_id UUID;
    v_org_id UUID;
    v_email TEXT := '<EMAIL_ORGANIZZAZIONE>'; -- Es: 'pizzeria@example.com'
    v_password TEXT := '<PASSWORD>'; -- Es: 'Pizza2025!'
    v_org_name TEXT := '<NOME_ORGANIZZAZIONE>'; -- Es: 'Pizzeria Da Mario'
BEGIN
    -- 1. Crea utente in auth.users (per il login)
    INSERT INTO auth.users (
        instance_id,
        id,
        aud,
        role,
        email,
        encrypted_password,
        email_confirmed_at,
        raw_app_meta_data,
        raw_user_meta_data,
        created_at,
        updated_at,
        confirmation_token,
        email_change,
        email_change_token_new,
        recovery_token
    ) VALUES (
        '00000000-0000-0000-0000-000000000000',
        gen_random_uuid(),
        'authenticated',
        'authenticated',
        v_email,
        crypt(v_password, gen_salt('bf')),
        NOW(),
        '{"provider":"email","providers":["email"]}',
        '{}',
        NOW(),
        NOW(),
        '',
        '',
        '',
        ''
    )
    RETURNING id INTO v_auth_user_id;

    RAISE NOTICE '✅ Utente auth creato: %', v_auth_user_id;

    -- 2. Crea l'organizzazione nella tabella organizations
    INSERT INTO organizations (
        id,
        name,
        auth_user_id,
        created_at
    ) VALUES (
        gen_random_uuid(),
        v_org_name,
        v_auth_user_id,
        NOW()
    )
    RETURNING id INTO v_org_id;

    RAISE NOTICE '✅ Organizzazione creata: %', v_org_id;
    RAISE NOTICE '   Nome: %', v_org_name;
    RAISE NOTICE '   Email: %', v_email;
    RAISE NOTICE '   Password: %', v_password;
    RAISE NOTICE '';
    RAISE NOTICE '🎉 Ora puoi fare login con queste credenziali!';

END $$;

-- Verifica che tutto sia stato creato correttamente
SELECT 
    o.id as org_id,
    o.name,
    o.auth_user_id,
    u.email,
    u.email_confirmed_at IS NOT NULL as email_confermata
FROM organizations o
JOIN auth.users u ON u.id = o.auth_user_id
WHERE u.email = '<EMAIL_ORGANIZZAZIONE>'
ORDER BY o.created_at DESC
LIMIT 1;
