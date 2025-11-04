-- =====================================================
-- DEBUG: Verifica perché giovanni non è in public.users
-- =====================================================

-- 1. Verifica che giovanni esista in auth.users
SELECT 
    id,
    email,
    created_at,
    email_confirmed_at,
    raw_user_meta_data
FROM auth.users
WHERE email = 'giovanni@cdm86.com';

-- 2. Verifica che NON esista in public.users
SELECT 
    id,
    email,
    first_name,
    last_name
FROM users
WHERE email = 'giovanni@cdm86.com';

-- 3. Verifica che il trigger esista e sia attivo
SELECT 
    tgname as trigger_name,
    tgenabled as enabled,
    pg_get_triggerdef(oid) as definition
FROM pg_trigger
WHERE tgname = 'on_auth_user_created';

-- 4. Verifica che la funzione generate_referral_code() esista
SELECT 
    proname as function_name,
    pg_get_functiondef(oid) as definition
FROM pg_proc
WHERE proname = 'generate_referral_code';

-- 5. Test manuale: Prova a creare giovanni in public.users
-- (Questo simula quello che dovrebbe fare il trigger)
DO $$
DECLARE
    v_user_id UUID;
    v_email TEXT;
    v_first_name TEXT;
    v_last_name TEXT;
    v_referral_code_used TEXT;
    v_new_referral_code VARCHAR(8);
    v_referrer_user_id UUID;
BEGIN
    -- Prendi i dati da auth.users
    SELECT 
        id,
        email,
        raw_user_meta_data->>'first_name',
        raw_user_meta_data->>'last_name',
        raw_user_meta_data->>'referral_code_used'
    INTO 
        v_user_id,
        v_email,
        v_first_name,
        v_last_name,
        v_referral_code_used
    FROM auth.users
    WHERE email = 'giovanni@cdm86.com';

    RAISE NOTICE '📧 Email: %', v_email;
    RAISE NOTICE '👤 First Name: %', v_first_name;
    RAISE NOTICE '👤 Last Name: %', v_last_name;
    RAISE NOTICE '🎫 Referral Code Used: %', v_referral_code_used;

    -- Trova il referrer
    IF v_referral_code_used IS NOT NULL AND v_referral_code_used != '' THEN
        SELECT id INTO v_referrer_user_id
        FROM users
        WHERE referral_code = v_referral_code_used
        LIMIT 1;
        
        RAISE NOTICE '🔍 Referrer ID trovato: %', v_referrer_user_id;
    ELSE
        RAISE NOTICE '⚠️ Nessun referral code usato';
    END IF;

    -- Genera nuovo referral code
    v_new_referral_code := UPPER(SUBSTRING(MD5(RANDOM()::TEXT), 1, 8));
    RAISE NOTICE '🎯 Nuovo referral code generato: %', v_new_referral_code;

    -- Prova a inserire
    INSERT INTO users (
        id,
        email,
        password_hash,
        first_name,
        last_name,
        referral_code,
        referred_by_id,
        role,
        is_verified,
        is_active,
        points
    ) VALUES (
        v_user_id,
        v_email,
        'auth_managed',
        COALESCE(v_first_name, 'Giovanni'),
        COALESCE(v_last_name, 'Unknown'),
        v_new_referral_code,
        v_referrer_user_id,
        'user',
        false,
        true,
        100
    );

    RAISE NOTICE '✅ Utente inserito con successo!';

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING '❌ ERRORE: %', SQLERRM;
        RAISE WARNING '📝 DETAIL: %', SQLSTATE;
END $$;

-- 6. Verifica che ora giovanni esista in public.users
SELECT 
    u.id,
    u.email,
    u.first_name,
    u.last_name,
    u.referral_code,
    u.referred_by_id,
    r.email as referrer_email,
    r.referral_code as referrer_code
FROM users u
LEFT JOIN users r ON u.referred_by_id = r.id
WHERE u.email = 'giovanni@cdm86.com';
