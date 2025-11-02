-- =====================================================
-- SCRIPT GENERICO: FIX REFERRAL SYSTEM
-- =====================================================
-- Trova e risolve problemi con il sistema referral
-- Cambia il valore nella prima riga per controllare altri codici
-- =====================================================

-- ⚙️ CONFIGURA IL CODICE REFERRAL DA CONTROLLARE QUI ⬇️
DO $$
DECLARE
    v_target_referral_code VARCHAR(10) := '06ac519c';  -- 👈 CAMBIA QUI
    v_referrer RECORD;
    v_referred_user RECORD;
    v_referred_count INTEGER;
    v_transactions_count INTEGER;
    v_fixed_count INTEGER := 0;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
    RAISE NOTICE '🔍 ANALISI REFERRAL CODE: %', v_target_referral_code;
    RAISE NOTICE '═══════════════════════════════════════════════════════';
    RAISE NOTICE '';
    
    -- ═══════════════════════════════════════════════════════
    -- STEP 1: Trova il proprietario del codice
    -- ═══════════════════════════════════════════════════════
    SELECT 
        u.id,
        u.first_name,
        u.last_name,
        u.email,
        u.referral_code,
        u.created_at,
        up.points_total,
        up.points_available,
        up.referrals_count
    INTO v_referrer
    FROM users u
    LEFT JOIN user_points up ON u.id = up.user_id
    WHERE u.referral_code = v_target_referral_code;
    
    IF NOT FOUND THEN
        RAISE NOTICE '❌ ERRORE: Nessun utente trovato con referral code "%"', v_target_referral_code;
        RAISE NOTICE '';
        RETURN;
    END IF;
    
    RAISE NOTICE '1️⃣ PROPRIETARIO DEL CODICE';
    RAISE NOTICE '   Nome: % %', v_referrer.first_name, v_referrer.last_name;
    RAISE NOTICE '   Email: %', v_referrer.email;
    RAISE NOTICE '   ID: %', v_referrer.id;
    RAISE NOTICE '   Registrato: %', v_referrer.created_at;
    RAISE NOTICE '';
    
    -- ═══════════════════════════════════════════════════════
    -- STEP 2: Conta gli utenti referiti
    -- ═══════════════════════════════════════════════════════
    SELECT COUNT(*) INTO v_referred_count
    FROM users
    WHERE referred_by_id = v_referrer.id;
    
    RAISE NOTICE '2️⃣ UTENTI REFERITI';
    RAISE NOTICE '   Totale: % utenti', v_referred_count;
    
    IF v_referred_count > 0 THEN
        RAISE NOTICE '   Lista:';
        FOR v_referred_user IN 
            SELECT first_name, last_name, email, created_at
            FROM users 
            WHERE referred_by_id = v_referrer.id
            ORDER BY created_at
        LOOP
            RAISE NOTICE '   - % % (%) - %', 
                v_referred_user.first_name,
                v_referred_user.last_name,
                v_referred_user.email,
                v_referred_user.created_at;
        END LOOP;
    END IF;
    RAISE NOTICE '';
    
    -- ═══════════════════════════════════════════════════════
    -- STEP 3: Controlla i punti
    -- ═══════════════════════════════════════════════════════
    SELECT COUNT(*) INTO v_transactions_count
    FROM points_transactions
    WHERE user_id = v_referrer.id 
    AND transaction_type = 'referral_completed';
    
    RAISE NOTICE '3️⃣ STATO PUNTI';
    RAISE NOTICE '   Punti totali: %', COALESCE(v_referrer.points_total, 0);
    RAISE NOTICE '   Punti disponibili: %', COALESCE(v_referrer.points_available, 0);
    RAISE NOTICE '   Contatore referrals: %', COALESCE(v_referrer.referrals_count, 0);
    RAISE NOTICE '   Transazioni "referral_completed": %', v_transactions_count;
    RAISE NOTICE '';
    
    -- ═══════════════════════════════════════════════════════
    -- STEP 4: Diagnostica
    -- ═══════════════════════════════════════════════════════
    RAISE NOTICE '4️⃣ DIAGNOSTICA';
    
    IF v_referred_count = 0 THEN
        RAISE NOTICE '   ℹ️  Nessun utente ha ancora usato questo codice referral';
        RAISE NOTICE '   ✅ Tutto normale, sistema in attesa';
        
    ELSIF v_referred_count > 0 AND v_transactions_count = 0 THEN
        RAISE NOTICE '   ⚠️  PROBLEMA CRITICO RILEVATO!';
        RAISE NOTICE '   - Ci sono % utenti referiti', v_referred_count;
        RAISE NOTICE '   - Ma ZERO transazioni di punti registrate';
        RAISE NOTICE '   - Il trigger non si è attivato o gli utenti non avevano referred_by_id';
        RAISE NOTICE '';
        RAISE NOTICE '   🔧 AVVIO FIX AUTOMATICO...';
        RAISE NOTICE '';
        
        -- FIX: Assegna i punti mancanti
        FOR v_referred_user IN 
            SELECT id, first_name, last_name, email
            FROM users 
            WHERE referred_by_id = v_referrer.id
        LOOP
            -- Controlla se già processato
            IF NOT EXISTS (
                SELECT 1 FROM points_transactions 
                WHERE user_id = v_referrer.id 
                AND transaction_type = 'referral_completed'
                AND reference_id = v_referred_user.id
            ) THEN
                -- Assegna i punti
                PERFORM add_points_to_user(
                    v_referrer.id,
                    50,
                    'referral_completed',
                    v_referred_user.id,
                    'Referral: ' || v_referred_user.first_name || ' ' || v_referred_user.last_name
                );
                
                -- Incrementa il contatore
                UPDATE user_points
                SET referrals_count = referrals_count + 1
                WHERE user_id = v_referrer.id;
                
                v_fixed_count := v_fixed_count + 1;
                
                RAISE NOTICE '      ✅ Assegnati 50 punti per: % %', 
                    v_referred_user.first_name, 
                    v_referred_user.last_name;
            END IF;
        END LOOP;
        
        RAISE NOTICE '';
        RAISE NOTICE '   ✅ FIX COMPLETATO: % referral corretti', v_fixed_count;
        
    ELSIF v_referred_count > v_transactions_count THEN
        RAISE NOTICE '   ⚠️  DISCREPANZA PARZIALE';
        RAISE NOTICE '   - Utenti referiti: %', v_referred_count;
        RAISE NOTICE '   - Transazioni registrate: %', v_transactions_count;
        RAISE NOTICE '   - Mancano % transazioni', v_referred_count - v_transactions_count;
        RAISE NOTICE '';
        RAISE NOTICE '   🔧 AVVIO FIX PARZIALE...';
        RAISE NOTICE '';
        
        -- FIX parziale
        FOR v_referred_user IN 
            SELECT id, first_name, last_name
            FROM users 
            WHERE referred_by_id = v_referrer.id
        LOOP
            IF NOT EXISTS (
                SELECT 1 FROM points_transactions 
                WHERE user_id = v_referrer.id 
                AND reference_id = v_referred_user.id
            ) THEN
                PERFORM add_points_to_user(
                    v_referrer.id, 50, 'referral_completed', v_referred_user.id,
                    'Referral: ' || v_referred_user.first_name || ' ' || v_referred_user.last_name
                );
                
                UPDATE user_points
                SET referrals_count = referrals_count + 1
                WHERE user_id = v_referrer.id;
                
                v_fixed_count := v_fixed_count + 1;
                RAISE NOTICE '      ✅ Assegnati 50 punti per: %', v_referred_user.first_name;
            END IF;
        END LOOP;
        
        RAISE NOTICE '';
        RAISE NOTICE '   ✅ FIX COMPLETATO: % referral corretti', v_fixed_count;
        
    ELSE
        RAISE NOTICE '   ✅ Sistema OK!';
        RAISE NOTICE '   - Tutti i referral sono stati correttamente processati';
        RAISE NOTICE '   - % utenti referiti = % transazioni', v_referred_count, v_transactions_count;
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
    RAISE NOTICE '📊 RIEPILOGO FINALE';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
    
    -- Rileggi i dati aggiornati
    SELECT up.points_total, up.points_available, up.referrals_count
    INTO v_referrer.points_total, v_referrer.points_available, v_referrer.referrals_count
    FROM user_points up
    WHERE up.user_id = v_referrer.id;
    
    RAISE NOTICE 'Utente: % %', v_referrer.first_name, v_referrer.last_name;
    RAISE NOTICE 'Referral Code: %', v_target_referral_code;
    RAISE NOTICE 'Punti totali: %', COALESCE(v_referrer.points_total, 0);
    RAISE NOTICE 'Punti disponibili: %', COALESCE(v_referrer.points_available, 0);
    RAISE NOTICE 'Contatore referrals: %', COALESCE(v_referrer.referrals_count, 0);
    RAISE NOTICE 'Utenti referiti: %', v_referred_count;
    
    IF v_fixed_count > 0 THEN
        RAISE NOTICE '';
        RAISE NOTICE '🎉 Punti corretti: +% (% x 50 punti)', v_fixed_count * 50, v_fixed_count;
    END IF;
    
    RAISE NOTICE '═══════════════════════════════════════════════════════';
    RAISE NOTICE '';
END $$;
