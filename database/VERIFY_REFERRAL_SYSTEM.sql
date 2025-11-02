-- =====================================================
-- VERIFICA COMPLETA SISTEMA REFERRAL
-- =====================================================
-- Questo script controlla tutto il sistema referral
-- =====================================================

-- 1. Verifica che i trigger esistano
SELECT 
    '1. TRIGGER ESISTENTI' as check_name,
    trigger_name,
    event_manipulation,
    action_timing,
    event_object_table
FROM information_schema.triggers
WHERE event_object_table = 'users'
AND trigger_name LIKE '%referral%'
ORDER BY trigger_name;

-- 2. Verifica ultimi utenti registrati con referred_by_id
SELECT 
    '2. ULTIMI UTENTI CON REFERRAL (ultimi 7 giorni)' as check_name,
    u.id,
    u.first_name,
    u.last_name,
    u.email,
    u.referred_by_id,
    u.created_at,
    ref.first_name || ' ' || ref.last_name as referrer_name,
    ref.referral_code as referrer_code,
    CASE 
        WHEN u.referred_by_id IS NULL THEN '❌ NO REFERRAL'
        ELSE '✅ HAS REFERRAL'
    END as status
FROM users u
LEFT JOIN users ref ON u.referred_by_id = ref.id
WHERE u.created_at > NOW() - INTERVAL '7 days'
ORDER BY u.created_at DESC
LIMIT 20;

-- 3. Controlla se ci sono utenti senza referred_by_id
SELECT 
    '3. UTENTI REGISTRATI OGGI SENZA REFERRAL' as check_name,
    COUNT(*) as count_no_referral
FROM users
WHERE referred_by_id IS NULL
AND created_at > CURRENT_DATE;

-- 4. Controlla punti assegnati oggi
SELECT 
    '4. PUNTI REFERRAL ASSEGNATI OGGI' as check_name,
    pt.id,
    pt.user_id,
    u.first_name || ' ' || u.last_name as user_name,
    pt.points,
    pt.description,
    pt.created_at
FROM points_transactions pt
JOIN users u ON pt.user_id = u.id
WHERE pt.transaction_type = 'referral_completed'
AND pt.created_at > CURRENT_DATE
ORDER BY pt.created_at DESC;

-- 5. Verifica discrepanze tra utenti referiti e punti
SELECT 
    '5. DISCREPANZE PUNTI VS REFERRAL' as check_name,
    u.id,
    u.first_name || ' ' || u.last_name as referrer_name,
    u.referral_code,
    up.referrals_count as points_table_count,
    (SELECT COUNT(*) FROM users WHERE referred_by_id = u.id) as actual_referrals_count,
    CASE 
        WHEN up.referrals_count != (SELECT COUNT(*) FROM users WHERE referred_by_id = u.id) 
        THEN '⚠️ DISCREPANZA!'
        ELSE '✅ OK'
    END as status
FROM users u
LEFT JOIN user_points up ON u.id = up.user_id
WHERE u.id IN (SELECT DISTINCT referred_by_id FROM users WHERE referred_by_id IS NOT NULL)
ORDER BY actual_referrals_count DESC;

-- 6. Test diagnostico automatico
DO $$
DECLARE
    v_total_referrals INTEGER;
    v_total_transactions INTEGER;
    v_missing INTEGER;
    v_trigger_exists BOOLEAN;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
    RAISE NOTICE '🔬 DIAGNOSI AUTOMATICA SISTEMA REFERRAL';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
    RAISE NOTICE '';
    
    -- Check trigger
    SELECT EXISTS (
        SELECT 1 FROM information_schema.triggers 
        WHERE trigger_name = 'trigger_award_referral_on_update'
    ) INTO v_trigger_exists;
    
    IF v_trigger_exists THEN
        RAISE NOTICE '✅ Trigger UPDATE esistente: trigger_award_referral_on_update';
    ELSE
        RAISE NOTICE '❌ Trigger UPDATE MANCANTE!';
        RAISE NOTICE '   Eseguire: database/FIX_TRIGGER_UPDATE_REFERRAL.sql';
    END IF;
    RAISE NOTICE '';
    
    -- Count referrals
    SELECT COUNT(*) INTO v_total_referrals
    FROM users
    WHERE referred_by_id IS NOT NULL;
    
    RAISE NOTICE '📊 Statistiche Generali:';
    RAISE NOTICE '   Totale utenti con referral: %', v_total_referrals;
    
    -- Count transactions
    SELECT COUNT(*) INTO v_total_transactions
    FROM points_transactions
    WHERE transaction_type = 'referral_completed';
    
    RAISE NOTICE '   Transazioni punti referral: %', v_total_transactions;
    
    v_missing := v_total_referrals - v_total_transactions;
    
    IF v_missing > 0 THEN
        RAISE NOTICE '';
        RAISE NOTICE '⚠️  PROBLEMA RILEVATO!';
        RAISE NOTICE '   Mancano % transazioni di punti', v_missing;
        RAISE NOTICE '   % utenti non hanno ricevuto punti per i loro referral', v_missing;
        RAISE NOTICE '';
        RAISE NOTICE '💡 SOLUZIONE:';
        RAISE NOTICE '   Eseguire: database/FIX_ALL_REFERRALS_RETROACTIVE.sql';
    ELSIF v_missing < 0 THEN
        RAISE NOTICE '';
        RAISE NOTICE '⚠️  ANOMALIA!';
        RAISE NOTICE '   Ci sono più transazioni (%) che referral (%)', v_total_transactions, v_total_referrals;
        RAISE NOTICE '   Possibili duplicati o errori';
    ELSE
        RAISE NOTICE '';
        RAISE NOTICE '✅ Sistema OK!';
        RAISE NOTICE '   Tutti i referral hanno ricevuto i punti correttamente';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
    RAISE NOTICE '';
END $$;

-- 7. Mostra TOP 5 referrer
SELECT 
    '7. TOP 5 REFERRER' as check_name,
    ref.first_name || ' ' || ref.last_name as referrer,
    ref.referral_code,
    COUNT(u.id) as total_referrals,
    up.points_total as total_points,
    up.referrals_count as referrals_count_in_points
FROM users u
JOIN users ref ON u.referred_by_id = ref.id
LEFT JOIN user_points up ON ref.id = up.user_id
GROUP BY ref.id, ref.first_name, ref.last_name, ref.referral_code, up.points_total, up.referrals_count
ORDER BY COUNT(u.id) DESC
LIMIT 5;
