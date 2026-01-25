-- Aggiungi campo per tracciare il tipo di referral usato
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS referral_type VARCHAR(20);

-- Possibili valori: 'user', 'org_employee', 'org_external'
COMMENT ON COLUMN users.referral_type IS 'Tipo di referral usato: user (utente normale), org_employee (dipendente), org_external (membro esterno)';

-- Crea indice per performance
CREATE INDEX IF NOT EXISTS idx_users_referral_type 
ON users(referral_type);

-- Aggiorna l'utente esistente (Diego Marruchi) che ha usato il codice employees
UPDATE users 
SET referral_type = 'org_employee'
WHERE id = 'a4b279cf-b71e-4c66-9fd3-419a195aac02'
  AND referred_by_organization_id = '4719b5ea-18f2-47cf-9967-1cac5e8b36c7';

-- Verifica
SELECT 
    u.id,
    u.email,
    u.first_name,
    u.last_name,
    u.referred_by_organization_id,
    u.referral_type,
    o.name as organization_name
FROM users u
LEFT JOIN organizations o ON u.referred_by_organization_id = o.id
WHERE u.referred_by_organization_id IS NOT NULL;
