-- ============================================
-- SISTEMA AZIENDE E ASSOCIAZIONI
-- ============================================

-- STEP 1: Crea tabella organizations
-- ============================================
CREATE TABLE IF NOT EXISTS organizations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Tipo organizzazione
    organization_type VARCHAR(20) NOT NULL CHECK (organization_type IN ('company', 'association')),
    
    -- Dati base
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    
    -- Dati fiscali
    vat_number VARCHAR(50), -- Partita IVA per aziende
    tax_code VARCHAR(50), -- Codice fiscale per associazioni
    
    -- Indirizzo
    address TEXT,
    city VARCHAR(100),
    province VARCHAR(2),
    zip_code VARCHAR(10),
    phone VARCHAR(50),
    
    -- Sistema referral
    referral_code VARCHAR(10) UNIQUE NOT NULL, -- Codice da dare ai dipendenti
    referred_by_id UUID, -- Se l'organizzazione è stata invitata da qualcuno (user o altra org)
    
    -- Statistiche
    points INTEGER DEFAULT 0,
    employees_count INTEGER DEFAULT 0, -- Contatore dipendenti registrati
    
    -- Stato
    active BOOLEAN DEFAULT true,
    
    -- Timestamp
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Indici per performance
CREATE INDEX idx_organizations_referral_code ON organizations(referral_code);
CREATE INDEX idx_organizations_email ON organizations(email);
CREATE INDEX idx_organizations_type ON organizations(organization_type);

-- STEP 2: Aggiorna tabella users
-- ============================================
-- Aggiungi colonna per collegare utenti alle organizzazioni
ALTER TABLE users ADD COLUMN IF NOT EXISTS organization_id UUID REFERENCES organizations(id);

-- Indice per performance
CREATE INDEX IF NOT EXISTS idx_users_organization_id ON users(organization_id);

-- STEP 3: Funzione per generare referral code organizzazioni
-- ============================================
CREATE OR REPLACE FUNCTION generate_organization_referral_code()
RETURNS VARCHAR(10) AS $$
DECLARE
    new_code VARCHAR(10);
    code_exists BOOLEAN;
    prefix VARCHAR(3);
BEGIN
    LOOP
        -- Prefisso ORG per distinguere dalle persone
        prefix := 'ORG';
        -- 4 numeri casuali
        new_code := prefix || lpad(floor(random() * 10000)::text, 4, '0');
        
        -- Verifica che non esista già
        SELECT EXISTS(
            SELECT 1 FROM organizations WHERE referral_code = new_code
        ) INTO code_exists;
        
        EXIT WHEN NOT code_exists;
    END LOOP;
    RETURN new_code;
END;
$$ LANGUAGE plpgsql;

-- STEP 4: Trigger per auto-generare referral code
-- ============================================
CREATE OR REPLACE FUNCTION handle_new_organization()
RETURNS TRIGGER AS $$
BEGIN
    -- Se non ha referral_code, ne genera uno
    IF NEW.referral_code IS NULL OR NEW.referral_code = '' THEN
        NEW.referral_code := generate_organization_referral_code();
    END IF;
    
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_organization_created ON organizations;
CREATE TRIGGER on_organization_created
    BEFORE INSERT ON organizations
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_organization();

-- STEP 5: Trigger per aggiornare employees_count
-- ============================================
CREATE OR REPLACE FUNCTION update_organization_employees_count()
RETURNS TRIGGER AS $$
BEGIN
    -- Quando un utente viene aggiunto/rimosso da un'organizzazione
    IF TG_OP = 'INSERT' AND NEW.organization_id IS NOT NULL THEN
        UPDATE organizations 
        SET employees_count = employees_count + 1,
            updated_at = NOW()
        WHERE id = NEW.organization_id;
    ELSIF TG_OP = 'UPDATE' THEN
        -- Rimosso da vecchia organizzazione
        IF OLD.organization_id IS NOT NULL AND NEW.organization_id IS NULL THEN
            UPDATE organizations 
            SET employees_count = employees_count - 1,
                updated_at = NOW()
            WHERE id = OLD.organization_id;
        END IF;
        -- Aggiunto a nuova organizzazione
        IF OLD.organization_id IS NULL AND NEW.organization_id IS NOT NULL THEN
            UPDATE organizations 
            SET employees_count = employees_count + 1,
                updated_at = NOW()
            WHERE id = NEW.organization_id;
        END IF;
        -- Cambiato organizzazione
        IF OLD.organization_id IS NOT NULL AND NEW.organization_id IS NOT NULL 
           AND OLD.organization_id != NEW.organization_id THEN
            UPDATE organizations 
            SET employees_count = employees_count - 1,
                updated_at = NOW()
            WHERE id = OLD.organization_id;
            UPDATE organizations 
            SET employees_count = employees_count + 1,
                updated_at = NOW()
            WHERE id = NEW.organization_id;
        END IF;
    ELSIF TG_OP = 'DELETE' AND OLD.organization_id IS NOT NULL THEN
        UPDATE organizations 
        SET employees_count = employees_count - 1,
            updated_at = NOW()
        WHERE id = OLD.organization_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_user_organization_changed ON users;
CREATE TRIGGER on_user_organization_changed
    AFTER INSERT OR UPDATE OR DELETE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_organization_employees_count();

-- STEP 6: Crea organizzazione di test
-- ============================================
INSERT INTO organizations (
    organization_type,
    name,
    email,
    vat_number,
    address,
    city,
    province,
    zip_code,
    phone,
    referral_code,
    active
) VALUES (
    'company',
    'CDM86 SRL',
    'info@cdm86.com',
    '12345678901',
    'Via Roma 123',
    'Milano',
    'MI',
    '20100',
    '+39 02 1234567',
    'ORG0001',
    true
) ON CONFLICT (email) DO NOTHING;

-- STEP 7: Verifica
-- ============================================
SELECT 
    'TABELLE CREATE!' as status,
    (SELECT COUNT(*) FROM organizations) as organizations_count,
    (SELECT COUNT(*) FROM users WHERE organization_id IS NOT NULL) as users_with_org_count;

-- Mostra organizzazione di test
SELECT 
    id,
    organization_type,
    name,
    email,
    referral_code,
    employees_count,
    created_at
FROM organizations
WHERE email = 'info@cdm86.com';
