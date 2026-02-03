-- Aggiorna tabella promotions per supportare landing pages
-- Versione SAFE - Controlla esistenza policy prima di crearle
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

-- Elimina e ricrea tabella redemptions (se esiste già)
DROP TABLE IF EXISTS promotion_redemptions CASCADE;

-- Crea tabella per tracciare i riscatti
CREATE TABLE promotion_redemptions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    promotion_id UUID NOT NULL REFERENCES promotions(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    redeemed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    redemption_code TEXT,
    status TEXT DEFAULT 'pending',
    CONSTRAINT promotion_redemptions_status_check CHECK (status IN ('pending', 'completed', 'expired', 'cancelled'))
);

-- Indici per performance
CREATE INDEX IF NOT EXISTS idx_redemptions_promotion ON promotion_redemptions(promotion_id);
CREATE INDEX IF NOT EXISTS idx_redemptions_user ON promotion_redemptions(user_id);
CREATE INDEX IF NOT EXISTS idx_redemptions_status ON promotion_redemptions(status);

-- RLS per redemptions
ALTER TABLE promotion_redemptions ENABLE ROW LEVEL SECURITY;

-- Elimina policy esistenti se presenti (per evitare errori duplicate)
DROP POLICY IF EXISTS "Anyone can create redemptions" ON promotion_redemptions;
DROP POLICY IF EXISTS "Users can create redemptions" ON promotion_redemptions;
DROP POLICY IF EXISTS "Users see own redemptions" ON promotion_redemptions;
DROP POLICY IF EXISTS "Public can view promotions" ON promotions;

-- Ricrea policy aggiornate
CREATE POLICY "Users can create redemptions"
ON promotion_redemptions FOR INSERT
WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

CREATE POLICY "Users see own redemptions"
ON promotion_redemptions FOR SELECT
USING (auth.uid() = user_id OR user_id IS NULL);

-- Policy per vedere tutte le promo pubbliche
CREATE POLICY "Public can view promotions"
ON promotions FOR SELECT
USING (is_active = true);

-- Commenti
COMMENT ON COLUMN promotions.landing_slug IS 'Slug univoco per URL landing page (/promo/{slug})';
COMMENT ON COLUMN promotions.cta_text IS 'Testo del pulsante Call-to-Action';
COMMENT ON COLUMN promotions.original_price IS 'Prezzo originale (prima dello sconto)';
COMMENT ON COLUMN promotions.category IS 'Categories: food, beauty, wellness, shopping, entertainment, travel, general';
COMMENT ON TABLE promotion_redemptions IS 'Traccia i riscatti delle promozioni';

-- Verifica finale
SELECT 
    'landing_slug' as column_name,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'promotions' AND column_name = 'landing_slug'
    ) THEN '✅ Installata' ELSE '❌ Mancante' END as status
UNION ALL
SELECT 'cta_text',
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'promotions' AND column_name = 'cta_text'
    ) THEN '✅ Installata' ELSE '❌ Mancante' END
UNION ALL
SELECT 'promotion_redemptions table',
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'promotion_redemptions'
    ) THEN '✅ Installata' ELSE '❌ Mancante' END;
