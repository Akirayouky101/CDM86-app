-- =====================================================
-- INSERIMENTO UTENTI ADMIN
-- =====================================================
-- Crea 2 utenti admin con referral code
-- Password: Criogenia2025!?
-- =====================================================

-- IMPORTANTE: Prima crea gli utenti su Supabase Auth Dashboard
-- 1. Authentication → Users → Add User
-- 2. Email: diegomarruchi@outlook.it, Password: Criogenia2025!?
-- 3. Email: claudio.mura1967@gmail.com, Password: Criogenia2025!?
-- 4. Conferma email automaticamente
-- 5. Annota gli UUID generati
-- 6. Sostituisci gli UUID qui sotto

-- =====================================================
-- STEP 1: Inserisci nella tabella users
-- =====================================================

DO $$
DECLARE
    v_diego_id UUID;
    v_claudio_id UUID;
BEGIN
    -- Trova gli ID da auth.users (dopo che li hai creati manualmente)
    SELECT id INTO v_diego_id FROM auth.users WHERE email = 'diegomarruchi@outlook.it';
    SELECT id INTO v_claudio_id FROM auth.users WHERE email = 'claudio.mura1967@gmail.com';
    
    IF v_diego_id IS NULL THEN
        RAISE EXCEPTION 'Utente diegomarruchi@outlook.it non trovato in auth.users! Crealo prima manualmente.';
    END IF;
    
    IF v_claudio_id IS NULL THEN
        RAISE EXCEPTION 'Utente claudio.mura1967@gmail.com non trovato in auth.users! Crealo prima manualmente.';
    END IF;
    
    RAISE NOTICE 'Diego ID: %', v_diego_id;
    RAISE NOTICE 'Claudio ID: %', v_claudio_id;
    
    -- Inserisci Diego nella tabella users
    INSERT INTO users (
        id,
        email,
        first_name,
        last_name,
        referral_code,
        created_at,
        updated_at
    ) VALUES (
        v_diego_id,
        'diegomarruchi@outlook.it',
        'Diego',
        'Marruchi',
        'ADMIN001',
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
        referral_code = 'ADMIN001',
        updated_at = NOW();
    
    RAISE NOTICE '✅ Diego inserito/aggiornato';
    
    -- Inserisci Claudio nella tabella users
    INSERT INTO users (
        id,
        email,
        first_name,
        last_name,
        referral_code,
        created_at,
        updated_at
    ) VALUES (
        v_claudio_id,
        'claudio.mura1967@gmail.com',
        'Claudio',
        'Mura',
        'ADMIN002',
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
        referral_code = 'ADMIN002',
        updated_at = NOW();
    
    RAISE NOTICE '✅ Claudio inserito/aggiornato';
    
    -- Crea record in user_points per entrambi
    INSERT INTO user_points (
        user_id,
        points_total,
        points_used,
        points_available,
        referrals_count,
        level
    ) VALUES (
        v_diego_id,
        0,
        0,
        0,
        0,
        1
    )
    ON CONFLICT (user_id) DO NOTHING;
    
    RAISE NOTICE '✅ User points Diego creato';
    
    INSERT INTO user_points (
        user_id,
        points_total,
        points_used,
        points_available,
        referrals_count,
        level
    ) VALUES (
        v_claudio_id,
        0,
        0,
        0,
        0,
        1
    )
    ON CONFLICT (user_id) DO NOTHING;
    
    RAISE NOTICE '✅ User points Claudio creato';
    
    RAISE NOTICE '';
    RAISE NOTICE '🎉 ADMIN USERS CREATI CON SUCCESSO!';
    RAISE NOTICE '';
    RAISE NOTICE 'Diego Marruchi:';
    RAISE NOTICE '  Email: diegomarruchi@outlook.it';
    RAISE NOTICE '  Referral Code: ADMIN001';
    RAISE NOTICE '  ID: %', v_diego_id;
    RAISE NOTICE '';
    RAISE NOTICE 'Claudio Mura:';
    RAISE NOTICE '  Email: claudio.mura1967@gmail.com';
    RAISE NOTICE '  Referral Code: ADMIN002';
    RAISE NOTICE '  ID: %', v_claudio_id;
    
END $$;

-- =====================================================
-- STEP 2: Verifica inserimento
-- =====================================================

SELECT 
    id,
    email,
    first_name,
    last_name,
    referral_code,
    is_admin,
    created_at
FROM users
WHERE email IN ('diegomarruchi@outlook.it', 'claudio.mura1967@gmail.com')
ORDER BY email;

-- =====================================================
-- STEP 3: Verifica user_points
-- =====================================================

SELECT 
    u.email,
    u.referral_code,
    up.points_total,
    up.points_available,
    up.referrals_count
FROM users u
LEFT JOIN user_points up ON u.id = up.user_id
WHERE u.email IN ('diegomarruchi@outlook.it', 'claudio.mura1967@gmail.com')
ORDER BY u.email;
