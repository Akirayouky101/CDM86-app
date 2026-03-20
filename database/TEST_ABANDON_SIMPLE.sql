-- ═══════════════════════════════════════════════════════════════════
-- TEST DIRETTO - Crea utente collaboratore di test
-- Da eseguire nel Supabase SQL Editor (ha permessi completi)
-- ═══════════════════════════════════════════════════════════════════

DO $$
DECLARE
    v_admin_id    UUID := 'e8cde03d-2aa6-4ea6-a29f-43f290ae00ce';
    v_auth_collab UUID;
    v_user_collab UUID;
    v_user_l1a    UUID;
    v_user_l1b    UUID;
    v_user_l2a    UUID;
    v_user_l2b    UUID;
    v_user_l3a    UUID;
    v_user_l3b    UUID;
    v_collab_id   UUID;
    v_pw          TEXT;
BEGIN
    -- Pulizia preventiva
    DELETE FROM public.collaborators WHERE email = 'collab.test@cdm86.it';
    DELETE FROM public.users WHERE email IN (
        'collab.test@cdm86.it',
        'l1a.test@cdm86.it', 'l1b.test@cdm86.it',
        'l2a.test@cdm86.it', 'l2b.test@cdm86.it',
        'l3a.test@cdm86.it', 'l3b.test@cdm86.it'
    );
    DELETE FROM auth.users WHERE email IN (
        'collab.test@cdm86.it',
        'l1a.test@cdm86.it', 'l1b.test@cdm86.it',
        'l2a.test@cdm86.it', 'l2b.test@cdm86.it',
        'l3a.test@cdm86.it', 'l3b.test@cdm86.it'
    );

    v_pw          := crypt('Test1234', gen_salt('bf'));
    v_auth_collab := gen_random_uuid();

    -- ── Crea auth user per il collaboratore ──
    INSERT INTO auth.users (
        id, instance_id, aud, role,
        email, encrypted_password,
        email_confirmed_at, confirmation_sent_at,
        raw_user_meta_data, raw_app_meta_data,
        created_at, updated_at,
        is_super_admin, is_sso_user, deleted_at
    ) VALUES (
        v_auth_collab,
        '00000000-0000-0000-0000-000000000000',
        'authenticated', 'authenticated',
        'collab.test@cdm86.it', v_pw,
        NOW(), NOW(),
        '{"account_type":"collaborator","first_name":"Carlo","last_name":"Collaboratore"}'::jsonb,
        '{"provider":"email","providers":["email"]}'::jsonb,
        NOW(), NOW(),
        false, false, null
    );

    -- ── public.users per il collaboratore ──
    INSERT INTO public.users (auth_user_id, email, first_name, last_name, referral_code, points, referred_by_id)
    VALUES (v_auth_collab, 'collab.test@cdm86.it', 'Carlo', 'Collaboratore', 'COLLABT1', 0, v_admin_id)
    RETURNING id INTO v_user_collab;

    -- ── L1: referenziati dal collaboratore ──
    INSERT INTO public.users (auth_user_id, email, first_name, last_name, referral_code, points, referred_by_id)
    VALUES (gen_random_uuid(), 'l1a.test@cdm86.it', 'Luigi', 'L1A', 'L1ATST01', 0, v_user_collab)
    RETURNING id INTO v_user_l1a;

    INSERT INTO public.users (auth_user_id, email, first_name, last_name, referral_code, points, referred_by_id)
    VALUES (gen_random_uuid(), 'l1b.test@cdm86.it', 'Maria', 'L1B', 'L1BTST01', 0, v_user_collab)
    RETURNING id INTO v_user_l1b;

    -- ── L2: referenziati dagli L1 ──
    INSERT INTO public.users (auth_user_id, email, first_name, last_name, referral_code, points, referred_by_id)
    VALUES (gen_random_uuid(), 'l2a.test@cdm86.it', 'Paolo', 'L2A', 'L2ATST01', 0, v_user_l1a)
    RETURNING id INTO v_user_l2a;

    INSERT INTO public.users (auth_user_id, email, first_name, last_name, referral_code, points, referred_by_id)
    VALUES (gen_random_uuid(), 'l2b.test@cdm86.it', 'Sara', 'L2B', 'L2BTST01', 0, v_user_l1b)
    RETURNING id INTO v_user_l2b;

    -- ── L3: referenziati dagli L2 (QUESTI VERRANNO RIASSEGNATI) ──
    INSERT INTO public.users (auth_user_id, email, first_name, last_name, referral_code, points, referred_by_id)
    VALUES (gen_random_uuid(), 'l3a.test@cdm86.it', 'Marco', 'L3A', 'L3ATST01', 0, v_user_l2a)
    RETURNING id INTO v_user_l3a;

    INSERT INTO public.users (auth_user_id, email, first_name, last_name, referral_code, points, referred_by_id)
    VALUES (gen_random_uuid(), 'l3b.test@cdm86.it', 'Elena', 'L3B', 'L3BTST01', 0, v_user_l2b)
    RETURNING id INTO v_user_l3b;

    -- ── Record collaboratore ──
    INSERT INTO public.collaborators (
        auth_user_id, user_id, email, first_name, last_name,
        referral_code, status, approved_at, referred_by_id
    )
    VALUES (
        v_auth_collab, v_user_collab,
        'collab.test@cdm86.it', 'Carlo', 'Collaboratore',
        'COLLABT1', 'active', NOW(), v_admin_id
    )
    RETURNING id INTO v_collab_id;

    RAISE NOTICE '════════════════════════════════════════';
    RAISE NOTICE '✅ TUTTO CREATO CON SUCCESSO';
    RAISE NOTICE '════════════════════════════════════════';
    RAISE NOTICE 'Auth UUID collab : %', v_auth_collab;
    RAISE NOTICE 'Collaborator ID  : %', v_collab_id;
    RAISE NOTICE 'User collab ID   : %', v_user_collab;
    RAISE NOTICE 'L3A (verrà riassegnato): %', v_user_l3a;
    RAISE NOTICE 'L3B (verrà riassegnato): %', v_user_l3b;
    RAISE NOTICE 'Login: collab.test@cdm86.it / Test1234';
    RAISE NOTICE '════════════════════════════════════════';
END $$;

-- Verifica visiva struttura MLM creata
SELECT
    u.email,
    u.first_name || ' ' || u.last_name AS nome,
    ref.email AS referral_di,
    CASE
        WHEN u.email = 'collab.test@cdm86.it'                                        THEN '👤 COLLABORATORE'
        WHEN ref.email = 'collab.test@cdm86.it'                                      THEN '  └─ L1 ✅ mantieni'
        WHEN ref.email IN ('l1a.test@cdm86.it','l1b.test@cdm86.it')                 THEN '     └─ L2 ✅ mantieni'
        WHEN ref.email IN ('l2a.test@cdm86.it','l2b.test@cdm86.it')                 THEN '        └─ L3 ⚠️ riassegnato'
        ELSE '?'
    END AS livello_mlm
FROM public.users u
LEFT JOIN public.users ref ON ref.id = u.referred_by_id
WHERE u.email IN (
    'collab.test@cdm86.it',
    'l1a.test@cdm86.it','l1b.test@cdm86.it',
    'l2a.test@cdm86.it','l2b.test@cdm86.it',
    'l3a.test@cdm86.it','l3b.test@cdm86.it'
)
ORDER BY u.created_at;


    v_user_collab UUID;
    v_user_l1a    UUID;
    v_user_l1b    UUID;
    v_user_l2a    UUID;
    v_user_l2b    UUID;
    v_user_l3a    UUID;
    v_user_l3b    UUID;
    v_collab_id   UUID;
BEGIN
    -- Pulizia preventiva
    DELETE FROM public.collaborators WHERE email = 'collab.test@cdm86.it';
    DELETE FROM public.users WHERE email IN (
        'collab.test@cdm86.it',
        'l1a.test@cdm86.it', 'l1b.test@cdm86.it',
        'l2a.test@cdm86.it', 'l2b.test@cdm86.it',
        'l3a.test@cdm86.it', 'l3b.test@cdm86.it'
    );

    -- Inserisci il collaboratore in public.users
    INSERT INTO public.users (auth_user_id, email, first_name, last_name, referral_code, points, referred_by_id)
    VALUES (v_auth_collab, 'collab.test@cdm86.it', 'Carlo', 'Collaboratore', 'COLLABT1', 0, v_admin_id)
    RETURNING id INTO v_user_collab;

    -- L1
    INSERT INTO public.users (auth_user_id, email, first_name, last_name, referral_code, points, referred_by_id)
    VALUES (gen_random_uuid(), 'l1a.test@cdm86.it', 'Luigi', 'L1A', 'L1ATST01', 0, v_user_collab)
    RETURNING id INTO v_user_l1a;

    INSERT INTO public.users (auth_user_id, email, first_name, last_name, referral_code, points, referred_by_id)
    VALUES (gen_random_uuid(), 'l1b.test@cdm86.it', 'Maria', 'L1B', 'L1BTST01', 0, v_user_collab)
    RETURNING id INTO v_user_l1b;

    -- L2
    INSERT INTO public.users (auth_user_id, email, first_name, last_name, referral_code, points, referred_by_id)
    VALUES (gen_random_uuid(), 'l2a.test@cdm86.it', 'Paolo', 'L2A', 'L2ATST01', 0, v_user_l1a)
    RETURNING id INTO v_user_l2a;

    INSERT INTO public.users (auth_user_id, email, first_name, last_name, referral_code, points, referred_by_id)
    VALUES (gen_random_uuid(), 'l2b.test@cdm86.it', 'Sara', 'L2B', 'L2BTST01', 0, v_user_l1b)
    RETURNING id INTO v_user_l2b;

    -- L3 (questi verranno riassegnati)
    INSERT INTO public.users (auth_user_id, email, first_name, last_name, referral_code, points, referred_by_id)
    VALUES (gen_random_uuid(), 'l3a.test@cdm86.it', 'Marco', 'L3A', 'L3ATST01', 0, v_user_l2a)
    RETURNING id INTO v_user_l3a;

    INSERT INTO public.users (auth_user_id, email, first_name, last_name, referral_code, points, referred_by_id)
    VALUES (gen_random_uuid(), 'l3b.test@cdm86.it', 'Elena', 'L3B', 'L3BTST01', 0, v_user_l2b)
    RETURNING id INTO v_user_l3b;

    -- Crea il collaboratore
    INSERT INTO public.collaborators (
        auth_user_id, user_id, email, first_name, last_name,
        referral_code, status, approved_at, referred_by_id
    )
    VALUES (
        v_auth_collab, v_user_collab,
        'collab.test@cdm86.it', 'Carlo', 'Collaboratore',
        'COLLABT1', 'active', NOW(), v_admin_id
    )
    RETURNING id INTO v_collab_id;

    RAISE NOTICE '✅ CREATO - collaborator id: %', v_collab_id;
    RAISE NOTICE '✅ user_collab id: %', v_user_collab;
    RAISE NOTICE '✅ L1A: %, L1B: %', v_user_l1a, v_user_l1b;
    RAISE NOTICE '✅ L2A: %, L2B: %', v_user_l2a, v_user_l2b;
    RAISE NOTICE '✅ L3A: %, L3B: %  ← QUESTI VERRANNO RIASSEGNATI', v_user_l3a, v_user_l3b;
END $$;

-- Verifica struttura creata
SELECT
    u.email,
    u.first_name || ' ' || u.last_name AS nome,
    ref.email AS referral_di,
    CASE
        WHEN u.email = 'collab.test@cdm86.it' THEN '👤 COLLABORATORE'
        WHEN ref.email = 'collab.test@cdm86.it' THEN '→ L1 (diretto del collab)'
        WHEN ref.email IN ('l1a.test@cdm86.it','l1b.test@cdm86.it') THEN '→→ L2'
        WHEN ref.email IN ('l2a.test@cdm86.it','l2b.test@cdm86.it') THEN '→→→ L3 ⚠️ verrà riassegnato'
        ELSE '?'
    END AS livello
FROM public.users u
LEFT JOIN public.users ref ON ref.id = u.referred_by_id
WHERE u.email IN (
    'collab.test@cdm86.it',
    'l1a.test@cdm86.it','l1b.test@cdm86.it',
    'l2a.test@cdm86.it','l2b.test@cdm86.it',
    'l3a.test@cdm86.it','l3b.test@cdm86.it'
)
ORDER BY u.created_at;
