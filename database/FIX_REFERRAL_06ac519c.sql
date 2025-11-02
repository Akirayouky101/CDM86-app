-- =====================================================
-- SCRIPT CORRETTO DI CONTROLLO REFERRAL 06ac519c
-- =====================================================
-- Nota: La tabella user_points usa points_total, NON total_points
-- =====================================================

-- 1. Trova l'utente proprietario del codice referral
SELECT 
    '1. PROPRIETARIO DEL CODICE REFERRAL' as step,
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
    '2. UTENTI CHE HANNO USATO IL CODICE' as step,
    u.id,
    u.first_name,
    u.last_name,
    u.email,
    u.referred_by_id,
    u.created_at
FROM users u
WHERE u.referred_by_id = (SELECT id FROM users WHERE referral_code = '06ac519c');

-- 3. Controlla i punti dell'utente con referral code 06ac519c
SELECT 
    '3. PUNTI DELL''UTENTE REFERRER' as step,
    u.first_name,
    u.last_name,
    up.points_total,
    up.points_used,
    up.points_available,
    up.referrals_count,
    up.approved_reports_count,
    up.level
FROM users u
LEFT JOIN user_points up ON u.id = up.user_id
WHERE u.referral_code = '06ac519c';

-- 4. Controlla le transazioni di punti per questo utente
SELECT 
    '4. TRANSAZIONI PUNTI' as step,
    pt.id,
    pt.points_awarded,
    pt.transaction_type,
    pt.description,
    pt.created_at
FROM users u
LEFT JOIN points_transactions pt ON u.id = pt.user_id
WHERE u.referral_code = '06ac519c'
ORDER BY pt.created_at DESC;

-- 5. Controlla se esistono referrals nella tabella referrals
SELECT 
    '5. REFERRALS NELLA TABELLA REFERRALS' as step,
    r.*
FROM users u
LEFT JOIN referrals r ON u.id = r.referrer_id
WHERE u.referral_code = '06ac519c';

-- =====================================================
-- DIAGNOSTICA COMPLETA
-- =====================================================
DO $$
DECLARE
    v_referrer RECORD;
    v_referred_count INTEGER;
    v_points_transactions_count INTEGER;
    v_current_points INTEGER;
BEGIN
    -- Trova il referrer
    SELECT u.*, up.points_total, up.referrals_count
    INTO v_referrer
    FROM users u
    LEFT JOIN user_points up ON u.id = up.user_id
    WHERE u.referral_code = '06ac519c';
    
    IF NOT FOUND THEN
        RAISE NOTICE '❌ Nessun utente trovato con referral code 06ac519c';
        RETURN;
    END IF;
    
    RAISE NOTICE '✅ Utente trovato: % % (ID: %)', v_referrer.first_name, v_referrer.last_name, v_referrer.id;
    
    -- Conta gli utenti referiti
    SELECT COUNT(*) INTO v_referred_count
    FROM users
    WHERE referred_by_id = v_referrer.id;
    
    RAISE NOTICE '📊 Utenti che hanno usato il codice: %', v_referred_count;
    
    -- Conta le transazioni di punti per referral
    SELECT COUNT(*) INTO v_points_transactions_count
    FROM points_transactions
    WHERE user_id = v_referrer.id 
    AND transaction_type = 'referral_completed';
    
    RAISE NOTICE '💰 Transazioni "referral_completed": %', v_points_transactions_count;
    RAISE NOTICE '📈 Punti attuali: %', COALESCE(v_referrer.points_total, 0);
    RAISE NOTICE '🎯 Contatore referrals: %', COALESCE(v_referrer.referrals_count, 0);
    
    -- Diagnostica
    IF v_referred_count > 0 AND v_points_transactions_count = 0 THEN
        RAISE NOTICE '';
        RAISE NOTICE '⚠️  PROBLEMA IDENTIFICATO:';
        RAISE NOTICE '   Ci sono % utenti referiti ma nessuna transazione!', v_referred_count;
        RAISE NOTICE '   Il trigger non si è attivato o gli utenti non hanno referred_by_id';
        RAISE NOTICE '';
        RAISE NOTICE '💡 ESEGUIRE IL FIX MANUALE PIÙ SOTTO';
    ELSIF v_referred_count > v_points_transactions_count THEN
        RAISE NOTICE '';
        RAISE NOTICE '⚠️  DISCREPANZA:';
        RAISE NOTICE '   Utenti referiti: %', v_referred_count;
        RAISE NOTICE '   Transazioni registrate: %', v_points_transactions_count;
        RAISE NOTICE '   Mancano % transazioni', v_referred_count - v_points_transactions_count;
    ELSIF v_referred_count = 0 THEN
        RAISE NOTICE '';
        RAISE NOTICE 'ℹ️  Nessun utente ha ancora usato questo codice referral';
    ELSE
        RAISE NOTICE '';
        RAISE NOTICE '✅ Tutto OK! Sistema funzionante correttamente';
    END IF;
END $$;

-- =====================================================
-- FIX MANUALE: ASSEGNA PUNTI PER REFERRAL MANCANTI
-- =====================================================
-- Eseguire SOLO se la diagnostica sopra mostra problemi
-- =====================================================

DO $$
DECLARE
    v_referrer_id UUID;
    v_referred_user RECORD;
    v_fixed_count INTEGER := 0;
BEGIN
    -- Trova il referrer
    SELECT id INTO v_referrer_id 
    FROM users 
    WHERE referral_code = '06ac519c';
    
    IF v_referrer_id IS NULL THEN
        RAISE NOTICE '❌ Utente non trovato';
        RETURN;
    END IF;
    
    RAISE NOTICE '🔧 Inizio fix per referral code 06ac519c...';
    RAISE NOTICE '';
    
    -- Per ogni utente che ha usato questo codice
    FOR v_referred_user IN 
        SELECT id, first_name, last_name, email, created_at
        FROM users 
        WHERE referred_by_id = v_referrer_id
        ORDER BY created_at
    LOOP
        -- Controlla se i punti sono già stati assegnati
        IF NOT EXISTS (
            SELECT 1 FROM points_transactions 
            WHERE user_id = v_referrer_id 
            AND transaction_type = 'referral_completed'
            AND reference_id = v_referred_user.id
        ) THEN
            -- Assegna i punti (50 punti per referral)
            PERFORM add_points_to_user(
                v_referrer_id,
                50,
                'referral_completed',
                v_referred_user.id,
                'Referral: ' || v_referred_user.first_name || ' ' || v_referred_user.last_name || ' (Fix manuale)'
            );
            
            -- Incrementa il contatore
            UPDATE user_points
            SET referrals_count = referrals_count + 1
            WHERE user_id = v_referrer_id;
            
            v_fixed_count := v_fixed_count + 1;
            
            RAISE NOTICE '✅ Punti assegnati per: % % (%)', 
                v_referred_user.first_name, 
                v_referred_user.last_name,
                v_referred_user.email;
        ELSE
            RAISE NOTICE '⏭️  Già processato: % %', 
                v_referred_user.first_name, 
                v_referred_user.last_name;
        END IF;
    END LOOP;
    
    IF v_fixed_count > 0 THEN
        RAISE NOTICE '';
        RAISE NOTICE '✅ Fix completato! Assegnati punti per % referral', v_fixed_count;
    ELSE
        RAISE NOTICE '';
        RAISE NOTICE 'ℹ️  Nessun fix necessario';
    END IF;
END $$;

-- =====================================================
-- VERIFICA FINALE POST-FIX
-- =====================================================
SELECT 
    '✅ STATO FINALE' as step,
    u.first_name || ' ' || u.last_name as nome_completo,
    u.email,
    u.referral_code,
    COALESCE(up.points_total, 0) as punti_totali,
    COALESCE(up.points_available, 0) as punti_disponibili,
    COALESCE(up.referrals_count, 0) as contatore_referrals,
    (SELECT COUNT(*) FROM users WHERE referred_by_id = u.id) as utenti_referiti_reali,
    (SELECT COUNT(*) FROM points_transactions 
     WHERE user_id = u.id AND transaction_type = 'referral_completed') as transazioni_referral
FROM users u
LEFT JOIN user_points up ON u.id = up.user_id
WHERE u.referral_code = '06ac519c';
