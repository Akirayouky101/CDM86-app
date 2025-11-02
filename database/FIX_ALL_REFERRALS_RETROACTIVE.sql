-- =====================================================
-- FIX COMPLETO: Assegna Punti per Tutti i Referral Esistenti
-- =====================================================
-- Trova TUTTI gli utenti che hanno un referred_by_id ma il referrer
-- non ha ricevuto i punti, e assegna i punti retroattivamente
-- =====================================================

DO $$
DECLARE
    v_user RECORD;
    v_referrer RECORD;
    v_total_fixed INTEGER := 0;
    v_total_points INTEGER := 0;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
    RAISE NOTICE '🔧 FIX RETROATTIVO: Assegna Punti per Tutti i Referral';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
    RAISE NOTICE '';
    
    -- Per ogni utente che ha un referred_by_id
    FOR v_user IN 
        SELECT 
            u.id,
            u.first_name,
            u.last_name,
            u.email,
            u.referred_by_id,
            u.created_at,
            ref.first_name || ' ' || ref.last_name as referrer_name,
            ref.referral_code as referrer_code
        FROM users u
        JOIN users ref ON u.referred_by_id = ref.id
        WHERE u.referred_by_id IS NOT NULL
        ORDER BY u.created_at
    LOOP
        -- Controlla se i punti sono già stati assegnati
        IF NOT EXISTS (
            SELECT 1 FROM points_transactions 
            WHERE user_id = v_user.referred_by_id 
            AND transaction_type = 'referral_completed'
            AND reference_id = v_user.id
        ) THEN
            -- Assegna i punti al referrer
            PERFORM add_points_to_user(
                v_user.referred_by_id,
                50,
                'referral_completed',
                v_user.id,
                'Referral: ' || v_user.first_name || ' ' || v_user.last_name || ' (Fix retroattivo)'
            );
            
            -- Incrementa il contatore
            UPDATE user_points
            SET referrals_count = referrals_count + 1
            WHERE user_id = v_user.referred_by_id;
            
            v_total_fixed := v_total_fixed + 1;
            v_total_points := v_total_points + 50;
            
            RAISE NOTICE '✅ [%/%] Assegnati 50 punti a "%" per referral "%"',
                v_total_fixed,
                (SELECT COUNT(*) FROM users WHERE referred_by_id IS NOT NULL),
                v_user.referrer_name,
                v_user.first_name || ' ' || v_user.last_name;
        ELSE
            RAISE NOTICE '⏭️  Già processato: "%" → "%"',
                v_user.referrer_name,
                v_user.first_name || ' ' || v_user.last_name;
        END IF;
    END LOOP;
    
    RAISE NOTICE '';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
    RAISE NOTICE '📊 RIEPILOGO FIX';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
    RAISE NOTICE 'Referral corretti: %', v_total_fixed;
    RAISE NOTICE 'Punti totali assegnati: %', v_total_points;
    RAISE NOTICE '═══════════════════════════════════════════════════════';
    RAISE NOTICE '';
    
    IF v_total_fixed = 0 THEN
        RAISE NOTICE 'ℹ️  Nessun referral da correggere. Tutti i punti sono già stati assegnati.';
    ELSE
        RAISE NOTICE '🎉 Successo! % utenti ora hanno ricevuto i loro punti referral!', v_total_fixed;
    END IF;
    
    RAISE NOTICE '';
END $$;

-- =====================================================
-- VERIFICA FINALE: Mostra Statistiche Referral
-- =====================================================
SELECT 
    '📊 STATISTICHE REFERRAL' as info,
    COUNT(DISTINCT referred_by_id) as referrer_totali,
    COUNT(*) as utenti_referiti_totali,
    SUM(50) as punti_dovuti_totali,
    (SELECT SUM(points_awarded) FROM points_transactions WHERE transaction_type = 'referral_completed') as punti_assegnati_totali
FROM users
WHERE referred_by_id IS NOT NULL;

-- Mostra i top referrer
SELECT 
    '🏆 TOP 10 REFERRER' as info,
    u.first_name || ' ' || u.last_name as referrer,
    u.email,
    u.referral_code,
    up.referrals_count as contatore,
    up.points_total as punti_totali,
    (SELECT COUNT(*) FROM users WHERE referred_by_id = u.id) as utenti_referiti_reali
FROM users u
LEFT JOIN user_points up ON u.id = up.user_id
WHERE u.id IN (SELECT DISTINCT referred_by_id FROM users WHERE referred_by_id IS NOT NULL)
ORDER BY (SELECT COUNT(*) FROM users WHERE referred_by_id = u.id) DESC
LIMIT 10;
