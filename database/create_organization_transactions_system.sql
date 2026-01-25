-- =====================================================
-- SISTEMA TRANSAZIONI COMMISSIONI ORGANIZZAZIONI
-- Stesso schema di points_transactions per utenti
-- =====================================================

-- 1. Crea tabella organization_transactions (come points_transactions)
CREATE TABLE IF NOT EXISTS organization_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL,
    transaction_type VARCHAR(50) NOT NULL,
    description TEXT,
    referred_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    referred_organization_id UUID REFERENCES organizations(id) ON DELETE SET NULL,
    referral_level INTEGER, -- 1 = diretto, 2 = indiretto
    created_at TIMESTAMP DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id),
    
    -- Constraints
    CONSTRAINT valid_transaction_type CHECK (
        transaction_type IN (
            'referral_bonus',           -- Bonus per referral
            'referral_user_direct',     -- Utente diretto (€2)
            'referral_user_indirect',   -- Utente indiretto (€1)
            'referral_org_direct',      -- Organizzazione diretta
            'referral_org_indirect',    -- Organizzazione indiretta (€20)
            'admin_adjustment',         -- Aggiustamento admin
            'payout',                   -- Pagamento effettuato (negativo)
            'bonus',                    -- Bonus generico
            'penalty'                   -- Penalità (negativo)
        )
    )
);

-- 2. Indici per performance
CREATE INDEX IF NOT EXISTS idx_org_transactions_organization ON organization_transactions(organization_id);
CREATE INDEX IF NOT EXISTS idx_org_transactions_type ON organization_transactions(transaction_type);
CREATE INDEX IF NOT EXISTS idx_org_transactions_created ON organization_transactions(created_at);
CREATE INDEX IF NOT EXISTS idx_org_transactions_referred_user ON organization_transactions(referred_user_id);
CREATE INDEX IF NOT EXISTS idx_org_transactions_referred_org ON organization_transactions(referred_organization_id);

-- 3. Rimuovi vecchia colonna commission_balance (ora calcolato da transazioni)
ALTER TABLE organizations DROP COLUMN IF EXISTS commission_balance;

-- 4. Funzione per calcolare saldo totale (come getUserBalance)
CREATE OR REPLACE FUNCTION get_organization_balance(org_id UUID)
RETURNS DECIMAL(10,2) AS $$
DECLARE
    balance DECIMAL(10,2);
BEGIN
    SELECT COALESCE(SUM(amount), 0)
    INTO balance
    FROM organization_transactions
    WHERE organization_id = org_id;
    
    RETURN balance;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Trigger automatico per referral DIRETTO utente (€2)
CREATE OR REPLACE FUNCTION create_org_referral_transaction()
RETURNS TRIGGER AS $$
DECLARE
    v_org_id UUID;
    v_amount DECIMAL(10,2);
BEGIN
    -- Se utente referito da organizzazione
    IF NEW.referred_by_organization_id IS NOT NULL THEN
        v_org_id := NEW.referred_by_organization_id;
        v_amount := 2.00;
        
        -- Crea transazione
        INSERT INTO organization_transactions (
            organization_id,
            amount,
            transaction_type,
            description,
            referred_user_id,
            referral_level
        ) VALUES (
            v_org_id,
            v_amount,
            'referral_user_direct',
            'Commissione per utente diretto registrato',
            NEW.id,
            1
        );
        
        RAISE LOG 'Organization % earned €% for direct user referral %', v_org_id, v_amount, NEW.id;
    END IF;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE LOG 'Error in create_org_referral_transaction: %', SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Crea trigger
DROP TRIGGER IF EXISTS on_user_org_referral_transaction ON users;

CREATE TRIGGER on_user_org_referral_transaction
    AFTER INSERT ON users
    FOR EACH ROW
    WHEN (NEW.referred_by_organization_id IS NOT NULL)
    EXECUTE FUNCTION create_org_referral_transaction();

-- 7. View per statistiche organizzazione (come getUserStats)
CREATE OR REPLACE VIEW organization_transaction_stats AS
SELECT 
    o.id as organization_id,
    o.name as organization_name,
    o.email as organization_email,
    COALESCE(SUM(t.amount), 0) as total_balance,
    COUNT(t.id) as total_transactions,
    COUNT(CASE WHEN t.transaction_type LIKE 'referral%' THEN 1 END) as referral_count,
    COALESCE(SUM(CASE WHEN t.transaction_type LIKE 'referral%' THEN t.amount ELSE 0 END), 0) as referral_earnings,
    COALESCE(SUM(CASE WHEN t.transaction_type = 'payout' THEN t.amount ELSE 0 END), 0) as total_payouts,
    COALESCE(SUM(CASE WHEN t.transaction_type = 'admin_adjustment' THEN t.amount ELSE 0 END), 0) as admin_adjustments
FROM organizations o
LEFT JOIN organization_transactions t ON o.id = t.organization_id
GROUP BY o.id, o.name, o.email;

-- 8. Funzione per admin: aggiungere transazione manuale
CREATE OR REPLACE FUNCTION add_organization_transaction(
    p_organization_id UUID,
    p_amount DECIMAL(10,2),
    p_type VARCHAR(50),
    p_description TEXT DEFAULT NULL,
    p_admin_id UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_transaction_id UUID;
BEGIN
    INSERT INTO organization_transactions (
        organization_id,
        amount,
        transaction_type,
        description,
        created_by
    ) VALUES (
        p_organization_id,
        p_amount,
        p_type,
        p_description,
        p_admin_id
    )
    RETURNING id INTO v_transaction_id;
    
    RETURN v_transaction_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. Migra dati da vecchia tabella commissions a organization_transactions
INSERT INTO organization_transactions (
    organization_id,
    amount,
    transaction_type,
    description,
    referred_user_id,
    referred_organization_id,
    referral_level,
    created_at
)
SELECT 
    c.organization_id,
    c.amount,
    CASE 
        WHEN c.referred_type = 'user' AND c.referral_level = 1 THEN 'referral_user_direct'
        WHEN c.referred_type = 'user' AND c.referral_level = 2 THEN 'referral_user_indirect'
        WHEN c.referred_type = 'organization' AND c.referral_level = 1 THEN 'referral_org_direct'
        WHEN c.referred_type = 'organization' AND c.referral_level = 2 THEN 'referral_org_indirect'
        ELSE 'referral_bonus'
    END,
    COALESCE(c.notes, 'Migrazione da sistema commissioni legacy'),
    c.referred_user_id,
    c.referred_organization_id,
    c.referral_level,
    c.created_at
FROM commissions c
WHERE NOT EXISTS (
    SELECT 1 FROM organization_transactions ot
    WHERE ot.organization_id = c.organization_id
    AND ot.referred_user_id = c.referred_user_id
    AND ot.created_at = c.created_at
);

-- 10. DROP vecchia tabella commissions (ora obsoleta)
DROP TABLE IF EXISTS commissions CASCADE;
DROP VIEW IF EXISTS organization_commission_stats CASCADE;
DROP FUNCTION IF EXISTS calculate_direct_commission() CASCADE;
DROP FUNCTION IF EXISTS approve_commission(UUID) CASCADE;
DROP FUNCTION IF EXISTS mark_commission_paid(UUID) CASCADE;

-- =====================================================
-- QUERY DI VERIFICA
-- =====================================================

-- Verifica transazioni
SELECT 
    ot.*,
    o.name as org_name,
    u.email as referred_user_email
FROM organization_transactions ot
LEFT JOIN organizations o ON ot.organization_id = o.id
LEFT JOIN users u ON ot.referred_user_id = u.id
ORDER BY ot.created_at DESC;

-- Verifica statistiche Barbell bello
SELECT * FROM organization_transaction_stats 
WHERE organization_name = 'Barbell bello';

-- Verifica saldi organizzazioni
SELECT 
    id,
    name,
    get_organization_balance(id) as balance
FROM organizations
ORDER BY get_organization_balance(id) DESC;

-- Test aggiungere bonus manuale
-- SELECT add_organization_transaction(
--     '4719b5ea-18f2-47cf-9967-1cac5e8b36c7'::UUID,  -- Barbell bello
--     10.00,
--     'bonus',
--     'Bonus di benvenuto'
-- );
