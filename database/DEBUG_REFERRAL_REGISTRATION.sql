-- =====================================================
-- DEBUG COMPLETO: Verifica Registrazione con Referral
-- =====================================================

-- STEP 1: Trova l'utente con referral code 06ac519c
SELECT 
    '🔍 STEP 1: UTENTE CON CODICE REFERRAL' as info,
    id as user_id,
    first_name,
    last_name,
    email,
    referral_code,
    created_at
FROM users 
WHERE referral_code = '06ac519c';

-- STEP 2: Verifica se qualcuno ha il referred_by_id che punta a questo utente
SELECT 
    '🔍 STEP 2: UTENTI CON REFERRED_BY_ID' as info,
    u.id as referred_user_id,
    u.first_name as referred_first_name,
    u.last_name as referred_last_name,
    u.email as referred_email,
    u.referred_by_id,
    u.created_at as registered_at,
    ref.first_name || ' ' || ref.last_name as referrer_name,
    ref.referral_code as referrer_code
FROM users u
LEFT JOIN users ref ON u.referred_by_id = ref.id
WHERE u.referred_by_id = (SELECT id FROM users WHERE referral_code = '06ac519c');

-- STEP 3: Controlla TUTTI gli utenti recenti (ultimi 30 giorni)
SELECT 
    '🔍 STEP 3: TUTTI GLI UTENTI RECENTI (30 giorni)' as info,
    u.id,
    u.first_name,
    u.last_name,
    u.email,
    u.referred_by_id,
    u.referral_code as my_code,
    CASE 
        WHEN u.referred_by_id IS NULL THEN '❌ Nessun referrer'
        ELSE '✅ Ha un referrer: ' || ref.first_name || ' ' || ref.last_name || ' (' || ref.referral_code || ')'
    END as referral_status,
    u.created_at
FROM users u
LEFT JOIN users ref ON u.referred_by_id = ref.id
WHERE u.created_at > NOW() - INTERVAL '30 days'
ORDER BY u.created_at DESC;

-- STEP 4: Controlla la tabella user_points
SELECT 
    '🔍 STEP 4: PUNTI DELL''UTENTE 06ac519c' as info,
    up.user_id,
    u.first_name,
    u.last_name,
    up.points_total,
    up.points_used,
    up.points_available,
    up.referrals_count,
    up.approved_reports_count,
    up.level,
    up.created_at,
    up.updated_at
FROM user_points up
JOIN users u ON up.user_id = u.id
WHERE u.referral_code = '06ac519c';

-- STEP 5: Controlla tutte le transazioni di punti
SELECT 
    '🔍 STEP 5: TRANSAZIONI PUNTI' as info,
    pt.id,
    u.first_name || ' ' || u.last_name as user_name,
    pt.points_awarded,
    pt.transaction_type,
    pt.description,
    pt.reference_id,
    pt.created_at
FROM points_transactions pt
JOIN users u ON pt.user_id = u.id
WHERE u.referral_code = '06ac519c'
ORDER BY pt.created_at DESC;

-- STEP 6: Verifica se il trigger è attivo
SELECT 
    '🔍 STEP 6: VERIFICA TRIGGER' as info,
    trigger_name,
    event_manipulation,
    action_statement,
    action_timing
FROM information_schema.triggers
WHERE trigger_name LIKE '%referral%' OR trigger_name LIKE '%award%'
AND event_object_table = 'users';

-- =====================================================
-- DIAGNOSI AUTOMATICA
-- =====================================================
DO $$
DECLARE
    v_referrer_id UUID;
    v_referrer_name TEXT;
    v_referred_count_by_id INTEGER;
    v_user_points RECORD;
    v_has_user_points BOOLEAN;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
    RAISE NOTICE '🔬 DIAGNOSI AUTOMATICA';
    RAISE NOTICE '═══════════════════════════════════════════════════════';
    RAISE NOTICE '';
    
    -- Trova il referrer
    SELECT id, first_name || ' ' || last_name 
    INTO v_referrer_id, v_referrer_name
    FROM users 
    WHERE referral_code = '06ac519c';
    
    IF v_referrer_id IS NULL THEN
        RAISE NOTICE '❌ PROBLEMA 1: Utente con referral code 06ac519c NON TROVATO!';
        RAISE NOTICE '   Verifica che l''utente esista nel database.';
        RETURN;
    ELSE
        RAISE NOTICE '✅ STEP 1: Utente trovato';
        RAISE NOTICE '   Nome: %', v_referrer_name;
        RAISE NOTICE '   ID: %', v_referrer_id;
    END IF;
    RAISE NOTICE '';
    
    -- Conta utenti con referred_by_id corretto
    SELECT COUNT(*) INTO v_referred_count_by_id
    FROM users
    WHERE referred_by_id = v_referrer_id;
    
    RAISE NOTICE '✅ STEP 2: Check referred_by_id';
    RAISE NOTICE '   Utenti con referred_by_id = %: %', v_referrer_id, v_referred_count_by_id;
    
    IF v_referred_count_by_id = 0 THEN
        RAISE NOTICE '';
        RAISE NOTICE '❌ PROBLEMA 2: NESSUN UTENTE HA referred_by_id CORRETTO!';
        RAISE NOTICE '';
        RAISE NOTICE '🔍 POSSIBILI CAUSE:';
        RAISE NOTICE '   1. L''utente si è registrato ma il campo referred_by_id è rimasto NULL';
        RAISE NOTICE '   2. Il codice referral NON è stato processato durante la registrazione';
        RAISE NOTICE '   3. Il frontend non sta inviando il referred_by_id al backend';
        RAISE NOTICE '';
        RAISE NOTICE '💡 SOLUZIONE:';
        RAISE NOTICE '   Controlla il codice di registrazione in auth-modal.js';
        RAISE NOTICE '   Cerca la funzione di registrazione e verifica che:';
        RAISE NOTICE '   - Il referral code venga letto dal localStorage';
        RAISE NOTICE '   - Il referred_by_id venga convertito da referral_code a user_id';
        RAISE NOTICE '   - Il campo venga inviato nella chiamata API';
        RAISE NOTICE '';
        RAISE NOTICE '🔧 VERIFICA CON QUESTO QUERY:';
        RAISE NOTICE '   SELECT * FROM users WHERE email = ''<email_utente_referito>''';
        RAISE NOTICE '   Controlla se referred_by_id è NULL o ha un valore';
    ELSE
        RAISE NOTICE '   ✅ Trovati % utenti referiti', v_referred_count_by_id;
    END IF;
    RAISE NOTICE '';
    
    -- Controlla se esiste record in user_points
    SELECT EXISTS(
        SELECT 1 FROM user_points WHERE user_id = v_referrer_id
    ) INTO v_has_user_points;
    
    IF NOT v_has_user_points THEN
        RAISE NOTICE '❌ PROBLEMA 3: Record user_points NON ESISTE!';
        RAISE NOTICE '   L''utente non ha un record in user_points.';
        RAISE NOTICE '   Questo dovrebbe essere creato automaticamente alla registrazione.';
        RAISE NOTICE '';
        RAISE NOTICE '🔧 FIX: Creo il record ora...';
        
        INSERT INTO user_points (user_id, points_total, points_used, points_available, referrals_count, level)
        VALUES (v_referrer_id, 0, 0, 0, 0, 1)
        ON CONFLICT (user_id) DO NOTHING;
        
        RAISE NOTICE '   ✅ Record user_points creato';
    ELSE
        SELECT * INTO v_user_points
        FROM user_points
        WHERE user_id = v_referrer_id;
        
        RAISE NOTICE '✅ STEP 3: Record user_points esiste';
        RAISE NOTICE '   Punti totali: %', v_user_points.points_total;
        RAISE NOTICE '   Punti disponibili: %', v_user_points.points_available;
        RAISE NOTICE '   Referrals count: %', v_user_points.referrals_count;
    END IF;
    RAISE NOTICE '';
    
    -- Verifica finale
    IF v_referred_count_by_id > 0 THEN
        RAISE NOTICE '✅ SISTEMA OK - Ma i punti potrebbero non essere stati assegnati';
        RAISE NOTICE '   Esegui lo script FIX_REFERRAL_GENERIC.sql per assegnare i punti';
    END IF;
    
    RAISE NOTICE '═══════════════════════════════════════════════════════';
    RAISE NOTICE '';
END $$;
