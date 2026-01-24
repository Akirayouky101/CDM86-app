-- =====================================================
-- MIGRAZIONE: Collega company_reports a organizations
-- =====================================================
-- Aggiunge colonna organization_id per tracciare quando
-- una segnalazione approvata genera un'organization
-- =====================================================

-- Aggiungi colonna organization_id
ALTER TABLE company_reports
ADD COLUMN IF NOT EXISTS organization_id UUID REFERENCES organizations(id) ON DELETE SET NULL;

-- Indice per performance
CREATE INDEX IF NOT EXISTS idx_company_reports_organization_id 
ON company_reports(organization_id);

-- Commento
COMMENT ON COLUMN company_reports.organization_id IS 
  'ID dell''organization creata quando la segnalazione viene approvata (se non esisteva già)';

-- Log successo
SELECT '✅ Colonna organization_id aggiunta a company_reports!' as status;
