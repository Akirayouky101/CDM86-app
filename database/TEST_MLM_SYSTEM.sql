-- ============================================================================
-- TEST SISTEMA MLM REFERRAL - 2 LIVELLI
-- ============================================================================
-- Test completo del sistema di Network Marketing Multi-Livello
--
-- SCENARIO DI TEST:
-- A (admin) invita B → A riceve +1 punto (livello 1)
-- B invita C → A riceve +1 punto (livello 2), B riceve +1 punto (livello 1)
-- C invita D → B riceve +1 punto (livello 2), C riceve +1 punto (livello 1), A riceve 0
-- D invita E → C riceve +1 punto (livello 2), D riceve +1 punto (livello 1), B e A ricevono 0
--
-- RISULTATI ATTESI:
-- A: 2 punti totali (1 da B livello 1, 1 da C livello 2)
-- B: 2 punti totali (1 da C livello 1, 1 da D livello 2)
-- C: 2 punti totali (1 da D livello 1, 1 da E livello 2)
-- D: 1 punto totale  (1 da E livello 1)
-- E: 0 punti totali
-- ============================================================================


-- ============================================================================
-- QUERY 1: Verifica tabella referral_network esiste
-- ============================================================================
SELECT 
  'referral_network' as table_name,
  COUNT(*) as record_count
FROM referral_network;


-- ============================================================================
-- QUERY 2: Verifica colonna account_type in users
-- ============================================================================
SELECT 
  column_name,
  data_type,
  column_default
FROM information_schema.columns
WHERE table_name = 'users' AND column_name = 'account_type';


-- ============================================================================
-- QUERY 3: Verifica trigger esistono
-- ============================================================================
SELECT 
  trigger_name,
  event_manipulation,
  event_object_table,
  action_statement
FROM information_schema.triggers
WHERE event_object_table = 'users'
AND trigger_name LIKE '%mlm%';


-- ============================================================================
-- QUERY 4: TEST MANUALE - Simula catena referral
-- ============================================================================
-- Usa gli admin esistenti per il test
-- Diego (ADMIN001): 4eeecfe7-d800-4c5b-af08-30e0df9c810b
-- Claudio (ADMIN002): 52f70606-c75b-4396-9203-a52af7d95886

-- Trova ID admin per test
SELECT 
  id,
  email,
  referral_code,
  referred_by_id
FROM users
WHERE referral_code IN ('ADMIN001', 'ADMIN002')
ORDER BY referral_code;


-- ============================================================================
-- QUERY 5: Visualizza rete completa di un utente (esempio Diego ADMIN001)
-- ============================================================================
-- Sostituisci con ID reale dopo la query sopra
WITH RECURSIVE referral_tree AS (
  -- Livello 0: l'utente stesso
  SELECT 
    id,
    email,
    referral_code,
    referred_by_id,
    0 as level,
    ARRAY[id] as path
  FROM users
  WHERE referral_code = 'ADMIN001'  -- Cambia con referral_code desiderato
  
  UNION ALL
  
  -- Livelli successivi: chi è stato invitato
  SELECT 
    u.id,
    u.email,
    u.referral_code,
    u.referred_by_id,
    rt.level + 1,
    rt.path || u.id
  FROM users u
  INNER JOIN referral_tree rt ON u.referred_by_id = rt.id
  WHERE rt.level < 5  -- Limite per evitare loop infiniti
)
SELECT 
  level,
  id,
  email,
  referral_code,
  referred_by_id,
  CASE 
    WHEN level = 0 THEN '👤 ROOT (te stesso)'
    WHEN level = 1 THEN '⭐ LIVELLO 1 (diretti) - Ricevi +1 punto'
    WHEN level = 2 THEN '🌟 LIVELLO 2 (rete) - Ricevi +1 punto'
    ELSE '❌ LIVELLO 3+ (nessun punto)'
  END as status
FROM referral_tree
ORDER BY level, email;


-- ============================================================================
-- QUERY 6: Statistiche rete per utente (usa la view creata)
-- ============================================================================
SELECT * FROM user_referral_network
ORDER BY total_points_from_referrals DESC
LIMIT 20;


-- ============================================================================
-- QUERY 7: Dettaglio referral per utente (usa la view)
-- ============================================================================
-- Esempio per Diego ADMIN001
SELECT * FROM user_referral_details
WHERE user_id = (SELECT id FROM users WHERE referral_code = 'ADMIN001')
ORDER BY level, created_at DESC;


-- ============================================================================
-- QUERY 8: Verifica punti distribuiti correttamente
-- ============================================================================
SELECT 
  rn.user_id,
  u.email as user_email,
  u.referral_code,
  rn.level,
  COUNT(*) as referrals_at_level,
  SUM(rn.points_awarded) as total_points_from_level,
  up.points_total as total_points_in_system,
  up.referrals_count
FROM referral_network rn
JOIN users u ON rn.user_id = u.id
LEFT JOIN user_points up ON rn.user_id = up.user_id
GROUP BY rn.user_id, u.email, u.referral_code, rn.level, up.points_total, up.referrals_count
ORDER BY u.email, rn.level;


-- ============================================================================
-- QUERY 9: Transazioni punti referral
-- ============================================================================
SELECT 
  pt.user_id,
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
LIMIT 50;


-- ============================================================================
-- QUERY 10: Trova catene referral incomplete (possibili bug)
-- ============================================================================
-- Utenti con referred_by_id ma ZERO punti assegnati al referrer
SELECT 
  u.id as user_id,
  u.email,
  u.referred_by_id,
  ref.email as referrer_email,
  ref.referral_code as referrer_code,
  u.created_at as registered_at,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM referral_network 
      WHERE referral_id = u.id AND user_id = u.referred_by_id AND level = 1
    ) THEN '✅ Punti assegnati'
    ELSE '❌ MISSING - Bug nel trigger!'
  END as status
FROM users u
JOIN users ref ON u.referred_by_id = ref.id
WHERE u.referred_by_id IS NOT NULL
ORDER BY u.created_at DESC;


-- ============================================================================
-- QUERY 11: TOP 10 utenti per rete (classifica)
-- ============================================================================
SELECT 
  u.id,
  u.email,
  u.referral_code,
  u.account_type,
  up.points_total,
  up.referrals_count,
  up.level,
  COUNT(DISTINCT rn.referral_id) as total_referrals_in_network,
  SUM(CASE WHEN rn.level = 1 THEN 1 ELSE 0 END) as direct_referrals,
  SUM(CASE WHEN rn.level = 2 THEN 1 ELSE 0 END) as network_referrals
FROM users u
LEFT JOIN user_points up ON u.id = up.user_id
LEFT JOIN referral_network rn ON u.id = rn.user_id
GROUP BY u.id, u.email, u.referral_code, u.account_type, up.points_total, up.referrals_count, up.level
ORDER BY up.points_total DESC NULLS LAST
LIMIT 10;


-- ============================================================================
-- QUERY 12: Verifica integrità dati
-- ============================================================================
-- Controlla se ci sono discrepanze tra referral_network e user_points
SELECT 
  'Data Integrity Check' as check_type,
  COUNT(*) as total_checks,
  SUM(CASE WHEN points_match THEN 1 ELSE 0 END) as passed,
  SUM(CASE WHEN NOT points_match THEN 1 ELSE 0 END) as failed
FROM (
  SELECT 
    rn.user_id,
    SUM(rn.points_awarded) as calculated_points,
    up.points_total as recorded_points,
    SUM(rn.points_awarded) = up.points_total as points_match
  FROM referral_network rn
  LEFT JOIN user_points up ON rn.user_id = up.user_id
  GROUP BY rn.user_id, up.points_total
) integrity_check;


-- ============================================================================
-- FINE TEST
-- ============================================================================
SELECT 
  '✅ Sistema MLM test queries pronte!' as status,
  'Esegui queste query per verificare il funzionamento' as instructions;
