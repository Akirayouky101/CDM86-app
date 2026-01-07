-- ============================================
-- ADD CARD_DATA TO organization_pages
-- Aggiunge campo per dati card promozione
-- ============================================

-- Aggiungi colonna card_data per i dati della card promozione
ALTER TABLE organization_pages 
ADD COLUMN IF NOT EXISTS card_data JSONB DEFAULT '{"title": "", "description": "", "image": "", "badge": "", "features": []}';

-- Aggiungi flag per pubblicazione card
ALTER TABLE organization_pages
ADD COLUMN IF NOT EXISTS card_published BOOLEAN DEFAULT false;

COMMENT ON COLUMN organization_pages.card_data IS 'JSON con dati della card promozione (titolo, immagine, descrizione, features)';
COMMENT ON COLUMN organization_pages.card_published IS 'Se true, la card appare nella pagina promotions';
