-- ═══════════════════════════════════════════════════════════════════
-- TEST: Abbandona Ruolo Collaboratore
-- ═══════════════════════════════════════════════════════════════════
-- Struttura test:
--   ADMIN (esiste già: e8cde03d-2aa6-4ea6-a29f-43f290ae00ce)
--     └── COLLAB_TEST (il collaboratore che abbandonerà il ruolo)
--           ├── L1_A  (invitato direttamente da COLLAB → MANTIENI)
--           │     └── L2_A (invitato da L1_A → MANTIENI)
--           │           └── L3_A (invitato da L2_A → RIASSEGNA al ref admin)
--           └── L1_B  (invitato direttamente da COLLAB → MANTIENI)
--                 └── L2_B (invitato da L1_B → MANTIENI)
--                       └── L3_B (invitato da L2_B → RIASSEGNA al ref admin)
-- ═══════════════════════════════════════════════════════════════════

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- PASSO 0: Pulisci eventuali dati di test precedenti
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DELETE FROM public.collaborators WHERE email = 'collab.test@cdm86.it';

DELETE FROM public.users WHERE email IN (
    'collab.test@cdm86.it',
    'l1a.test@cdm86.it',
    'l1b.test@cdm86.it',
    'l2a.test@cdm86.it',
    'l2b.test@cdm86.it',
    'l3a.test@cdm86.it',
    'l3b.test@cdm86.it'
);

DELETE FROM auth.users WHERE email IN (
    'collab.test@cdm86.it',
    'l1a.test@cdm86.it',
    'l1b.test@cdm86.it',
    'l2a.test@cdm86.it',
    'l2b.test@cdm86.it',
    'l3a.test@cdm86.it',
    'l3b.test@cdm86.it'
);

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- PASSO 1: Crea utenti auth per il collaboratore e tutta la rete
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DO $$
DECLARE
    v_admin_id          UUID := 'e8cde03d-2aa6-4ea6-a29f-43f290ae00ce';

    -- Auth IDs (fissi per il test)
    v_auth_collab       UUID := 'aa000001-0000-0000-0000-000000000001';
    v_auth_l1a          UUID := 'aa000001-0000-0000-0000-000000000002';
    v_auth_l1b          UUID := 'aa000001-0000-0000-0000-000000000003';
    v_auth_l2a          UUID := 'aa000001-0000-0000-0000-000000000004';
    v_auth_l2b          UUID := 'aa000001-0000-0000-0000-000000000005';
    v_auth_l3a          UUID := 'aa000001-0000-0000-0000-000000000006';
    v_auth_l3b          UUID := 'aa000001-0000-0000-0000-000000000007';

    -- Public users IDs
    v_user_collab       UUID;
    v_user_l1a          UUID;
    v_user_l1b          UUID;
    v_user_l2a          UUID;
    v_user_l2b          UUID;
    v_user_l3a          UUID;
    v_user_l3b          UUID;

    -- Collab ID
    v_collab_id         UUID;

    -- Password test (uguale per tutti: "Test1234")
    v_pw TEXT := crypt('Test1234', gen_salt('bf'));
BEGIN

    -- ── Crea utenti in auth.users ──────────────────────────────────
    INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, raw_user_meta_data, created_at, updated_at)
    VALUES
        (v_auth_collab, 'collab.test@cdm86.it', v_pw, NOW(), '{"account_type":"collaborator","first_name":"Carlo","last_name":"Collaboratore"}'::jsonb, NOW(), NOW()),
        (v_auth_l1a,    'l1a.test@cdm86.it',    v_pw, NOW(), '{"account_type":"user","first_name":"Luigi","last_name":"L1A"}'::jsonb,          NOW(), NOW()),
        (v_auth_l1b,    'l1b.test@cdm86.it',    v_pw, NOW(), '{"account_type":"user","first_name":"Maria","last_name":"L1B"}'::jsonb,          NOW(), NOW()),
        (v_auth_l2a,    'l2a.test@cdm86.it',    v_pw, NOW(), '{"account_type":"user","first_name":"Paolo","last_name":"L2A"}'::jsonb,          NOW(), NOW()),
        (v_auth_l2b,    'l2b.test@cdm86.it',    v_pw, NOW(), '{"account_type":"user","first_name":"Sara","last_name":"L2B"}'::jsonb,           NOW(), NOW()),
        (v_auth_l3a,    'l3a.test@cdm86.it',    v_pw, NOW(), '{"account_type":"user","first_name":"Marco","last_name":"L3A"}'::jsonb,          NOW(), NOW()),
        (v_auth_l3b,    'l3b.test@cdm86.it',    v_pw, NOW(), '{"account_type":"user","first_name":"Elena","last_name":"L3B"}'::jsonb,          NOW(), NOW())
    ON CONFLICT (id) DO NOTHING;

    -- ── Crea record in public.users per la rete MLM ───────────────
    -- Il collaboratore viene inserito senza referred_by_id (o con quello dell'admin)
    INSERT INTO public.users (auth_user_id, email, first_name, last_name, referral_code, points, referred_by_id)
    VALUES (v_auth_collab, 'collab.test@cdm86.it', 'Carlo', 'Collaboratore', 'COLLABT1', 0, v_admin_id)
    RETURNING id INTO v_user_collab;

    -- L1: referenziati direttamente dal collaboratore
    INSERT INTO public.users (auth_user_id, email, first_name, last_name, referral_code, points, referred_by_id)
    VALUES (v_auth_l1a, 'l1a.test@cdm86.it', 'Luigi', 'L1A', 'L1ATST01', 0, v_user_collab)
    RETURNING id INTO v_user_l1a;

    INSERT INTO public.users (auth_user_id, email, first_name, last_name, referral_code, points, referred_by_id)
    VALUES (v_auth_l1b, 'l1b.test@cdm86.it', 'Maria', 'L1B', 'L1BTST01', 0, v_user_collab)
    RETURNING id INTO v_user_l1b;

    -- L2: referenziati dagli L1
    INSERT INTO public.users (auth_user_id, email, first_name, last_name, referral_code, points, referred_by_id)
    VALUES (v_auth_l2a, 'l2a.test@cdm86.it', 'Paolo', 'L2A', 'L2ATST01', 0, v_user_l1a)
    RETURNING id INTO v_user_l2a;

    INSERT INTO public.users (auth_user_id, email, first_name, last_name, referral_code, points, referred_by_id)
    VALUES (v_auth_l2b, 'l2b.test@cdm86.it', 'Sara', 'L2B', 'L2BTST01', 0, v_user_l1b)
    RETURNING id INTO v_user_l2b;

    -- L3: referenziati dagli L2 (questi dovranno essere riassegnati)
    INSERT INTO public.users (auth_user_id, email, first_name, last_name, referral_code, points, referred_by_id)
    VALUES (v_auth_l3a, 'l3a.test@cdm86.it', 'Marco', 'L3A', 'L3ATST01', 0, v_user_l2a)
    RETURNING id INTO v_user_l3a;

    INSERT INTO public.users (auth_user_id, email, first_name, last_name, referral_code, points, referred_by_id)
    VALUES (v_auth_l3b, 'l3b.test@cdm86.it', 'Elena', 'L3B', 'L3BTST01', 0, v_user_l2b)
    RETURNING id INTO v_user_l3b;

    -- ── Crea il record collaboratore ───────────────────────────────
    INSERT INTO public.collaborators (
        auth_user_id,
        user_id,
        email,
        first_name,
        last_name,
        referral_code,
        status,
        approved_at,
        referred_by_id
    )
    VALUES (
        v_auth_collab,
        v_user_collab,
        'collab.test@cdm86.it',
        'Carlo',
        'Collaboratore',
        'COLLABT1',
        'active',
        NOW(),
        v_admin_id   -- Il collaboratore è stato invitato dall'admin
    )
    RETURNING id INTO v_collab_id;

    RAISE NOTICE '════════════════════════════════════════════════';
    RAISE NOTICE 'TEST DATA CREATA CON SUCCESSO';
    RAISE NOTICE '════════════════════════════════════════════════';
    RAISE NOTICE 'Collaboratore ID (collaborators): %', v_collab_id;
    RAISE NOTICE 'Collaboratore user ID (users):    %', v_user_collab;
    RAISE NOTICE 'Auth ID collaboratore:            %', v_auth_collab;
    RAISE NOTICE '────────────────────────────────────────────────';
    RAISE NOTICE 'L1A user_id: % (referred_by: %)', v_user_l1a, v_user_collab;
    RAISE NOTICE 'L1B user_id: % (referred_by: %)', v_user_l1b, v_user_collab;
    RAISE NOTICE 'L2A user_id: % (referred_by: %)', v_user_l2a, v_user_l1a;
    RAISE NOTICE 'L2B user_id: % (referred_by: %)', v_user_l2b, v_user_l1b;
    RAISE NOTICE 'L3A user_id: % (referred_by: %)', v_user_l3a, v_user_l2a;
    RAISE NOTICE 'L3B user_id: % (referred_by: %)', v_user_l3b, v_user_l2b;
    RAISE NOTICE '════════════════════════════════════════════════';
    RAISE NOTICE 'Credenziali login test per TUTTI: password = Test1234';
    RAISE NOTICE 'Email collaboratore: collab.test@cdm86.it';
    RAISE NOTICE '════════════════════════════════════════════════';

END $$;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- PASSO 2: Verifica la struttura PRIMA dell'abbandono
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SELECT
    '=== STATO PRIMA ABBANDONO ===' AS info,
    u.email,
    u.first_name || ' ' || u.last_name AS nome,
    u.referred_by_id,
    ref.email AS referral_di,
    CASE
        WHEN u.referred_by_id IS NULL THEN 'ROOT'
        WHEN u.referred_by_id = (SELECT id FROM public.users WHERE email='collab.test@cdm86.it') THEN 'L1 del collaboratore'
        WHEN u.referred_by_id IN (SELECT id FROM public.users WHERE email IN ('l1a.test@cdm86.it','l1b.test@cdm86.it')) THEN 'L2 del collaboratore'
        WHEN u.referred_by_id IN (SELECT id FROM public.users WHERE email IN ('l2a.test@cdm86.it','l2b.test@cdm86.it')) THEN 'L3 del collaboratore ← VERRÀ RIASSEGNATO'
        ELSE 'altro'
    END AS livello_mlm
FROM public.users u
LEFT JOIN public.users ref ON ref.id = u.referred_by_id
WHERE u.email IN (
    'collab.test@cdm86.it',
    'l1a.test@cdm86.it', 'l1b.test@cdm86.it',
    'l2a.test@cdm86.it', 'l2b.test@cdm86.it',
    'l3a.test@cdm86.it', 'l3b.test@cdm86.it'
)
ORDER BY u.created_at;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ISTRUZIONI PASSO 3 (da fare manualmente)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 1. Apri il pannello admin → sezione Collaboratori
-- 2. Cerca "Carlo Collaboratore" con email collab.test@cdm86.it
-- 3. Clicca "🚪 Abbandona Ruolo" e conferma
-- 4. Annota la password generata mostrata nel modal
-- 5. Esegui la query PASSO 4 qui sotto per verificare il risultato
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- PASSO 4: Verifica DOPO l'abbandono (esegui dopo aver cliccato il pulsante)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SELECT
    '=== STATO DOPO ABBANDONO ===' AS info,
    u.email,
    u.first_name || ' ' || u.last_name AS nome,
    ref.email AS referral_di,
    CASE
        WHEN u.referred_by_id IS NULL THEN '⚠️ nessun referral'
        WHEN ref.email = 'collab.test@cdm86.it' THEN '✅ L1 mantenuto (referral = collaboratore)'
        WHEN ref.email IN ('l1a.test@cdm86.it','l1b.test@cdm86.it') THEN '✅ L2 mantenuto (referral = L1)'
        ELSE '🔄 Riassegnato → referral di: ' || ref.email
    END AS esito
FROM public.users u
LEFT JOIN public.users ref ON ref.id = u.referred_by_id
WHERE u.email IN (
    'collab.test@cdm86.it',
    'l1a.test@cdm86.it', 'l1b.test@cdm86.it',
    'l2a.test@cdm86.it', 'l2b.test@cdm86.it',
    'l3a.test@cdm86.it', 'l3b.test@cdm86.it'
)
ORDER BY u.created_at;

-- Verifica che il collaboratore NON esista più nella tabella collaborators
SELECT
    CASE
        WHEN COUNT(*) = 0 THEN '✅ OK: collaboratore rimosso da collaborators'
        ELSE '❌ ERRORE: collaboratore ancora presente in collaborators'
    END AS check_collaborators
FROM public.collaborators
WHERE email = 'collab.test@cdm86.it';

-- Verifica che L3 sia stato riassegnato al referral admin
SELECT
    u.email,
    ref.email AS nuovo_referral,
    CASE
        WHEN ref.email != 'l2a.test@cdm86.it' AND ref.email != 'l2b.test@cdm86.it'
        THEN '✅ L3 riassegnato correttamente'
        ELSE '❌ L3 ancora punta all L2 originale'
    END AS esito_l3
FROM public.users u
LEFT JOIN public.users ref ON ref.id = u.referred_by_id
WHERE u.email IN ('l3a.test@cdm86.it', 'l3b.test@cdm86.it');


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- PASSO 5 (opzionale): Pulizia dati di test
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Decommentare e eseguire dopo il test per eliminare tutti i dati creati
/*
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
SELECT 'Dati test eliminati' AS status;
*/
