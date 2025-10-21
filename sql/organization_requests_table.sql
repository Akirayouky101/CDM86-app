-- Tabella per le richieste di contatto delle organizzazioni
CREATE TABLE IF NOT EXISTS organization_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    organization_name VARCHAR(255) NOT NULL,
    contact_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(50) NOT NULL,
    business_type VARCHAR(100) NOT NULL,
    message TEXT,
    has_referral BOOLEAN DEFAULT FALSE,
    referral_code VARCHAR(50),
    status VARCHAR(50) DEFAULT 'pending', -- pending, contacted, approved, rejected
    notes TEXT, -- Note interne per admin
    contacted_at TIMESTAMP,
    contacted_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Indici per performance
CREATE INDEX idx_org_requests_status ON organization_requests(status);
CREATE INDEX idx_org_requests_created_at ON organization_requests(created_at DESC);
CREATE INDEX idx_org_requests_email ON organization_requests(email);

-- Trigger per updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_organization_requests_updated_at
    BEFORE UPDATE ON organization_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Tabella per notifiche admin (se non esiste già)
CREATE TABLE IF NOT EXISTS admin_notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    type VARCHAR(100) NOT NULL, -- organization_request, user_registration, etc.
    data JSONB,
    read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP,
    read_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Indice per notifiche non lette
CREATE INDEX idx_admin_notif_unread ON admin_notifications(read, created_at DESC) WHERE read = FALSE;