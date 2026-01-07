-- ============================================
-- AGGIUNGE CAMPI PER PAGINA AZIENDALE
-- ============================================
-- Questi campi permettono alle aziende di personalizzare la loro pagina pubblica
-- ============================================

-- Aggiungi colonne se non esistono
DO $$ 
BEGIN
    -- Descrizione azienda (testo lungo)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'organizations' AND column_name = 'description'
    ) THEN
        ALTER TABLE organizations ADD COLUMN description TEXT;
    END IF;
    
    -- URL logo
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'organizations' AND column_name = 'logo_url'
    ) THEN
        ALTER TABLE organizations ADD COLUMN logo_url TEXT;
    END IF;
    
    -- URL immagine copertina
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'organizations' AND column_name = 'cover_url'
    ) THEN
        ALTER TABLE organizations ADD COLUMN cover_url TEXT;
    END IF;
    
    -- Sito web
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'organizations' AND column_name = 'website'
    ) THEN
        ALTER TABLE organizations ADD COLUMN website TEXT;
    END IF;
    
    -- Social media links (JSON)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'organizations' AND column_name = 'social_links'
    ) THEN
        ALTER TABLE organizations ADD COLUMN social_links JSONB;
    END IF;
    
    RAISE NOTICE 'Campi per pagina aziendale aggiunti con successo';
END $$;

-- Verifica struttura
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'organizations'
AND column_name IN ('description', 'logo_url', 'cover_url', 'website', 'social_links', 'user_id')
ORDER BY column_name;
