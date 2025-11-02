-- =====================================================
-- SCRIPT DI CONTROLLO REFERRAL 06ac519c
-- =====================================================

-- 1. Trova l'utente proprietario del codice referral
SELECT 
    id,
    first_name,
    last_name,
    email,
    referral_code,
    created_at
FROM users 
WHERE referral_code = '06ac519c';

-- 2. Trova gli utenti che hanno usato questo codice
SELECT 
    u.id,
    u.first_name,
    u.last_name,
    u.email,
    u.referred_by_id,
    u.referred_by_code,
    u.created_at,
    CASE 
        WHEN u.referred_by_code = '06ac519c' THEN '✅ Ha usato il codice'
        ELSE '❌ Non ha usato il codice'
    END as status
FROM users u
WHERE u.referred_by_code = '06ac519c';

-- 3. Controlla i punti dell'utente con referral code 06ac519c
SELECT 
    up.user_id,
    up.points_total,
    up.points_used,
    up.points_available,
    up.referrals_count,
    up.approved_reports_count,
    up.level,
    up.created_at
FROM user_points up
JOIN users u ON up.user_id = u.id
WHERE u.referral_code = '06ac519c';

-- 4. Controlla le transazioni di punti per questo utente
SELECT 
    pt.*
FROM points_transactions pt
JOIN users u ON pt.user_id = u.id
WHERE u.referral_code = '06ac519c'
ORDER BY pt.created_at DESC;

-- 5. Controlla se esistono referrals nella tabella referrals
SELECT 
    r.*
FROM referrals r
JOIN users u ON r.referrer_id = u.id
WHERE u.referral_code = '06ac519c';

-- =====================================================
-- SE NON CI SONO PUNTI, ESEGUI QUESTO FIX MANUALE
-- =====================================================

-- PASSO 1: Trova l'ID del referrer
DO $$
DECLARE
    v_referrer_id UUID;
    v_referred_user_id UUID;
    v_referred_user_name TEXT;
BEGIN
    -- Trova il referrer
    SELECT id INTO v_referrer_id 
    FROM users 
    WHERE referral_code = '06ac519c';
    
    IF v_referrer_id IS NULL THEN
        RAISE NOTICE 'Nessun utente trovato con referral code 06ac519c';
        RETURN;
    END IF;
    
    RAISE NOTICE 'Referrer ID: %', v_referrer_id;
    
    -- Trova l'utente che ha usato questo codice
    SELECT id, first_name || ' ' || last_name 
    INTO v_referred_user_id, v_referred_user_name
    FROM users 
    WHERE referred_by_code = '06ac519c'
    LIMIT 1;
    
    IF v_referred_user_id IS NULL THEN
        RAISE NOTICE 'Nessun utente ha ancora usato questo codice referral';
        RETURN;
    END IF;
    
    RAISE NOTICE 'Utente referito: % (ID: %)', v_referred_user_name, v_referred_user_id;
    
    -- Controlla se i punti sono già stati assegnati
    IF EXISTS (
        SELECT 1 FROM points_transactions 
        WHERE user_id = v_referrer_id 
        AND transaction_type = 'referral_completed'
        AND reference_id = v_referred_user_id
    ) THEN
        RAISE NOTICE '✅ Punti già assegnati per questo referral';
    ELSE
        RAISE NOTICE '❌ Punti NON ancora assegnati - ESEGUIRE IL FIX!';
        
        -- ASSEGNA I PUNTI MANUALMENTE
        PERFORM add_points_to_user(
            v_referrer_id,
            50,
            'referral_completed',
            v_referred_user_id,
            'Referral: ' || v_referred_user_name || ' (Fix manuale)'
        );
        
        -- Incrementa il contatore referrals
        UPDATE user_points
        SET referrals_count = referrals_count + 1
        WHERE user_id = v_referrer_id;
        
        RAISE NOTICE '✅ Punti assegnati con successo!';
    END IF;
END $$;

-- VERIFICA FINALE
SELECT 
    u.first_name,
    u.last_name,
    u.referral_code,
    up.points_total,
    up.points_available,
    up.referrals_count,
    (SELECT COUNT(*) FROM users WHERE referred_by_code = '06ac519c') as utenti_portati
FROM users u
LEFT JOIN user_points up ON u.id = up.user_id
WHERE u.referral_code = '06ac519c';
