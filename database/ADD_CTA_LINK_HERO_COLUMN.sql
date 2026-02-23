-- ============================================
-- ADD CTA LINK HERO TO organization_pages
-- Aggiunge il link del pulsante CTA dentro la landing page
-- Distinto da card_data.ctaLink che punta ALLA landing page
-- ============================================

-- Il pulsante CTA dentro la landing page (es. WhatsApp, sito esterno)
-- È diverso da card_data.ctaLink che serve a promotions.html
-- per aprire la landing stessa.

-- Nota: non serve una colonna separata perché il valore è già in:
--   card_data->>'ctaLinkHero'   (JSONB)
--   page_data->>'ctaLinkHero'   (JSONB)
-- Entrambi vengono gestiti dal landing-builder.html e promo-landing.html.

-- Se vuoi una colonna dedicata per query rapide, esegui questo:
ALTER TABLE organization_pages
ADD COLUMN IF NOT EXISTS cta_link_hero TEXT;

COMMENT ON COLUMN organization_pages.cta_link_hero IS 'URL del pulsante CTA dentro la landing page (es. WhatsApp, sito esterno). Diverso da card_data.ctaLink che punta alla landing stessa.';

-- Sincronizza con card_data esistente se già presente
UPDATE organization_pages
SET cta_link_hero = card_data->>'ctaLinkHero'
WHERE cta_link_hero IS NULL 
  AND card_data->>'ctaLinkHero' IS NOT NULL;

-- Verifica
SELECT 
    id,
    slug,
    cta_link_hero,
    card_data->>'ctaLink' AS card_cta_link,
    card_data->>'ctaLinkHero' AS card_cta_link_hero,
    status
FROM organization_pages
ORDER BY created_at DESC
LIMIT 10;
