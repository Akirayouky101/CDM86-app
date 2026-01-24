-- Verifica rete MLM per Mario Rossi
SELECT 
  '=== UTENTI REFERENZIATI ===' as section;

SELECT 
  id,
  email,
  first_name,
  last_name,
  referral_code,
  created_at
FROM users
WHERE referred_by_id = '293caa0f-f12c-4cde-81ba-26da97f2f13e'
ORDER BY created_at DESC;

SELECT 
  '=== ORGANIZZAZIONI REFERENZIATE ===' as section;

SELECT 
  id,
  name,
  email,
  active,
  referral_code,
  referred_by_user_id,
  created_at
FROM organizations
WHERE referred_by_user_id = '293caa0f-f12c-4cde-81ba-26da97f2f13e'
ORDER BY created_at DESC;

SELECT 
  '=== TOTALE RETE ===' as section;

SELECT 
  (SELECT COUNT(*) FROM users WHERE referred_by_id = '293caa0f-f12c-4cde-81ba-26da97f2f13e') as utenti_referenziati,
  (SELECT COUNT(*) FROM organizations WHERE referred_by_user_id = '293caa0f-f12c-4cde-81ba-26da97f2f13e' AND active = true) as organizzazioni_attive,
  (SELECT COUNT(*) FROM users WHERE referred_by_id = '293caa0f-f12c-4cde-81ba-26da97f2f13e') + 
  (SELECT COUNT(*) FROM organizations WHERE referred_by_user_id = '293caa0f-f12c-4cde-81ba-26da97f2f13e' AND active = true) as totale_rete;
