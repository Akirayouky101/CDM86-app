-- =====================================================
-- CDM86 POINTS SYSTEM - Complete Database Setup
-- =====================================================

-- 1. USER POINTS TABLE
-- Tracks total points for each user
CREATE TABLE IF NOT EXISTS user_points (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE NOT NULL,
    points_total INTEGER DEFAULT 0 CHECK (points_total >= 0),
    points_used INTEGER DEFAULT 0 CHECK (points_used >= 0),
    points_available INTEGER DEFAULT 0 CHECK (points_available >= 0),
    referrals_count INTEGER DEFAULT 0 CHECK (referrals_count >= 0),
    approved_reports_count INTEGER DEFAULT 0 CHECK (approved_reports_count >= 0),
    rejected_reports_count INTEGER DEFAULT 0 CHECK (rejected_reports_count >= 0),
    level VARCHAR(20) DEFAULT 'bronze' CHECK (level IN ('bronze', 'silver', 'gold', 'platinum')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_points_user_id ON user_points(user_id);
CREATE INDEX IF NOT EXISTS idx_user_points_level ON user_points(level);
CREATE INDEX IF NOT EXISTS idx_user_points_total ON user_points(points_total DESC);

-- 2. POINTS TRANSACTIONS TABLE
-- Detailed log of all point movements
CREATE TABLE IF NOT EXISTS points_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    points INTEGER NOT NULL,
    transaction_type VARCHAR(50) NOT NULL CHECK (transaction_type IN (
        'referral_completed',
        'report_approved',
        'report_rejected',
        'reward_redeemed',
        'admin_adjustment',
        'bonus'
    )),
    reference_id UUID, -- ID of related entity (referral, report, reward)
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_points_transactions_user_id ON points_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_points_transactions_type ON points_transactions(transaction_type);
CREATE INDEX IF NOT EXISTS idx_points_transactions_created_at ON points_transactions(created_at DESC);

-- 3. REWARDS CATALOG TABLE
-- Available rewards that users can redeem
CREATE TABLE IF NOT EXISTS rewards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    points_required INTEGER NOT NULL CHECK (points_required > 0),
    level_required VARCHAR(20) DEFAULT 'bronze' CHECK (level_required IN ('bronze', 'silver', 'gold', 'platinum')),
    image_url TEXT,
    stock INTEGER DEFAULT -1, -- -1 = unlimited
    redeemed_count INTEGER DEFAULT 0,
    active BOOLEAN DEFAULT true,
    category VARCHAR(50) DEFAULT 'general',
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_rewards_active ON rewards(active);
CREATE INDEX IF NOT EXISTS idx_rewards_level ON rewards(level_required);
CREATE INDEX IF NOT EXISTS idx_rewards_points ON rewards(points_required);

-- 4. REWARD REDEMPTIONS TABLE
-- Track who redeemed what and when
CREATE TABLE IF NOT EXISTS reward_redemptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    reward_id UUID REFERENCES rewards(id) ON DELETE SET NULL,
    points_spent INTEGER NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'delivered', 'cancelled')),
    notes TEXT,
    redeemed_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_redemptions_user_id ON reward_redemptions(user_id);
CREATE INDEX IF NOT EXISTS idx_redemptions_reward_id ON reward_redemptions(reward_id);
CREATE INDEX IF NOT EXISTS idx_redemptions_status ON reward_redemptions(status);

-- =====================================================
-- FUNCTIONS
-- =====================================================

-- Function: Calculate user level based on points
CREATE OR REPLACE FUNCTION calculate_user_level(points INTEGER)
RETURNS VARCHAR(20) AS $$
BEGIN
    IF points >= 1000 THEN
        RETURN 'platinum';
    ELSIF points >= 500 THEN
        RETURN 'gold';
    ELSIF points >= 100 THEN
        RETURN 'silver';
    ELSE
        RETURN 'bronze';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Function: Add points to user
CREATE OR REPLACE FUNCTION add_points_to_user(
    p_user_id UUID,
    p_points INTEGER,
    p_transaction_type VARCHAR(50),
    p_reference_id UUID DEFAULT NULL,
    p_description TEXT DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    v_new_total INTEGER;
    v_new_level VARCHAR(20);
BEGIN
    -- Ensure user has a points record
    INSERT INTO user_points (user_id)
    VALUES (p_user_id)
    ON CONFLICT (user_id) DO NOTHING;
    
    -- Update points
    UPDATE user_points
    SET 
        points_total = points_total + p_points,
        points_available = points_available + p_points,
        updated_at = NOW()
    WHERE user_id = p_user_id
    RETURNING points_total INTO v_new_total;
    
    -- Calculate new level
    v_new_level := calculate_user_level(v_new_total);
    
    -- Update level if changed
    UPDATE user_points
    SET level = v_new_level
    WHERE user_id = p_user_id;
    
    -- Log transaction
    INSERT INTO points_transactions (
        user_id,
        points,
        transaction_type,
        reference_id,
        description
    ) VALUES (
        p_user_id,
        p_points,
        p_transaction_type,
        p_reference_id,
        p_description
    );
END;
$$ LANGUAGE plpgsql;

-- Function: Deduct points from user (for reward redemption)
CREATE OR REPLACE FUNCTION deduct_points_from_user(
    p_user_id UUID,
    p_points INTEGER,
    p_transaction_type VARCHAR(50),
    p_reference_id UUID DEFAULT NULL,
    p_description TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    v_available_points INTEGER;
    v_new_total INTEGER;
    v_new_level VARCHAR(20);
BEGIN
    -- Check available points
    SELECT points_available INTO v_available_points
    FROM user_points
    WHERE user_id = p_user_id;
    
    IF v_available_points IS NULL OR v_available_points < p_points THEN
        RETURN FALSE; -- Not enough points
    END IF;
    
    -- Deduct points
    UPDATE user_points
    SET 
        points_used = points_used + p_points,
        points_available = points_available - p_points,
        updated_at = NOW()
    WHERE user_id = p_user_id
    RETURNING points_total INTO v_new_total;
    
    -- Calculate new level (based on total, not available)
    v_new_level := calculate_user_level(v_new_total);
    
    -- Update level if changed
    UPDATE user_points
    SET level = v_new_level
    WHERE user_id = p_user_id;
    
    -- Log transaction (negative points)
    INSERT INTO points_transactions (
        user_id,
        points,
        transaction_type,
        reference_id,
        description
    ) VALUES (
        p_user_id,
        -p_points,
        p_transaction_type,
        p_reference_id,
        p_description
    );
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Trigger: Award points when a referral is completed (user created via referral code)
CREATE OR REPLACE FUNCTION award_referral_points()
RETURNS TRIGGER AS $$
DECLARE
    v_referrer_id UUID;
BEGIN
    -- Get referrer user_id from referral_code
    SELECT id INTO v_referrer_id
    FROM users
    WHERE referral_code = NEW.referred_by;
    
    IF v_referrer_id IS NOT NULL THEN
        -- Award 50 points to referrer
        PERFORM add_points_to_user(
            v_referrer_id,
            50,
            'referral_completed',
            NEW.id,
            'Referral: ' || (SELECT first_name || ' ' || last_name FROM users WHERE id = NEW.id)
        );
        
        -- Increment referrals count
        UPDATE user_points
        SET referrals_count = referrals_count + 1
        WHERE user_id = v_referrer_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_award_referral_points ON users;
CREATE TRIGGER trigger_award_referral_points
    AFTER INSERT ON users
    FOR EACH ROW
    WHEN (NEW.referred_by IS NOT NULL)
    EXECUTE FUNCTION award_referral_points();

-- Trigger: Award/Remove points when organization request is approved/rejected
CREATE OR REPLACE FUNCTION handle_organization_request_status()
RETURNS TRIGGER AS $$
BEGIN
    -- Only process if status changed to approved or rejected
    IF NEW.status != OLD.status THEN
        IF NEW.status = 'approved' THEN
            -- Award 100 points for approved report
            PERFORM add_points_to_user(
                NEW.user_id,
                100,
                'report_approved',
                NEW.id,
                'Segnalazione approvata: ' || NEW.organization_name
            );
            
            -- Increment approved reports count
            UPDATE user_points
            SET approved_reports_count = approved_reports_count + 1
            WHERE user_id = NEW.user_id;
            
        ELSIF NEW.status = 'rejected' THEN
            -- No points awarded, just log
            INSERT INTO points_transactions (
                user_id,
                points,
                transaction_type,
                reference_id,
                description
            ) VALUES (
                NEW.user_id,
                0,
                'report_rejected',
                NEW.id,
                'Segnalazione rifiutata: ' || NEW.organization_name
            );
            
            -- Increment rejected reports count
            UPDATE user_points
            SET rejected_reports_count = rejected_reports_count + 1
            WHERE user_id = NEW.user_id;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_organization_request_status ON organization_requests;
CREATE TRIGGER trigger_organization_request_status
    AFTER UPDATE ON organization_requests
    FOR EACH ROW
    EXECUTE FUNCTION handle_organization_request_status();

-- Trigger: Update reward stock when redeemed
CREATE OR REPLACE FUNCTION update_reward_stock()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'approved' AND (OLD.status IS NULL OR OLD.status != 'approved') THEN
        -- Decrement stock (if not unlimited)
        UPDATE rewards
        SET 
            redeemed_count = redeemed_count + 1,
            stock = CASE WHEN stock > 0 THEN stock - 1 ELSE stock END
        WHERE id = NEW.reward_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_reward_stock ON reward_redemptions;
CREATE TRIGGER trigger_update_reward_stock
    AFTER INSERT OR UPDATE ON reward_redemptions
    FOR EACH ROW
    EXECUTE FUNCTION update_reward_stock();

-- =====================================================
-- SEED DATA - Sample Rewards
-- =====================================================

INSERT INTO rewards (title, description, points_required, level_required, category, image_url, stock, sort_order) VALUES
-- Bronze Level Rewards
('Sconto 5€', 'Buono sconto di 5€ su qualsiasi promozione', 50, 'bronze', 'discount', null, -1, 1),
('Badge Bronzo', 'Badge digitale livello Bronzo per il tuo profilo', 30, 'bronze', 'badge', null, -1, 2),
('Accesso Anticipato', 'Visualizza nuove promozioni 24h prima degli altri', 80, 'bronze', 'premium', null, -1, 3),

-- Silver Level Rewards
('Sconto 10€', 'Buono sconto di 10€ su qualsiasi promozione', 150, 'silver', 'discount', null, -1, 4),
('Badge Argento', 'Badge digitale livello Argento per il tuo profilo', 100, 'silver', 'badge', null, -1, 5),
('Promozione Esclusiva', 'Accesso a 1 promozione esclusiva riservata', 200, 'silver', 'premium', null, 20, 6),

-- Gold Level Rewards
('Sconto 25€', 'Buono sconto di 25€ su qualsiasi promozione', 500, 'gold', 'discount', null, -1, 7),
('Badge Oro', 'Badge digitale livello Oro per il tuo profilo', 300, 'gold', 'badge', null, -1, 8),
('VIP Pass Mensile', 'Accesso VIP per 1 mese con vantaggi esclusivi', 700, 'gold', 'premium', null, 10, 9),

-- Platinum Level Rewards
('Sconto 50€', 'Buono sconto di 50€ su qualsiasi promozione', 1000, 'platinum', 'discount', null, -1, 10),
('Badge Platino', 'Badge digitale livello Platino per il tuo profilo', 500, 'platinum', 'badge', null, -1, 11),
('VIP Pass Annuale', 'Accesso VIP per 1 anno con tutti i vantaggi', 1500, 'platinum', 'premium', null, 5, 12),
('Consulenza Premium', 'Sessione di consulenza 1-1 per ottimizzare i tuoi referral', 1200, 'platinum', 'service', null, 15, 13);

-- =====================================================
-- RLS POLICIES
-- =====================================================

-- Enable RLS
ALTER TABLE user_points ENABLE ROW LEVEL SECURITY;
ALTER TABLE points_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE rewards ENABLE ROW LEVEL SECURITY;
ALTER TABLE reward_redemptions ENABLE ROW LEVEL SECURITY;

-- user_points policies
CREATE POLICY "Users can view own points"
    ON user_points FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can view all points for leaderboard"
    ON user_points FOR SELECT
    USING (true);

-- points_transactions policies
CREATE POLICY "Users can view own transactions"
    ON points_transactions FOR SELECT
    USING (auth.uid() = user_id);

-- rewards policies
CREATE POLICY "Anyone can view active rewards"
    ON rewards FOR SELECT
    USING (active = true);

-- reward_redemptions policies
CREATE POLICY "Users can view own redemptions"
    ON reward_redemptions FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create redemptions"
    ON reward_redemptions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- =====================================================
-- GRANT PERMISSIONS
-- =====================================================

GRANT SELECT, INSERT, UPDATE ON user_points TO authenticated;
GRANT SELECT ON points_transactions TO authenticated;
GRANT SELECT ON rewards TO authenticated;
GRANT SELECT, INSERT, UPDATE ON reward_redemptions TO authenticated;

-- =====================================================
-- SETUP COMPLETE
-- =====================================================
SELECT 'Points system setup completed successfully!' as status;
