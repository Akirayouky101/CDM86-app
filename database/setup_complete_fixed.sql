-- ============================================
-- CDM86 DATABASE SETUP COMPLETO - FIXED
-- Esegui questo script nel SQL Editor di Supabase
-- ============================================

-- PARTE 1: CREAZIONE TABELLE
-- ============================================

-- Tabella USERS
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    first_name TEXT,
    last_name TEXT,
    phone TEXT,
    avatar TEXT,
    referral_code TEXT UNIQUE NOT NULL,
    referred_by_id UUID REFERENCES users(id),
    referral_count INTEGER DEFAULT 0,
    points INTEGER DEFAULT 100,
    total_points_earned INTEGER DEFAULT 0,
    total_points_spent INTEGER DEFAULT 0,
    role TEXT DEFAULT 'user' CHECK (role IN ('user', 'partner', 'admin')),
    is_verified BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabella PROMOTIONS
CREATE TABLE IF NOT EXISTS promotions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    description TEXT,
    short_description TEXT,
    partner_name TEXT NOT NULL,
    partner_address TEXT,
    partner_city TEXT,
    partner_province TEXT,
    partner_phone TEXT,
    partner_email TEXT,
    category TEXT NOT NULL,
    tags TEXT[],
    image_url TEXT,
    thumbnail_url TEXT,
    discount_type TEXT CHECK (discount_type IN ('percentage', 'fixed', 'free')),
    discount_value DECIMAL(10,2),
    original_price DECIMAL(10,2),
    discounted_price DECIMAL(10,2),
    start_date TIMESTAMPTZ,
    end_date TIMESTAMPTZ,
    points_cost INTEGER DEFAULT 0,
    points_reward INTEGER DEFAULT 0,
    max_redemptions INTEGER,
    current_redemptions INTEGER DEFAULT 0,
    per_user_limit INTEGER DEFAULT 1,
    is_active BOOLEAN DEFAULT true,
    is_featured BOOLEAN DEFAULT false,
    terms TEXT,
    how_to_redeem TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabella FAVORITES
CREATE TABLE IF NOT EXISTS favorites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    promotion_id UUID REFERENCES promotions(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, promotion_id)
);

-- Tabella REDEMPTIONS
CREATE TABLE IF NOT EXISTS promotion_redemptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    promotion_id UUID REFERENCES promotions(id) ON DELETE CASCADE,
    redemption_code TEXT UNIQUE NOT NULL,
    points_spent INTEGER DEFAULT 0,
    redeemed_at TIMESTAMPTZ,
    is_used BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indici per performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_referral_code ON users(referral_code);
CREATE INDEX IF NOT EXISTS idx_promotions_category ON promotions(category);
CREATE INDEX IF NOT EXISTS idx_promotions_is_active ON promotions(is_active);
CREATE INDEX IF NOT EXISTS idx_favorites_user ON favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_redemptions_user ON promotion_redemptions(user_id);

-- ============================================
-- PARTE 2: TRIGGER PER AUTH
-- ============================================

-- Funzione per creare user in public.users quando si registra
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    new_referral_code TEXT;
    referral_exists BOOLEAN;
    attempt_count INTEGER := 0;
BEGIN
    -- Genera referral code unico
    LOOP
        new_referral_code := UPPER(
            SUBSTRING(NEW.email FROM 1 FOR 3) || 
            LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0')
        );
        
        SELECT EXISTS(SELECT 1 FROM public.users WHERE referral_code = new_referral_code) 
        INTO referral_exists;
        
        EXIT WHEN NOT referral_exists OR attempt_count > 10;
        attempt_count := attempt_count + 1;
    END LOOP;
    
    IF referral_exists THEN
        new_referral_code := 'REF' || LPAD(FLOOR(EXTRACT(EPOCH FROM NOW()))::TEXT, 7, '0');
    END IF;
    
    -- Inserisci in public.users
    INSERT INTO public.users (
        id, email, first_name, last_name, referral_code, points, is_verified, created_at, updated_at
    ) VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'first_name', ''),
        COALESCE(NEW.raw_user_meta_data->>'last_name', ''),
        new_referral_code,
        100,
        false,
        NOW(),
        NOW()
    ) ON CONFLICT (id) DO NOTHING;
    
    RETURN NEW;
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'Error creating user: %', SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger che si attiva quando si crea un nuovo utente
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_user();

-- ============================================
-- PARTE 3: ROW LEVEL SECURITY (RLS)
-- ============================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE promotions ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE promotion_redemptions ENABLE ROW LEVEL SECURITY;

-- Policy USERS: lettura per autenticati, scrittura solo per se stessi
CREATE POLICY "Users can view all users" ON users FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Users can update own profile" ON users FOR UPDATE USING (auth.uid() = id);

-- Policy PROMOTIONS: lettura per tutti, scrittura solo admin
CREATE POLICY "Anyone can view active promotions" ON promotions FOR SELECT USING (is_active = true);
CREATE POLICY "Admins can manage promotions" ON promotions FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
);

-- Policy FAVORITES: ogni utente vede solo i propri
CREATE POLICY "Users can view own favorites" ON favorites FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own favorites" ON favorites FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own favorites" ON favorites FOR DELETE USING (auth.uid() = user_id);

-- Policy REDEMPTIONS: ogni utente vede solo i propri
CREATE POLICY "Users can view own redemptions" ON promotion_redemptions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create redemptions" ON promotion_redemptions FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ============================================
-- PARTE 4: DATI DI TEST (8 PROMOZIONI)
-- ============================================

INSERT INTO promotions (title, slug, description, short_description, partner_name, partner_address, partner_city, partner_province, category, tags, image_url, discount_type, discount_value, original_price, discounted_price, points_cost, points_reward, is_active, is_featured) VALUES
('Pizza Margherita + Bibita Omaggio', 'pizza-margherita-bibita', 'Ordina una pizza margherita e ricevi una bibita in omaggio!', 'Pizza + Bibita gratis!', 'Pizzeria da Antonio', 'Via Roma 123', 'Milano', 'MI', 'ristoranti', ARRAY['pizza', 'cibo', 'italiano'], 'https://images.unsplash.com/photo-1513104890138-7c749659a591', 'fixed', 3.00, 11.00, 8.00, 0, 50, true, true),
('Sconto 20% su Tutto', 'sconto-20-tutto', 'Approfitta del nostro super sconto del 20% su tutti i prodotti!', '20% su tutto', 'Fashion Store Milano', 'Corso Buenos Aires 45', 'Milano', 'MI', 'shopping', ARRAY['moda', 'abbigliamento', 'sconto'], 'https://images.unsplash.com/photo-1441986300917-64674bd600d8', 'percentage', 20.00, 100.00, 80.00, 0, 100, true, true),
('Taglio + Piega Donna €25', 'taglio-piega-donna-25', 'Pacchetto completo taglio e piega per donna a prezzo speciale!', 'Taglio + Piega €25', 'Salone Bellezza', 'Via Dante 78', 'Torino', 'TO', 'bellezza', ARRAY['parrucchiere', 'capelli', 'donna'], 'https://images.unsplash.com/photo-1560066984-138dadb4c035', 'fixed', 15.00, 40.00, 25.00, 0, 80, true, false),
('Colazione Completa €5', 'colazione-completa-5', 'Cappuccino, brioche e spremuta d''arancia a soli €5!', 'Colazione €5', 'Bar Centrale', 'Piazza Duomo 12', 'Roma', 'RM', 'ristoranti', ARRAY['colazione', 'bar', 'cappuccino'], 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085', 'fixed', 3.50, 8.50, 5.00, 0, 30, true, true),
('Ingresso Palestra 1 Mese Gratis', 'palestra-1-mese-gratis', 'Prova gratuita di 1 mese in palestra! Include tutte le attività.', 'Prova 1 mese gratis', 'FitZone Gym', 'Via dello Sport 34', 'Bologna', 'BO', 'sport', ARRAY['palestra', 'fitness', 'sport'], 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48', 'free', 50.00, 50.00, 0.00, 200, 150, true, true),
('Menu Sushi 30 Pezzi €18', 'menu-sushi-30-pezzi', 'Menu sushi con 30 pezzi assortiti a prezzo speciale!', 'Sushi 30pz €18', 'Sakura Sushi', 'Via Veneto 89', 'Firenze', 'FI', 'ristoranti', ARRAY['sushi', 'giapponese', 'pesce'], 'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351', 'fixed', 12.00, 30.00, 18.00, 0, 90, true, false),
('Massaggio Rilassante 50min €30', 'massaggio-rilassante-30', 'Massaggio rilassante completo di 50 minuti a prezzo speciale.', 'Massaggio €30', 'Centro Benessere Armonia', 'Viale della Pace 56', 'Verona', 'VR', 'benessere', ARRAY['massaggio', 'relax', 'spa'], 'https://images.unsplash.com/photo-1544161515-4ab6ce6db874', 'fixed', 20.00, 50.00, 30.00, 150, 70, true, false),
('Lavaggio Auto Completo €12', 'lavaggio-auto-completo', 'Lavaggio esterno + interno + aspirazione a prezzo promozionale!', 'Lavaggio €12', 'AutoWash Express', 'Via Industria 23', 'Genova', 'GE', 'servizi', ARRAY['auto', 'lavaggio', 'pulizia'], 'https://images.unsplash.com/photo-1601362840469-51e4d8d58785', 'fixed', 8.00, 20.00, 12.00, 0, 40, true, false);

-- ============================================
-- SETUP COMPLETATO! ✅
-- ============================================
