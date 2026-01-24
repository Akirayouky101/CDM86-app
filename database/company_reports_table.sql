-- =====================================================
-- TABELLA SEGNALAZIONI AZIENDE (COMPANY REPORTS)
-- =====================================================
-- Questa tabella memorizza le segnalazioni di aziende/associazioni
-- fatte dagli utenti, con tutti i dati del sondaggio e il referral dell'utente

CREATE TABLE IF NOT EXISTS company_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Chi ha fatto la segnalazione (collegato al referral)
    reported_by_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    reported_by_referral_code VARCHAR(20) NOT NULL,
    
    -- Dati Azienda (Step 1)
    company_name VARCHAR(255) NOT NULL,
    contact_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(50) NOT NULL,
    address TEXT NOT NULL,
    
    -- Sondaggio (Step 2)
    sector VARCHAR(100) NOT NULL,
    company_aware BOOLEAN NOT NULL DEFAULT false,
    who_knows VARCHAR(100) NOT NULL,
    preferred_call_time VARCHAR(50) NOT NULL,
    
    -- Status e Metadati
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'contacted', 'approved', 'rejected')),
    admin_notes TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indici per performance
CREATE INDEX idx_company_reports_user ON company_reports(reported_by_user_id);
CREATE INDEX idx_company_reports_referral ON company_reports(reported_by_referral_code);
CREATE INDEX idx_company_reports_status ON company_reports(status);
CREATE INDEX idx_company_reports_created ON company_reports(created_at DESC);

-- RLS Policy: Users can see only their own reports
ALTER TABLE company_reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own reports"
    ON company_reports FOR SELECT
    USING (auth.uid() = reported_by_user_id);

CREATE POLICY "Users can insert own reports"
    ON company_reports FOR INSERT
    WITH CHECK (auth.uid() = reported_by_user_id);

-- Admins can see all reports
CREATE POLICY "Admins can view all reports"
    ON company_reports FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.auth_id = auth.uid()
            AND users.role = 'admin'
        )
    );

CREATE POLICY "Admins can update all reports"
    ON company_reports FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.auth_id = auth.uid()
            AND users.role = 'admin'
        )
    );

-- Trigger per updated_at
CREATE OR REPLACE FUNCTION update_company_reports_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_company_reports_timestamp
    BEFORE UPDATE ON company_reports
    FOR EACH ROW
    EXECUTE FUNCTION update_company_reports_updated_at();

-- Grant permissions
GRANT SELECT, INSERT ON company_reports TO authenticated;
GRANT ALL ON company_reports TO service_role;
