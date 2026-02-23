-- ============================================
-- ADD SOCIAL LINKS TO organization_pages
-- Aggiunge colonna per i link social media
-- ============================================

-- Aggiungi colonna social_links per i link social dell'organizzazione
ALTER TABLE organization_pages 
ADD COLUMN IF NOT EXISTS social_links JSONB DEFAULT '{}';

-- Aggiungi colonna landing_slug (alias del slug per compatibilità con landing builder)
ALTER TABLE organization_pages
ADD COLUMN IF NOT EXISTS landing_slug VARCHAR(255);

-- Aggiungi colonna page_type per distinguere landing vs altre pagine
ALTER TABLE organization_pages
ADD COLUMN IF NOT EXISTS page_type VARCHAR(50) DEFAULT 'landing';

-- Aggiungi colonna content per HTML snapshot della landing page
ALTER TABLE organization_pages
ADD COLUMN IF NOT EXISTS content TEXT;

-- Aggiungi colonne di compatibilità con landing-builder
ALTER TABLE organization_pages
ADD COLUMN IF NOT EXISTS title VARCHAR(255);

ALTER TABLE organization_pages
ADD COLUMN IF NOT EXISTS description TEXT;

ALTER TABLE organization_pages
ADD COLUMN IF NOT EXISTS image_url TEXT;

ALTER TABLE organization_pages
ADD COLUMN IF NOT EXISTS cta_text VARCHAR(255) DEFAULT 'SCOPRI DI PIÙ';

ALTER TABLE organization_pages
ADD COLUMN IF NOT EXISTS sections TEXT; -- JSON array delle sezioni attive

ALTER TABLE organization_pages
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;

-- Sincronizza landing_slug con slug se vuoto
UPDATE organization_pages 
SET landing_slug = slug 
WHERE landing_slug IS NULL AND slug IS NOT NULL;

-- Commenti
COMMENT ON COLUMN organization_pages.social_links IS 'JSON con link social: facebook, instagram, twitter, linkedin, tiktok, whatsapp, website';
COMMENT ON COLUMN organization_pages.landing_slug IS 'Slug per URL landing page pubblica (/promo/{slug})';
COMMENT ON COLUMN organization_pages.page_type IS 'Tipo di pagina: landing, card, profile';
COMMENT ON COLUMN organization_pages.content IS 'HTML completo della landing page pubblicata';
COMMENT ON COLUMN organization_pages.is_active IS 'Se true, la pagina è attiva e visibile';
