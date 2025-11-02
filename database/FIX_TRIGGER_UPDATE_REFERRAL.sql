-- =====================================================
-- FIX: Aggiungi Trigger per UPDATE di referred_by_id
-- =====================================================
-- Problema: Il referral viene aggiunto DOPO la registrazione via UPDATE
-- Il trigger award_referral_points() si attiva solo su INSERT
-- Soluzione: Aggiungi trigger anche per UPDATE
-- =====================================================

-- Crea un nuovo trigger che si attiva su UPDATE di referred_by_id
CREATE OR REPLACE FUNCTION award_referral_points_on_update()
RETURNS TRIGGER AS $$
DECLARE
    v_referrer_id UUID;
    v_referred_user_name TEXT;
BEGIN
    -- Si attiva solo se referred_by_id cambia da NULL a un valore
    IF OLD.referred_by_id IS NULL AND NEW.referred_by_id IS NOT NULL THEN
        
        v_referrer_id := NEW.referred_by_id;
        v_referred_user_name := NEW.first_name || ' ' || NEW.last_name;
        
        -- Assegna 50 punti al referrer
        PERFORM add_points_to_user(
            v_referrer_id,
            50,
            'referral_completed',
            NEW.id,
            'Referral: ' || v_referred_user_name
        );
        
        -- Incrementa il contatore referrals
        UPDATE user_points
        SET referrals_count = referrals_count + 1
        WHERE user_id = v_referrer_id;
        
        RAISE NOTICE 'Punti referral assegnati a % per utente %', v_referrer_id, v_referred_user_name;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Crea il trigger che si attiva su UPDATE
DROP TRIGGER IF EXISTS trigger_award_referral_on_update ON users;

CREATE TRIGGER trigger_award_referral_on_update
    AFTER UPDATE OF referred_by_id ON users
    FOR EACH ROW
    WHEN (OLD.referred_by_id IS NULL AND NEW.referred_by_id IS NOT NULL)
    EXECUTE FUNCTION award_referral_points_on_update();

-- =====================================================
-- VERIFICA CHE I TRIGGER SIANO ATTIVI
-- =====================================================
SELECT 
    trigger_name,
    event_manipulation as "when",
    action_statement as "function",
    action_timing as timing
FROM information_schema.triggers
WHERE event_object_table = 'users'
AND trigger_name LIKE '%referral%'
ORDER BY trigger_name;

-- =====================================================
-- TEST: Simula un UPDATE di referred_by_id
-- =====================================================
DO $$
DECLARE
    v_test_user_id UUID;
    v_referrer_id UUID;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🧪 TEST TRIGGER UPDATE';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
    
    -- Trova l'utente con referral code 06ac519c
    SELECT id INTO v_referrer_id 
    FROM users 
    WHERE referral_code = '06ac519c';
    
    IF v_referrer_id IS NULL THEN
        RAISE NOTICE '❌ Utente con referral code 06ac519c non trovato';
        RETURN;
    END IF;
    
    RAISE NOTICE '✅ Referrer trovato: %', v_referrer_id;
    
    -- Trova un utente che NON ha referred_by_id (per test)
    SELECT id INTO v_test_user_id
    FROM users
    WHERE referred_by_id IS NULL
    AND id != v_referrer_id
    LIMIT 1;
    
    IF v_test_user_id IS NULL THEN
        RAISE NOTICE 'ℹ️  Nessun utente disponibile per il test';
        RAISE NOTICE '   (Tutti gli utenti hanno già un referred_by_id)';
        RETURN;
    END IF;
    
    RAISE NOTICE 'ℹ️  Trovato utente test: %', v_test_user_id;
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  NOTA: Questo è solo un test. Non verrà eseguito l''UPDATE.';
    RAISE NOTICE '   Per testare manualmente, esegui:';
    RAISE NOTICE '';
    RAISE NOTICE '   UPDATE users SET referred_by_id = ''%'' WHERE id = ''%'';', v_referrer_id, v_test_user_id;
    RAISE NOTICE '';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
END $$;

RAISE NOTICE '';
RAISE NOTICE '✅ Trigger UPDATE creato con successo!';
RAISE NOTICE '';
RAISE NOTICE '📝 PROSSIMI PASSI:';
RAISE NOTICE '1. Esegui lo script FIX_REFERRAL_GENERIC.sql per assegnare punti agli utenti esistenti';
RAISE NOTICE '2. I nuovi utenti che si registrano ora riceveranno automaticamente i punti';
RAISE NOTICE '';
