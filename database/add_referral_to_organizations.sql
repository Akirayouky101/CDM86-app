-- =====================================================
-- MIGRAZIONE: Sistema Referral per Organizations
-- =====================================================
-- Aggiunge colonna per tracciare chi ha portato l'organization
-- =====================================================

-- Aggiungi colonna referred_by_id (riferimento a users)
ALTER TABLE organizations
ADD COLUMN IF NOT EXISTS referred_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL;

-- Indice per performance
CREATE INDEX IF NOT EXISTS idx_organizations_referred_by_user_id 
ON organizations(referred_by_user_id);

-- Commento
COMMENT ON COLUMN organizations.referred_by_user_id IS 
  'ID dell''utente che ha segnalato/portato questa organization (per MLM)';

-- Log successo
SELECT '✅ Colonna referred_by_user_id aggiunta a organizations!' as status;
