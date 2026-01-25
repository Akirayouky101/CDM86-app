-- Verifica utenti collegati all'organizzazione Barbell bello
SELECT 
  u.id,
  u.email,
  u.first_name,
  u.last_name,
  u.referred_by_organization_id,
  o.name as organization_name,
  u.created_at
FROM users u
LEFT JOIN organizations o ON u.referred_by_organization_id = o.id
WHERE u.referred_by_organization_id = '4719b5ea-18f2-47cf-9967-1cac5e8b36c7'
ORDER BY u.created_at DESC;

-- Mostra anche l'organizzazione
SELECT 
  id,
  name,
  referral_code,
  referral_code_employees,
  referral_code_external
FROM organizations
WHERE id = '4719b5ea-18f2-47cf-9967-1cac5e8b36c7';
