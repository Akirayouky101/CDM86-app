-- ============================================
-- CDM86 Platform - PostgreSQL Database Schema
-- Database: CDM86DB
-- Target: Vercel Postgres
-- ============================================

-- Abilita estensioni necessarie
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================
-- TABELLA: users
-- Utenti della piattaforma con sistema referral
-- ============================================
CREATE TABLE IF NOT EXISTS users (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Informazioni Base
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    avatar TEXT,
    
    -- Sistema Referral (OBBLIGATORIO)
    referral_code VARCHAR(8) NOT NULL UNIQUE,
    referred_by_id UUID REFERENCES users(id) ON DELETE SET NULL,
    referral_count INTEGER DEFAULT 0 NOT NULL,
    
    -- Sistema Punti
    points INTEGER DEFAULT 0 NOT NULL CHECK (points >= 0),
    total_points_earned INTEGER DEFAULT 0 NOT NULL,
    total_points_spent INTEGER DEFAULT 0 NOT NULL,
    
    -- Ruolo e Status
    role VARCHAR(20) DEFAULT 'user' NOT NULL CHECK (role IN ('user', 'partner', 'admin')),
    is_verified BOOLEAN DEFAULT false NOT NULL,
    is_active BOOLEAN DEFAULT true NOT NULL,
    
    -- Sicurezza
    verification_token VARCHAR(255),
    verification_expires TIMESTAMP WITH TIME ZONE,
    reset_password_token VARCHAR(255),
    reset_password_expires TIMESTAMP WITH TIME ZONE,
    login_attempts INTEGER DEFAULT 0 NOT NULL,
    lock_until TIMESTAMP WITH TIME ZONE,
    
    -- Metadata
    last_login TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    -- Indici
    CONSTRAINT users_email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- Indici per performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_referral_code ON users(referral_code);
CREATE INDEX idx_users_referred_by ON users(referred_by_id);
CREATE INDEX idx_users_created_at ON users(created_at DESC);
CREATE INDEX idx_users_role ON users(role);

-- ============================================
-- TABELLA: promotions
-- Promozioni convenzionate con partner
-- ============================================
CREATE TABLE IF NOT EXISTS promotions (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Informazioni Base
    title VARCHAR(200) NOT NULL,
    slug VARCHAR(250) UNIQUE NOT NULL,
    description TEXT NOT NULL,
    short_description VARCHAR(300),
    
    -- Partner Info
    partner_name VARCHAR(200) NOT NULL,
    partner_logo TEXT,
    partner_website VARCHAR(255),
    partner_address VARCHAR(255),
    partner_city VARCHAR(100),
    partner_province VARCHAR(2),
    partner_zip_code VARCHAR(10),
    partner_phone VARCHAR(20),
    partner_email VARCHAR(255),
    
    -- Categoria e Tags
    category VARCHAR(50) NOT NULL CHECK (category IN (
        'ristoranti', 'shopping', 'viaggi', 'intrattenimento', 
        'salute', 'tecnologia', 'sport', 'servizi', 'altro'
    )),
    tags TEXT[], -- Array di tags
    
    -- Immagini
    image_main TEXT NOT NULL,
    image_thumbnail TEXT,
    image_gallery TEXT[], -- Array di URL immagini
    
    -- Sconto
    discount_type VARCHAR(20) NOT NULL CHECK (discount_type IN ('percentage', 'fixed', 'code')),
    discount_value DECIMAL(10,2) NOT NULL,
    discount_max_amount DECIMAL(10,2),
    discount_min_purchase DECIMAL(10,2),
    
    -- Prezzi
    original_price DECIMAL(10,2),
    discounted_price DECIMAL(10,2),
    
    -- Validità
    validity_start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    validity_end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    validity_days TEXT[], -- Array: ['lun', 'mar', 'mer', ...]
    validity_hours_from TIME,
    validity_hours_to TIME,
    
    -- Limiti
    limit_total_redemptions INTEGER,
    limit_per_user INTEGER DEFAULT 1 NOT NULL,
    limit_per_day INTEGER,
    
    -- Status e Flags
    is_active BOOLEAN DEFAULT true NOT NULL,
    is_featured BOOLEAN DEFAULT false NOT NULL,
    is_exclusive BOOLEAN DEFAULT false NOT NULL,
    
    -- Statistiche
    stat_views INTEGER DEFAULT 0 NOT NULL,
    stat_favorites INTEGER DEFAULT 0 NOT NULL,
    stat_redemptions INTEGER DEFAULT 0 NOT NULL,
    stat_clicks INTEGER DEFAULT 0 NOT NULL,
    stat_rating_average DECIMAL(3,2) DEFAULT 0 CHECK (stat_rating_average >= 0 AND stat_rating_average <= 5),
    stat_rating_count INTEGER DEFAULT 0 NOT NULL,
    
    -- Punti
    points_cost INTEGER DEFAULT 0 NOT NULL CHECK (points_cost >= 0),
    points_reward INTEGER DEFAULT 0 NOT NULL CHECK (points_reward >= 0),
    
    -- Termini e Condizioni
    terms TEXT,
    how_to_redeem TEXT,
    
    -- SEO
    meta_title VARCHAR(255),
    meta_description TEXT,
    meta_keywords TEXT[],
    
    -- Metadata
    created_by_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    updated_by_id UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    -- Constraints
    CONSTRAINT promotions_dates_valid CHECK (validity_end_date >= validity_start_date)
);

-- Indici per performance
CREATE INDEX idx_promotions_slug ON promotions(slug);
CREATE INDEX idx_promotions_category ON promotions(category, is_active);
CREATE INDEX idx_promotions_dates ON promotions(validity_start_date, validity_end_date);
CREATE INDEX idx_promotions_featured ON promotions(is_featured DESC, stat_redemptions DESC);
CREATE INDEX idx_promotions_partner ON promotions(partner_name);
CREATE INDEX idx_promotions_active ON promotions(is_active, validity_end_date);

-- Indice full-text search
CREATE INDEX idx_promotions_search ON promotions USING gin(to_tsvector('italian', title || ' ' || description || ' ' || partner_name));

-- ============================================
-- TABELLA: user_favorites
-- Promozioni preferite degli utenti (Many-to-Many)
-- ============================================
CREATE TABLE IF NOT EXISTS user_favorites (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    promotion_id UUID NOT NULL REFERENCES promotions(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    PRIMARY KEY (user_id, promotion_id)
);

CREATE INDEX idx_user_favorites_user ON user_favorites(user_id);
CREATE INDEX idx_user_favorites_promotion ON user_favorites(promotion_id);

-- ============================================
-- TABELLA: referrals
-- Sistema referral con tracking completo
-- ============================================
CREATE TABLE IF NOT EXISTS referrals (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Referrer (chi invita) - OBBLIGATORIO
    referrer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Referred (chi viene invitato)
    referred_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    referred_email VARCHAR(255),
    
    -- Codice utilizzato
    code_used VARCHAR(8) NOT NULL,
    
    -- Status workflow
    status VARCHAR(20) DEFAULT 'pending' NOT NULL CHECK (status IN (
        'pending', 'registered', 'verified', 'completed', 'expired'
    )),
    
    -- Punti guadagnati
    points_earned_referrer INTEGER DEFAULT 0 NOT NULL,
    points_earned_referred INTEGER DEFAULT 0 NOT NULL,
    
    -- Tracking temporale
    clicked_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    registered_at TIMESTAMP WITH TIME ZONE,
    verified_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (CURRENT_TIMESTAMP + INTERVAL '30 days') NOT NULL,
    
    -- Tracking info
    source VARCHAR(50) DEFAULT 'link' CHECK (source IN ('link', 'email', 'social', 'direct')),
    ip_address INET,
    user_agent TEXT,
    referrer_url TEXT,
    
    -- Campaign tracking (UTM)
    campaign_name VARCHAR(100),
    campaign_medium VARCHAR(50),
    campaign_source VARCHAR(50),
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Indici
CREATE INDEX idx_referrals_referrer ON referrals(referrer_id, status);
CREATE INDEX idx_referrals_referred ON referrals(referred_user_id);
CREATE INDEX idx_referrals_code ON referrals(code_used);
CREATE INDEX idx_referrals_status ON referrals(status, created_at DESC);
CREATE INDEX idx_referrals_expires ON referrals(expires_at);

-- ============================================
-- TABELLA: transactions
-- Transazioni di riscatto promozioni
-- ============================================
CREATE TABLE IF NOT EXISTS transactions (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Relazioni
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    promotion_id UUID NOT NULL REFERENCES promotions(id) ON DELETE RESTRICT,
    
    -- Codici
    transaction_code VARCHAR(12) NOT NULL UNIQUE,
    qr_code TEXT NOT NULL, -- Base64 encoded QR code
    barcode VARCHAR(50),
    verification_code VARCHAR(6) NOT NULL,
    
    -- Status
    status VARCHAR(20) DEFAULT 'pending' NOT NULL CHECK (status IN (
        'pending', 'verified', 'completed', 'expired', 'cancelled', 'refunded'
    )),
    
    -- Metodo e location riscatto
    redemption_method VARCHAR(20) DEFAULT 'qr' CHECK (redemption_method IN ('qr', 'code', 'online', 'instore')),
    redemption_location VARCHAR(255),
    redeemed_at TIMESTAMP WITH TIME ZONE,
    redeemed_by_id UUID REFERENCES users(id) ON DELETE SET NULL,
    
    -- Scadenza
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    
    -- Punti
    points_used INTEGER DEFAULT 0 NOT NULL CHECK (points_used >= 0),
    points_earned INTEGER DEFAULT 0 NOT NULL CHECK (points_earned >= 0),
    
    -- Sconto applicato
    discount_type VARCHAR(20),
    discount_value DECIMAL(10,2),
    discount_applied_amount DECIMAL(10,2),
    
    -- Importi
    original_amount DECIMAL(10,2) DEFAULT 0,
    discounted_amount DECIMAL(10,2) DEFAULT 0,
    final_amount DECIMAL(10,2) DEFAULT 0,
    
    -- Verifica
    verified_at TIMESTAMP WITH TIME ZONE,
    
    -- Rating
    rating_score INTEGER CHECK (rating_score >= 1 AND rating_score <= 5),
    rating_comment TEXT,
    rating_created_at TIMESTAMP WITH TIME ZONE,
    
    -- Metadata
    metadata_user_agent TEXT,
    metadata_ip_address INET,
    metadata_device_type VARCHAR(20) CHECK (metadata_device_type IN ('mobile', 'tablet', 'desktop')),
    
    -- Note
    notes TEXT,
    internal_notes TEXT,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Indici
CREATE INDEX idx_transactions_user ON transactions(user_id, created_at DESC);
CREATE INDEX idx_transactions_promotion ON transactions(promotion_id, status);
CREATE INDEX idx_transactions_code ON transactions(transaction_code);
CREATE INDEX idx_transactions_status ON transactions(status, expires_at);
CREATE INDEX idx_transactions_redeemed ON transactions(redeemed_at DESC);

-- ============================================
-- FUNCTIONS & TRIGGERS
-- ============================================

-- Function: Aggiorna updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger per users
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger per promotions
CREATE TRIGGER update_promotions_updated_at BEFORE UPDATE ON promotions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger per referrals
CREATE TRIGGER update_referrals_updated_at BEFORE UPDATE ON referrals
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger per transactions
CREATE TRIGGER update_transactions_updated_at BEFORE UPDATE ON transactions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function: Genera referral code univoco
CREATE OR REPLACE FUNCTION generate_referral_code()
RETURNS VARCHAR(8) AS $$
DECLARE
    chars TEXT := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    result VARCHAR(8) := '';
    i INTEGER;
    code_exists BOOLEAN;
BEGIN
    LOOP
        result := '';
        FOR i IN 1..8 LOOP
            result := result || substr(chars, floor(random() * length(chars) + 1)::int, 1);
        END LOOP;
        
        SELECT EXISTS(SELECT 1 FROM users WHERE referral_code = result) INTO code_exists;
        
        EXIT WHEN NOT code_exists;
    END LOOP;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function: Genera transaction code univoco
CREATE OR REPLACE FUNCTION generate_transaction_code()
RETURNS VARCHAR(12) AS $$
DECLARE
    result VARCHAR(12);
    code_exists BOOLEAN;
BEGIN
    LOOP
        result := UPPER(encode(gen_random_bytes(6), 'hex'));
        
        SELECT EXISTS(SELECT 1 FROM transactions WHERE transaction_code = result) INTO code_exists;
        
        EXIT WHEN NOT code_exists;
    END LOOP;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function: Incrementa referral_count quando un utente si registra
CREATE OR REPLACE FUNCTION increment_referrer_count()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.referred_by_id IS NOT NULL THEN
        UPDATE users 
        SET referral_count = referral_count + 1
        WHERE id = NEW.referred_by_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Incrementa count del referrer
CREATE TRIGGER after_user_insert_update_referrer
AFTER INSERT ON users
FOR EACH ROW
WHEN (NEW.referred_by_id IS NOT NULL)
EXECUTE FUNCTION increment_referrer_count();

-- Function: Aggiorna statistiche promozione
CREATE OR REPLACE FUNCTION update_promotion_stats_on_favorite()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE promotions 
        SET stat_favorites = stat_favorites + 1
        WHERE id = NEW.promotion_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE promotions 
        SET stat_favorites = GREATEST(stat_favorites - 1, 0)
        WHERE id = OLD.promotion_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Aggiorna favorites count
CREATE TRIGGER after_favorite_change
AFTER INSERT OR DELETE ON user_favorites
FOR EACH ROW
EXECUTE FUNCTION update_promotion_stats_on_favorite();

-- ============================================
-- VIEWS
-- ============================================

-- View: Statistiche utente complete
CREATE OR REPLACE VIEW user_stats AS
SELECT 
    u.id,
    u.email,
    u.first_name,
    u.last_name,
    u.referral_code,
    u.points,
    u.referral_count,
    COUNT(DISTINCT uf.promotion_id) as favorites_count,
    COUNT(DISTINCT t.id) FILTER (WHERE t.status = 'completed') as transactions_completed,
    COALESCE(SUM(t.points_earned) FILTER (WHERE t.status = 'completed'), 0) as total_points_from_transactions,
    (
        SELECT COUNT(*) 
        FROM referrals r 
        WHERE r.referrer_id = u.id AND r.status = 'completed'
    ) as successful_referrals,
    u.created_at,
    u.last_login
FROM users u
LEFT JOIN user_favorites uf ON u.id = uf.user_id
LEFT JOIN transactions t ON u.id = t.user_id
GROUP BY u.id;

-- View: Promozioni attive
CREATE OR REPLACE VIEW active_promotions AS
SELECT 
    p.*,
    u.first_name || ' ' || u.last_name as created_by_name,
    CASE 
        WHEN p.discount_type = 'percentage' THEN '-' || p.discount_value || '%'
        WHEN p.discount_type = 'fixed' THEN '-€' || p.discount_value
        ELSE 'CODICE'
    END as discount_label,
    EXTRACT(DAY FROM (p.validity_end_date - CURRENT_TIMESTAMP)) as days_remaining
FROM promotions p
JOIN users u ON p.created_by_id = u.id
WHERE p.is_active = true
  AND p.validity_start_date <= CURRENT_TIMESTAMP
  AND p.validity_end_date >= CURRENT_TIMESTAMP;

-- View: Top referrers
CREATE OR REPLACE VIEW top_referrers AS
SELECT 
    u.id,
    u.first_name,
    u.last_name,
    u.email,
    u.referral_code,
    u.referral_count,
    COUNT(r.id) FILTER (WHERE r.status = 'completed') as completed_referrals,
    COALESCE(SUM(r.points_earned_referrer), 0) as total_points_earned
FROM users u
LEFT JOIN referrals r ON u.id = r.referrer_id
GROUP BY u.id
HAVING u.referral_count > 0
ORDER BY completed_referrals DESC, total_points_earned DESC;

-- ============================================
-- COMMENTS (Documentation)
-- ============================================

COMMENT ON TABLE users IS 'Utenti della piattaforma con sistema referral obbligatorio';
COMMENT ON COLUMN users.referral_code IS 'Codice referral univoco 8 caratteri (es: MARIO001)';
COMMENT ON COLUMN users.referred_by_id IS 'ID dell''utente che ha fornito il referral (OBBLIGATORIO tranne per admin)';

COMMENT ON TABLE promotions IS 'Promozioni convenzionate con partner locali';
COMMENT ON COLUMN promotions.category IS 'Categoria: ristoranti, shopping, viaggi, etc.';

COMMENT ON TABLE referrals IS 'Tracking referral con workflow: pending -> registered -> verified -> completed';
COMMENT ON COLUMN referrals.status IS 'pending=click, registered=signup, verified=email, completed=reward';

COMMENT ON TABLE transactions IS 'Transazioni di riscatto promozioni con QR code';
COMMENT ON COLUMN transactions.qr_code IS 'QR code Base64 encoded per verifica';

-- ============================================
-- DONE!
-- ============================================
-- Schema creato con successo!
-- Prossimi passi:
-- 1. Creare database CDM86DB su Vercel Postgres
-- 2. Eseguire questo file: psql -d CDM86DB -f schema.sql
-- 3. Eseguire seed.sql per popolare dati iniziali
-- ============================================
