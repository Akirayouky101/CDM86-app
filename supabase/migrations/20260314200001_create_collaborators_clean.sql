-- ═══════════════════════════════════════════════════════════
-- SISTEMA COLLABORATORI CDM86 - VERSIONE PULITA
-- Esegui questo script nel Supabase SQL Editor
-- ═══════════════════════════════════════════════════════════

-- Pulizia tabelle esistenti parziali
DROP TABLE IF EXISTS collaborator_earnings CASCADE;
DROP TABLE IF EXISTS collaborator_bonus_rules CASCADE;
DROP TABLE IF EXISTS collaborator_settings CASCADE;
DROP TABLE IF EXISTS collaborators CASCADE;
DROP VIEW IF EXISTS admin_collaborators_view CASCADE;

-- 1. TABELLA COLLABORATORI
CREATE TABLE collaborators (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    auth_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    first_name TEXT,
    last_name TEXT,
    referral_code TEXT,
    status TEXT NOT NULL DEFAULT 'pending',
    notes TEXT,
    registered_at TIMESTAMPTZ DEFAULT now(),
    approved_at TIMESTAMPTZ,
    approved_by UUID,
    rate_user NUMERIC(10,2) DEFAULT 0.50,
    rate_azienda NUMERIC(10,2) DEFAULT 5.00,
    total_earned NUMERIC(10,2) DEFAULT 0,
    total_pending NUMERIC(10,2) DEFAULT 0,
    total_paid NUMERIC(10,2) DEFAULT 0,
    users_count INT DEFAULT 0,
    aziende_count INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 2. TABELLA GUADAGNI
CREATE TABLE collaborator_earnings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    collaborator_id UUID REFERENCES collaborators(id) ON DELETE CASCADE,
    referred_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    registration_type TEXT NOT NULL DEFAULT 'user',
    amount NUMERIC(10,2) NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'pending',
    credited_at TIMESTAMPTZ,
    paid_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 3. REGOLE BONUS
CREATE TABLE collaborator_bonus_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    valid_from TIMESTAMPTZ,
    valid_to TIMESTAMPTZ,
    applies_to TEXT DEFAULT 'all',
    threshold INT DEFAULT 100,
    bonus_per_registration NUMERIC(10,2) DEFAULT 0.20,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 4. IMPOSTAZIONI
CREATE TABLE collaborator_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    setting_key TEXT UNIQUE NOT NULL,
    setting_value TEXT NOT NULL,
    label TEXT,
    updated_at TIMESTAMPTZ DEFAULT now()
);

INSERT INTO collaborator_settings (setting_key, setting_value, label) VALUES
    ('rate_user_default',    '0.50',  '€ per ogni utente iscritto'),
    ('rate_azienda_default', '5.00',  '€ per ogni azienda iscritta'),
    ('min_payout',           '20.00', 'Minimo per pagamento (€)'),
    ('payout_day',           '15',    'Giorno del mese per pagamenti');

-- 5. VIEW ADMIN
CREATE VIEW admin_collaborators_view AS
SELECT
    c.id,
    c.user_id,
    c.auth_user_id,
    c.email,
    c.first_name,
    c.last_name,
    c.referral_code,
    c.status,
    c.notes,
    c.registered_at,
    c.approved_at,
    c.rate_user,
    c.rate_azienda,
    c.total_earned,
    c.total_pending,
    c.total_paid,
    c.users_count,
    c.aziende_count
FROM collaborators c;

-- 6. RLS
ALTER TABLE collaborators ENABLE ROW LEVEL SECURITY;
ALTER TABLE collaborator_earnings ENABLE ROW LEVEL SECURITY;
ALTER TABLE collaborator_bonus_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE collaborator_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admin full access collaborators"
    ON collaborators FOR ALL
    USING (EXISTS (SELECT 1 FROM users WHERE auth_user_id = auth.uid() AND role = 'admin'));

CREATE POLICY "Admin full access earnings"
    ON collaborator_earnings FOR ALL
    USING (EXISTS (SELECT 1 FROM users WHERE auth_user_id = auth.uid() AND role = 'admin'));

CREATE POLICY "Admin full access bonus_rules"
    ON collaborator_bonus_rules FOR ALL
    USING (EXISTS (SELECT 1 FROM users WHERE auth_user_id = auth.uid() AND role = 'admin'));

CREATE POLICY "Admin full access settings"
    ON collaborator_settings FOR ALL
    USING (EXISTS (SELECT 1 FROM users WHERE auth_user_id = auth.uid() AND role = 'admin'));

CREATE POLICY "Collaborator reads own data"
    ON collaborators FOR SELECT
    USING (auth_user_id = auth.uid());

CREATE POLICY "Collaborator reads own earnings"
    ON collaborator_earnings FOR SELECT
    USING (collaborator_id IN (SELECT id FROM collaborators WHERE auth_user_id = auth.uid()));

-- 7. INDICI
CREATE INDEX idx_collaborators_status ON collaborators(status);
CREATE INDEX idx_collaborators_auth_user_id ON collaborators(auth_user_id);
CREATE INDEX idx_collaborator_earnings_collaborator_id ON collaborator_earnings(collaborator_id);
CREATE INDEX idx_collaborator_earnings_status ON collaborator_earnings(status);
