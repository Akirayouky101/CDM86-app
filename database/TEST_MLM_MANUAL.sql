-- ============================================================================
-- TEST COMPLETO SISTEMA MLM - SCENARIO REALE
-- ============================================================================
-- Testa il sistema referral con catena a 2 livelli
--
-- SCENARIO TEST:
-- Diego (ADMIN001) invita Utente B
-- Utente B invita Utente C  
-- Utente C invita Utente D
--
-- RISULTATI ATTESI:
-- Diego: 2 punti (1 da B livello 1, 1 da C livello 2)
-- Utente B: 2 punti (1 da C livello 1, 1 da D livello 2)
-- Utente C: 1 punto (1 da D livello 1)
-- Utente D: 0 punti
-- ============================================================================


-- ============================================================================
-- STEP 1: Trova ID degli admin per il test
-- ============================================================================
SELECT 
  'STEP 1: Admin disponibili per test' as step,
  id,
  email,
  referral_code,
  COALESCE(account_type, 'user') as account_type
FROM users
WHERE referral_code IN ('ADMIN001', 'ADMIN002')
ORDER BY referral_code;

-- Salva questi ID per usarli dopo
-- Diego ADMIN001: 4eeecfe7-d800-4c5b-af08-30e0df9c810b
-- Claudio ADMIN002: 52f70606-c75b-4396-9203-a52af7d95886


-- ============================================================================
-- STEP 2: Controlla punti PRIMA del test
-- ============================================================================
SELECT 
  'STEP 2: Punti attuali admin (PRIMA del test)' as step,
  u.email,
  u.referral_code,
  COALESCE(up.points_total, 0) as points_total,
  COALESCE(up.referrals_count, 0) as referrals_count
FROM users u
LEFT JOIN user_points up ON u.id = up.user_id
WHERE u.referral_code IN ('ADMIN001', 'ADMIN002')
ORDER BY u.referral_code;


-- ============================================================================
-- STEP 3: Verifica rete attuale admin
-- ============================================================================
SELECT 
  'STEP 3: Rete attuale Diego (ADMIN001)' as step,
  COALESCE(COUNT(*), 0) as total_referrals,
  COALESCE(SUM(CASE WHEN level = 1 THEN 1 ELSE 0 END), 0) as level_1_count,
  COALESCE(SUM(CASE WHEN level = 2 THEN 1 ELSE 0 END), 0) as level_2_count
FROM referral_network
WHERE user_id = (SELECT id FROM users WHERE referral_code = 'ADMIN001');


-- ============================================================================
-- STEP 4: ISTRUZIONI PER TEST MANUALE
-- ============================================================================
SELECT 
  '🎯 ISTRUZIONI TEST MANUALE' as step,
  'Ora registra 3 nuovi utenti in sequenza:' as instruction;

/*
ISTRUZIONI DETTAGLIATE:

1️⃣ REGISTRA UTENTE B con referral ADMIN001
   - Vai su https://cdm86.com/?ref=ADMIN001
   - Registrati con email: test-user-b@example.com
   - Password: TestUser123!
   - Nome: Test B
   
2️⃣ COPIA IL REFERRAL CODE di Utente B
   - Dopo registrazione, vai su Dashboard
   - Cerca "Il tuo codice referral"
   - Copia il codice (es. ABC123)
   
3️⃣ REGISTRA UTENTE C con referral di B
   - Apri finestra incognito
   - Vai su https://cdm86.com/?ref=ABC123 (usa codice di B)
   - Registrati con email: test-user-c@example.com
   - Password: TestUser123!
   - Nome: Test C
   
4️⃣ COPIA IL REFERRAL CODE di Utente C
   - Dopo registrazione, vai su Dashboard
   - Copia il suo referral code (es. DEF456)
   
5️⃣ REGISTRA UTENTE D con referral di C
   - Apri nuova finestra incognito
   - Vai su https://cdm86.com/?ref=DEF456 (usa codice di C)
   - Registrati con email: test-user-d@example.com
   - Password: TestUser123!
   - Nome: Test D

6️⃣ ESEGUI LE QUERY DI VERIFICA QUI SOTTO
*/


-- ============================================================================
-- STEP 5: VERIFICA RISULTATI - Esegui DOPO aver registrato i 3 utenti
-- ============================================================================

-- Query 5.1: Trova gli utenti di test appena creati
SELECT 
  'STEP 5.1: Utenti di test creati' as step,
  id,
  email,
  referral_code,
  referred_by_id,
  account_type,
  created_at
FROM users
WHERE email LIKE 'test-user-%@example.com'
ORDER BY created_at DESC;


-- Query 5.2: Verifica catena referral completa
WITH RECURSIVE referral_chain AS (
  -- Livello 0: Diego (root)
  SELECT 
    id,
    email,
    referral_code,
    referred_by_id,
    0 as level,
    ARRAY[id] as path,
    email as chain
  FROM users
  WHERE referral_code = 'ADMIN001'
  
  UNION ALL
  
  -- Livelli successivi: chi è stato invitato
  SELECT 
    u.id,
    u.email,
    u.referral_code,
    u.referred_by_id,
    rc.level + 1,
    rc.path || u.id,
    rc.chain || ' → ' || u.email
  FROM users u
  INNER JOIN referral_chain rc ON u.referred_by_id = rc.id
  WHERE rc.level < 5
)
SELECT 
  'STEP 5.2: Catena referral completa' as step,
  level,
  email,
  referral_code,
  chain as full_chain,
  CASE 
    WHEN level = 0 THEN '👤 ROOT'
    WHEN level = 1 THEN '⭐ LIVELLO 1 (+1 punto a root)'
    WHEN level = 2 THEN '🌟 LIVELLO 2 (+1 punto a root)'
    ELSE '❌ LIVELLO 3+ (nessun punto a root)'
  END as points_distribution
FROM referral_chain
ORDER BY level, email;


-- Query 5.3: Verifica punti assegnati a Diego (ADMIN001)
SELECT 
  'STEP 5.3: Punti Diego (ADMIN001)' as step,
  u.email,
  u.referral_code,
  up.points_total as total_points,
  up.referrals_count as direct_referrals,
  (SELECT COUNT(*) FROM referral_network WHERE user_id = u.id AND level = 1) as level_1_referrals,
  (SELECT COUNT(*) FROM referral_network WHERE user_id = u.id AND level = 2) as level_2_referrals,
  CASE 
    WHEN up.points_total >= 2 THEN '✅ CORRETTO (almeno 2 punti)'
    ELSE '❌ ERRORE - Dovrebbe avere almeno 2 punti'
  END as validation
FROM users u
LEFT JOIN user_points up ON u.id = up.user_id
WHERE u.referral_code = 'ADMIN001';


-- Query 5.4: Verifica dettaglio referral_network per Diego
SELECT 
  'STEP 5.4: Dettaglio rete Diego' as step,
  rn.level,
  u_ref.email as referral_email,
  u_ref.referral_code as referral_code,
  rn.points_awarded,
  rn.referral_type,
  rn.created_at
FROM referral_network rn
JOIN users u_ref ON rn.referral_id = u_ref.id
WHERE rn.user_id = (SELECT id FROM users WHERE referral_code = 'ADMIN001')
ORDER BY rn.level, rn.created_at;


-- Query 5.5: Verifica punti TUTTI gli utenti della catena
SELECT 
  'STEP 5.5: Punti tutti gli utenti (catena completa)' as step,
  u.email,
  u.referral_code,
  COALESCE(up.points_total, 0) as points_total,
  COALESCE(up.referrals_count, 0) as direct_referrals,
  (SELECT COUNT(*) FROM referral_network WHERE user_id = u.id AND level = 1) as level_1_count,
  (SELECT COUNT(*) FROM referral_network WHERE user_id = u.id AND level = 2) as level_2_count,
  (SELECT COUNT(*) FROM referral_network WHERE user_id = u.id) as total_network
FROM users u
LEFT JOIN user_points up ON u.id = up.user_id
WHERE u.referral_code = 'ADMIN001' 
   OR u.email LIKE 'test-user-%@example.com'
ORDER BY u.created_at;


-- Query 5.6: Verifica transazioni punti
SELECT 
  'STEP 5.6: Transazioni punti (ultime 20)' as step,
  pt.id,
  u.email,
  u.referral_code,
  pt.type,
  pt.points,
  pt.description,
  pt.created_at
FROM points_transactions pt
JOIN users u ON pt.user_id = u.id
WHERE pt.type IN ('referral_level_1', 'referral_level_2')
ORDER BY pt.created_at DESC
LIMIT 20;


-- Query 5.7: Test integrità dati
SELECT 
  'STEP 5.7: Test integrità dati' as step,
  u.email,
  SUM(rn.points_awarded) as calculated_points,
  up.points_total as recorded_points,
  CASE 
    WHEN SUM(rn.points_awarded) = up.points_total THEN '✅ MATCH'
    ELSE '❌ MISMATCH - Bug nel calcolo!'
  END as integrity_check
FROM users u
LEFT JOIN referral_network rn ON u.id = rn.user_id
LEFT JOIN user_points up ON u.id = up.user_id
WHERE u.referral_code = 'ADMIN001' OR u.email LIKE 'test-user-%@example.com'
GROUP BY u.email, up.points_total
ORDER BY u.created_at;


-- ============================================================================
-- STEP 6: RISULTATI ATTESI
-- ============================================================================
SELECT 
  'STEP 6: RISULTATI ATTESI (se tutto funziona)' as step,
  'test-user-b@example.com' as email,
  'Dovrebbe avere 2 punti' as expected_points,
  '1 da test-user-c (livello 1) + 1 da test-user-d (livello 2)' as breakdown
UNION ALL
SELECT 
  'STEP 6: RISULTATI ATTESI (se tutto funziona)',
  'test-user-c@example.com',
  'Dovrebbe avere 1 punto',
  '1 da test-user-d (livello 1)'
UNION ALL
SELECT 
  'STEP 6: RISULTATI ATTESI (se tutto funziona)',
  'test-user-d@example.com',
  'Dovrebbe avere 0 punti',
  'Nessuno invitato da D'
UNION ALL
SELECT 
  'STEP 6: RISULTATI ATTESI (se tutto funziona)',
  'diegomarruchi@outlook.it (ADMIN001)',
  'Dovrebbe avere almeno 2 punti',
  '1 da test-user-b (livello 1) + 1 da test-user-c (livello 2)';


-- ============================================================================
-- CLEANUP (OPZIONALE): Rimuovi utenti di test
-- ============================================================================
-- ATTENZIONE: Esegui solo se vuoi rimuovere gli utenti di test
-- Decommenta le righe sotto SOLO per cleanup

/*
-- Mostra utenti che verranno eliminati
SELECT 
  'CLEANUP PREVIEW: Utenti da eliminare' as warning,
  id,
  email,
  created_at
FROM users
WHERE email LIKE 'test-user-%@example.com';

-- ATTENZIONE: Questa query ELIMINA i dati!
-- Decommenta solo se sei sicuro
/*
DELETE FROM users 
WHERE email LIKE 'test-user-%@example.com';
*/

-- Verifica cleanup
SELECT 
  'CLEANUP VERIFY: Utenti rimanenti' as status,
  COUNT(*) as total_users
FROM users
WHERE email LIKE 'test-user-%@example.com';
*/


-- ============================================================================
-- FINE TEST
-- ============================================================================
SELECT 
  '✅ Test MLM completato!' as status,
  'Controlla i risultati delle query sopra' as next_step,
  'Se tutti i check sono ✅ MATCH, il sistema funziona perfettamente!' as validation;
