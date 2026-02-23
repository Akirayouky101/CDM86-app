-- ============================================================
-- MIGRAZIONE: Aggiungi colonne landing page a organization_pages
-- Esegui su Supabase SQL Editor
-- 
-- NOTA: Il landing builder ora salva su organization_pages
--       (non più su promotions - quella era la struttura vecchia)
-- ============================================================

-- 1. Colonne per il landing builder
ALTER TABLE organization_pages
ADD COLUMN IF NOT EXISTS landing_slug VARCHAR(255);

ALTER TABLE organization_pages
ADD COLUMN IF NOT EXISTS sections TEXT; -- JSON array stringified delle sezioni attive

ALTER TABLE organization_pages
ADD COLUMN IF NOT EXISTS page_type VARCHAR(50) DEFAULT 'landing';

ALTER TABLE organization_pages
ADD COLUMN IF NOT EXISTS content TEXT; -- HTML snapshot completo della landing

ALTER TABLE organization_pages
ADD COLUMN IF NOT EXISTS image_url TEXT;

ALTER TABLE organization_pages
ADD COLUMN IF NOT EXISTS cta_text VARCHAR(255) DEFAULT 'SCOPRI DI PIÙ';

ALTER TABLE organization_pages
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;

-- 2. Colonna social links
ALTER TABLE organization_pages
ADD COLUMN IF NOT EXISTS social_links JSONB DEFAULT '{}'::jsonb;

-- 3. Colonne titolo/descrizione (alias di page_title/page_description)
ALTER TABLE organization_pages
ADD COLUMN IF NOT EXISTS title VARCHAR(255);

ALTER TABLE organization_pages
ADD COLUMN IF NOT EXISTS description TEXT;

-- 4. Sync: popola landing_slug da slug dove mancante
UPDATE organization_pages 
SET landing_slug = slug 
WHERE landing_slug IS NULL AND slug IS NOT NULL;

-- 5. Indice per ricerca per slug landing
CREATE INDEX IF NOT EXISTS idx_org_pages_landing_slug 
ON organization_pages(landing_slug);

-- 6. Commenti
COMMENT ON COLUMN organization_pages.landing_slug IS 'Slug per URL pubblico /promo/{slug} - usato dal landing builder';
COMMENT ON COLUMN organization_pages.sections IS 'JSON array delle sezioni attive: hero, about, services, gallery, contact, social';
COMMENT ON COLUMN organization_pages.social_links IS 'JSON con link social: facebook, instagram, twitter, linkedin, tiktok, whatsapp, website';
COMMENT ON COLUMN organization_pages.content IS 'HTML completo della landing page (snapshot al momento della pubblicazione)';
COMMENT ON COLUMN organization_pages.page_type IS 'Tipo pagina: landing (default), card, profile';

-- 7. Verifica installazione
SELECT 
    column_name,
    data_type,
    '✅ OK' as status
FROM information_schema.columns 
WHERE table_name = 'organization_pages' 
  AND column_name IN ('landing_slug', 'sections', 'page_type', 'social_links', 'content', 'card_data', 'card_published', 'is_active', 'cta_text')
ORDER BY column_name;
