-- =====================================================
-- Aggiungi 2 codici referral separati per organizations
-- =====================================================

-- 1. Aggiungi colonne per i due codici referral
ALTER TABLE organizations
ADD COLUMN IF NOT EXISTS referral_code_employees VARCHAR(20) UNIQUE,
ADD COLUMN IF NOT EXISTS referral_code_external VARCHAR(20) UNIQUE;

-- 2. Genera codici per organizations esistenti (se non presenti)
UPDATE organizations
SET 
  referral_code_employees = UPPER(substring(md5(random()::text || id::text || 'emp') from 1 for 8)),
  referral_code_external = UPPER(substring(md5(random()::text || id::text || 'ext') from 1 for 8))
WHERE referral_code_employees IS NULL OR referral_code_external IS NULL;

-- 3. Crea indici per performance
CREATE INDEX IF NOT EXISTS idx_org_referral_employees 
ON organizations(referral_code_employees);

CREATE INDEX IF NOT EXISTS idx_org_referral_external 
ON organizations(referral_code_external);

-- 4. Aggiungi colonna per tracciare il tipo di referral nell'utente
ALTER TABLE users
ADD COLUMN IF NOT EXISTS referral_type VARCHAR(20);

-- Valori possibili: 'user', 'org_employee', 'org_external'

-- 5. Verifica
SELECT 
  name,
  referral_code as codice_base,
  referral_code_employees as codice_dipendenti,
  referral_code_external as codice_esterni
FROM organizations
WHERE referral_code_employees IS NOT NULL
LIMIT 5;
