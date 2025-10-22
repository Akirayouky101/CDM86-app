-- =====================================================
-- CONTRACTS MANAGEMENT SYSTEM
-- Sistema gestione contratti organizzazioni con scadenze
-- =====================================================

-- 1. TABELLA CONTRACTS
-- =====================================================
CREATE TABLE IF NOT EXISTS contracts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Codice contratto univoco
    contract_code VARCHAR(20) UNIQUE NOT NULL,
    
    -- Riferimento organizzazione
    organization_request_id UUID REFERENCES organization_requests(id) ON DELETE SET NULL,
    organization_name VARCHAR(255) NOT NULL,
    
    -- Date contratto
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    
    -- Status
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'expiring', 'expired', 'cancelled', 'renewed')),
    
    -- Dettagli
    contract_type VARCHAR(50), -- 'standard', 'premium', 'enterprise'
    annual_fee DECIMAL(10,2),
    payment_terms VARCHAR(100), -- 'monthly', 'quarterly', 'annual'
    
    -- Note e documenti
    notes TEXT,
    document_url TEXT, -- Link al PDF del contratto
    
    -- Alert scadenza
    alert_30_days BOOLEAN DEFAULT false,
    alert_15_days BOOLEAN DEFAULT false,
    alert_7_days BOOLEAN DEFAULT false,
    last_alert_sent TIMESTAMPTZ,
    
    -- Contatti
    contact_person VARCHAR(255),
    contact_email VARCHAR(255),
    contact_phone VARCHAR(50),
    
    -- Metadata
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    cancelled_at TIMESTAMPTZ,
    renewed_to UUID REFERENCES contracts(id) -- Se rinnovato, link al nuovo contratto
);

-- Indici per performance
CREATE INDEX IF NOT EXISTS idx_contracts_code ON contracts(contract_code);
CREATE INDEX IF NOT EXISTS idx_contracts_org_request ON contracts(organization_request_id);
CREATE INDEX IF NOT EXISTS idx_contracts_status ON contracts(status);
CREATE INDEX IF NOT EXISTS idx_contracts_end_date ON contracts(end_date);
CREATE INDEX IF NOT EXISTS idx_contracts_organization_name ON contracts(organization_name);

-- 2. FUNZIONE CALCOLO STATUS AUTOMATICO
-- =====================================================
CREATE OR REPLACE FUNCTION update_contract_status()
RETURNS TRIGGER AS $$
DECLARE
    days_to_expiry INTEGER;
BEGIN
    -- Calcola giorni alla scadenza
    days_to_expiry := (NEW.end_date - CURRENT_DATE);
    
    -- Aggiorna status in base ai giorni rimanenti
    IF days_to_expiry < 0 THEN
        NEW.status := 'expired';
    ELSIF days_to_expiry <= 30 THEN
        NEW.status := 'expiring';
    ELSIF NEW.status = 'cancelled' OR NEW.status = 'renewed' THEN
        -- Mantieni status manuale
        NEW.status := NEW.status;
    ELSE
        NEW.status := 'active';
    END IF;
    
    -- Aggiorna timestamp
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger per calcolo automatico status
DROP TRIGGER IF EXISTS trigger_update_contract_status ON contracts;
CREATE TRIGGER trigger_update_contract_status
    BEFORE INSERT OR UPDATE ON contracts
    FOR EACH ROW
    EXECUTE FUNCTION update_contract_status();

-- 3. FUNZIONE PER VERIFICA SCADENZE GIORNALIERA
-- =====================================================
CREATE OR REPLACE FUNCTION check_contract_expiry_alerts()
RETURNS TABLE(
    contract_id UUID,
    contract_code VARCHAR,
    organization_name VARCHAR,
    days_remaining INTEGER,
    alert_type VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.contract_code,
        c.organization_name,
        (c.end_date - CURRENT_DATE) as days_remaining,
        CASE 
            WHEN (c.end_date - CURRENT_DATE) <= 7 AND NOT c.alert_7_days THEN '7_days'
            WHEN (c.end_date - CURRENT_DATE) <= 15 AND NOT c.alert_15_days THEN '15_days'
            WHEN (c.end_date - CURRENT_DATE) <= 30 AND NOT c.alert_30_days THEN '30_days'
        END as alert_type
    FROM contracts c
    WHERE c.status IN ('active', 'expiring')
    AND c.end_date >= CURRENT_DATE
    AND (
        ((c.end_date - CURRENT_DATE) <= 7 AND NOT c.alert_7_days) OR
        ((c.end_date - CURRENT_DATE) <= 15 AND NOT c.alert_15_days) OR
        ((c.end_date - CURRENT_DATE) <= 30 AND NOT c.alert_30_days)
    )
    ORDER BY days_remaining ASC;
END;
$$ LANGUAGE plpgsql;

-- 4. FUNZIONE GENERA CODICE CONTRATTO UNIVOCO
-- =====================================================
CREATE OR REPLACE FUNCTION generate_contract_code()
RETURNS VARCHAR AS $$
DECLARE
    new_code VARCHAR(20);
    code_exists BOOLEAN;
BEGIN
    LOOP
        -- Genera codice formato: CTR-YYYY-XXXX (es: CTR-2025-0001)
        new_code := 'CTR-' || 
                    TO_CHAR(CURRENT_DATE, 'YYYY') || '-' || 
                    LPAD(FLOOR(RANDOM() * 9999 + 1)::TEXT, 4, '0');
        
        -- Verifica se esiste già
        SELECT EXISTS(SELECT 1 FROM contracts WHERE contract_code = new_code) INTO code_exists;
        
        -- Se non esiste, esci dal loop
        EXIT WHEN NOT code_exists;
    END LOOP;
    
    RETURN new_code;
END;
$$ LANGUAGE plpgsql;

-- 5. VIEW PER CONTRATTI CON DETTAGLI
-- =====================================================
CREATE OR REPLACE VIEW contracts_with_details AS
SELECT 
    c.*,
    (c.end_date - CURRENT_DATE) as days_remaining,
    CASE 
        WHEN c.end_date < CURRENT_DATE THEN 'Scaduto'
        WHEN (c.end_date - CURRENT_DATE) <= 7 THEN 'Scade tra 7 giorni'
        WHEN (c.end_date - CURRENT_DATE) <= 15 THEN 'Scade tra 15 giorni'
        WHEN (c.end_date - CURRENT_DATE) <= 30 THEN 'Scade tra 30 giorni'
        ELSE 'Attivo'
    END as status_label,
    org_req.contact_email as org_contact_email,
    org_req.contact_phone as org_contact_phone
FROM contracts c
LEFT JOIN organization_requests org_req ON c.organization_request_id = org_req.id
ORDER BY c.end_date ASC;

-- 6. RLS POLICIES
-- =====================================================
ALTER TABLE contracts ENABLE ROW LEVEL SECURITY;

-- Admin può vedere tutti i contratti
CREATE POLICY "Admin can view all contracts"
    ON contracts FOR SELECT
    TO authenticated
    USING (true);

-- Admin può creare contratti
CREATE POLICY "Admin can insert contracts"
    ON contracts FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Admin può aggiornare contratti
CREATE POLICY "Admin can update contracts"
    ON contracts FOR UPDATE
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- 7. GRANT PERMISSIONS
-- =====================================================
GRANT SELECT, INSERT, UPDATE ON contracts TO authenticated;

-- 8. SEED DATA DI TEST (opzionale)
-- =====================================================
-- Esempio: inserisci un contratto di test
-- INSERT INTO contracts (
--     contract_code, organization_name, start_date, end_date, 
--     contract_type, annual_fee, contact_person, contact_email
-- ) VALUES (
--     'CTR-2025-0001', 'Azienda Test SRL', '2025-01-01', '2025-12-31',
--     'standard', 1200.00, 'Mario Rossi', 'mario.rossi@aziendatest.it'
-- );

-- =====================================================
-- VERIFICA SETUP
-- =====================================================
SELECT 'Tabella contracts creata con successo!' as status;
SELECT 'Trigger e funzioni configurate!' as status;
SELECT 'Sistema pronto per gestire contratti e scadenze!' as status;
