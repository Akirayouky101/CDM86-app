-- ============================================
-- SISTEMA RICHIESTE CODICE CONTRATTO ORGANIZZAZIONI
-- ============================================

-- STEP 1: Crea tabella organization_requests
-- ============================================
CREATE TABLE IF NOT EXISTS organization_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Chi ha invitato (referral)
    referred_by_id UUID NOT NULL, -- ID dell'utente o organizzazione che ha fornito il codice d'invito
    referred_by_code VARCHAR(10) NOT NULL, -- Codice referral usato
    
    -- Dati organizzazione richiedente
    organization_name VARCHAR(255) NOT NULL,
    organization_type VARCHAR(20), -- 'company' o 'association' (se specificato)
    
    -- Dati referente
    contact_first_name VARCHAR(100) NOT NULL,
    contact_last_name VARCHAR(100) NOT NULL,
    contact_email VARCHAR(255) NOT NULL,
    contact_phone VARCHAR(50) NOT NULL,
    
    -- Status
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'completed')),
    contract_code VARCHAR(10), -- Codice contratto assegnato dall'admin
    
    -- Note admin
    admin_notes TEXT,
    
    -- Timestamp
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    approved_at TIMESTAMP,
    completed_at TIMESTAMP
);

-- Indici per performance
CREATE INDEX idx_org_requests_referred_by ON organization_requests(referred_by_id);
CREATE INDEX idx_org_requests_status ON organization_requests(status);
CREATE INDEX idx_org_requests_created ON organization_requests(created_at DESC);

-- STEP 2: Funzione per contare segnalazioni per utente
-- ============================================
CREATE OR REPLACE FUNCTION get_user_organization_referrals(user_id UUID)
RETURNS TABLE (
    total_requests BIGINT,
    pending_requests BIGINT,
    approved_requests BIGINT,
    completed_requests BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::BIGINT as total_requests,
        COUNT(*) FILTER (WHERE status = 'pending')::BIGINT as pending_requests,
        COUNT(*) FILTER (WHERE status = 'approved')::BIGINT as approved_requests,
        COUNT(*) FILTER (WHERE status = 'completed')::BIGINT as completed_requests
    FROM organization_requests
    WHERE referred_by_id = user_id;
END;
$$ LANGUAGE plpgsql;

-- STEP 3: View per admin con dettagli completi
-- ============================================
CREATE OR REPLACE VIEW admin_organization_requests AS
SELECT 
    r.id,
    r.organization_name,
    r.organization_type,
    r.contact_first_name,
    r.contact_last_name,
    r.contact_email,
    r.contact_phone,
    r.referred_by_code,
    r.status,
    r.contract_code,
    r.admin_notes,
    r.created_at,
    r.updated_at,
    -- Dettagli chi ha invitato (utente)
    u.first_name as referrer_first_name,
    u.last_name as referrer_last_name,
    u.email as referrer_email,
    'user' as referrer_type,
    -- Dettagli chi ha invitato (organizzazione)
    o.name as referrer_org_name,
    o.email as referrer_org_email,
    CASE WHEN o.id IS NOT NULL THEN 'organization' ELSE 'user' END as actual_referrer_type
FROM organization_requests r
LEFT JOIN users u ON r.referred_by_id = u.id
LEFT JOIN organizations o ON r.referred_by_id = o.id
ORDER BY r.created_at DESC;

-- STEP 4: Trigger per aggiornare updated_at
-- ============================================
CREATE OR REPLACE FUNCTION update_organization_request_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    
    -- Se lo status cambia in approved, salva il timestamp
    IF NEW.status = 'approved' AND OLD.status != 'approved' THEN
        NEW.approved_at = NOW();
    END IF;
    
    -- Se lo status cambia in completed, salva il timestamp
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        NEW.completed_at = NOW();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_organization_request_updated ON organization_requests;
CREATE TRIGGER on_organization_request_updated
    BEFORE UPDATE ON organization_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_organization_request_timestamp();

-- STEP 5: Funzione per creare richiesta (da usare nel form)
-- ============================================
CREATE OR REPLACE FUNCTION create_organization_request(
    p_referred_by_code VARCHAR(10),
    p_organization_name VARCHAR(255),
    p_contact_first_name VARCHAR(100),
    p_contact_last_name VARCHAR(100),
    p_contact_email VARCHAR(255),
    p_contact_phone VARCHAR(50)
) RETURNS UUID AS $$
DECLARE
    v_referred_by_id UUID;
    v_request_id UUID;
BEGIN
    -- Find referrer ID from code (check both users and organizations)
    SELECT id INTO v_referred_by_id FROM users WHERE referral_code = p_referred_by_code;
    
    IF v_referred_by_id IS NULL THEN
        SELECT id INTO v_referred_by_id FROM organizations WHERE referral_code = p_referred_by_code;
    END IF;
    
    IF v_referred_by_id IS NULL THEN
        RAISE EXCEPTION 'Invalid referral code';
    END IF;
    
    -- Create request
    INSERT INTO organization_requests (
        referred_by_id,
        referred_by_code,
        organization_name,
        contact_first_name,
        contact_last_name,
        contact_email,
        contact_phone
    ) VALUES (
        v_referred_by_id,
        p_referred_by_code,
        p_organization_name,
        p_contact_first_name,
        p_contact_last_name,
        p_contact_email,
        p_contact_phone
    ) RETURNING id INTO v_request_id;
    
    RETURN v_request_id;
END;
$$ LANGUAGE plpgsql;

-- STEP 6: Verifica
-- ============================================
SELECT 
    'TABELLA ORGANIZATION_REQUESTS CREATA!' as status,
    (SELECT COUNT(*) FROM organization_requests) as requests_count;
