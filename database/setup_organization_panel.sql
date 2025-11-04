-- =====================================================
-- SETUP DATABASE PER PANNELLO AZIENDE
-- =====================================================

-- 1. Aggiungi campi alle aziende
ALTER TABLE organizations 
ADD COLUMN IF NOT EXISTS referral_code_external VARCHAR(20) UNIQUE;

ALTER TABLE organizations 
ADD COLUMN IF NOT EXISTS total_points INTEGER DEFAULT 0;

-- 2. Genera referral_code_external per aziende esistenti
UPDATE organizations 
SET referral_code_external = referral_code || '_EXT'
WHERE referral_code_external IS NULL;

-- 3. Aggiungi campi per distinguere dipendenti da esterni
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS is_employee BOOLEAN DEFAULT false;

ALTER TABLE users 
ADD COLUMN IF NOT EXISTS referred_by_organization_external BOOLEAN DEFAULT false;

-- 4. Crea tabella per benefit aziendali
CREATE TABLE IF NOT EXISTS organization_benefits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    points_required INTEGER NOT NULL,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 5. Crea indici per performance
CREATE INDEX IF NOT EXISTS idx_users_organization_employee 
ON users(organization_id, is_employee);

CREATE INDEX IF NOT EXISTS idx_org_benefits_active 
ON organization_benefits(organization_id, active);

-- 6. Verifica struttura
SELECT 
    'organizations' as tabella,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name = 'organizations'
AND column_name IN ('referral_code', 'referral_code_external', 'total_points')
ORDER BY ordinal_position;

-- 7. Mostra esempio azienda
SELECT 
    id,
    name,
    email,
    referral_code as "Codice Dipendenti",
    referral_code_external as "Codice Esterni",
    total_points
FROM organizations
LIMIT 1;