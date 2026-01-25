-- =====================================================
-- SISTEMA COMMISSIONI AZIENDE - LIVELLO 1 (DIRETTI)
-- =====================================================

-- 1. Crea tabella commissioni
CREATE TABLE IF NOT EXISTS commissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    referred_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    referred_organization_id UUID REFERENCES organizations(id) ON DELETE SET NULL,
    referral_level INTEGER NOT NULL DEFAULT 1, -- 1 = diretto, 2 = indiretto (futuro)
    referred_type VARCHAR(20) NOT NULL, -- 'user' o 'organization'
    amount DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'approved', 'paid'
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    paid_at TIMESTAMP,
    
    -- Constraints
    CONSTRAINT valid_referred CHECK (
        (referred_user_id IS NOT NULL AND referred_organization_id IS NULL) OR
        (referred_user_id IS NULL AND referred_organization_id IS NOT NULL)
    ),
    CONSTRAINT valid_type CHECK (referred_type IN ('user', 'organization')),
    CONSTRAINT valid_status CHECK (status IN ('pending', 'approved', 'paid', 'cancelled')),
    CONSTRAINT positive_amount CHECK (amount > 0)
);

-- 2. Indici per performance
CREATE INDEX IF NOT EXISTS idx_commissions_organization ON commissions(organization_id);
CREATE INDEX IF NOT EXISTS idx_commissions_status ON commissions(status);
CREATE INDEX IF NOT EXISTS idx_commissions_created ON commissions(created_at);
CREATE INDEX IF NOT EXISTS idx_commissions_referred_user ON commissions(referred_user_id);

-- 3. Aggiungi colonna balance alle organizzazioni (saldo guadagni)
ALTER TABLE organizations 
ADD COLUMN IF NOT EXISTS commission_balance DECIMAL(10,2) DEFAULT 0.00;

-- 4. Crea funzione per calcolare commissione automatica
CREATE OR REPLACE FUNCTION calculate_direct_commission()
RETURNS TRIGGER AS $$
DECLARE
    v_org_id UUID;
    v_commission_amount DECIMAL(10,2);
BEGIN
    -- Solo per utenti normali (non organizzazioni)
    -- Se l'utente ha been referito da un'organizzazione
    IF NEW.referred_by_organization_id IS NOT NULL THEN
        
        v_org_id := NEW.referred_by_organization_id;
        
        -- Commissione per utente diretto = €2
        v_commission_amount := 2.00;
        
        -- Crea record commissione
        INSERT INTO commissions (
            organization_id,
            referred_user_id,
            referral_level,
            referred_type,
            amount,
            status,
            notes
        ) VALUES (
            v_org_id,
            NEW.id,
            1, -- Livello 1 (diretto)
            'user',
            v_commission_amount,
            'pending',
            'Commissione automatica per utente diretto'
        );
        
        -- Aggiorna saldo organizzazione
        UPDATE organizations
        SET commission_balance = commission_balance + v_commission_amount
        WHERE id = v_org_id;
        
        RAISE LOG 'Commission created: Org % earned €% for user %', v_org_id, v_commission_amount, NEW.id;
        
    END IF;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE LOG 'Error in calculate_direct_commission: %', SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Crea trigger per commissioni automatiche
DROP TRIGGER IF EXISTS on_user_referred_commission ON users;

CREATE TRIGGER on_user_referred_commission
    AFTER INSERT ON users
    FOR EACH ROW
    WHEN (NEW.referred_by_organization_id IS NOT NULL)
    EXECUTE FUNCTION calculate_direct_commission();

-- 6. Funzione per approvare commissione (admin)
CREATE OR REPLACE FUNCTION approve_commission(commission_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE commissions
    SET status = 'approved'
    WHERE id = commission_id AND status = 'pending';
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Funzione per marcare commissione come pagata
CREATE OR REPLACE FUNCTION mark_commission_paid(commission_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE commissions
    SET 
        status = 'paid',
        paid_at = NOW()
    WHERE id = commission_id AND status = 'approved';
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. View per statistiche commissioni per organizzazione
CREATE OR REPLACE VIEW organization_commission_stats AS
SELECT 
    o.id as organization_id,
    o.name as organization_name,
    o.commission_balance,
    COUNT(c.id) as total_commissions,
    COUNT(CASE WHEN c.status = 'pending' THEN 1 END) as pending_count,
    COUNT(CASE WHEN c.status = 'approved' THEN 1 END) as approved_count,
    COUNT(CASE WHEN c.status = 'paid' THEN 1 END) as paid_count,
    COALESCE(SUM(c.amount), 0) as total_earned,
    COALESCE(SUM(CASE WHEN c.status = 'pending' THEN c.amount ELSE 0 END), 0) as pending_amount,
    COALESCE(SUM(CASE WHEN c.status = 'approved' THEN c.amount ELSE 0 END), 0) as approved_amount,
    COALESCE(SUM(CASE WHEN c.status = 'paid' THEN c.amount ELSE 0 END), 0) as paid_amount
FROM organizations o
LEFT JOIN commissions c ON o.id = c.organization_id
GROUP BY o.id, o.name, o.commission_balance;

-- 9. Crea commissione per Diego Marruchi (già esistente)
-- Questo utente era già stato registrato con Barbell bello
INSERT INTO commissions (
    organization_id,
    referred_user_id,
    referral_level,
    referred_type,
    amount,
    status,
    notes,
    created_at
)
SELECT 
    '4719b5ea-18f2-47cf-9967-1cac5e8b36c7'::UUID, -- Barbell bello
    'a4b279cf-b71e-4c66-9fd3-419a195aac02'::UUID, -- Diego
    1,
    'user',
    2.00,
    'pending',
    'Commissione retroattiva per utente già registrato',
    (SELECT created_at FROM users WHERE id = 'a4b279cf-b71e-4c66-9fd3-419a195aac02')
WHERE NOT EXISTS (
    SELECT 1 FROM commissions 
    WHERE referred_user_id = 'a4b279cf-b71e-4c66-9fd3-419a195aac02'
);

-- 10. Aggiorna saldo Barbell bello
UPDATE organizations
SET commission_balance = (
    SELECT COALESCE(SUM(amount), 0) 
    FROM commissions 
    WHERE organization_id = organizations.id
)
WHERE id = '4719b5ea-18f2-47cf-9967-1cac5e8b36c7';

-- =====================================================
-- QUERY DI VERIFICA
-- =====================================================

-- Verifica tabella commissioni
SELECT * FROM commissions ORDER BY created_at DESC;

-- Verifica statistiche Barbell bello
SELECT * FROM organization_commission_stats 
WHERE organization_name = 'Barbell bello';

-- Verifica saldo organizzazioni
SELECT 
    id,
    name,
    commission_balance,
    created_at
FROM organizations
ORDER BY commission_balance DESC;
