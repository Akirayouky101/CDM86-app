-- ============================================================================
-- VERIFICA RAPIDA INSTALLAZIONE MLM
-- ============================================================================
-- Esegui queste query SUBITO DOPO aver installato SETUP_MLM_REFERRAL_SYSTEM.sql
-- per confermare che tutto funziona correttamente
-- ============================================================================

-- ============================================================================
-- CHECK 1: Verifica tabella referral_network esiste
-- ============================================================================
SELECT 
  'CHECK 1: Tabella referral_network' as test,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.tables 
      WHERE table_name = 'referral_network'
    ) THEN '✅ PASS - Tabella creata'
    ELSE '❌ FAIL - Tabella mancante'
  END as result;


-- ============================================================================
-- CHECK 2: Verifica colonna account_type in users
-- ============================================================================
SELECT 
  'CHECK 2: Colonna account_type' as test,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'users' AND column_name = 'account_type'
    ) THEN '✅ PASS - Colonna aggiunta'
    ELSE '❌ FAIL - Colonna mancante'
  END as result;


-- ============================================================================
-- CHECK 3: Verifica trigger MLM esistono
-- ============================================================================
SELECT 
  'CHECK 3: Trigger MLM' as test,
  CASE 
    WHEN COUNT(*) = 2 THEN '✅ PASS - 2 trigger attivi'
    WHEN COUNT(*) = 1 THEN '⚠️ WARNING - Solo 1 trigger attivo'
    ELSE '❌ FAIL - Nessun trigger'
  END as result,
  string_agg(trigger_name, ', ') as trigger_names
FROM information_schema.triggers
WHERE event_object_table = 'users'
AND trigger_name LIKE '%mlm%';


-- ============================================================================
-- CHECK 4: Verifica funzioni MLM esistono
-- ============================================================================
SELECT 
  'CHECK 4: Funzioni MLM' as test,
  CASE 
    WHEN COUNT(*) >= 2 THEN '✅ PASS - Funzioni create'
    ELSE '❌ FAIL - Funzioni mancanti'
  END as result,
  COUNT(*) as function_count
FROM information_schema.routines
WHERE routine_name LIKE '%mlm%';


-- ============================================================================
-- CHECK 5: Verifica view dashboard esistono
-- ============================================================================
SELECT 
  'CHECK 5: View Dashboard' as test,
  CASE 
    WHEN COUNT(*) = 2 THEN '✅ PASS - Entrambe le view create'
    WHEN COUNT(*) = 1 THEN '⚠️ WARNING - Solo 1 view creata'
    ELSE '❌ FAIL - View mancanti'
  END as result,
  string_agg(table_name, ', ') as view_names
FROM information_schema.views
WHERE table_name IN ('user_referral_network', 'user_referral_details');


-- ============================================================================
-- CHECK 6: Verifica constraint account_type
-- ============================================================================
SELECT 
  'CHECK 6: Constraint account_type' as test,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.check_constraints 
      WHERE constraint_name = 'check_account_type'
    ) THEN '✅ PASS - Constraint attivo'
    ELSE '⚠️ WARNING - Constraint mancante (non critico)'
  END as result;


-- ============================================================================
-- CHECK 7: Verifica indici su referral_network
-- ============================================================================
SELECT 
  'CHECK 7: Indici referral_network' as test,
  CASE 
    WHEN COUNT(*) >= 3 THEN '✅ PASS - Indici creati'
    ELSE '⚠️ WARNING - Alcuni indici mancanti'
  END as result,
  COUNT(*) as index_count
FROM pg_indexes
WHERE tablename = 'referral_network';


-- ============================================================================
-- RIEPILOGO FINALE
-- ============================================================================
SELECT 
  '=' as separator,
  'RIEPILOGO INSTALLAZIONE MLM' as title,
  '=' as separator2;

SELECT 
  CASE 
    WHEN (
      SELECT COUNT(*) FROM (
        SELECT 1 WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'referral_network')
        UNION ALL
        SELECT 1 WHERE EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'account_type')
        UNION ALL
        SELECT 1 WHERE (SELECT COUNT(*) FROM information_schema.triggers WHERE event_object_table = 'users' AND trigger_name LIKE '%mlm%') = 2
        UNION ALL
        SELECT 1 WHERE (SELECT COUNT(*) FROM information_schema.routines WHERE routine_name LIKE '%mlm%') >= 2
        UNION ALL
        SELECT 1 WHERE (SELECT COUNT(*) FROM information_schema.views WHERE table_name IN ('user_referral_network', 'user_referral_details')) = 2
      ) checks
    ) = 5 THEN '🎉 INSTALLAZIONE COMPLETATA CON SUCCESSO!'
    ELSE '⚠️ INSTALLAZIONE PARZIALE - Controlla i check sopra'
  END as status;


-- ============================================================================
-- TEST VELOCE: Simula referral per verificare funzionamento
-- ============================================================================
-- NOTA: Questo test usa gli admin esistenti (Diego ADMIN001, Claudio ADMIN002)
-- Se vuoi testare, decomenta le righe sotto dopo aver verificato i check sopra

/*
-- Trova ID admin per test
SELECT 
  id,
  email,
  referral_code,
  referred_by_id,
  account_type
FROM users
WHERE referral_code IN ('ADMIN001', 'ADMIN002')
ORDER BY referral_code;

-- ISTRUZIONI TEST MANUALE:
-- 1. Registra nuovo utente con referral ADMIN001
-- 2. Esegui query sotto per verificare punti assegnati

SELECT 
  u.email,
  u.referral_code,
  up.points_total,
  up.referrals_count,
  (SELECT COUNT(*) FROM referral_network WHERE user_id = u.id) as total_network_size,
  (SELECT COUNT(*) FROM referral_network WHERE user_id = u.id AND level = 1) as direct_referrals,
  (SELECT COUNT(*) FROM referral_network WHERE user_id = u.id AND level = 2) as network_referrals
FROM users u
LEFT JOIN user_points up ON u.id = up.user_id
WHERE u.referral_code IN ('ADMIN001', 'ADMIN002')
ORDER BY u.referral_code;
*/


-- ============================================================================
-- FINE VERIFICA
-- ============================================================================
SELECT 
  '✅ Verifica installazione MLM completata!' as status,
  'Se tutti i check sono PASS, il sistema è pronto!' as next_step;
