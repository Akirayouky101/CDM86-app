-- =====================================================
-- MIGRAZIONE: Aggiungi campo company_type e compensation_amount
-- =====================================================
-- Esegui questo script su Supabase per aggiungere i nuovi campi
-- NOTA: Usa questo SOLO se la tabella company_reports esiste già

-- Aggiungi la colonna company_type
ALTER TABLE company_reports
ADD COLUMN IF NOT EXISTS company_type VARCHAR(20) NOT NULL DEFAULT 'partner'
CHECK (company_type IN ('inserzionista', 'partner', 'associazione'));

-- Aggiungi la colonna compensation_amount per tracciare compensi
ALTER TABLE company_reports
ADD COLUMN IF NOT EXISTS compensation_amount DECIMAL(10,2) DEFAULT 0.00;

-- Aggiungi colonna per tracciare punti assegnati
ALTER TABLE company_reports
ADD COLUMN IF NOT EXISTS points_awarded INTEGER DEFAULT 0;

-- Commenti descrittivi
COMMENT ON COLUMN company_reports.company_type IS 'Tipo di azienda: inserzionista (compenso 30€ + 1 punto), partner (1 punto), associazione (1 punto)';
COMMENT ON COLUMN company_reports.compensation_amount IS 'Compenso economico assegnato quando approvata (30€ per inserzionista, 0€ per partner/associazione)';
COMMENT ON COLUMN company_reports.points_awarded IS 'Punti assegnati all''utente quando segnalazione approvata (sempre 1 punto)';

-- Log
SELECT '✅ Campi company_type, compensation_amount, points_awarded aggiunti con successo!' as status;
