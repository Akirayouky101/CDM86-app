-- Verifica organizzazione creata
SELECT 
  id,
  name,
  email,
  referral_code,
  referred_by_user_id,
  active,
  created_at
FROM organizations
WHERE email = 'info@zgimpiantisrl.it'
   OR name ILIKE '%ZG Impianti%';
