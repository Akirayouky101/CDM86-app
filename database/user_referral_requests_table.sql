-- ============================================
-- TABELLA RICHIESTE REFERRAL UTENTI
-- Per gestire richieste di codici referral da utenti che vogliono registrarsi
-- ============================================

CREATE TABLE IF NOT EXISTS user_referral_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Dati utente richiedente
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(20),
    
    -- Note/messaggio
    message TEXT,
    
    -- Status workflow
    status VARCHAR(20) DEFAULT 'pending' NOT NULL CHECK (status IN (
        'pending',      -- In attesa di revisione
        'contacted',    -- Admin ha contattato l'utente
        'approved',     -- Codice referral inviato
        'rejected'      -- Richiesta rifiutata
    )),
    
    -- Codice referral assegnato (se approvato)
    assigned_referral_code VARCHAR(8),
    assigned_by UUID REFERENCES users(id) ON DELETE SET NULL,  -- Admin che ha approvato
    
    -- Note admin
    admin_notes TEXT,
    
    -- Timestamp
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    contacted_at TIMESTAMPTZ,
    resolved_at TIMESTAMPTZ
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_user_referral_requests_status ON user_referral_requests(status);
CREATE INDEX IF NOT EXISTS idx_user_referral_requests_email ON user_referral_requests(email);
CREATE INDEX IF NOT EXISTS idx_user_referral_requests_created ON user_referral_requests(created_at DESC);

-- RLS Policies
ALTER TABLE user_referral_requests ENABLE ROW LEVEL SECURITY;

-- Admin può vedere e modificare tutto
DROP POLICY IF EXISTS "Admin can manage user referral requests" ON user_referral_requests;
CREATE POLICY "Admin can manage user referral requests"
ON user_referral_requests
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM users
        WHERE users.id = auth.uid()
        AND users.role = 'admin'
    )
);

-- Gli utenti possono solo inserire (registrazione)
DROP POLICY IF EXISTS "Users can insert referral requests" ON user_referral_requests;
CREATE POLICY "Users can insert referral requests"
ON user_referral_requests
FOR INSERT
TO anon
WITH CHECK (true);

-- Trigger per updated_at
DROP TRIGGER IF EXISTS update_user_referral_requests_updated_at ON user_referral_requests;
CREATE TRIGGER update_user_referral_requests_updated_at
    BEFORE UPDATE ON user_referral_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Verifica
SELECT 'Tabella user_referral_requests creata con successo!' as status;
