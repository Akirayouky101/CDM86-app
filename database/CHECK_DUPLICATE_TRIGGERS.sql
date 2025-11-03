-- Verifica quanti trigger ci sono sulla tabella users
SELECT 
  tgname as trigger_name,
  tgenabled as enabled,
  tgtype,
  pg_get_triggerdef(oid) as definition
FROM pg_trigger
WHERE tgrelid = 'users'::regclass
AND tgname LIKE '%referral%'
ORDER BY tgname;

-- Verifica se ci sono trigger duplicati
SELECT 
  tgname,
  COUNT(*) as count
FROM pg_trigger
WHERE tgrelid = 'users'::regclass
GROUP BY tgname
HAVING COUNT(*) > 1;
