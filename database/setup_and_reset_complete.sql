-- =====================================================
-- PROCEDURA COMPLETA: Reset + Setup Password System
-- =====================================================

-- STEP 1: Crea tabella password temporanee
CREATE TABLE IF NOT EXISTS organization_temp_passwords (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  temp_password TEXT NOT NULL,
  email_sent BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() + INTERVAL '7 days'
);

CREATE INDEX IF NOT EXISTS idx_org_temp_passwords_org_id 
  ON organization_temp_passwords(organization_id);

-- STEP 2: Reset tutti i dati di test
DELETE FROM organization_temp_passwords;
DELETE FROM organizations WHERE referred_by_user_id IS NOT NULL;
DELETE FROM company_reports;
DELETE FROM points_transactions;
UPDATE user_points SET points_total = 0, points_available = 0, approved_reports_count = 0, rejected_reports_count = 0, updated_at = NOW();

-- STEP 3: Verifica reset
SELECT 'Setup completato! Ora segnala una nuova azienda e approvala.' as status;

SELECT 
  (SELECT COUNT(*) FROM organization_temp_passwords) as password_salvate,
  (SELECT COUNT(*) FROM organizations WHERE referred_by_user_id IS NOT NULL) as organizations_create,
  (SELECT COUNT(*) FROM company_reports) as segnalazioni,
  (SELECT COUNT(*) FROM points_transactions) as transazioni;

-- Dovresti vedere tutti 0
-- Ora vai sulla dashboard, segnala un'azienda, vai su admin panel e approvala
-- Poi torna qui ed esegui la query sotto per vedere la password!

/*
-- QUERY PER VEDERE LA PASSWORD DOPO L'APPROVAZIONE:
SELECT 
  o.name AS "Nome Azienda",
  o.email AS "Email Login",
  otp.temp_password AS "PASSWORD",
  o.referral_code AS "Codice Referral",
  otp.created_at AS "Creata il"
FROM organization_temp_passwords otp
JOIN organizations o ON o.id = otp.organization_id
ORDER BY otp.created_at DESC
LIMIT 1;
*/
