-- =====================================================
-- TABELLA PAGAMENTI E ABBONAMENTI
-- =====================================================

-- 1. Tabella pagamenti
CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    organization_id UUID REFERENCES organizations(id) ON DELETE SET NULL,
    stripe_payment_id VARCHAR(255) UNIQUE,
    stripe_customer_id VARCHAR(255),
    amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'EUR',
    status VARCHAR(50) DEFAULT 'pending', -- pending, completed, failed, refunded
    payment_type VARCHAR(50), -- subscription, one_time, benefit
    description TEXT,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 2. Tabella abbonamenti
CREATE TABLE IF NOT EXISTS subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    stripe_subscription_id VARCHAR(255) UNIQUE,
    stripe_customer_id VARCHAR(255),
    plan_type VARCHAR(50) NOT NULL, -- basic, premium, enterprise
    price DECIMAL(10, 2) NOT NULL,
    status VARCHAR(50) DEFAULT 'active', -- active, cancelled, expired
    current_period_start TIMESTAMP,
    current_period_end TIMESTAMP,
    cancel_at_period_end BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 3. Tabella piani disponibili
CREATE TABLE IF NOT EXISTS subscription_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'EUR',
    billing_period VARCHAR(20) DEFAULT 'monthly', -- monthly, yearly
    features JSONB,
    stripe_price_id VARCHAR(255),
    active BOOLEAN DEFAULT true,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
);

-- 4. Inserisci piani base
INSERT INTO subscription_plans (name, description, price, billing_period, features, sort_order) VALUES
('Free', 'Piano base gratuito', 0.00, 'monthly', '{"max_referrals": 5, "support": false}', 1),
('Basic', 'Piano mensile', 9.99, 'monthly', '{"max_referrals": -1, "support": "email", "benefits": true}', 2),
('Premium', 'Piano annuale (2 mesi gratis)', 99.99, 'yearly', '{"max_referrals": -1, "support": "priority", "benefits": true, "analytics": true}', 3)
ON CONFLICT DO NOTHING;

-- 5. Indici per performance
CREATE INDEX IF NOT EXISTS idx_payments_user ON payments(user_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);
CREATE INDEX IF NOT EXISTS idx_subscriptions_user ON subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON subscriptions(status);

-- 6. Trigger per aggiornare updated_at
CREATE OR REPLACE FUNCTION update_payment_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_payment_timestamp
BEFORE UPDATE ON payments
FOR EACH ROW
EXECUTE FUNCTION update_payment_timestamp();

CREATE TRIGGER trigger_update_subscription_timestamp
BEFORE UPDATE ON subscriptions
FOR EACH ROW
EXECUTE FUNCTION update_payment_timestamp();

-- 7. Verifica tabelle create
SELECT 
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count
FROM information_schema.tables t
WHERE table_schema = 'public'
AND table_name IN ('payments', 'subscriptions', 'subscription_plans')
ORDER BY table_name;