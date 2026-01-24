-- =====================================================
-- MIGRAZIONE: Aggiungi campi referral_given e email_consent
-- =====================================================
-- Esegui questo script su Supabase per aggiungere i nuovi campi
-- NOTA: Usa questo SOLO se la tabella company_reports esiste già

-- Aggiungi le nuove colonne
ALTER TABLE company_reports
ADD COLUMN IF NOT EXISTS referral_given BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE company_reports
ADD COLUMN IF NOT EXISTS email_consent BOOLEAN NOT NULL DEFAULT false;

-- Commenti descrittivi
COMMENT ON COLUMN company_reports.referral_given IS 'Indica se l''utente ha già comunicato il proprio referral code all''azienda';
COMMENT ON COLUMN company_reports.email_consent IS 'Indica se l''utente ha dato il consenso per inviare email informativa all''azienda';
