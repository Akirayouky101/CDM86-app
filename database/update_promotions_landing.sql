-- Aggiorna tabella promotions per supportare landing pages
-- Esegui su Supabase SQL Editor

-- Aggiungi colonne per landing page
ALTER TABLE promotions
ADD COLUMN IF NOT EXISTS landing_slug TEXT UNIQUE,
ADD COLUMN IF NOT EXISTS cta_text TEXT DEFAULT 'RISCATTA ORA',
ADD COLUMN IF NOT EXISTS original_price DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS category TEXT DEFAULT 'general';

-- Aggiungi indice per performance
CREATE INDEX IF NOT EXISTS idx_promotions_landing_slug ON promotions(landing_slug);
CREATE INDEX IF NOT EXISTS idx_promotions_category ON promotions(category);

-- Crea tabella per tracciare i riscatti
CREATE TABLE IF NOT EXISTS promotion_redemptions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    promotion_id UUID NOT NULL REFERENCES promotions(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    redeemed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    redemption_code TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'expired', 'cancelled'))
);

-- Indici per performance
CREATE INDEX IF NOT EXISTS idx_redemptions_promotion ON promotion_redemptions(promotion_id);
CREATE INDEX IF NOT EXISTS idx_redemptions_user ON promotion_redemptions(user_id);
CREATE INDEX IF NOT EXISTS idx_redemptions_status ON promotion_redemptions(status);

-- RLS per redemptions
ALTER TABLE promotion_redemptions ENABLE ROW LEVEL SECURITY;

-- Policy: Tutti possono inserire riscatti
CREATE POLICY "Anyone can create redemptions"
ON promotion_redemptions FOR INSERT
WITH CHECK (true);

-- Policy: Gli utenti vedono solo i propri riscatti
CREATE POLICY "Users see own redemptions"
ON promotion_redemptions FOR SELECT
USING (auth.uid() = user_id);

-- Policy: Le organizzazioni vedono i riscatti delle loro promo
CREATE POLICY "Organizations see their redemptions"
ON promotion_redemptions FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM promotions p
        WHERE p.id = promotion_redemptions.promotion_id
        AND p.organization_id = auth.uid()
    )
);

-- Commenti
COMMENT ON COLUMN promotions.landing_slug IS 'Slug univoco per URL landing page (/promo/{slug})';
COMMENT ON COLUMN promotions.cta_text IS 'Testo del pulsante Call-to-Action';
COMMENT ON COLUMN promotions.original_price IS 'Prezzo originale (prima dello sconto)';
COMMENT ON COLUMN promotions.category IS 'Categoria: food, beauty, wellness, shopping, entertainment, travel';
COMMENT ON TABLE promotion_redemptions IS 'Traccia i riscatti delle promozioni';

-- Esempi categorie valide
COMMENT ON COLUMN promotions.category IS 'Categories: food, beauty, wellness, shopping, entertainment, travel, general';
